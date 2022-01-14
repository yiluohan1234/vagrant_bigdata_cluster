#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

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
    wget_mysql_connector ${INSTALL_PATH}/spark/jars

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
    # yarn-site.xml
    #cp -f ${HADOOP_RES_DIR}/yarn-site.xml ${SPARK_CONF_DIR}
    
    # hive-site.xml
    #cp -f ${HIVE_RES_DIR}/hive-site.xml ${SPARK_CONF_DIR}
    #cp -rf ${INSTALL_PATH}/spark/jars/*.jar ${INSTALL_PATH}/hive/lib/
}

download_spark() {
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
    mv ${INSTALL_PATH}/"${SPARK_VERSION}-bin-hadoop3.2" ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    rm ${DOWNLOAD_PATH}/${archive}
}

install_spark() {
    local app_name="spark"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"

        download_spark ${app_name}
        setup_spark ${app_name}
        setupEnv_app ${app_name}
        # if [ "${IS_VAGRANT}" != "true" ];then
        #     dispatch_app ${app_name}
        # fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_spark
fi
