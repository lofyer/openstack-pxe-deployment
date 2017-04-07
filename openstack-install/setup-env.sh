#!/bin/bash
export ip=192.168.0.80
export fqdn=os.example.com
export hostname=os

systemctl disable NetworkManager
systemctl enable network

echo -e "$ip $fqdn $hostname" >> /etc/hosts
hostname $fqdn

yum install -y iptables-services
