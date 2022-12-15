#!/bin/bash
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi 

install_scala() {
    local app_name="scala"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setupEnv_app ${app_name}
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_scala
fi
