#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_sqoop() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/sqoop-env.sh ${conf_dir}
    cp -f ${res_dir}/configure-sqoop ${INSTALL_PATH}/sqoop/bin

    wget_mysql_connector ${INSTALL_PATH}/sqoop/lib

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

download_sqoop() {
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
    mv ${INSTALL_PATH}/"${SQOOP_VERSION}.bin__hadoop-2.6.0" ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    rm ${DOWNLOAD_PATH}/${archive}
}

install_sqoop() {
    local app_name="sqoop"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_sqoop ${app_name}
        setup_sqoop ${app_name}
        setupEnv_app ${app_name}
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_sqoop
fi
