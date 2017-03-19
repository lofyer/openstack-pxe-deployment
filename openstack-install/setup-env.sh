#!/bin/bash
export ip=192.168.0.80
export fqdn=os.example.com
export hostname=os
chkconfig NetworkManager off
chkconfig network on

echo -e "$ip $fqdn $hostname" >> /etc/hosts
hostname $fqdn
