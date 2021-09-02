#!/bin/bash
#set -x

setup_flink() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    cp -f $FLINK_RES_DIR/* $FLINK_CONF_DIR
}

download_flink() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $FLINK_ARCHIVE; then
        installFromLocal $FLINK_ARCHIVE
    else
        installFromRemote $FLINK_ARCHIVE $FLINK_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/${FLINK_VERSION} ${INSTALL_PATH}/flink
}

install_flink() {
    local app_name="flink"
    log info "setup $app_name"

    download_flink $app_name
    setup_flink $app_name
    setupEnv_app $app_name
    dispatch_app $app_name
    source $PROFILE
}

