#!/bin/bash
#set -x

if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
else
    source "/home/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
fi


setup_zabbix() {
    # agent配置
    sed -i 's/^Server=127.0.0.1/Server=hdp103/' /etc/zabbix/zabbix_agentd.conf
    sed -i 's/^ServerActive=127.0.0.1/#ServerActive=127.0.0.1/' /etc/zabbix/zabbix_agentd.conf
    sed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/' /etc/zabbix/zabbix_agentd.conf

    hostname=`cat /etc/hostname`
    # 配置环境中不同节点配置不同的情况
    if [ "${IS_VAGRANT}" == "true" ];then
        if [ "$hostname" = "hdp103" ];then
            # 导入Zabbix建表语句
            zabbix_server_path=`ls /usr/share/doc/|grep zabbix-server`
            zcat /usr/share/doc/$zabbix_server_path/create.sql.gz | mysql -uroot -p199037 zabbix
            # server配置
            sed -i 's/^# DBHost=.*/DBHost=hdp103/g' /etc/zabbix/zabbix_server.conf
            sed -i 's/^DBUser=zabbix/DBUser=root/g' /etc/zabbix/zabbix_server.conf
            sed -i 's/^# DBPassword=/DBPassword=199037/g' /etc/zabbix/zabbix_server.conf
            # 配置时区
            echo "php_value[date.timezone] = Asia/Shanghai" >> /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
            
        fi
    fi
:<<skip
    # 启动Zabbix
    if [ "$hostname" != "hdp103" ];then
        systemctl start zabbix-agent
        systemctl enable zabbix-agent
    else
        systemctl start zabbix-server zabbix-agent httpd rh-php72-php-fpm
        systemctl enable zabbix-server zabbix-agent httpd rh-php72-php-fpm
    fi
skip
}

download_zabbix() {
    rpm -Uvh https://mirrors.aliyun.com/zabbix/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
    yum install -y centos-release-scl
    sed -i 's/http:\/\/repo.zabbix.com/https:\/\/mirrors.aliyun.com\/zabbix/g' /etc/yum.repos.d/zabbix.repo
    sed -i '11s/enabled=0/enabled=1/' /etc/yum.repos.d/zabbix.repo
    yum install -y zabbix-agent
    
    hostname=`cat /etc/hostname`
    if [ "$hostname" = "hdp103" ];then
        yum install -y zabbix-server-mysql zabbix-web-mysql-scl zabbix-apache-conf-scl
    fi
}

install_zabbix() {
    local app_name="zabbix"
    log info "setup ${app_name}"

    download_zabbix ${app_name}
    setup_zabbix ${app_name}
    if [ "${IS_VAGRANT}" != "true" ];then
        dispatch_zabbix ${app_name}
    fi
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_zabbix
fi