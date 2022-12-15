#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi 

setup_hadoop() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "creating ${app_name} directories"
    mkdir -p ${INSTALL_PATH}/${app_name}/tmp
	
    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/${HADOOP_VERSION_NUM}/* ${conf_dir}
    mv ${conf_dir}/${HADOOP_VERSION_NUM}/hadoop-lzo-0.4.20.jar ${INSTALL_PATH}/hadoop/share/hadoop/common
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

install_hadoop() {
    local app_name="hadoop"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_and_unzip_app ${app_name}
        setupEnv_app ${app_name} sbin
        setup_hadoop ${app_name}
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
    fi
    
    echo 'export HDFS_NAMENODE_USER="root"' >> $PROFILE
    echo 'export HDFS_DATANODE_USER="root"' >> $PROFILE
    echo 'export HDFS_SECONDARYNAMENODE_USER="root"' >> $PROFILE
    echo 'export YARN_RESOURCEMANAGER_USER="root"' >> $PROFILE
    echo 'export YARN_NODEMANAGER_USER="root"' >> $PROFILE
    # 解决Unable to load native-hadoop library for your platform
    echo 'export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native/:$LD_LIBRARY_PATH' >> ${PROFILE}

    source ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_hadoop
fi
