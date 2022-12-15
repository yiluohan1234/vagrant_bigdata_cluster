#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_mysql() {
    # 安装mysql57
    wget http://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
    yum -y install mysql57-community-release-el7-11.noarch.rpm
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_mysql
fi

