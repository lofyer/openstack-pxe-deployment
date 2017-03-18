create database neutron_ml2;
grant all privileges on neutron_ml2.* to neutron_ml2@'localhost' identified by 'password';
grant all privileges on neutron_ml2.* to neutron_ml2@'%' identified by 'password';
flush privileges;
