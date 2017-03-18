#!/bin/bash
export controller=192.168.0.80
yum install -y openstack-glance
source ~/keystone.rc
# Slacne service password
openstack user create --domain default --project service --password servicepassword glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image 
openstack endpoint create --region RegionOne image public http://$controller:9292 
openstack endpoint create --region RegionOne image internal http://$controller:9292 
openstack endpoint create --region RegionOne image admin http://$controller:9292 

# Create database
mysql -uroot -p123456 < add-glance-on-controller.sql

mv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.org 

cat > /etc/glance/glance-api.conf <<EOF
# create new
[DEFAULT]
bind_host = 0.0.0.0
notification_driver = noop

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

[database]
# MariaDB connection info
connection = mysql+pymysql://glance:password@$controller/glance

# keystone auth info
[keystone_authtoken]
auth_uri = http://$controller:5000
auth_url = http://$controller:35357
memcached_servers = $controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = servicepassword

[paste_deploy]
flavor = keystone
EOF

chmod 640 /etc/glance/glance-api.conf 
chown root:glance /etc/glance/glance-api.conf

mv /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.org 
cat > /etc/glance/glance-registry.conf <<EOF
# create new
[DEFAULT]
bind_host = 0.0.0.0
notification_driver = noop

[database]
# MariaDB connection info
connection = mysql+pymysql://glance:password@$controller/glance

# keystone auth info
[keystone_authtoken]
auth_uri = http://$controller:5000
auth_url = http://$controller:35357
memcached_servers = $controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = servicepassword

[paste_deploy]
flavor = keystone
EOF

chmod 640 /etc/glance/glance-registry.conf 
chown root:glance /etc/glance/glance-registry.conf
su -s /bin/bash glance -c "glance-manage db_sync"
systemctl enable openstack-glance-api openstack-glance-registry 
systemctl start openstack-glance-api openstack-glance-registry

# SELinux
#setsebool -P glance_api_can_network on
# Firewalld
#firewall-cmd --add-port={9191/tcp,9292/tcp} --permanent 
#firewall-cmd --reload
