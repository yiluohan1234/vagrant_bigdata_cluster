#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_maxwell() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over $app_name configuration files"
    cp ${conf_dir}/config.properties.example ${conf_dir}/config.properties

    sed -i "s@^kafka.bootstrap.servers=.*@kafka.bootstrap.servers=${HOSTNAME_LIST[0]}:9092,${HOSTNAME_LIST[1]}:9092,${HOSTNAME_LIST[2]}:9092@g" ${CANAL_CONF_DIR}/canal.properties
    sed -i "s@^host=.*@host=${HOSTNAME_LIST[2]}@g" ${CANAL_CONF_DIR}/canal.properties
    sed -i "11a# add"  ${CANAL_CONF_DIR}/canal.properties
    sed  -i  "/# add/i\  kafka_topic=gmall_db_m"  ${CANAL_CONF_DIR}/canal.properties

    # 在数据库中建立一个maxwell 库用于存储 Maxwell的元数据
    #${mysql_install_dir}/bin/mysql -uroot -p${dbrootpwd} -e "CREATE DATABASE maxwell;GRANT ALL ON maxwell.* TO 'maxwell'@'%' IDENTIFIED BY 'maxwell';GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO maxwell@'%';flush privileges;"
}

install_maxwell() {
    local app_name="maxwell"
    log info "setup ${app_name}"
    download_and_unzip_app ${app_name}
    setup_maxwell ${app_name}
    setupEnv_app ${app_name}
    source ${PROFILE}
}

if [ "$IS_VAGRANT" == "true" ];then
    install_maxwell
fi

