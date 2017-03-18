#!/bin/bash
export controller=192.168.0.80
export subnet=192.168.118
source ~/keystone.rc

ovs-vsctl add-br br-ens38
ovs-vsctl add-port br-ens38 ens38

sed -i "/\[ml2_type_flat\]$/aflat_networks = physnet1" /etc/neutron/plugins/ml2/ml2_conf.in
sed -i "/\[ovs\]$/abridge_mappings = physnet1:br-ens38" /etc/neutron/plugins/ml2/openvswitch_agent.ini

systemctl restart neutron-openvswitch-ageno

projectID=`openstack project list | grep service | awk '{print $2}'`
openstack network create --project $projectID \
    --share --provider-network-type flat --provider-physical-network physnet1 sharednet1

# Create subnet
openstack subnet create subnet1 --network sharednet1 \
    --project $projectID --subnet-range $subnet.0/24 \
    --allocation-pool start=$subnet.200,end=$subnet.254 \
    --gateway $subnet.1 --dns-nameserver $subnet.1

openstack network list
openstack subnet list
