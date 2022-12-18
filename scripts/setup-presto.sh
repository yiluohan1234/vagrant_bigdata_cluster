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

setup_presto() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "create ${app_name} configuration directories"
    mkdir -p ${INSTALL_PATH}/presto/data
    mkdir -p ${INSTALL_PATH}/presto/etc/catalog

    log info "modifying over ${app_name} configuration files"
    # config.properties
    echo "coordinator=false" >> $conf_dir/config.properties
    # echo "node-scheduler.include-coordinator=false" >> $conf_dir/config.properties
    echo "http-server.http.port=8881" >> $conf_dir/config.properties
    echo "query.max-memory=50GB" >> $conf_dir/config.properties
    echo "discovery-server.enabled=true" >> $conf_dir/config.properties
    echo "discovery.uri=http://${HOSTNAME_LIST[0]}:8881" >> $conf_dir/config.properties
    # hive.properties
    echo "connector.name=hive-hadoop2" >> $conf_dir/catalog/hive.properties
    echo "hive.metastore.uri=thrift://${HOSTNAME_LIST[0]}:9083" >> $conf_dir/catalog/hive.properties
    # jvm.config
    echo "-server" >> $conf_dir/jvm.config
    echo "-Xmx16G" >> $conf_dir/jvm.config
    echo "-XX:+UseG1GC" >> $conf_dir/jvm.config
    echo "-XX:G1HeapRegionSize=32M" >> $conf_dir/jvm.config
    echo "-XX:+UseGCOverheadLimit" >> $conf_dir/jvm.config
    echo "-XX:+ExplicitGCInvokesConcurrent" >> $conf_dir/jvm.config
    echo "-XX:+HeapDumpOnOutOfMemoryError" >> $conf_dir/jvm.config
    echo "-XX:+ExitOnOutOfMemoryError" >> $conf_dir/jvm.config
    # node.properties
    echo "node.environment=production" >> $conf_dir/node.properties
    echo "node.id=ffffffff-ffff-ffff-ffff-fffffffffff1" >> $conf_dir/node.properties
    echo "node.data-dir=${INSTALL_PATH}/presto/data" >> $conf_dir/node.properties

    
    # 配置环境中不同节点配置不同的情况
    if [ "${IS_VAGRANT}" == "true" ];then
        sed -i 's@^node.id=.*@node.id=ffffffff-ffff-ffff-ffff-fffffffffff'$ID'@' ${INSTALL_PATH}/${app_name}/etc/node.properties    
    else 
        sed -i 's@^node.id=.*@node.id=ffffffff-ffff-ffff-ffff-fffffffffff1@' ${INSTALL_PATH}/${app_name}/etc/node.properties
    fi

    curl -o ${INSTALL_PATH}/${app_name}/presto-cli-0.196-executable.jar -O -L http://maven.aliyun.com/nexus/content/groups/public/com/facebook/presto/presto-cli/0.196/presto-cli-0.196-executable.jar
    mv ${INSTALL_PATH}/${app_name}/presto-cli-0.196-executable.jar ${INSTALL_PATH}/${app_name}/prestocli
    chmod a+x ${INSTALL_PATH}/${app_name}/prestocli
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

dispatch_presto() {
    local app_name=$1
    dispatch_app ${app_name}
    for ((i=0; i<$length; i++));do
        current_hostname=`cat /etc/hostname`
        node_file_path=${INSTALL_PATH}/${app_name}/etc/node.properties
        config_file_path=${INSTALL_PATH}/${app_name}/etc/config.properties
        if [ "$current_hostname" != "${HOSTNAME_LIST[$i]}" ];then
            ssh $i "sed -i 's@^node.id=.*@node.id=ffffffff-ffff-ffff-ffff-fffffffffff'$(($i+1))'@' ${node_file_path}"
        fi
    done
}

install_presto() {
    local app_name="presto"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setup_presto ${app_name}
        setupEnv_app $app_name
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_presto ${app_name}
        fi
        source ${PROFILE}
    fi
    
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_presto
fi
