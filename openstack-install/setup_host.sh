#!/bin/bash
echo -e "Initialize iptables firewalld ssh httpd...\n"
systemctl disable firewalld
systemctl enable sshd
echo -e "Setup network...\n"
export IP=192.168.0.70
export IPPREFIX=192.168.0
