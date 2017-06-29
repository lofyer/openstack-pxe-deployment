#!/bin/bash
# ON ADMIN NODE
yum install -y epel-release gcc python-devel python-pip
yum install -y ceph-deploy
# pip2 install ceph-deploy

ssh-copy-id root@ceph1
ssh-copy-id root@ceph2
ssh-copy-id root@ceph3

mkdir ceph-deploy; cd ceph-deploy

ceph-deploy purge ceph1 ceph2 ceph3
ceph-deploy purgedata ceph1 ceph2 ceph3
ceph-deploy forgetkeys

ceph-deploy new ceph1 ceph2 ceph3

ceph-deploy mon create-initial

ceph-deploy install ceph1 ceph2 ceph3

# NEED to be executed on every host

hostname

parted /dev/sda mklabel gpt
parted /dev/sda mkpart journal 0% 20%
parted /dev/sda mkpart journal 20% 100%

mkfs.xfs -f -i size=512 -l size=128m,lazy-count=1 /dev/sda1
mkfs.xfs -f -i size=512 -l size=128m,lazy-count=1 /dev/sda2

mkdir -p /ceph/{journal,data}

# EDIT fstab, DO NOT mount journal
#/dev/sda1       /ceph/journal   xfs     noatime,nodiratime,nobarrier 0 0
/dev/sda2       /ceph/data      xfs     noatime,nodiratime,nobarrier 0 0

mount -a

# ON ADMIN NODE
ceph-deploy mon create-initial

OR

ceph-deploy --overwrite-conf mon create ceph1 ceph2 ceph3
ceph-deploy --overwrite-conf config push ceph1 ceph2 ceph3
ceph-deploy gatherkeys ceph1 ceph2 ceph3

# NEXT
ceph-deploy --overwrite-conf osd create \
ceph-1:/ceph/data:/dev/sda1 \
ceph-2:/ceph/data:/dev/sda1 \
ceph-3:/ceph/data:/dev/sda1

# Change the partion uid or disk uid with osd uid
#sgdisk -t 1:45B0969E-9B03-4F30-B4C6-B4B80CEFF106 /dev/sdd
#chown ceph:ceph /dev/sda1

ceph-deploy --overwrite-conf osd activate \
ceph1:/ceph/data:/dev/sda1 \
ceph2:/ceph/data:/dev/sda1 \
ceph3:/ceph/data:/dev/sda1

ceph osd crush add-bucket ceph1 host
ceph osd crush add-bucket ceph2 host
ceph osd crush add-bucket ceph3 host

ceph osd crush move ceph1 root=default
ceph osd crush move ceph2 root=default
ceph osd crush move ceph2 root=default

ceph osd crush create-or-move osd.0 0.2 root=default host=ceph1
ceph osd crush create-or-move osd.1 0.2 root=default host=ceph2
ceph osd crush create-or-move osd.2 0.2 root=default host=ceph3
