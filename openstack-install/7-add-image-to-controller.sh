#!/bin/bash
export controller=192.168.0.80
source ~/keystone.rc

mkdir -p /var/kvm/images
#qemu-img create -f qcow2 /var/kvm/images/centos7.img 10G
#virt-install --name centos7 --ram 2048 --disk path=/var/kvm/images/centos7.img,format=qcow2 --vcpus 2 --os-type linux --os-variant rhel7 --graphics none --console pty,target_type=serial --location 'http://mirrors.ustc.edu.cn/centos/7/os/x86_64/' --extra-args 'console=ttyS0,115200n8 serial'

#openstack image create "CentOS7" --file /var/kvm/images/centos7.img --disk-format qcow2 --container-format bare --public

wget http://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img -P /var/kvm/images

openstack image create "Ubuntu1604" --file /var/kvm/images/ubuntu-16.04-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --public 

openstack image list
