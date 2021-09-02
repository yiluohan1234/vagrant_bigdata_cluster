#!/bin/bash
# at /home/vagrant
#---basic install---
sudo yum install -y epel-release          

sudo yum install -y vim-enhanced
sudo yum install -y nmap-ncat
sudo yum install -y lrzsz
sudo yum install -y net-tools
sudo yum install -y sshpass
sudo yum install -y lsof
sudo yum install -y nc
sudo yum install -y unzip
sudo yum install -y zip
sudo yum install -y expect
#---ssh---
mv /home/vagrant/resources/sshd_config /etc/ssh/sshd_config
systemctl restart sshd.service

#---hosts---
cat >>/etc/hosts <<EOF
192.168.10.101  hdp-node-01
192.168.10.102  hdp-node-02
192.168.10.103  hdp-node-03
EOF
