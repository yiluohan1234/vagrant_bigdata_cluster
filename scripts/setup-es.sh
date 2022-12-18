#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

# sh setup-hosts.sh -i myid
# 4,5,6
while getopts i: option
do
    case "${option}"
    in
        i) ID=${OPTARG};;
    esac
done

setup_es() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "create ${app_name} directories"
    mkdir -p ${INSTALL_PATH}/elasticsearch/data
    mkdir -p ${INSTALL_PATH}/elasticsearch/logs

    log info "copying over ${app_name} configuration files"
    # cp -f ${res_dir}/* ${conf_dir}
    # jvm.options
    sed -i 's@-Xms1g@-Xms512m@' ${conf_dir}/jvm.options
    sed -i 's@-Xmx1g@-Xmx512m@' ${conf_dir}/jvm.options
    # elasticsearch.yml
    
    sed -i 's@^#cluster.name:.*@cluster.name: "hdp-testing-es"@' ${conf_dir}/elasticsearch.yml
    sed -i 's@^#path.data:.*@'${INSTALL_PATH}'/elasticsearch/data@' ${conf_dir}/elasticsearch.yml
    sed -i 's@^#path.logs:.*@'${INSTALL_PATH}'/elasticsearch/logs@' ${conf_dir}/elasticsearch.yml
    sed -i 's@^#bootstrap.memory_lock:.*@bootstrap.memory_lock: false@' ${conf_dir}/elasticsearch.yml
    
    sed -i 's@^#http.port: .*@http.port: 9200@' ${conf_dir}/elasticsearch.yml
    sed -i 's@^#discovery.zen.ping.unicast.hosts: .*@#discovery.zen.ping.unicast.hosts: ["'${HOSTNAME_LIST[0]}'", "'${HOSTNAME_LIST[1]}'", "'${HOSTNAME_LIST[2]}'"]@' ${conf_dir}/elasticsearch.yml
    sed -i 's@^#discovery.zen.minimum_master_nodes: .*@discovery.zen.minimum_master_nodes: 2@' ${conf_dir}/elasticsearch.yml
    sed -i 's@^#gateway.recover_after_nodes: .*@gateway.recover_after_nodes: 3@' ${conf_dir}/elasticsearch.yml  

    if [ "${IS_VAGRANT}" == "true" ];then
        ip=${IP_LIST[$(($ID-1))]}
        hostname=${HOSTNAME_LIST[$(($ID-1))]}
        sed -i 's@^#node.name:.*@node.name: '${hostname}'@' ${conf_dir}/elasticsearch.yml
        sed -i 's@^#network.host:.*@network.host: '${ip}'@' ${conf_dir}/elasticsearch.yml   
    else 
        sed -i 's@^#node.name:.*@node.name: '${HOSTNAME_LIST[0]}'@' ${conf_dir}/elasticsearch.yml
        sed -i 's@^#network.host:.*@network.host: '${IP_LIST[0]}'@' ${conf_dir}/elasticsearch.yml
    fi
}

dispatch_es() {
    local app_name=$1
    dispatch_app ${app_name}
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        current_hostname=`cat /etc/hostname`
        ip=${IP_LIST[$i]}
        hostname=${HOSTNAME_LIST[$i]}
        file_path=${INSTALL_PATH}/${app_name}/config/elasticsearch.yml

        if [ "$current_hostname" != "${HOSTNAME_LIST[$i]}" ];then
            echo "------modify ${HOSTNAME_LIST[$i]} server.properties-------"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's@^node.name: .*@node.name: '$hostname'@' $file_path"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's@^network.host: .*@network.host: '${ip}'@' ${file_path}"
        fi
    done
}

install_es() {
    local app_name="elasticsearch"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"

        download_and_unzip_app ${app_name}
        setup_es ${app_name}
        setupEnv_app ${app_name}

        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_es ${app_name}
        fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_es
fi
