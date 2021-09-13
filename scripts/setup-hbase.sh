#!/bin/bash
#set -x
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

setup_hbase() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    cp -f $HBASE_RES_DIR/* $HBASE_CONF_DIR
    cp $INSTALL_PATH/hadoop/etc/hadoop/core-site.xml $INSTALL_PATH/hbase/conf/
    cp $INSTALL_PATH/hadoop/etc/hadoop/hdfs-site.xml $INSTALL_PATH/hbase/conf/
}

download_hbase() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $HBASE_ARCHIVE; then
        installFromLocal $HBASE_ARCHIVE
    else
        installFromRemote $HBASE_ARCHIVE $HBASE_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${HBASE_VERSION}" ${INSTALL_PATH}/$app_name
    sudo chown -R vagrant:vagrant $INSTALL_PATH/$app_name
    rm $DOWNLOAD_PATH/$HBASE_ARCHIVE
}

install_hbase() {
    local app_name="hbase"
    log info "setup $app_name"

    download_hbase $app_name
    setup_hbase $app_name
    #dispatch_app $app_name
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_app $app_name
    fi
    setupEnv_app $app_name
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_hbase
fi
