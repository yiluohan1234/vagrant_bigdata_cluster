#!/bin/bash
#set -x

setup_hive() {
    local app_name=$1
    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/hive/logs
    mkdir -p ${INSTALL_PATH}/hive/tmpdir
	
    log info "copying over $app_name configuration files"
    cp -f $HADOOP_RES_DIR/* $HADOOP_CONF_DIR
}


download_hive() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $HIVE_ARCHIVE; then
        installFromLocal $HIVE_ARCHIVE
    else
        installFromRemote $HIVE_ARCHIVE $HIVE_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"apache-$HIVE_VERSION-bin" ${INSTALL_PATH}/hive
}

install_hive() {
    local app_name="hive"
    log info "setup $app_name"

    download_hive $app_name
    setupEnv_app $app_name sbin
    source $PROFILE
}

