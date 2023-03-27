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

    sed -i "s@^kafka.bootstrap.servers=.*@kafka.bootstrap.servers=${HOSTNAME_LIST[0]}:9092,${HOSTNAME_LIST[1]}:9092,${HOSTNAME_LIST[2]}:9092@g" ${conf_dir}/config.properties
    sed -i "s@^host=.*@host=${HOSTNAME_LIST[2]}@g" ${conf_dir}/config.properties
    sed -i "11a# add"  ${conf_dir}/config.properties
    sed  -i  "/# add/a kafka_topic=gmall_db_m"  ${conf_dir}/config.properties
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

