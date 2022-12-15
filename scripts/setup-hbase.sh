#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_hbase() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/* ${conf_dir}
    cp ${INSTALL_PATH}/hadoop/etc/hadoop/core-site.xml ${INSTALL_PATH}/hbase/conf/
    cp ${INSTALL_PATH}/hadoop/etc/hadoop/hdfs-site.xml ${INSTALL_PATH}/hbase/conf/
    mv ${INSTALL_PATH}/hbase/lib/slf4j-log4j12-1.7.25.jar ${INSTALL_PATH}/hbase/lib/slf4j-log4j12-1.7.25.jar_bak
    
    if [ "${IS_KERBEROS}" != "true" ];then
        sed -i '55,83d' ${conf_dir}/hbase-site.xml
    fi

    if [ $INSTALL_PATH != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

install_hbase() {
    local app_name="hbase"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setup_hbase ${app_name}
        setupEnv_app ${app_name}

        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
        
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_hbase
fi
