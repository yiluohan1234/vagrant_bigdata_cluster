#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_flume() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over $app_name configuration files"
    cp -f ${res_dir}/* ${conf_dir}
    mv ${conf_dir}/flume-interceptor-1.0-SNAPSHOT-jar-with-dependencies.jar ${INSTALL_PATH}/${app_name}/lib
    cp ${INSTALL_PATH}/${app_name}/conf/flume-conf.properties.template ${INSTALL_PATH}/${app_name}/conf/flume-conf.properties

    # 将lib文件夹下的guava-11.0.2.jar删除以兼容Hadoop-3.1.3
    rm ${INSTALL_PATH}/${app_name}/lib/guava-11.0.2.jar

    if [ "${IS_KERBEROS}" != "true" ];then
        sed -i '39,40d' ${conf_dir}/kafka-flume-hdfs.conf
    fi


    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

install_flume() {
    local app_name="flume"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_and_unzip_app ${app_name}
        setup_flume ${app_name}
        setupEnv_app ${app_name}

        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
        source ${PROFILE}
    fi
}
if [ "${IS_VAGRANT}" == "true" ];then
    install_flume
fi
