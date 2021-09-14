#!/bin/bash
# at /home/vagrant
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi
#---basic install---
# -q（不显示安装的过程）
yum install -y -q sshpass
yum install -y -q lrzsz
yum install -y -q expect
        
:<<skip
sudo yum install -y vim-enhanced
sudo yum install -y nmap-ncat
sudo yum install -y net-tools
sudo yum install -y epel-release  
sudo yum install -y lsof
sudo yum install -y nc
sudo yum install -y unzip
sudo yum install -y zip
skip
#---ssh---
mv /home/vagrant/resources/sshd_config /etc/ssh/sshd_config
systemctl restart sshd.service

[ ! -d $INSTALL_PATH ] && mkdir -p $INSTALL_PATH
[ ! -d $DOWNLOAD_PATH ] && mkdir -p $DOWNLOAD_PATH
chown -R vagrant:vagrant $INSTALL_PATH
chown -R vagrant:vagrant $DOWNLOAD_PATH

# 启动elasticsearch需要的设置
# 更改最大文件句柄数和最大线程数限制
echo -e "* soft nofile 65536\n* hard nofile 65536\n* soft nproc 2048\n* hard nproc 65536" >> /etc/security/limits.conf

# 虚拟内存扩容
echo "vm.max_map_count=262144" >> /etc/sysctl.conf