#!/bin/bash
export controller=192.168.0.80
export node=192.168.0.81

yum install -y openstack-nova-compute qemu-kvm libvirt virt-install bridge-utils openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
systemctl enable libvirtd
systemctl start libvirtd
mv /etc/nova/nova.conf /etc/nova/nova.conf.org 
cat > /etc/nova/nova.conf <<EOF
# create new
[DEFAULT]
# define own IP address
my_ip = $node
state_path = /var/lib/nova
enabled_apis = osapi_compute,metadata
log_dir = /var/log/nova
# RabbitMQ connection info
transport_url = rabbit://openstack:password@$controller

[api]
auth_strategy = keystone

# enable VNC
[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $node
novncproxy_base_url = http://$controller:6080/vnc_auto.html 

# Glance connection info
[glance]
api_servers = http://$controller:9292

[oslo_concurrency]
lock_path = \$state_path/tmp

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

[wsgi]
api_paste_config = /etc/nova/api-paste.ini
EOF

chmod 640 /etc/nova/nova.conf
chgrp nova /etc/nova/nova.conf

systemctl start openstack-nova-compute
systemctl enable openstack-nova-compute
su -s /bin/bash nova -c "nova-manage cell_v2 discover_hosts"
openstack compute service list

echo "Configuring Neutron..."
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.org
cat > /etc/neutron/neutron.conf << EOF
# create new
[DEFAULT]
core_plugin = ml2
service_plugins = router
auth_strategy = keystone
state_path = /var/lib/neutron
allow_overlapping_ips = True
# RabbitMQ connection info
transport_url = rabbit://openstack:password@$controller

# Keystone auth info
[keystone_authtoken]
auth_uri = http://$controller:5000
auth_url = http://$controller:35357
memcached_servers = $controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = servicepassword

[oslo_concurrency]
lock_path = \$state_path/lock
EOF

chmod 640 /etc/neutron/neutron.conf 
chgrp neutron /etc/neutron/neutron.conf 

# ML2_CONF
sed -i "114atype_drivers = flat,vlan,gre,vxlan\ntenant_network_types =\nmechanism_drivers = openvswitch,l2population\nextension_drivers = port_security" /etc/neutron/plugins/ml2/ml2_conf.ini
echo -e "enable_security_group = True\nfirewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver\nenable_ipset = True" >> /etc/neutron/plugins/ml2/ml2_conf.ini

# ADD NOVA_CONF
sed -i "/\[DEFAULT\]$/a# NEUTRON\nuse_neutron = True\nlinuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver\nfirewall_driver = nova.virt.firewall.NoopFirewallDriver\nvif_plugging_is_fatal = True\nvif_plugging_timeout = 300" /etc/nova/nova.conf
cat >> /etc/nova/nova.conf <<EOF

[neutron]
url = http://$controller:9696
auth_url = http://$controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = servicepassword
service_metadata_proxy = True
metadata_proxy_shared_secret = metadata_secret
EOF

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini 
systemctl start openvswitch 
systemctl enable openvswitch 
ovs-vsctl add-br br-int 
systemctl restart openstack-nova-compute 
systemctl start neutron-openvswitch-agent 
systemctl enable neutron-openvswitch-agent 
