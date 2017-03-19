#/bin/bash
echo -e "Install essential packages...\n"
yum install -y mariadb-server rabbitmq-server memcached iptables-services
systemctl disable firewalld
systemctl stop firewalld
iptables -F
service iptables save

# Disable mysql name-resolv
sed -i "/\[mysqld\]$/askip-name-resolve" /etc/my.cnf.d/mariadb-server.cnf

systemctl enable mariadb rabbitmq-server memcached iptables
systemctl start mariadb rabbitmq-server memcached iptables

echo -e "Setting MySQL and RabbitMQ...\n"
# Set mysql root password
mysqladmin password 123456
# RabbitMQ ready
rabbitmqctl add_user openstack password 
rabbitmqctl set_permissions openstack ".*" ".*" ".*" 

# Firewalld
#firewall-cmd --add-port={11211/tcp,5672/tcp} --permanent 
#firewall-cmd --reload
