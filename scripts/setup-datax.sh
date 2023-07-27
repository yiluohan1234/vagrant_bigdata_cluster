#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_datax() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "del $app_name directories"
    find ${INSTALL_PATH}/datax/plugin/reader/ -type f -name "._*er" | xargs rm -rf
    find ${INSTALL_PATH}/datax/plugin/writer/ -type f -name "._*er" | xargs rm -rf

    yum install -y MySQL-python
}

install_datax() {
    local app_name="datax"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"

        download_and_unzip_app ${app_name}
        setup_datax ${app_name}

    fi
}
if [ "${IS_VAGRANT}" == "true" ];then
    install_datax
fi
