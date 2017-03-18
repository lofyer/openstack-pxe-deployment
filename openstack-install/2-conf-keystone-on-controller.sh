#!/bin/bash
export controller=192.168.0.80
# Install Keystone
yum install -y openstack-keystone openstack-utils python-openstackclient httpd mod_wsgi

# Create database
mysql -uroot -p123456 < add-keystone-on-controller.sql


sed -i "/\[memcache\]$/aservers = $controller:11211" /etc/keystone/keystone.conf
sed -i  "/\[database\]$/aconnection = mysql+pymysql://keystone:password@$controller\/keystone" /etc/keystone/keystone.conf
sed -i "/\[token\]$/aprovider = fernet\ndriver = memcache" /etc/keystone/keystone.conf

su -s /bin/bash keystone -c "keystone-manage db_sync"

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone 
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Set admin password in Horizon
keystone-manage bootstrap --bootstrap-password admin \
    --bootstrap-admin-url http://$controller:35357/v3/ \
    --bootstrap-internal-url http://$controller:35357/v3/ \
    --bootstrap-public-url http://$controller:5000/v3/ \
    --bootstrap-region-id RegionOne

# SELinux
#setsebool -P httpd_use_openstack on 
#setsebool -P httpd_can_network_connect on 
#setsebool -P httpd_can_network_connect_db on 

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl start httpd 
systemctl enable httpd 

# Firewalld
#firewall-cmd --add-port={5000/tcp,35357/tcp} --permanent 
#firewall-cmd --reload 

cat > ~/keystone.rc << EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=admin
export OS_AUTH_URL=http://$controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='[\u@\h \W(keystone)]\\$ '
EOF

chmod 600 ~/keystone.rc 
source ~/keystone.rc 

# Create service project
openstack project create --domain default --description "Service Project" service
openstack project list
