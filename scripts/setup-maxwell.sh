#!/bin/bash
#set -x

if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi


setup_maxwell() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    cp -f $MAXWELL_RES_DIR/config.properties $MAXWELL_CONF_DIR

    # 在数据库中建立一个maxwell 库用于存储 Maxwell的元数据
    #${mysql_install_dir}/bin/mysql -uroot -p${dbrootpwd} -e "CREATE DATABASE maxwell;GRANT ALL ON maxwell.* TO 'maxwell'@'%' IDENTIFIED BY 'maxwell';GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO maxwell@'%';flush privileges;"
}

download_maxwell() {
    local app_name=$1

    log info "install $app_name"
    if resourceExists $MAXWELL_ARCHIVE; then
        installFromLocal $MAXWELL_ARCHIVE
    else
        installFromRemote $MAXWELL_ARCHIVE $MAXWELL_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/${MAXWELL_VERSION} ${INSTALL_PATH}/$app_name
    sudo chown -R vagrant:vagrant $INSTALL_PATH/$app_name
    rm $DOWNLOAD_PATH/$CANAL_ARCHIVE
}

install_maxwell() {
    local app_name="maxwell"
    log info "setup $app_name"

    download_maxwell $app_name
    setup_maxwell $app_name
    setupEnv_app $app_name
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_maxwell
fi

