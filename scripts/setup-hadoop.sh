#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_hadoop() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "creating ${app_name} directories"
    mkdir -p ${INSTALL_PATH}/hadoop/tmp
	
    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/* ${conf_dir}
    mv ${conf_dir}/hadoop-lzo-0.4.20.jar ${INSTALL_PATH}/hadoop/share/hadoop/common
    #echo 'export CLASSPATH=$CLASSPATH:${INSTALL_PATH}/hadoop/share/hadoop/common' >> $PROFILE
    if [ "${IS_KERBEROS}" == "true" ];then
        sed -i '31,49s/vagrant/hive/g' ${conf_dir}/core-site.xml
        sed -i '30,34s/vagrant/hive/g' ${conf_dir}/core-site.xml
    else
        sed -i '66,99d' ${conf_dir}/core-site.xml
        sed -i '35,111d' ${conf_dir}/hdfs-site.xml
        sed -i '36,46d' ${conf_dir}/mapred-site.xml
        sed -i '73,112d' ${conf_dir}/yarn-site.xml
        rm -rf ${conf_dir}/ssl-server.xml
    fi
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

download_hadoop() {
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

install_hadoop() {
    local app_name="hadoop"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_hadoop ${app_name}
        setupEnv_app ${app_name} sbin
    fi
    setup_hadoop ${app_name}
    
    # 解决Unable to load native-hadoop library for your platform
    #echo 'export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native/:$LD_LIBRARY_PATH' >> ${PROFILE}

    if [ "${IS_VAGRANT}" != "true" ];then
        dispatch_app ${app_name}
    fi

    source ${PROFILE}
    #format_hdfs
    #start_daemons
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_hadoop
fi
