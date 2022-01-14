#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"


setup_maxwell() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over $app_name configuration files"
    cp -f ${res_dir}/config.properties ${conf_dir}

    # 在数据库中建立一个maxwell 库用于存储 Maxwell的元数据
    #${mysql_install_dir}/bin/mysql -uroot -p${dbrootpwd} -e "CREATE DATABASE maxwell;GRANT ALL ON maxwell.* TO 'maxwell'@'%' IDENTIFIED BY 'maxwell';GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO maxwell@'%';flush privileges;"
}

download_maxwell() {
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
    mv ${INSTALL_PATH}/"${app_version}" ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    rm ${DOWNLOAD_PATH}/${archive}
}

install_maxwell() {
    local app_name="maxwell"
    log info "setup ${app_name}"

    download_maxwell ${app_name}
    setup_maxwell ${app_name}
    setupEnv_app ${app_name}
    source ${PROFILE}
}

if [ "$IS_VAGRANT" == "true" ];then
    install_maxwell
fi

