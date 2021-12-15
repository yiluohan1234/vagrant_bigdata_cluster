#!/bin/bash
#set -x
if [ "${IS_VAGRANT}" == "true" ];then 
    source "/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
else
    source "/home/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
fi

setup_hive() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/hive/logs
    mkdir -p ${INSTALL_PATH}/hive/tmpdir
	
    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/* ${conf_dir}

    # 安装phoenix后hive启动失败
    #rm ${INSTALL_PATH}/hive/lib/icu4j-4.8.1.jar
    # java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument
    #rm ${INSTALL_PATH}/hive/lib/guava-19.0.jar
    #cp ${INSTALL_PATH}/hadoop/share/hadoop/common/lib/guava-27.0-jre.jar ${INSTALL_PATH}/hive/lib
    # 解决log4j冲突
    mv ${INSTALL_PATH}/hive/lib/log4j-slf4j-impl-2.10.0.jar ${INSTALL_PATH}/hive/lib/log4j-slf4j-impl-2.10.0.jar_bak
    
    wget_mysql_connector ${INSTALL_PATH}/hive/lib

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

download_hive() {
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
    mv ${INSTALL_PATH}/"apache-${HIVE_VERSION}-bin" ${INSTALL_PATH}/${app_name}
    rm ${DOWNLOAD_PATH}/${archive}
}

download_hive_src() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local app_version=$(eval echo \$${app_name_upper}_VERSION)
    local archive=$(eval echo \$${app_name_upper}_SRC_ARCHIVE)
    local download_url=$(eval echo \$${app_name_upper}_SRC_MIRROR_DOWNLOAD)

    log info "install ${app_name}"
    if resourceExists ${archive}; then
        installFromLocal ${archive}
    else
        installFromRemote ${archive} ${download_url}
    fi
    mv ${INSTALL_PATH}/"apache-${HIVE_VERSION}-src" ${INSTALL_PATH}/${app_name}-src
    rm ${DOWNLOAD_PATH}/${archive}
}

install_hive() {
    local app_name="hive"
    log info "setup ${app_name}"

    download_hive ${app_name}
    setup_hive ${app_name}
    setupEnv_app ${app_name}
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_app ${app_name}
    fi
    source ${PROFILE}
}
if [ "${IS_VAGRANT}" == "true" ];then
    install_hive
fi
