#!/bin/bash
export controller=192.168.0.80
source ~/keystone.rc

yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch

openstack user create --domain default --project service --password servicepassword neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking service" network
openstack endpoint create --region RegionOne network public http://$controller:9696 
openstack endpoint create --region RegionOne network internal http://$controller:9696
openstack endpoint create --region RegionOne network admin http://$controller:9696

mysql -uroot -p123456 < add-neutron_ml2-on-controller.sql

echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
sysctl -p

mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.org
cat > /etc/neutron/neutron.conf << EOF
# create new
[DEFAULT]
core_plugin = ml2
service_plugins = router
auth_strategy = keystone
state_path = /var/lib/neutron
dhcp_agent_notification = True
allow_overlapping_ips = True
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
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

# MariaDB connection info
[database]
connection = mysql+pymysql://neutron:password@$controller/neutron_ml2

# Nova connection info
[nova]
auth_url = http://$controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = servicepassword

[oslo_concurrency]
lock_path = \$state_path/tmp
EOF

chmod 640 /etc/neutron/neutron.conf
chgrp neutron /etc/neutron/neutron.conf

# L3
sed -i "17ainterface_driver = neutron.agent.linux.interface.OVSInterfaceDriver" /etc/neutron/l3_agent.ini
sed -i "100aexternal_network_bridge =" /etc/neutron/l3_agent.ini

# DHCP_AGENT
sed -i "17ainterface_driver = neutron.agent.linux.interface.OVSInterfaceDriver" /etc/neutron/dhcp_agent.ini
sed -i "33adhcp_driver = neutron.agent.linux.dhcp.Dnsmasq" /etc/neutron/dhcp_agent.ini
sed -i "43aenable_isolated_metadata = True" /etc/neutron/dhcp_agent.ini

# METADATA
sed -i "22anova_metadata_ip = $controller" /etc/neutron/metadata_agent.ini
sed -i "35ametadata_proxy_shared_secret = metadata_secret" /etc/neutron/metadata_agent.ini

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

# SELinux
#setsebool -P neutron_can_network on 
#checkmodule -m -M -o neutron-services_pol.mod neutron-services_pol.te
#semodule_package --outfile neutron-services_pol.pp --module neutron-services_pol.mod 
#semodule -i neutron-services_pol.pp

# Firewalld
#firewall-cmd --add-port=9696/tcp --permanent
#firewall-cmd --reload

systemctl start openvswitch
systemctl enable openvswitch
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini 
su -s /bin/bash neutron -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head"
for service in server dhcp-agent l3-agent metadata-agent openvswitch-agent; do
    systemctl start neutron-$service
    systemctl enable neutron-$service
done
systemctl restart openstack-nova-api openstack-nova-compute
openstack network agent list 
