#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_hbase() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/* ${conf_dir}
    cp ${INSTALL_PATH}/hadoop/etc/hadoop/core-site.xml ${INSTALL_PATH}/hbase/conf/
    cp ${INSTALL_PATH}/hadoop/etc/hadoop/hdfs-site.xml ${INSTALL_PATH}/hbase/conf/

    if [ "${IS_KERBEROS}" != "true" ];then
        sed -i '55,83d' ${conf_dir}/hbase-site.xml
    fi

    if [ $INSTALL_PATH != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

download_hbase() {
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
    mv ${INSTALL_PATH}/"${app_version}" ${INSTALL_PATH}/${app_name}
    # rm ${DOWNLOAD_PATH}/${archive}
    # mv ${INSTALL_PATH}/hbase/lib/slf4j-log4j12-1.7.25.jar ${INSTALL_PATH}/hbase/lib/slf4j-log4j12-1.7.25.jar_bak
}

setupEnv_hbase() {
    local app_name=$1
    log info "creating ${app_name} environment variables"
    # app_path=${INSTALL_PATH}/java
    app_path=${INSTALL_PATH}/${app_name}/${HBASE_VERSION}
    echo "# $app_name environment" >> ${PROFILE}
    echo "export HBASE_HOME=${app_path}" >> ${PROFILE}
    echo 'export PATH=${HBASE_HOME}/bin:$PATH' >> ${PROFILE}
    echo -e "\n" >> ${PROFILE}
}

install_hbase() {
    local app_name="hbase"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_hbase ${app_name}
        setup_hbase ${app_name}
        setupEnv_hbase ${app_name}
    fi


    if [ "${IS_VAGRANT}" != "true" ];then
        dispatch_app ${app_name}
    fi
    
    source ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_hbase
fi
