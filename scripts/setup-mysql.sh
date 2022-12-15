#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/vbc-config.sh"
fi

install_mysql() {
    # 安装mysql57
    wget http://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
    yum -y install mysql57-community-release-el7-11.noarch.rpm
    yum -y install mysql-community-server

    # 启动并设置开机自启
    systemctl start mysqld.service
    systemctl enable mysqld.service

    # 更改初始密码
    #1获取安装时的临时密码（在第一次登录时就是用这个密码）：
    PASSWORD=`grep 'temporary password' /var/log/mysqld.log|awk -F "root@localhost: " '{print $2}'`

    PORT="3306"
    USERNAME="root"
    
    mysql -u${USERNAME} -p${PASSWORD} -e "set global validate_password_policy=0; \
        set global validate_password_length=4; \
        ALTER USER 'root'@'localhost' IDENTIFIED BY \'${MYSQL_PASSWORD}\'; \
        use mysql; \
        update user set host='%' where user='root'; \
        create user 'hive'@'%' IDENTIFIED BY 'hive'; \
        GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION; \
        GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%' IDENTIFIED BY 'canal'; \
        CREATE DATABASE maxwell; \
        GRANT ALL ON maxwell.* TO 'maxwell'@'%' IDENTIFIED BY 'maxwell'; \
        GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO maxwell@'%'; \
        CREATE DATABASE azkaban; \
        CREATE USER 'azkaban'@'%' IDENTIFIED BY '199037'; \
        GRANT SELECT,INSERT,UPDATE,DELETE ON azkaban.* to 'azkaban'@'%' WITH GRANT OPTION; \
        CREATE DATABASE zabbix character set utf8 collate utf8_bin; \
        CREATE USER 'zabbix'@'%' IDENTIFIED BY '199037'; \
        GRANT SELECT,INSERT,UPDATE,DELETE ON zabbix.* to 'zabbix'@'%' WITH GRANT OPTION; \
        CREATE DATABASE ranger;CREATE USER 'ranger'@'%' IDENTIFIED BY 'ranger'; \
        GRANT all privileges ON ranger.* to 'ranger'@'%' identified by 'ranger'; \
        CREATE DATABASE gmall CHARACTER SET 'utf8' COLLATE 'utf8_general_ci'; \
        CREATE DATABASE gmall_report CHARACTER SET 'utf8' COLLATE 'utf8_general_ci'; \
        flush privileges;" --connect-expired-password
    
    # 删除
    yum -y remove mysql57-community-release-el7-11.noarch
    rm -rf ~/mysql57-community-release-el7-11.noarch.rpm

}

if [ "${IS_VAGRANT}" == "true" ];then
    install_mysql
fi

