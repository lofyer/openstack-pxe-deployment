#!/bin/bash
export controller=192.168.0.80
source ~/keystone.rc
yum install -y openstack-nova openstack-nova-compute qemu-kvm libvirt virt-install bridge-utils
mv /etc/nova/nova.conf /etc/nova/nova.conf.org

echo -e "Configuring nova services except nova-compute...\n"

cat > /etc/nova/nova.conf <<EOF
# create new
[DEFAULT]
# define own IP
my_ip = $controller
state_path = /var/lib/nova
enabled_apis = osapi_compute,metadata
log_dir = /var/log/nova
# RabbitMQ connection info
transport_url = rabbit://openstack:password@$controller

[api]
auth_strategy = keystone

# Glance connection info
[glance]
api_servers = http://$controller:9292

[oslo_concurrency]
lock_path = $state_path/tmp

# MariaDB connection info
[api_database]
connection = mysql+pymysql://nova:password@$controller/nova_api

[database]
connection = mysql+pymysql://nova:password@$controller/nova

# Keystone auth info
[keystone_authtoken]
auth_uri = http://$controller:5000
auth_url = http://$controller:35357
memcached_servers = $controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = servicepassword

[placement]
auth_url = http://$controller:35357
os_region_name = RegionOne
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = placement
password = servicepassword

[placement_database]
connection = mysql+pymysql://nova:password@$controller/nova_placement

[wsgi]
api_paste_config = /etc/nova/api-paste.ini
EOF

chmod 640 /etc/nova/nova.conf
chgrp nova /etc/nova/nova.conf

sed -i '15a\  <Directory /usr/bin>\n   Require all granted\n  </Directory>' /etc/httpd/conf.d/00-nova-placement-api.conf

# SELinux
#semanage port -a -t http_port_t -p tcp 8778 
#checkmodule -m -M -o nova-api_pol.mod nova-api_pol.te
#semodule_package --outfile nova-api_pol.pp --module nova-api_pol.mod 
#semodule -i nova-api_pol.pp 

# Firewalld
#firewall-cmd --add-port={6080/tcp,8774/tcp,8775/tcp,8778/tcp} --permanent 
#firewall-cmd --reload 

su -s /bin/bash nova -c "nova-manage api_db sync"
su -s /bin/bash nova -c "nova-manage cell_v2 map_cell0 \
    --database_connection mysql+pymysql://nova:password@$controller/nova_cell0"
su -s /bin/bash nova -c "nova-manage db sync"
su -s /bin/bash nova -c "nova-manage cell_v2 create_cell --name cell1 \
    --database_connection mysql+pymysql://nova:password@$controller/nova \
    --transport-url rabbit://openstack:password@$controller:5672"
systemctl restart httpd
chown nova. /var/log/nova/nova-placement-api.log
for service in api cert consoleauth conductor scheduler novncproxy; do
    systemctl start openstack-nova-$service
    systemctl enable openstack-nova-$service
done
openstack compute service list

echo -e "Configuring nova-compute now...\n"

systemctl start libvirtd
systemctl enable libvirtd 

cat >> /etc/nova/nova.conf << EOF
[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $controller
novncproxy_base_url = http://$controller:6080/vnc_auto.html 
EOF

# SELinux
#checkmodule -m -M -o nova-compute_pol.mod nova-compute_pol.te 
#semodule_package --outfile nova-compute_pol.pp --module nova-compute_pol.mod 
#semodule -i nova-compute_pol.pp 

systemctl start openstack-nova-compute 
systemctl enable openstack-nova-compute
su -s /bin/bash nova -c "nova-manage cell_v2 discover_hosts"
openstack compute service list
