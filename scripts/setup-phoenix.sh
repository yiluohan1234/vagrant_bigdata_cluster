#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_phoenix() {
    local app_name=$1

    log info "copying server.jar to hbase"
    cp ${INSTALL_PATH}/phoenix/phoenix-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}-server.jar ${INSTALL_PATH}/hbase/lib
    cp ${INSTALL_PATH}/phoenix/phoenix-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}-client.jar ${INSTALL_PATH}/hbase/lib
    cp ${INSTALL_PATH}/phoenix/phoenix-core-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}.jar ${INSTALL_PATH}/hbase/lib
    cp -f ${HBASE_RES_DIR}/hbase-site.xml ${INSTALL_PATH}/phoenix/bin
    if [ "${IS_VAGRANT}" != "true" ];then
        for i in {"hdp102","hdp103"};
        do
            scp ${INSTALL_PATH}/phoenix/phoenix-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}-server.jar vagrant@$i:${INSTALL_PATH}/hbase/lib
            scp ${INSTALL_PATH}/phoenix/phoenix-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}-client.jar vagrant@$i:${INSTALL_PATH}/hbase/lib
            scp ${INSTALL_PATH}/phoenix/phoenix-core-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}.jar vagrant@$i:${INSTALL_PATH}/hbase/lib
        done
    fi
}

download_phoenix() {
    local app_name=$1
    local app_name_upper=$(echo $app_name | tr '[a-z]' '[A-Z]')
    local app_version=$(eval echo \$${app_name_upper}_VERSION)
    local archive=$(eval echo \$${app_name_upper}_ARCHIVE)
    local download_url=$(eval echo \$${app_name_upper}_MIRROR_DOWNLOAD)

    log info "install $app_name"
    if resourceExists $archive; then
        installFromLocal $archive
    else
        installFromRemote $archive $download_url
    fi
    mv ${INSTALL_PATH}/"${app_version}" ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    rm $DOWNLOAD_PATH/${archive}
}

install_phoenix() {
    log info "setup phoenix"
    app_name="phoenix"

    download_phoenix $app_name
    setup_phoenix $app_name
    setupEnv_app $app_name
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_app ${app_name}
    fi
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_phoenix
fi
