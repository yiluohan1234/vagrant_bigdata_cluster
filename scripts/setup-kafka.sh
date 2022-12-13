#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_kafka() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "creating ${app_name} directories"
    mkdir -p ${INSTALL_PATH}/${app_name}/${KAFKA_VERSION}/tmp/kafka-logs

    log info "copying over $app_name configuration files"
    cp -f ${res_dir}/* ${conf_dir}
    echo -e "\n" >> ${INSTALL_PATH}/${app_name}/${KAFKA_VERSION}/bin/kafka-run-class.sh
    echo "export JAVA_HOME=/usr/java/jdk1.8.0_221" >> ${INSTALL_PATH}/${app_name}/${KAFKA_VERSION}/bin/kafka-run-class.sh

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

download_kafka() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local app_version=$(eval echo \$${app_name_upper}_VERSION)
    local archive=$(eval echo \$${app_name_upper}_ARCHIVE)
    local download_url=$(eval echo \$${app_name_upper}_MIRROR_DOWNLOAD)

    log info "install ${app_name}"
    if resourceExists ${archive}; then
        installFromLocal ${archive}
    else
        installFromRemote ${archive} ${download_url}
    fi
    mkdir ${INSTALL_PATH}/${app_name}
    mv ${INSTALL_PATH}/${app_version} ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    # rm ${DOWNLOAD_PATH}/${archive}
}

setupEnv_kafka() {
    local app_name=$1
    log info "creating ${app_name} environment variables"
    # app_path=${INSTALL_PATH}/java
    app_path=${INSTALL_PATH}/${app_name}/${KAFKA_VERSION}
    echo "# $app_name environment" >> ${PROFILE}
    echo "export KAFKA_HOME=${app_path}" >> ${PROFILE}
    echo 'export PATH=${KAFKA_HOME}/bin:$PATH' >> ${PROFILE}
    echo -e "\n" >> ${PROFILE}
}

dispatch_kafka() {
    local app_name=$1
    dispatch_app ${app_name}
    i=1
    for host in ${HOSTNAME_LIST[@]};do
        value="PLAINTEXT://$host:9092"
        file_path=${INSTALL_PATH}/${app_name}/${KAFKA_VERSION}/config
        echo "------modify $i server.properties-------"
        ssh $host "sed -i 's/^broker.id=.*/broker.id='${i}'/' ${file_path}/server.properties"
        ssh $host "sed -i 's@^listeners=.*@listeners='${value}'@' ${file_path}/server.properties"
        ssh $host "sed -i 's@^advertised.listeners=.*@advertised.listeners='${value}'@' ${file_path}/server.properties"
        ssh $host "sed -i 's@^log.dirs=.*@log.dirs='${KAFKA_LOG_DIR}'@' ${file_path}/server.properties"
        i=$(( i+1 ))
    done
}

install_kafka() {
    local app_name="kafka"
    log info "setup $app_name"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_kafka ${app_name}
        setup_kafka ${app_name}
        setupEnv_kafka ${app_name} 
    fi

    # 主机长度
    host_name_list_len=${#HOSTNAME_LIST[@]}
    if [ "${IS_VAGRANT}" != "true" ] && [ ${host_name_list_len} -gt 1 ];then
        dispatch_kafka ${app_name}
    fi
    source ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_kafka
fi
