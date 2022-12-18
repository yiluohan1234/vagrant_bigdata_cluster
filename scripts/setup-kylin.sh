#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_kylin() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "copying over ${app_name} configuration files"  
    sed -i "s@^spark_dependency=.*@spark_dependency=`find -L $spark_home/jars -name '*.jar' ! -name '*slf4j*' ! -name '*jackson*' ! -name '*metastore*' ! -name '*calcite*' ! -name '*doc*' ! -name '*test*' ! -name '*sources*' ''-printf '%p:' | sed 's/:$//'`@" ${INSTALL_PATH}/${app_name}/bin/find-spark-dependency.sh
    
}

install_kylin() {
    local app_name="kylin"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_and_unzip_app ${app_name}
        setup_kylin ${app_name}
        setupEnv_app $app_name
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_kylin
fi
