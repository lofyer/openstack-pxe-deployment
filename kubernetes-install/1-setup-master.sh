#!/bin/bash
yum install -y kubernetes etcd flannel
echo "192.168.0.30 centos-master
192.168.0.31 centos-minion-1
192.168.0.32 centos-minion-2" >> /etc/hosts
