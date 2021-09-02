#!/bin/bash
#set -x

setup_sqoop() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    cp -f $SQOOP_RES_DIR/* $SQOOP_CONF_DIR
}

download_sqoop() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $SQOOP_ARCHIVE; then
        installFromLocal $SQOOP_ARCHIVE
    else
        installFromRemote $SQOOP_ARCHIVE $SQOOP_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${SQOOP_VERSION}.bin__hadoop-2.0.4-alpha" ${INSTALL_PATH}/sqoop
}

install_sqoop() {
    local app_name="sqoop"
    log info "setup $app_name"

    download_sqoop $app_name
    setup_sqoop $app_name
    setupEnv_app $app_name
    source $PROFILE
}

