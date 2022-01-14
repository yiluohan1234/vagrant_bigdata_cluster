#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_kibana() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over $app_name configuration files"
    cp -f ${res_dir}/* ${conf_dir}
    mkdir -p ${INSTALL_PATH}/kibana/logs

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

download_kibana() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local app_version=$(eval echo \$${app_name_upper}_VERSION)
    local archive=$(eval echo \$${app_name_upper}_ARCHIVE)
    local download_url=$(eval echo \$${app_name_upper}_MIRROR_DOWNLOAD)

    log info "install ${app_name}"
    if resourceExists ${archive}; then
        installFromLocal ${archive}
    else
        installFromRemote ${archive} ${download_url}
    fi
    mv ${INSTALL_PATH}/${KIBANA_VERSION}-linux-x86_64 ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    rm ${DOWNLOAD_PATH}/${archive}
}

install_kibana() {
    local app_name="kibana"
    log info "setup ${app_name}"

    download_kibana ${app_name}
    setup_kibana ${app_name}
    setupEnv_app ${app_name}
    source ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_kibana
fi
