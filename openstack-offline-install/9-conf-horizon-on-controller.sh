#!/bin/bash
export controller=192.168.0.80
export hostname=controller
export memcache=$controller
source ~/keystone.rc

yum install -y openstack-dashboard
# Host that can visit horizon
# Uncomment below to allow all
sed -i "s/^DEBUG = False/DEBUG = True/g" /etc/openstack-dashboard/local_settings
sed -i "28aALLOWED_HOSTS = \[\'$hostname\', \'localhost\'\]" /etc/openstack-dashboard/local_settings
sed -i "60aOPENSTACK_API_VERSIONS = {\n    #\"data-processing\": 1\.1,\n    \"identity\": 3,\n    \"volume\": 2,\n    \"compute\": 2,\n}" /etc/openstack-dashboard/local_settings
sed -i "71aOPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True" /etc/openstack-dashboard/local_settings
sed -i "80aOPENSTACK_KEYSTONE_DEFAULT_DOMAIN = \'Default\'" /etc/openstack-dashboard/local_settings
sed -i "142aCACHES = {\n    \'default\': {\n        \'BACKEND\': \'django.core.cache.backends.memcached.MemcachedCache\',\n        \'LOCATION\': \'$controller:11211\',\n   },\n}" /etc/openstack-dashboard/local_settings

sed -i "s/^OPENSTACK_HOST.*$/OPENSTACK_HOST = \"$controller\"/g" /etc/openstack-dashboard/local_settings
sed -i "s/^OPENSTACK_KEYSTONE_DEFAULT_ROLE.*$/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"/g" /etc/openstack-dashboard/local_settings

systemctl restart httpd memcached 

# SELinux
#setsebool -P httpd_can_network_connect on 
# Firewalld
#firewall-cmd --add-service={http,https} --permanent 
#firewall-cmd --reload
