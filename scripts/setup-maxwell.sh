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
    sed -i "11a# kafka topic"  ${conf_dir}/config.properties
    sed -i "/# kafka topic/a kafka_topic=topic_db"  ${conf_dir}/config.properties
    sed -i "/^password=maxwell/a jdbc_options=useSSL=false&serverTimezone=Asia/Shanghai"  ${conf_dir}/config.properties

    # Delete guava-11.0.2.jar in the lib folder to be compatible with Hadoop-3.1.3
    rm ${INSTALL_PATH}/${app_name}/lib/guava-*.jar
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

