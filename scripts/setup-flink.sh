#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_flink() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "modifying over ${app_name} configuration files"
    # cp -f ${res_dir}/* ${conf_dir}

    # flink-conf.yaml
    echo "jobmanager.rpc.address: ${HOSTNAME_LIST[0]}" >> ${conf_dir}/flink-conf.yaml
    echo "jobmanager.rpc.port: 6123" >> ${conf_dir}/flink-conf.yaml
    echo "jobmanager.heap.size: 1024m" >> ${conf_dir}/flink-conf.yaml
    echo "taskmanager.heap.size: 1024m" >> ${conf_dir}/flink-conf.yaml
    echo "taskmanager.numberOfTaskSlots: 10" >> ${conf_dir}/flink-conf.yaml
    echo "taskmanager.memory.preallocate: false" >> ${conf_dir}/flink-conf.yaml
    echo "parallelism.default: 1" >> ${conf_dir}/flink-conf.yaml
    echo "jobmanager.web.port: 8381" >> ${conf_dir}/flink-conf.yaml
    echo "rest.port: 8381" >> ${conf_dir}/flink-conf.yaml
    echo "env.java.opts: -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:+AlwaysPreTouch -server -XX:+HeapDumpOnOutOfMemoryError" >> ${conf_dir}/flink-conf.yaml
    echo "env.java.home: ${INSTALL_PATH}/java" >> ${conf_dir}/flink-conf.yaml
    echo "classloader.resolve-order: parent-first" >> ${conf_dir}/flink-conf.yaml

    # masters and workers
    sed -i '1,$d' ${conf_dir}/masters 
    echo "${HOSTNAME_LIST[0]}" >> ${conf_dir}/masters
    sed -i '1,$d' ${conf_dir}/regionservers 
    echo -e "${HOSTNAME_LIST[0]}\n${HOSTNAME_LIST[1]}\n${HOSTNAME_LIST[2]}" >> ${conf_dir}/workers

}

install_flink() {
    local app_name="flink"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_and_unzip_app ${app_name}
        setup_flink ${app_name}
        setupEnv_app ${app_name}

        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
        source ${PROFILE}
    fi
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_flink
fi
