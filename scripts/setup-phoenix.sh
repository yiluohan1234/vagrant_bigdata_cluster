#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_phoenix() {
    local app_name=$1

    log info "copying server.jar to hbase"
    cp ${INSTALL_PATH}/phoenix/phoenix-server-hbase-${HBASE_VERSION_NUM}-${PHOENIX_VERSION_NUM}.jar ${INSTALL_PATH}/hbase/lib
    # cp ${INSTALL_PATH}/phoenix/phoenix-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}-client.jar ${INSTALL_PATH}/hbase/lib
    # cp ${INSTALL_PATH}/phoenix/phoenix-core-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}.jar ${INSTALL_PATH}/hbase/lib
    cp ${INSTALL_PATH}/hbase/conf/hbase-site.xml ${INSTALL_PATH}/phoenix/bin
}

dispatch_phoenix() {
    local app_name=$1
    dispatch_app ${app_name}

    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        current_hostname=`cat /etc/hostname`
        if [ "$current_hostname" != "${HOSTNAME_LIST[$i]}" ];then
            scp ${INSTALL_PATH}/phoenix/phoenix-server-hbase-${HBASE_VERSION_NUM}-${PHOENIX_VERSION_NUM}.jar ${DEFAULT_USER}@${HOSTNAME_LIST[$i]}:${INSTALL_PATH}/hbase/lib
            # scp ${INSTALL_PATH}/phoenix/phoenix-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}-client.jar vagrant@$i:${INSTALL_PATH}/hbase/lib
            # scp ${INSTALL_PATH}/phoenix/phoenix-core-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}.jar vagrant@$i:${INSTALL_PATH}/hbase/lib
        fi
    done
}

install_phoenix() {
    app_name="phoenix"
    log info "setup phoenix"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_and_unzip_app $app_name
        setup_phoenix $app_name
        setupEnv_app $app_name
        if [ "$IS_VAGRANT" != "true" ];then
            dispatch_phoenix ${app_name}
        fi
        source $PROFILE
    fi
}

if [ "$IS_VAGRANT" == "true" ];then
    install_phoenix
fi
