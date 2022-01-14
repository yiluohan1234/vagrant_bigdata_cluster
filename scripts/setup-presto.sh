#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"


setup_presto() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "create ${app_name} configuration directories"
    mkdir -p ${INSTALL_PATH}/presto/data
    mkdir -p ${INSTALL_PATH}/presto/etc/catalog

    log info "copying over ${app_name} configuration files"
    # 将resources配置文件拷贝到插件的配置目录
    cp -f $res_dir/jvm.config $conf_dir
    cp -f $res_dir/node.properties $conf_dir
    cp -f $res_dir/config.properties $conf_dir
    cp -f $res_dir/hive.properties $conf_dir/catalog
    
    # 配置环境中不同节点配置不同的情况
    if [ "${IS_VAGRANT}" == "true" ];then
        hostname=`cat /etc/hostname`
        ip=`cat /etc/hosts |grep ${hostname}|awk '{print $1}'`
        ip_end=${ip##*.} 
        node_file_path=${INSTALL_PATH}/${app_name}/etc/node.properties
        config_file_path=${INSTALL_PATH}/${app_name}/etc/config.properties
        
        if [ "$hostname" != "hdp101" ];then
            sed -i 's@^node.id=.*@node.id=ffffffff-ffff-ffff-ffff-fffffffffff'${ip_end}'@' ${node_file_path}
            sed -i 's@coordinator=true@coordinator=false@' ${config_file_path}
            sed -i '2d' ${config_file_path}
        fi
    fi
    curl -o ${INSTALL_PATH}/${app_name}/presto-cli-0.196-executable.jar -O -L http://maven.aliyun.com/nexus/content/groups/public/com/facebook/presto/presto-cli/0.196/presto-cli-0.196-executable.jar
    mv ${INSTALL_PATH}/${app_name}/presto-cli-0.196-executable.jar ${INSTALL_PATH}/${app_name}/prestocli
    chmod a+x ${INSTALL_PATH}/${app_name}/prestocli
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

download_presto() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local app_version=$(eval echo \$${app_name_upper}_VERSION)
    local archive=$(eval echo \$${app_name_upper}_ARCHIVE)
    local download_url=$(eval echo \$${app_name_upper}_MIRROR_DOWNLOAD)

    log info "install ${app_name}"
    if resourceExists ${archive}; then
        installFromLocal ${archive}
    else
        installFromRemote ${archive} ${download_url}
    fi
    mv ${INSTALL_PATH}/"${app_version}" ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    rm ${DOWNLOAD_PATH}/${archive}
}

dispatch_presto() {
    local app_name=$1
    dispatch_app ${app_name}
    for i in {"hdp102","hdp103"};
    do
        node_name=$i
        ip=`cat /etc/hosts |grep $i|awk '{print $1}'`
        ip_end=${ip##*.} 
        node_file_path=${INSTALL_PATH}/${app_name}/etc/node.properties
        config_file_path=${INSTALL_PATH}/${app_name}/etc/config.properties

        ssh $i "sed -i 's@^node.id=.*@node.id=ffffffff-ffff-ffff-ffff-fffffffffff'${ip_end}'@' ${node_file_path}"
        ssh $i "sed -i 's@coordinator=true@coordinator=false@' ${config_file_path}"
        ssh $i "sed -i '2d' ${config_file_path}"
    done
}

install_presto() {
    local app_name="presto"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"

        download_presto ${app_name}
    fi
    setup_presto ${app_name}
    setupEnv_app $app_name
    if [ "${IS_VAGRANT}" != "true" ];then
        dispatch_presto ${app_name}
    fi
    source ${PROFILE}
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_presto
fi
