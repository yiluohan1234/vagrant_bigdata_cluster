#!/bin/bash
#set -x

if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi


setup_kibana() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    cp -f $KIBANA_RES_DIR/* $KIBANA_CONF_DIR
    mkdir -p ${INSTALL_PATH}/kibana/logs

    if [ $INSTALL_PATH != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@$INSTALL_PATH@g" `grep '/home/vagrant/apps' -rl $KIBANA_CONF_DIR/`
    fi
}

download_kibana() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $KIBANA_ARCHIVE; then
        installFromLocal $KIBANA_ARCHIVE
    else
        installFromRemote $KIBANA_ARCHIVE $KIBANA_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/${KIBANA_VERSION}-linux-x86_64 ${INSTALL_PATH}/$app_name
    sudo chown -R vagrant:vagrant $INSTALL_PATH/$app_name
    rm $DOWNLOAD_PATH/$KIBANA_ARCHIVE
}

install_kibana() {
    local app_name="kibana"
    log info "setup $app_name"

    download_kibana $app_name
    setup_kibana $app_name
    setupEnv_app $app_name
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_kibana
fi
