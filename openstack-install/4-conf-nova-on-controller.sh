#!/bin/bash
export controller=192.168.0.80
source ~/keystone.rc
openstack user create --domain default --project service --password servicepassword nova 
openstack role add --project service --user nova admin
openstack user create --domain default --project service --password servicepassword placement
openstack role add --project service --user placement admin
openstack service create --name nova --description "OpenStack Compute service" compute
openstack service create --name placement --description "OpenStack Compute Placement service" placement
openstack endpoint create --region RegionOne compute public http://$controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://$controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://$controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne placement public http://$controller:8778
openstack endpoint create --region RegionOne placement internal http://$controller:8778
openstack endpoint create --region RegionOne placement admin http://$controller:8778

mysql -uroot -p123456 < add-nova-on-controller.sql
