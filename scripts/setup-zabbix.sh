#!/bin/bash
#set -x

if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
else
    source "/home/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
fi


setup_zabbix() {
    zabbix_server_path=`ls /usr/share/doc/|grep zabbix-server`
    zcat /usr/share/doc/$zabbix_server_path/create.sql.gz | mysql -uroot -p199037 zabbix

    
    # 配置环境中不同节点配置不同的情况
    if [ "${IS_VAGRANT}" == "true" ];then
        hostname=`cat /etc/hostname`

        if [ "$hostname" != "hdp103" ];then
            sudo yum install -y zabbix-server-mysql zabbix-web-mysql-scl zabbix-apache-conf-scl
        fi
    fi
    zabbix_server_path=`ls /usr/share/doc/|grep zabbix-server`
    zcat /usr/share/doc/$zabbix_server_path/create.sql.gz | mysql -uroot -p199037 zabbix
    
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

download_zabbix() {
    rpm -Uvh https://mirrors.aliyun.com/zabbix/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
    yum install -y centos-release-scl
    sed -i 's/http:\/\/repo.zabbix.com/https:\/\/mirrors.aliyun.com\/zabbix/g' /etc/yum.repos.d/zabbix.repo
    sed -i '11s/enabled=0/enabled=1/' /etc/yum.repos.d/zabbix.repo
    yum install -y zabbix-agent
    
    hostname=`cat /etc/hostname`
    if [ "$hostname" != "hdp103" ];then
        yum install -y zabbix-server-mysql zabbix-web-mysql-scl zabbix-apache-conf-scl
    fi
}

dispatch_zabbix() {
    local app_name=$1
    dispatch_app ${app_name}
    for i in {"hdp102","hdp103"};
    do
        node_name=$i
        node_host=`cat /etc/hosts |grep $i|awk '{print $1}'`
        file_path=${INSTALL_PATH}/${app_name}/config/elasticsearch.yml

        echo "------modify $i server.properties-------"
        #ssh $i "sed -i 's/^node.name: .*/node.name: '$node_name'/' $file_path"
        ssh $i "sed -i 's@^network.host: .*@network.host: '${node_host}'@' ${file_path}"
    done
}

install_zabbix() {
    local app_name="zabbix"
    log info "setup ${app_name}"

    download_zabbix ${app_name}
    setup_zabbix ${app_name}
    setupEnv_app $app_name
    if [ "${IS_VAGRANT}" != "true" ];then
        dispatch_zabbix ${app_name}
    fi
    source ${PROFILE}
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_zabbix
fi
