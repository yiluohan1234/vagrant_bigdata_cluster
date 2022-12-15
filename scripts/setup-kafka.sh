#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_kafka() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "creating ${app_name} directories"
    mkdir -p ${INSTALL_PATH}/kafka/tmp/kafka-logs

    log info "copying over $app_name configuration files"
    cp -f ${res_dir}/* ${conf_dir}
    echo -e "\n" >> ${INSTALL_PATH}/kafka/bin/kafka-run-class.sh
    echo "export JAVA_HOME=/home/vagrant/apps/java" >> ${INSTALL_PATH}/kafka/bin/kafka-run-class.sh

    if [ "$IS_VAGRANT" == "true" ];then
        hostname=`cat /etc/hostname`
        ip=`cat /etc/hosts |grep ${hostname}|awk '{print $1}'`
        ip_end=${ip##*.} 
        value="PLAINTEXT://${ip}:9092"
        file_path=${INSTALL_PATH}/${app_name}/config/server.properties
        log info "------modify $i server.properties-------"
        sed -i 's/^broker.id=.*/broker.id='${ip_end}'/' ${file_path}
        sed -i 's@^listeners=.*@listeners='${value}'@' ${file_path}
        sed -i 's@^advertised.listeners=.*@advertised.listeners='${value}'@' ${file_path}
    fi

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

dispatch_kafka() {
    local app_name=$1
    dispatch_app ${app_name}
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        current_hostname=`cat /etc/hostname`
        ip=`cat /etc/hosts |grep $i|awk '{print $1}'`
        ip_end=${ip##*.} 
        value="PLAINTEXT://$ip:9092"
        file_path=${INSTALL_PATH}/${app_name}/config/server.properties

        if [ "$current_hostname" != "${HOSTNAME_LIST[0]}" ];then
            echo "------modify $i server.properties-------"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's/^broker.id=.*/broker.id='${ip_end}'/' ${file_path}"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's@^listeners=.*@listeners='${value}'@' ${file_path}"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's@^advertised.listeners=.*@advertised.listeners='${value}'@' ${file_path}"
        fi
    done
}

install_kafka() {
    local app_name="kafka"
    log info "setup $app_name"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_and_unzip_app ${app_name}
        setup_kafka ${app_name}
        setupEnv_app ${app_name}
        if [ "$IS_VAGRANT" != "true" ];then
            dispatch_kafka ${app_name}
        fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_kafka
fi
