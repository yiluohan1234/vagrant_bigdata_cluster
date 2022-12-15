#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
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

install_hive() {
    local app_name="hive"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"

        download_and_unzip_app ${app_name}
        setup_hive ${app_name}
        setupEnv_app ${app_name}
        # if [ "$IS_VAGRANT" != "true" ];then
        #     dispatch_app ${app_name}
        # fi
        source ${PROFILE}
    fi
}
if [ "${IS_VAGRANT}" == "true" ];then
    install_hive
fi
