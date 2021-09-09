#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"
#source "/home/vagrant/scripts/common.sh"

setup_kafka() {
    local app_name=$1
    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/kafka/tmp/kafka-logs:wq

    log info "copying over $app_name configuration files"
    cp -f $KAFKA_RES_DIR/* $KAFKA_CONF_DIR
    echo -e "\n" >> ${INSTALL_PATH}/kafka/bin/kafka-run-class.sh
    echo "export JAVA_HOME=/home/vagrant/apps/java" >> ${INSTALL_PATH}/kafka/bin/kafka-run-class.sh
}

download_kafka() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $KAFKA_ARCHIVE; then
        installFromLocal $KAFKA_ARCHIVE
    else
        installFromRemote $KAFKA_ARCHIVE $KAFKA_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${KAFKA_VERSION}" ${INSTALL_PATH}/$app_name
    sudo chown -R vagrant:vagrant $INSTALL_PATH/$app_name
    rm $DOWNLOAD_PATH/$KAFKA_ARCHIVE
}
dispatch_kafka() {
    local app_name=$1
    #dispatch_app $app_name
    for i in {"hdp-node-02","hdp-node-03"};
    do
        ip=`cat /etc/hosts |grep $i|awk '{print $1}'`
        ip_end=${ip##*.} 
        value="PLAINTEXT://$ip:9092"
        file_path=$INSTALL_PATH/$app_name/config/server.properties
        echo "------modify $i server.properties-------"
        ssh $i "sed -i 's/^broker.id=.*/broker.id='$ip_end'/' $file_path"
        ssh $i "sed -i 's@^listeners=.*@listeners='$value'@' $file_path"
        ssh $i "sed -i 's@^advertised.listeners=.*@advertised.listeners='$value'@' $file_path"
    done
}

install_kafka() {
    log info "setup kafka"
    app_name="kafka"

    #download_kafka
    #setup_kafka $app_name
    #setupEnv_app $app_name
    dispatch_kafka $app_name
    source $PROFILE
}

