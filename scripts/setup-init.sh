#!/bin/bash
# at /home/vagrant
if [ "${IS_VAGRANT}" == "true" ];then
    source "/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
else
    source "/home/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
fi
#---basic install---
# -q（不显示安装的过程）
yum install -y -q sshpass
yum install -y -q lrzsz
yum install -y -q expect
yum install -y -q vim-enhanced
yum install -y -q unzip
yum install -y -q zip
yum install -y -q nmap-ncat
yum install -y -q net-tools
yum install -y -q epel-release  
yum install -y -q lsof
yum install -y -q nc
yum install -y -q wget
yum install -y *unixODBC*
yum install -y http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm
yum install -y git

#---ssh---
mv /home/vagrant/vagrant_bigdata_cluster/resources/sshd_config /etc/ssh/sshd_config
systemctl restart sshd.service

[ ! -d $INSTALL_PATH ] && mkdir -p $INSTALL_PATH
[ ! -d $DOWNLOAD_PATH ] && mkdir -p $DOWNLOAD_PATH
[ ! -d $INIT_SHELL_BIN ] && mkdir -p $INIT_SHELL_BIN

chown -R vagrant:vagrant $INSTALL_PATH
chown -R vagrant:vagrant $DOWNLOAD_PATH
chown -R vagrant:vagrant $INIT_SHELL_BIN

# 启动elasticsearch需要的设置
# 更改最大文件句柄数和最大线程数限制
echo -e "* soft nofile 65536\n* hard nofile 65536\n* soft nproc 131072\n* hard nproc 131072" >> /etc/security/limits.conf

# CentOS取消SELINUX
echo -e "SELINUX=disabled" >> /etc/selinux/config

# 虚拟内存扩容
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# 统一缩进为4
echo "set tabstop=4" > /home/vagrant/.vimrc
echo "set softtabstop=4" > /home/vagrant/.vimrc
echo "set shiftwidth=4" > /home/vagrant/.vimrc

# 复制初始化程序到init_shell的bin目录
log info "copy init shell to ${INIT_SHELL_BIN}"
cp $INIT_PATH/* ${INIT_SHELL_BIN}
chmod 777 ${INIT_SHELL_BIN}/jpsall
chmod 777 ${INIT_SHELL_BIN}/bigstart
chmod 777 ${INIT_SHELL_BIN}/setssh
chmod 777 ${INIT_SHELL_BIN}/xsync
echo "export INIT_SHELL_BIN=${INIT_SHELL_BIN}" >> ${PROFILE}
echo 'export PATH=${INIT_SHELL_BIN}:$PATH' >> ${PROFILE}
source ${PROFILE}