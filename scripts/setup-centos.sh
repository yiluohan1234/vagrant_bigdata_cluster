#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/vbc-function.sh"
    source "/vagrant/scripts/vbc-config.sh"
fi

log info "Basic configuration"

# Set timezone
log info "Set timezone"
timedatectl set-timezone Asia/Shanghai

# Ssh:Set to allow password login
log info "Set vagrant ssh"
sed -i 's@^PasswordAuthentication no@PasswordAuthentication yes@g' /etc/ssh/sshd_config
sed -i 's@^#PubkeyAuthentication yes@PubkeyAuthentication yes@g' /etc/ssh/sshd_config
systemctl restart sshd.service
log info "Set the maximum number of file handles, maximum number of threads and maximum number of processes"
# Set the maximum number of file handles and maximum number of threads
echo -e "* soft nofile 65536\n* hard nofile 65536\n* soft nproc 131072\n* hard nproc 131072" >> /etc/security/limits.conf
# Set the number of processes
sed -i 's@4096@65536@g' /etc/security/limits.d/20-nproc.conf
# CentOS cancel SELINUX
sed -i "s@^SELINUX=.*@SELINUX=disabled@g" /etc/selinux/config
# Virtual memory expansion
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

Install basic software: -q (do not display the installation process)
log info "Install epel-release sshpass lrzsz expect unzip zip vim-enhanced lzop dos2unix nmap-ncat net-tools nc wget lsof"
for app in ${CENTOS_BASIC_APPS[@]};do
    yum install -y -q ${app}
done

# git upgrade
if [ "${IS_UPDATE_GIT}" == "true" ];then
    log info "安装 git"
    #yum remove -y  -q git
    rpm -ivh https://opensource.wandisco.com/git/wandisco-git-release-7-2.noarch.rpm
    yum install -y -q git
fi

# Support Chinese language pack
if [ "${IS_CHINESE}" == "true" ];then
    # yum -y -q groupinstall "fonts"
    log info "Install Chinese language pack"
    yum install -y -q glibc-common
    localectl set-locale LANG=zh_CN.UTF-8
fi
