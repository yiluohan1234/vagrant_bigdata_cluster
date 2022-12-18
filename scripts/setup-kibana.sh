#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_kibana() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "modifying over $app_name configuration files"
    mkdir -p ${INSTALL_PATH}/${app_name}/logs
    
    sed -i 's@^#server.host:.*@server.host: "0.0.0.0"@' ${conf_dir}/kibana.yml
    sed -i 's@^#elasticsearch.hosts.*@elasticsearch.hosts: ["http://'${HOSTNAME_LIST[0]}':9200", "http://'${HOSTNAME_LIST[1]}':9200", "http://'${HOSTNAME_LIST[2]}':9200"]@' ${conf_dir}/kibana.yml
    

}

install_kibana() {
    local app_name="kibana"
    log info "setup ${app_name}"
    download_and_unzip_app ${app_name}
    setup_kibana ${app_name}
    setupEnv_app ${app_name}
    source ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_kibana
fi
