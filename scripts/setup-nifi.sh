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

setup_nifi() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "modifying over ${app_name} configuration files"
    # nifi.properties
    if [ "${IS_VAGRANT}" == "true" ];then
        sed -i "s@^nifi.web.http.host=.*@nifi.web.http.host=${HOSTNAME_LIST[$(($ID-1))]}@" ${conf_dir}/nifi.properties
        sed -i "s@^nifi.cluster.node.address=.*@nifi.cluster.node.address=${HOSTNAME_LIST[$(($ID-1))]}@" ${conf_dir}/nifi.properties
    else
        sed -i "s@^nifi.web.http.host=.*@nifi.web.http.host=${HOSTNAME_LIST[0]}@" ${conf_dir}/nifi.properties
        sed -i "s@^nifi.cluster.node.address=.*@nifi.cluster.node.address=${HOSTNAME_LIST[0]}@" ${conf_dir}/nifi.properties
    fi

    sed -i "s@^nifi.cluster.is.node=.*@nifi.cluster.is.node=true@" ${conf_dir}/nifi.properties

    # The protocol port of the node. Default is blank
    sed -i "s@^nifi.cluster.node.protocol.port=.*@nifi.cluster.node.protocol.port=28001@" ${conf_dir}/nifi.properties
    # Specifies the desired number of nodes in the cluster for stream selection ahead of time. This allows nodes in the cluster to avoid waiting a long time before starting processing
    sed -i "s@^nifi.cluster.flow.election.max.candidates=.*@nifi.cluster.flow.election.max.candidates=1@" ${conf_dir}/nifi.properties
    # Connect to the external ZooKeeper connection address
    sed -i "s@^nifi.zookeeper.connect.string=.*@nifi.zookeeper.connect.string=${HOSTNAME_LIST[0]}:2181,${HOSTNAME_LIST[1]}:2181,${HOSTNAME_LIST[2]}:2181@" ${conf_dir}/nifi.properties

    # state-management.xml
    sed -i 's@<property name="Connect String"></property>@<property name="Connect String">'${HOSTNAME_LIST[0]}':2181,'${HOSTNAME_LIST[1]}':2181,'${HOSTNAME_LIST[2]}':2181</property>@' ${conf_dir}/nifi.properties
}

dispatch_nifi() {
    local app_name=$1
    dispatch_app ${app_name}
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        current_hostname=`cat /etc/hostname`
        host_name=${HOSTNAME_LIST[$i]}
        file_path=${INSTALL_PATH}/${app_name}/conf/nifi.properties

        if [ "$current_hostname" != "${HOSTNAME_LIST[$i]}" ];then
            echo "------modify ${HOSTNAME_LIST[$i]} server.properties-------"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's@^nifi.web.http.host=.*@nifi.web.http.host='${host_name}'@' ${file_path}"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's@^nifi.cluster.node.address=.*@nifi.cluster.node.address='${host_name}'@' ${file_path}"

        fi
    done
}

install_nifi() {
    local app_name="nifi"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setup_nifi ${app_name}
        setupEnv_app ${app_name}
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_nifi ${app_name}
        fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_nifi
fi
