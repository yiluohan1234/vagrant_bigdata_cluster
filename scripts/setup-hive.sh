#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_hive() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/hive/logs
    mkdir -p ${INSTALL_PATH}/hive/tmpdir

    log info "modifying over ${app_name} configuration files"
    # cp -f ${res_dir}/hive* ${conf_dir}
    cp ${conf_dir}/hive-env.sh.template  ${conf_dir}/hive-env.sh
    sed -i 's@^# export HADOOP_HEAPSIZE=.*@export HADOOP_HEAPSIZE=2048@' ${conf_dir}/hive-env.sh

    # hive-env.sh
    echo "export HADOOP_HOME=${INSTALL_PATH}/hadoop" >> ${conf_dir}/hive-env.sh
    echo "export HIVE_CONF_DIR=${INSTALL_PATH}/hive/conf" >> ${conf_dir}/hive-env.sh
    echo "export HIVE_AUX_JARS_PATH=${INSTALL_PATH}/hive/lib" >> ${conf_dir}/hive-env.sh

    echo '<?xml version="1.0" encoding="UTF-8"?>' >> ${conf_dir}/hive-site.xml
    echo '<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>' >> ${conf_dir}/hive-site.xml
    echo '<configuration>' >> ${conf_dir}/hive-site.xml
    echo '</configuration>' >> ${conf_dir}/hive-site.xml
    create_property_xml ${res_dir}/hive-site.properties ${conf_dir}/hive-site.xml

    # 解决log4j冲突
    # mv ${INSTALL_PATH}/hive/lib/log4j-slf4j-impl-2.10.0.jar ${INSTALL_PATH}/hive/lib/log4j-slf4j-impl-2.10.0.jar_bak
    # 解决jline的版本冲突
    cp ${INSTALL_PATH}/hive/lib/jline-2.12.jar ${INSTALL_PATH}/hadoop/share/hadoop/yarn/lib/

    wget_mysql_connector ${INSTALL_PATH}/hive/lib

    # 更换默认配置
    sed -i "s@hdp101@${HOSTNAME_LIST[0]}@g" `grep 'hdp101' -rl ${conf_dir}/`
    # sed -i "s@hdp102@${HOSTNAME_LIST[1]}@g" `grep 'hdp102' -rl ${conf_dir}/`
    sed -i "s@hdp103@${HOSTNAME_LIST[2]}@g" `grep 'hdp103' -rl ${conf_dir}/`

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi

}

install_hive() {
    local app_name="hive"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"

        download_and_unzip_app ${app_name}
        setup_hive ${app_name}
        setupEnv_app ${app_name}
        if [ "$IS_VAGRANT" != "true" ];then
            dispatch_app ${app_name}
        fi
        source ${PROFILE}
    fi
}
if [ "${IS_VAGRANT}" == "true" ];then
    install_hive
fi
