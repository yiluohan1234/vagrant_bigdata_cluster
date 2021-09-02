#!/bin/bash

setup_maven() {
    local app_name=$1
    log info "creating $app_name directories"
	
    log info "copying over $app_name configuration files"
    cp -f $MAVEN_RES_DIR/* $MAVEN_CONF_DIR
}


download_maven() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $MAVEN_ARCHIVE; then
        installFromLocal $MAVEN_ARCHIVE
    else
        installFromRemote $MAVEN_ARCHIVE $MAVEN_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/$MAVEN_VERSION ${INSTALL_PATH}/maven
}


install_maven() {
    local app_name="maven"
    log info "setup $app_name"
    download_maven $app_name
    setupEnv_app $app_name
    setup_maven $app_name
    source $PROFILE
}
