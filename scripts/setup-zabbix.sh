#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_zabbix() {
    # agent配置
    sed -i 's/^Server=127.0.0.1/Server='$MYSQL_HOST'/' /etc/zabbix/zabbix_agentd.conf
    sed -i 's/^ServerActive=127.0.0.1/#ServerActive=127.0.0.1/' /etc/zabbix/zabbix_agentd.conf
    sed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/' /etc/zabbix/zabbix_agentd.conf

    hostname=`cat /etc/hostname`
    # 配置环境中不同节点配置不同的情况
    if [ "${IS_VAGRANT}" == "true" ];then
        if [ "$hostname" = "$MYSQL_HOST" ];then
            # 导入Zabbix建表语句
            zabbix_server_path=`ls /usr/share/doc/|grep zabbix-server`
            zcat /usr/share/doc/$zabbix_server_path/create.sql.gz | mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} zabbix
            # server配置
            sed -i 's/^# DBHost=.*/DBHost='${MYSQL_HOST}'/g' /etc/zabbix/zabbix_server.conf
            sed -i 's/^DBUser=zabbix/DBUser='${MYSQL_USER}'/g' /etc/zabbix/zabbix_server.conf
            sed -i 's/^# DBPassword=/DBPassword='${MYSQL_PASSWORD}'/g' /etc/zabbix/zabbix_server.conf
            # 配置时区
            echo "php_value[date.timezone] = Asia/Shanghai" >> /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
            
        fi
    fi

    # 启动Zabbix
    if [ "$hostname" != "$MYSQL_HOST" ];then
        systemctl start zabbix-agent
        systemctl enable zabbix-agent
    else
        systemctl start zabbix-server zabbix-agent httpd rh-php72-php-fpm
        systemctl enable zabbix-server zabbix-agent httpd rh-php72-php-fpm
    fi
}

download_zabbix() {
    rpm -Uvh https://mirrors.aliyun.com/zabbix/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
    yum install -y centos-release-scl
    sed -i 's/http:\/\/repo.zabbix.com/https:\/\/mirrors.aliyun.com\/zabbix/g' /etc/yum.repos.d/zabbix.repo
    sed -i '11s/enabled=0/enabled=1/' /etc/yum.repos.d/zabbix.repo
    yum install -y -q zabbix-agent
    
    hostname=`cat /etc/hostname`
    if [ "$hostname" = "$MYSQL_HOST" ];then
        yum install -y -q zabbix-server-mysql zabbix-web-mysql-scl zabbix-apache-conf-scl
    fi
}
dispatch_zabbix(){
    for ip in {"hdp101","hdp102","hdp103"};
    do
        ssh $ip "$(typeset -f); download_zabbix"
        ssh $ip "$(typeset -f); setup_zabbix"
    done
}
install_zabbix() {
    local app_name="zabbix"
    log info "setup ${app_name}"

    if [ "${IS_VAGRANT}" != "true" ];then
        dispatch_zabbix ${app_name}
    else
        download_zabbix ${app_name}
        setup_zabbix ${app_name}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_zabbix
fi
