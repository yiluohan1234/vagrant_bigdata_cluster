#!/bin/bash
#set -x

setup_zookeeper() {
    local app_name=$1
    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/zookeeper/data 
    mkdir -p ${INSTALL_PATH}/zookeeper/log
    touch ${INSTALL_PATH}/zookeeper/data/myid
    log info "copying over $app_name configuration files"
    cp -f $ZOOKEEPER_RES_DIR/* $ZOOKEEPER_CONF_DIR
    echo -e "\n" >> ${INSTALL_PATH}/zookeeper/bin/zkEnv.sh
    echo "export JAVA_HOME=/home/vagrant/apps/java" >> ${INSTALL_PATH}/zookeeper/bin/zkEnv.sh
}

download_zookeeper() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $ZOOKEEPER_ARCHIVE; then
        installFromLocal $ZOOKEEPER_ARCHIVE
    else
        installFromRemote $ZOOKEEPER_ARCHIVE $ZOOKEEPER_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${ZOOKEEPER_VERSION}" ${INSTALL_PATH}/zookeeper
}
dispatch_zookeeper() {
    local app_name=$1
    log info "dispatch $app_name" 
    dispatch_app $app_name
    echo "1" >>${INSTALL_PATH}/zookeeper/data/myid
    ssh hdp-node-02 "echo '2' >> /home/vagrant/apps/zookeeper/data/myid"
    ssh hdp-node-03 "echo '3' >> /home/vagrant/apps/zookeeper/data/myid"
}

install_zookeeper() {
    local app_name="zookeeper"
    log info "setup $app_name"

    download_zookeeper $app_name
    setup_zookeeper $app_name
    setupEnv_app $app_name
    source $PROFILE
}

