#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_#@() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "create ${app_name} configuration directories"
    mkdir -p ${INSTALL_PATH}/elasticsearch/datas
    mkdir -p ${INSTALL_PATH}/elasticsearch/logs

    log info "copying over ${app_name} configuration files"
    # 将resources配置文件拷贝到插件的配置目录
    cp -f $res_dir/* $conf_dir
    
    # 配置环境中不同节点配置不同的情况
    if [ "${IS_VAGRANT}" == "true" ];then
        hostname=`cat /etc/hostname`
        node_host=`cat /etc/hosts |grep ${hostname}|awk '{print $1}'`
        file_path=${INSTALL_PATH}/${app_name}/config/elasticsearch.yml
        
        echo "------modify $i server.properties-------"
        #sed -i 's/^node.name: .*/node.name: '$hostname'/' $file_path
        sed -i 's@^network.host: .*@network.host: '${node_host}'@' ${file_path}
    fi
    
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

dispatch_#@() {
    local app_name=$1
    dispatch_app ${app_name}
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        current_hostname=`cat /etc/hostname`
        node_host=`cat /etc/hosts |grep $i|awk '{print $1}'`
        file_path=${INSTALL_PATH}/${app_name}/config/elasticsearch.yml

        if [ "$current_hostname" != "${HOSTNAME_LIST[0]}" ];then
            echo "------modify $i server.properties-------"
            #ssh $i "sed -i 's/^node.name: .*/node.name: '$node_name'/' $file_path"
            ssh $i "sed -i 's@^network.host: .*@network.host: '${node_host}'@' ${file_path}"
        fi
    done
}

install_#@() {
    local app_name="#@"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setup_#@ ${app_name}
        setupEnv_app $app_name
        
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_#@ ${app_name}
        fi
        source ${PROFILE}
    fi
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_#@
fi
