#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

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

    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/* ${conf_dir}

    # log4j.properties
    log4j_path=${conf_dir}/log4j.properties
    log_path=${INSTALL_PATH}/zookeeper/logs
    sed -i 's@^zookeeper.root.logger=INFO, CONSOLE*@zookeeper.root.logger=INFO, CONSOLE, ROLLINGFILE@' ${log4j_path}
    sed -i 's@^zookeeper.log.dir=.*@zookeeper.log.dir='${log_path}'@' ${log4j_path}


    # zkEnv.sh
    zkenv_path=${INSTALL_PATH}/zookeeper/bin/zkEnv.sh
    sed -i 's@ZOO_LOG4J_PROP="INFO,CONSOLE"*@ZOO_LOG4J_PROP="INFO,CONSOLE,ROLLINGFILE"@' ${zkenv_path}

    if [ "${IS_VAGRANT}" == "true" ];then
        echo $MYID >>${INSTALL_PATH}/zookeeper/data/myid
    fi
    
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${ZOOKEEPER_CONF_DIR}/`
    fi
}

download_zookeeper() {
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
    mkdir ${INSTALL_PATH}/${app_name}
    mv ${INSTALL_PATH}/apache-${app_version} ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    # rm ${DOWNLOAD_PATH}/${archive}
}

setupEnv_spark() {
    local app_name=$1
    log info "creating ${app_name} environment variables"
    # app_path=${INSTALL_PATH}/java
    app_path=${INSTALL_PATH}/${app_name}/apache-${ZOOKEEPER_VERSION}
    echo "# $app_name environment" >> ${PROFILE}
    echo "export ZOOKEEPER_HOME=${app_path}" >> ${PROFILE}
    echo 'export PATH=${ZOOKEEPER_HOME}/bin:$PATH' >> ${PROFILE}
    echo -e "\n" >> ${PROFILE}
}

dispatch_zookeeper() {
    local app_name=$1
    log info "dispatch ${app_name}" 
    dispatch_app ${app_name}
    echo "1" >>${INSTALL_PATH}/apache-${ZOOKEEPER_VERSION}/data/myid
    i=1
    for name in ${HOSTNAME_LIST[@]};do
        current_hostname=`cat /etc/hostname`
        if [ "$current_hostname" != "$host" ];then
            ssh name "echo $i >> ${INSTALL_PATH}/apache-${ZOOKEEPER_VERSION}/data/myid"
        fi
        i=$(( i+1 ))
    done
}

install_zookeeper() {
    local app_name="zookeeper"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_zookeeper ${app_name}
        setup_zookeeper ${app_name}
        setupEnv_app ${app_name}
    fi

    # 主机长度
    host_name_list_len=${#HOSTNAME_LIST[@]}
    if [ "${IS_VAGRANT}" != "true" ] && [ ${host_name_list_len} -gt 1 ];then
        dispatch_zookeeper ${app_name}
    fi
    source ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_zookeeper
fi
