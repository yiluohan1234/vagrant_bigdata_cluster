#!/bin/bash
#set -x

setup_phoenix() {
    local app_name=$1

    log info "copying server.jar to hbase"
    cp ${INSTALL_PATH}/phoenix/phoenix-4.8.1-HBase-1.2-server.jar ${INSTALL_PATH}/hbase/lib
    scp ${INSTALL_PATH}/phoenix/phoenix-4.8.1-HBase-1.2-server.jar vagrant@hdp-node-02:${INSTALL_PATH}/hbase/lib
    scp ${INSTALL_PATH}/phoenix/phoenix-4.8.1-HBase-1.2-server.jar vagrant@hdp-node-03:${INSTALL_PATH}/hbase/lib
}

download_phoenix() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $PHOENIX_ARCHIVE; then
        installFromLocal $PHOENIX_ARCHIVE
    else
        installFromRemote $PHOENIX_ARCHIVE $PHOENIX_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${PHOENIX_VERSION}" ${INSTALL_PATH}/phoenix
}

install_phoenix() {
    log info "setup phoenix"
    app_name="phoenix"

    download_phoenix $app_name
    setup_phoenix $app_name
    setupEnv_app $app_name
    source $PROFILE
}

