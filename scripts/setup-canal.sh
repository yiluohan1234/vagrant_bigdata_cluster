#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_canal() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    # cp -f ${CANAL_RES_DIR}/canal.properties ${CANAL_CONF_DIR}
    # cp -f ${CANAL_RES_DIR}/instance.properties ${CANAL_CONF_DIR}/example

    # canal.properties
    sed -i "s@^canal.serverMode =.*@canal.serverMode = kafka@g" ${CANAL_CONF_DIR}/canal.properties
    sed -i "s@^canal.zkServers =.*@canal.zkServers = ${HOSTNAME_LIST[0]}:2181,${HOSTNAME_LIST[1]}:2181,${HOSTNAME_LIST[2]}:2181@g" ${CANAL_CONF_DIR}/canal.properties
    sed -i "s@^canal.serverMode =.*@canal.serverMode = kafka@g" ${CANAL_CONF_DIR}/canal.properties
    sed -i '116s/^/#/' ${CANAL_CONF_DIR}/canal.properties
    sed -i '117s/^#//' ${CANAL_CONF_DIR}/canal.properties
    sed -i "s@^kafka.bootstrap.servers =.*@kafka.bootstrap.servers = ${HOSTNAME_LIST[0]}:9092,${HOSTNAME_LIST[1]}:9092,${HOSTNAME_LIST[2]}:9092@g" ${CANAL_CONF_DIR}/canal.properties


    # example/instance.properties
    sed -i "s@^canal.instance.master.address=.*@canal.instance.master.address=${HOSTNAME_LIST[2]}:3306@g" ${CANAL_CONF_DIR}/example/instance.properties
    sed -i "s@^# canal.instance.mysql.slaveId=.*@canal.instance.mysql.slaveId=20@g" ${CANAL_CONF_DIR}/example/instance.properties
    sed -i "s@^canal.instance.dbUsername=.*@canal.instance.dbUsername=canal@g" ${CANAL_CONF_DIR}/example/instance.properties
    sed -i "s@^canal.instance.dbPassword=.*@canal.instance.dbPassword=canal@g" ${CANAL_CONF_DIR}/example/instance.properties
}

download_canal() {
    local app_name=$1
    local LOCAL_ARCHIVE=${CANAL_ARCHIVE}
    local REMOTE_MIRROR_DOWNLOAD=${CANAL_MIRROR_DOWNLOAD}

    mkdir -p ${INSTALL_PATH}/${app_name}
    log info "install ${app_name}"
    if resourceExists ${CANAL_ARCHIVE}; then
        log info "install ${LOCAL_ARCHIVE} from local file"
        FILE=${DOWNLOAD_PATH}/${LOCAL_ARCHIVE}
        tar -xzf ${FILE} -C ${INSTALL_PATH}/${app_name}
    else
        FILE=${DOWNLOAD_PATH}/${LOCAL_ARCHIVE}

        log info "install ${LOCAL_ARCHIVE} from remote file"
        curl -o ${FILE} -O -L ${REMOTE_MIRROR_DOWNLOAD}
        tar -xzf ${FILE} -C ${INSTALL_PATH}/${app_name}
    fi
    chown -R $DEFAULT_USER:$DEFAULT_GROUP $INSTALL_PATH/${app_name}
    rm ${DOWNLOAD_PATH}/${CANAL_ARCHIVE}
}

install_canal() {
    local app_name="canal"
    log info "setup ${app_name}"

    download_canal ${app_name}
    setup_canal ${app_name}
    setupEnv_app ${app_name}
    source ${PROFILE}
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_canal
fi

