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

    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/* ${conf_dir}

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
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
