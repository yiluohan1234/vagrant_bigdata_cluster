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
    cp -f ${res_dir}/spark-env.sh ${conf_dir}
    cp ${DOWNLOAD_PATH}/mysql-connector-java*.jar ${INSTALL_PATH}/spark/$SPARK_VERSION/jars

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
    mkdir ${INSTALL_PATH}/${app_name}
    mv ${INSTALL_PATH}/"${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION_NUM_TWO}" ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    # rm ${DOWNLOAD_PATH}/${archive}
}

setupEnv_spark() {
    local app_name=$1
    log info "creating ${app_name} environment variables"
    # app_path=${INSTALL_PATH}/java
    app_path=${INSTALL_PATH}/${app_name}/${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION_NUM_TWO}
    echo "# $app_name environment" >> ${PROFILE}
    echo "export SPARK_HOME=${app_path}" >> ${PROFILE}
    echo 'export PATH=${SPARK_HOME}/bin:$PATH' >> ${PROFILE}
    echo -e "\n" >> ${PROFILE}
}

install_spark() {
    local app_name="spark"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_spark ${app_name}
        setup_spark ${app_name}
        setupEnv_spark ${app_name}
    fi
    
    # 主机长度
    host_name_list_len=${#HOSTNAME_LIST[@]}
    if [ "${IS_VAGRANT}" != "true" ] && [ ${host_name_list_len} -gt 1 ];then
        dispatch_app ${app_name}
    fi
    source ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_spark
fi
