#!/bin/bash
#set -x
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

setup_sqoop() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    cp -f $SQOOP_RES_DIR/* $SQOOP_CONF_DIR

    if [ $INSTALL_PATH != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@$INSTALL_PATH@g" `grep '/home/vagrant/apps' -rl $SQOOP_CONF_DIR/`
    fi
}

download_sqoop() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $SQOOP_ARCHIVE; then
        installFromLocal $SQOOP_ARCHIVE
    else
        installFromRemote $SQOOP_ARCHIVE $SQOOP_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${SQOOP_VERSION}.bin__hadoop-2.6.0" ${INSTALL_PATH}/sqoop
    sudo chown -R vagrant:vagrant $INSTALL_PATH/sqoop
    rm $DOWNLOAD_PATH/$SQOOP_ARCHIVE
}

install_sqoop() {
    local app_name="sqoop"
    log info "setup $app_name"

    download_sqoop $app_name
    setup_sqoop $app_name
    setupEnv_app $app_name
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_sqoop
fi
