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
    local app_ver_dir=$(eval echo \$${app_name_upper}_VERSION_NUM)

    log info "creating ${app_name} directories"
    mkdir -p ${INSTALL_PATH}/${app_name}/tmp

    log info "copying over ${app_name} configuration files"
    # cp -f ${res_dir}/${app_ver_dir}/* ${conf_dir}
    create_property_xml ${res_dir}/${HADOOP_VERSION_NUM}/core-site.properties ${conf_dir}/core-site.xml
    create_property_xml ${res_dir}/${HADOOP_VERSION_NUM}/hdfs-site.properties ${conf_dir}/hdfs-site.xml

    if [ ! -f ${conf_dir}/mapred-site.xml ]
    then
        cp ${conf_dir}/mapred-site.xml.template ${conf_dir}/mapred-site.xml
    fi
    create_property_xml ${res_dir}/${HADOOP_VERSION_NUM}/mapred-site.properties ${conf_dir}/mapred-site.xml
    create_property_xml ${res_dir}/${HADOOP_VERSION_NUM}/yarn-site.properties ${conf_dir}/yarn-site.xml
    # hadoop-env.sh(modify)
    sed -i "s@^# export JAVA_HOME=.*\|^export JAVA_HOME=.*@export JAVA_HOME=${INSTALL_PATH}/java@" ${conf_dir}/hadoop-env.sh
    # yarn-evn.sh(add)
    echo "export JAVA_HOME=${INSTALL_PATH}/java" >> ${conf_dir}/yarn-env.sh
    # master and slaves
    # echo "${HOSTNAME_LIST[0]}" >> ${conf_dir}/master
    if [ ! -f ${conf_dir}/slaves ]
    then
        sed -i '1,$d' ${conf_dir}/workers
        echo -e "${HOSTNAME_LIST[0]}\n${HOSTNAME_LIST[1]}\n${HOSTNAME_LIST[2]}" >> ${conf_dir}/workers
    else
        sed -i '1,$d' ${conf_dir}/slaves
        echo -e "${HOSTNAME_LIST[0]}\n${HOSTNAME_LIST[1]}\n${HOSTNAME_LIST[2]}" >> ${conf_dir}/slaves
    fi

    mv ${res_dir}/hadoop-lzo-0.4.20.jar ${INSTALL_PATH}/hadoop/share/hadoop/common

    # Replace the default host configuration
    sed -i "s@hdp101@${HOSTNAME_LIST[0]}@g" `grep 'hdp101' -rl ${conf_dir}/`
    sed -i "s@hdp102@${HOSTNAME_LIST[1]}@g" `grep 'hdp102' -rl ${conf_dir}/`
    sed -i "s@hdp103@${HOSTNAME_LIST[2]}@g" `grep 'hdp103' -rl ${conf_dir}/`

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

install_hadoop() {
    local app_name="hadoop"
    log info "install ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_and_unzip_app ${app_name}
        setupEnv_app ${app_name} sbin
        setup_hadoop ${app_name}
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
    fi

    source ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_hadoop
fi
