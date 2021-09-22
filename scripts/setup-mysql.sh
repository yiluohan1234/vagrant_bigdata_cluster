#!/bin/bash
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

# 安装mysql并为hive配置环境
install_mysql()
{
    #rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
    rpm -Uvh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
    yum install -y -q mysql mysql-server mysql-libs
    service mysqld start
    systemctl start mysqld.service
    mysqladmin -u root password 199037
    HOSTNAME="localhost"
    PORT="3306"
    USERNAME="root"
    PASSWORD="199037"
    # 创建hive的元数据库
    #mysql -uroot -p199037 -e "create user 'hive'@'%' IDENTIFIED BY 'hive';GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION;grant all on *.* to 'hive'@'localhost' identified by 'hive';flush privileges;"

    # 进行远程访问授权
    #mysql -uroot -p199037 -e "use mysql; update user set authentication_string=password('199037') where user='root'; update user set authentication_string=password('199037'),plugin='mysql_native_password' where user='root';grant all on *.* to root@'%' identified by '199037' with grant option;grant all privileges on *.* to 'root'@'%' identified by '199037' with grant option;flush privileges;"

}
install_mysql
