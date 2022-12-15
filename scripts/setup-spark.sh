#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_spark() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over ${app_name} configuration files"
    # basic
    cp -f ${res_dir}/slaves ${conf_dir}
    cp -f ${res_dir}/spark-defaults.conf ${conf_dir}
    cp -f ${res_dir}/spark-env.sh ${conf_dir}
    wget_mysql_connector ${INSTALL_PATH}/${app_name}/jars

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
    # yarn-site.xml
    #cp -f ${HADOOP_RES_DIR}/yarn-site.xml ${SPARK_CONF_DIR}
    
    # hive-site.xml
    #cp -f ${HIVE_RES_DIR}/hive-site.xml ${SPARK_CONF_DIR}
    #cp -rf ${INSTALL_PATH}/spark/jars/*.jar ${INSTALL_PATH}/hive/lib/
}

install_spark() {
    local app_name="spark"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setup_spark ${app_name}
        setupEnv_app ${app_name}
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_spark
fi
