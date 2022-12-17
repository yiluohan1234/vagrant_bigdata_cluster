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

setup_kafka() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "creating ${app_name} directories"
    mkdir -p ${INSTALL_PATH}/kafka/tmp/kafka-logs

    log info "copying over $app_name configuration files"
    # cp -f ${res_dir}/* ${conf_dir}
    # echo -e "\n" >> ${INSTALL_PATH}/kafka/bin/kafka-run-class.sh
    # echo "export JAVA_HOME=/home/vagrant/apps/java" >> ${INSTALL_PATH}/kafka/bin/kafka-run-class.sh

    # server.properties
    current_hostname=`cat /etc/hostname`
    value="PLAINTEXT://${current_hostname}:9092"
    if [ "${IS_VAGRANT}" == "true" ];then
        sed -i "s/^broker.id=.*/broker.id=${ID}/" ${conf_dir}/server.properties
    fi
    sed -i 's@^#listeners=.*@listeners='${value}'@' ${conf_dir}/server.properties
    sed -i 's@^#advertised.listeners=.*@advertised.listeners='${value}'@' ${conf_dir}/server.properties
    sed -i 's@^num.partitions=.*@num.partitions=3@' ${conf_dir}/server.properties
    sed -i "s@^zookeeper.connect=.*@zookeeper.connect=${HOSTNAME_LIST[0]}:2181,${HOSTNAME_LIST[1]}:2181,${HOSTNAME_LIST[2]}:2181/kafka@" ${conf_dir}/server.properties
    
    # consumer.properties,producer.properties,zookeeper.properties
    sed -i "s@^zookeeper.connect=.*@zookeeper.connect=${HOSTNAME_LIST[0]}:2181,${HOSTNAME_LIST[1]}:2181,${HOSTNAME_LIST[2]}:2181@" ${conf_dir}/consumer.properties
    sed -i "s@^bootstrap.servers=.*@bootstrap.servers=${HOSTNAME_LIST[0]}:9092,${HOSTNAME_LIST[1]}:9092,${HOSTNAME_LIST[2]}:9092@" ${conf_dir}/producer.properties
    sed -i "s@^dataDir=.*@dataDir=${INSTALL_PATH}/zookeeper/data@" ${conf_dir}/zookeeper.properties

}

dispatch_kafka() {
    local app_name=$1
    dispatch_app ${app_name}
    sed -i "s/^broker.id=.*/broker.id=1/" ${INSTALL_PATH}/${app_name}/config/server.properties
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        current_hostname=`cat /etc/hostname`
        value="PLAINTEXT://${HOSTNAME_LIST[$i]}:9092"
        file_path=${INSTALL_PATH}/${app_name}/config/server.properties

        if [ "$current_hostname" != "${HOSTNAME_LIST[$i]}" ];then
            echo "------modify ${HOSTNAME_LIST[$i]} server.properties-------"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's/^broker.id=.*/broker.id='$(($i+1))'/' ${file_path}"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's@^listeners=.*@listeners='${value}'@' ${file_path}"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's@^advertised.listeners=.*@advertised.listeners='${value}'@' ${file_path}"
            ssh ${HOSTNAME_LIST[$i]} "sed -i 's@^zookeeper.connect=.*@zookeeper.connect='${HOSTNAME_LIST[0]}':2181,'${HOSTNAME_LIST[1]}':2181,'${HOSTNAME_LIST[2]}':2181/kafka@' ${file_path}"
        fi
    done
}

install_kafka() {
    local app_name="kafka"
    log info "setup $app_name"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_and_unzip_app ${app_name}
        setup_kafka ${app_name}
        setupEnv_app ${app_name}
        if [ "$IS_VAGRANT" != "true" ];then
            dispatch_kafka ${app_name}
        fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_kafka
fi
