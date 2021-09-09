#!/bin/bash
# at /home/vagrant
source "/vagrant/scripts/common.sh"
#---basic install---
yum install -y sshpass
        
:<<skip
sudo yum install -y vim-enhanced
sudo yum install -y nmap-ncat
sudo yum install -y lrzsz
sudo yum install -y net-tools
sudo yum install -y epel-release  
sudo yum install -y lsof
sudo yum install -y nc
sudo yum install -y unzip
sudo yum install -y zip
sudo yum install -y expect
skip
#---ssh---
mv /home/vagrant/resources/sshd_config /etc/ssh/sshd_config
systemctl restart sshd.service

[ ! -d $INSTALL_PATH ] && mkdir -p $INSTALL_PATH
[ ! -d $DOWNLOAD_PATH ] && mkdir -p $DOWNLOAD_PATH
chown -R vagrant:vagrant $INSTALL_PATH
chown -R vagrant:vagrant $DOWNLOAD_PATH