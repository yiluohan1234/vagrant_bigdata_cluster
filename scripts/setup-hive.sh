#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_hive() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/hive/logs
    mkdir -p ${INSTALL_PATH}/hive/tmpdir
	
    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/hive* ${conf_dir}

    if [ "${IS_KERBEROS}" != "true" ];then
        sed -i '77,113d' ${conf_dir}/hive-site.xml
    fi

    # 安装phoenix后hive启动失败
    #rm ${INSTALL_PATH}/hive/lib/icu4j-4.8.1.jar
    # java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument
    #rm ${INSTALL_PATH}/hive/lib/guava-19.0.jar
    #cp ${INSTALL_PATH}/hadoop/share/hadoop/common/lib/guava-27.0-jre.jar ${INSTALL_PATH}/hive/lib
    # 解决log4j冲突
    mv ${INSTALL_PATH}/hive/lib/log4j-slf4j-impl-2.10.0.jar ${INSTALL_PATH}/hive/lib/log4j-slf4j-impl-2.10.0.jar_bak
    mv ${conf_dir}/hivefunction-1.0-SNAPSHOT.jar ${INSTALL_PATH}/hive/lib/
    
    wget_mysql_connector ${INSTALL_PATH}/hive/lib

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
    chmod -R 755 $INSTALL_PATH
    chown -R $DEFAULT_USER:$DEFAULT_GROUP $INSTALL_PATH
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
    mkdir ${INSTALL_PATH}/${app_name}
    mv ${INSTALL_PATH}/"apache-${HIVE_VERSION}-bin" ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    # rm ${DOWNLOAD_PATH}/${archive}
}

setupEnv_hive() {
    local app_name=$1
    log info "creating ${app_name} environment variables"
    # app_path=${INSTALL_PATH}/java
    app_path=${INSTALL_PATH}/${app_name}/apache-${HIVE_VERSION}-bin
    echo "# $app_name environment" >> ${PROFILE}
    echo "export HIVE_HOME=${app_path}" >> ${PROFILE}
    echo 'export PATH=${HIVE_HOME}/bin:$PATH' >> ${PROFILE}
    echo -e "\n" >> ${PROFILE}
}

install_hive() {
    local app_name="hive"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_hive ${app_name}
        setup_hive ${app_name}
        setupEnv_hive ${app_name}
    fi

    # 主机长度
    host_name_list_len=${#HOSTNAME_LIST[@]}
    if [ "${IS_VAGRANT}" != "true" ] && [ ${host_name_list_len} -gt 1 ];then
        dispatch_app ${app_name}
    fi
    source ${PROFILE}
}
if [ "${IS_VAGRANT}" == "true" ];then
    install_hive
fi
