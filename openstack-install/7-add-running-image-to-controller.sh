#!/bin/bash
export controller=192.168.0.80
source ~/keystone.rc

mkdir -p /var/kvm/images

# CentOS7 from virtinstall
#qemu-img create -f qcow2 /var/kvm/images/centos7.img 10G
#virt-install --name centos7 --ram 2048 --disk path=/var/kvm/images/centos7.img,format=qcow2 --vcpus 2 --os-type linux --os-variant rhel7 --graphics none --console pty,target_type=serial --location 'http://mirrors.ustc.edu.cn/centos/7/os/x86_64/' --extra-args 'console=ttyS0,115200n8 serial'
#openstack image create "CentOS7" --file /var/kvm/images/centos7.img --disk-format qcow2 --container-format bare --public

# Ubuntu1604 from ubutun
#wget http://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img -P /var/kvm/images
#openstack image create "Ubuntu1604" --file /var/kvm/images/ubuntu-16.04-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --public 
#openstack image list

# Cirros
wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
openstack image create "cirros" --file cirros-0.3.5-x86_64-disk.img --disk-format qcow2 --container-format bare --public 
openstack image list

openstack flavor create --id 0 --vcpus 1 --ram 2048 --disk 10 m1.small 
openstack flavor list
openstack image list
openstack network list
netID=`openstack network list | grep sharednet1 | awk '{ print $2 }'` 
openstack server create --flavor m1.small --image cirros --security-group default --nic net-id=$netID cirros_instance
echo -e "Building instance...\n"
sleep 30
openstack server list

openstack security group rule create --protocol icmp --ingress default
openstack security group rule create --protocol tcp --dst-port 22:22 default
openstack security group rule list 
ping 10.0.0.201 -c 5

# Pubkey

#echo -e "Enter pubkey...\n"
#ssh-keygen -q -N ""
#openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
#openstack keypair list

#openstack server create --flavor m1.small --image CentOS7 --security-group default --nic net-id=$netID --key-name mykey CentOS_7
#ssh -i mykey centos@10.0.0.194
#openstack server stop cirros
openstack console url show cirros_instance
