#!/bin/bash
source "/vagrant/scripts/common.sh"

log info "Centos 基本配置" 
log info "安装 epel-release" 
yum install -y -q epel-release

# 设置系统时区
log info "设置时区" 
timedatectl set-timezone Asia/Shanghai 

# ssh 设置允许密码登录
log info "设置ssh" 
sed -i 's@^PasswordAuthentication no@PasswordAuthentication yes@g' /etc/ssh/sshd_config
sed -i 's@^#PubkeyAuthentication yes@PubkeyAuthentication yes@g' /etc/ssh/sshd_config
systemctl restart sshd.service
log info "设置最大文件句柄数、最大线程数和最大进程数" 
# 设置最大文件句柄数和最大线程数
echo -e "* soft nofile 65536\n* hard nofile 65536\n* soft nproc 131072\n* hard nproc 131072" >> /etc/security/limits.conf
# 设置进程数
sed -i 's@4096@65536@g' /etc/security/limits.d/20-nproc.conf
# CentOS取消SELINUX
sed -i "s@^SELINUX=.*@SELINUX=disabled@g" /etc/selinux/config
# 虚拟内存扩容
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# 安装基本的软件：-q（不显示安装的过程）
# 高质量软件包管理
log info "安装 sshpass lrzsz expect unzip zip vim-enhanced lzop"
yum install -y -q sshpass
yum install -y -q lrzsz 
yum install -y -q expect 
yum install -y -q unzip 
yum install -y -q zip 
yum install -y -q vim-enhanced 
yum install -y -q lzop 
yum install -y -q dos2unix
log info "安装 nmap-ncat net-tools nc wget lsof"
yum install -y -q nmap-ncat 
yum install -y -q net-tools 
yum install -y -q nc 
yum install -y -q wget 
yum install -y -q lsof 
yum install -y -q telnet 
yum install -y -q tcpdump 
yum install -y -q ntp
# 已安装(查看openssl version -a)
# yum install -y -q openssl-devel
# git升级
log info "安装 git" 
#yum remove -y  -q git
rpm -ivh https://opensource.wandisco.com/git/wandisco-git-release-7-2.noarch.rpm
yum install -y -q git

# 支持中文包
# yum -y -q groupinstall "fonts"
log info "安装 中文包" 
yum install -y -q glibc-common
localectl set-locale LANG=zh_CN.UTF-8
