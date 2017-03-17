#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --disabled
# Install OS instead of upgrade
install
# Use HTTP installation media
url --url="http://172.16.111.10:8080/centos/iso-root/"
# Root password [i used here 000000]
rootpw --iscrypted $1$xYUugTf4$4aDhjs0XfqZ3xUqAg7fH3.
# System authorization information
auth  useshadow  passalgo=sha512
# Use graphical install
graphical
firstboot disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux disabled
# Network
#network --bootproto=dhcp --ipv6=auto --activate --hostname=localhost
network --bootproto=dhcp --ipv6=auto --activate
# Installation logging level
logging level=info
# System timezone
timezone Asia/Shanghai
# System bootloader configuration
bootloader location=mbr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --size=1024
part /boot --fstype xfs --size=200
part pv.01 --size=1 --grow
volgroup rootvg01 pv.01
logvol / --fstype xfs --name=lv01 --vgname=rootvg01 --size=1 --grow

%packages
@core
%end

%post
%end
