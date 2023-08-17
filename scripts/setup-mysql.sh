#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_mysql() {
    # Install mysql57
    curl -o /root/mysql57-community-release-el7-11.noarch.rpm -O -L http://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
    # 卸载自带的Mysql-libs
    # rpm -qa | grep -i -E mysql\|mariadb | xargs -n1 sudo rpm -e --nodeps
    yum -y -q install /root/mysql57-community-release-el7-11.noarch.rpm
    yum -y -q install mysql-community-server
    # copy configuration file my.cnf
    sed -i "4askip_ssl" /etc/my.cnf
    sed -i "4abinlog-do-db=gmall" /etc/my.cnf
    sed -i "4abinlog_format=row" /etc/my.cnf
    sed -i "4alog-bin=mysql-bin" /etc/my.cnf
    sed -i "4aserver-id=1" /etc/my.cnf

    # Start and set up to start automatically
    systemctl start mysqld.service
    systemctl enable mysqld.service

    # change initial password
    # Obtain the temporary password during installation (this password is used when logging in for the first time)：
    PASSWORD=`grep 'temporary password' /var/log/mysqld.log|awk -F "root@localhost: " '{print $2}'`

    PORT="3306"
    USERNAME="root"

    mysql -u${USERNAME} -p${PASSWORD} -e "set global validate_password_policy=0; \
        set global validate_password_length=4; \
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}'; \
        use mysql; \
        update user set host='%' where user='root'; \
        create user 'hive'@'%' IDENTIFIED BY 'hive'; \
        CREATE DATABASE hive; \
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

    #cp ${MYSQL_RES_DIR}/my.cnf /etc/

    # restart mysqld
    # systemctl restart mysqld.service

    # Delete
    yum -y remove mysql57-community-release-el7-11.noarch
    rm -rf /root/mysql57-community-release-el7-11.noarch.rpm

}

if [ "${IS_VAGRANT}" == "true" ];then
    install_mysql
fi

