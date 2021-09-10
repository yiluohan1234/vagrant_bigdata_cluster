#!/bin/bash
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

download_scala() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $SCALA_ARCHIVE; then
        installFromLocal $SCALA_ARCHIVE
    else
        installFromRemote $SCALA_ARCHIVE $SCALA_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/$SCALA_VERSION ${INSTALL_PATH}/$app_name
    sudo chown -R vagrant:vagrant $INSTALL_PATH/$app_name
    rm $DOWNLOAD_PATH/$SCALA_ARCHIVE
}

install_scala() {
    local app_name="scala"
    log info "setup $app_name"
    download_scala $app_name
    setupEnv_app $app_name
    # dispatch_app $app_name
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_app $app_name
    fi
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_scala
fi