#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi
setup_sqoop() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over ${app_name} configuration files"
    sed -i '134,143s/^/#/' ${INSTALL_PATH}/${app_name}/bin/configure-sqoop

    # sqoop-env.sh
    echo "export HADOOP_COMMON_HOME=/home/vagrant/apps/hadoop" >> ${conf_dir}/sqoop-env.sh
    echo "export HADOOP_MAPRED_HOME=/home/vagrant/apps/hadoop" >> ${conf_dir}/sqoop-env.sh
    echo "export HBASE_HOME=/home/vagrant/apps/hbase" >> ${conf_dir}/sqoop-env.sh
    echo "export HIVE_HOME=/home/vagrant/apps/hive" >> ${conf_dir}/sqoop-env.sh
    echo "export ZOOCFGDIR=/home/vagrant/apps/zookeeper/conf" >> ${conf_dir}/sqoop-env.sh

    wget_mysql_connector ${INSTALL_PATH}/${app_name}/lib

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

install_sqoop() {
    local app_name="sqoop"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setup_sqoop ${app_name}
        setupEnv_app ${app_name}
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_sqoop
fi
