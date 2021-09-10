#!/bin/bash
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi
set -x
# 安装mysql并为hive配置环境
install_mysql()
{
    rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
    yum install -y -q mysql mysql-server mysql-libs
    service mysqld start
    systemctl start mysqld.service
    mysqladmin -u root password 199037
    HOSTNAME="localhost"
    PORT="3306"
    USERNAME="root"
    PASSWORD="199037"
}
install_mysql
