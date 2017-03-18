create database glance;
grant all privileges on glance.* to glance@'localhost' identified by 'password';
grant all privileges on glance.* to glance@'%' identified by 'password';
flush privileges;
