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
        i) MYID=${OPTARG};;
    esac
done

setup_zookeeper() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)
    
    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/zookeeper/data 
    mkdir -p ${INSTALL_PATH}/zookeeper/logs
    touch ${INSTALL_PATH}/zookeeper/data/myid

    log info "modify the ${app_name} configuration files"
    # cp -f ${res_dir}/* ${conf_dir}

    # log4j.properties
    log4j_path=${conf_dir}/log4j.properties
    log_path=${INSTALL_PATH}/${app_name}/logs
    sed -i 's@^zookeeper.root.logger=INFO, CONSOLE*@zookeeper.root.logger=INFO, CONSOLE, ROLLINGFILE@' ${log4j_path}
    sed -i 's@^zookeeper.log.dir=.*@zookeeper.log.dir='${log_path}'@' ${log4j_path}


    # zkEnv.sh
    zkenv_path=${INSTALL_PATH}/${app_name}/bin/zkEnv.sh
    sed -i 's@ZOO_LOG4J_PROP="INFO,CONSOLE"*@ZOO_LOG4J_PROP="INFO,CONSOLE,ROLLINGFILE"@' ${zkenv_path}

    # zoo.cfg
    cp ${conf_dir}/zoo_sample.cfg ${conf_dir}/zoo.cfg
    sed -i "s@^dataDir=.*@dataDir=${INSTALL_PATH}/zookeeper/data@" ${conf_dir}/zoo.cfg
    echo "dataLogDir=${INSTALL_PATH}/zookeeper/logs" >> ${conf_dir}/zoo.cfg
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        echo "server.$(($i+1))=${HOSTNAME_LIST[$i]}:2888:3888" >> ${conf_dir}/zoo.cfg
    done

    if [ "${IS_VAGRANT}" == "true" ];then
        echo $MYID >>${INSTALL_PATH}/zookeeper/data/myid
    fi
}

dispatch_zookeeper() {
    local app_name=$1
    log info "dispatch ${app_name}" 
    dispatch_app ${app_name}
    echo "1" >> ${INSTALL_PATH}/${app_name}/data/myid
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        current_hostname=`cat /etc/hostname`
        if [ "$current_hostname" != "${HOSTNAME_LIST[0]}" ];then
            ssh ${HOSTNAME_LIST[$i]} "mkdir -p ${INSTALL_PATH}/${app_name}/data"
            ssh ${HOSTNAME_LIST[$i]} "mkdir -p ${INSTALL_PATH}/${app_name}/logs"
            ssh ${HOSTNAME_LIST[$i]} "echo $i >> ${INSTALL_PATH}/${app_name}/data/myid"
        fi
    done
}

install_zookeeper() {
    local app_name="zookeeper"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setup_zookeeper ${app_name}
        setupEnv_app ${app_name}
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_zookeeper ${app_name}
        fi
        source ${PROFILE} 
    fi
    
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_zookeeper
fi
