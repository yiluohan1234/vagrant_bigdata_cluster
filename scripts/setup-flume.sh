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

    log info "modifying over $app_name configuration files"
    # flume-env.sh
    cp ${conf_dir}/flume-env.sh.template ${conf_dir}/flume-env.sh
    sed -i "s@^# export JAVA_HOME=.*@export JAVA_HOME=${INSTALL_PATH}/java@" ${conf_dir}/flume-env.sh
    sed -i 's@^# export JAVA_OPTS=".-*@export JAVA_OPTS="-Xms100m -Xmx2000m -Dcom.sun.management.jmxremote"@' ${conf_dir}/flume-env.sh
    # flume-conf.properties
    cp ${INSTALL_PATH}/${app_name}/conf/flume-conf.properties.template ${INSTALL_PATH}/${app_name}/conf/flume-conf.properties

    # Delete guava-11.0.2.jar in the lib folder to be compatible with Hadoop-3.1.3
    rm ${INSTALL_PATH}/${app_name}/lib/guava-*.jar

    log4j_path=${conf_dir}/log4j.properties
    log_path=${INSTALL_PATH}/${app_name}/logs
    sed -i 's@^flume.log.dir=.*@flume.log.dir='${log_path}'@' ${log4j_path}


    # Replace the default host configuration
    # sed -i "s@hdp101@${HOSTNAME_LIST[0]}@g" `grep 'hdp101' -rl ${conf_dir}/`
    # sed -i "s@hdp102@${HOSTNAME_LIST[1]}@g" `grep 'hdp102' -rl ${conf_dir}/`
    # sed -i "s@hdp103@${HOSTNAME_LIST[2]}@g" `grep 'hdp103' -rl ${conf_dir}/`

    # if [ "${IS_KERBEROS}" != "true" ];then
    #     sed -i '39,40d' ${conf_dir}/kafka-flume-hdfs.conf
    # fi

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
