#!/bin/bash
yum install -y kubernetes etcd flannel
echo "192.168.0.30 k1.example.com
192.168.0.31 k2.example.com
192.168.0.32 k3.example.com" >> /etc/hosts
