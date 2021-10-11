#!/bin/bash
#set -x
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

setup_phoenix() {
    local app_name=$1

    log info "copying server.jar to hbase"
    cp ${INSTALL_PATH}/phoenix/phoenix-4.14.0-HBase-1.2-server.jar ${INSTALL_PATH}/hbase/lib
    cp ${INSTALL_PATH}/phoenix/phoenix-4.14.0-HBase-1.2-client.jar ${INSTALL_PATH}/hbase/lib
    cp ${INSTALL_PATH}/phoenix/phoenix-core-4.14.0-HBase-1.2.jar ${INSTALL_PATH}/hbase/lib
    cp -f $HBASE_RES_DIR/hbase-site.xml ${INSTALL_PATH}/phoenix/bin
    #scp ${INSTALL_PATH}/phoenix/phoenix-4.14.0-HBase-1.2-server.jar vagrant@hdp102:${INSTALL_PATH}/hbase/lib
    #scp ${INSTALL_PATH}/phoenix/phoenix-4.14.0-HBase-1.2-server.jar vagrant@hdp103:${INSTALL_PATH}/hbase/lib
}

download_phoenix() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $PHOENIX_ARCHIVE; then
        installFromLocal $PHOENIX_ARCHIVE
    else
        installFromRemote $PHOENIX_ARCHIVE $PHOENIX_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${PHOENIX_VERSION}" ${INSTALL_PATH}/$app_name
    sudo chown -R vagrant:vagrant $INSTALL_PATH/$app_name
    rm $DOWNLOAD_PATH/$PHOENIX_ARCHIVE
}

install_phoenix() {
    log info "setup phoenix"
    app_name="phoenix"

    download_phoenix $app_name
    setup_phoenix $app_name
    setupEnv_app $app_name
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_phoenix
fi
