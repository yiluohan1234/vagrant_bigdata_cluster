#!/bin/bash
#set -x
if [ "$IS_VAGRANT" == "true" ];then 
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

setup_hive() {
    local app_name=$1
    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/hive/logs
    mkdir -p ${INSTALL_PATH}/hive/tmpdir
	
    log info "copying over $app_name configuration files"
    cp -f $HIVE_RES_DIR/* $HIVE_CONF_DIR
    wget_mysql_connector ${INSTALL_PATH}/hive/lib
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
    setup_hive $app_name
    setupEnv_app $app_name
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_app $app_name
    fi
    source $PROFILE
    

    # create user 'hive'@'%' IDENTIFIED BY 'hive';GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION;grant all on *.* to 'hive'@'localhost' identified by 'hive';flush privileges;
}
if [ "$IS_VAGRANT" == "true" ];then
    install_hive
fi
