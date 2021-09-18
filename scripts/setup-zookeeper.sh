#!/bin/bash
#set -x
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
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
    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/zookeeper/data 
    mkdir -p ${INSTALL_PATH}/zookeeper/logs
    touch ${INSTALL_PATH}/zookeeper/data/myid
    log info "copying over $app_name configuration files"
    cp -f $ZOOKEEPER_RES_DIR/* $ZOOKEEPER_CONF_DIR

    # log4j.properties
    log4j_path=$ZOOKEEPER_CONF_DIR/log4j.properties
    log_path=${INSTALL_PATH}/zookeeper/logs
    sed -i 's@^zookeeper.root.logger=INFO, CONSOLE*@zookeeper.root.logger=INFO, CONSOLE, ROLLINGFILE@' $log4j_path
    sed -i 's@^zookeeper.log.dir=.*@zookeeper.log.dir='$log_path'@' $log4j_path

    # zkServer.sh
    zkserver_path=${INSTALL_PATH}/zookeeper/bin/zkServer.sh
    sed -i 's@^_ZOO_DAEMON_OUT="$ZOO_LOG_DIR/zookeeper.out"*@_ZOO_DAEMON_OUT="$ZOO_LOG_DIR/zookeeper.log"@' $zkserver_path

    # zkEnv.sh
    zkenv_path=${INSTALL_PATH}/zookeeper/bin/zkEnv.sh
    sed -i 's@ZOO_LOG_DIR="."*@ZOO_LOG_DIR="$ZOOBINDIR/../logs"@' $zkenv_path
    sed -i 's@ZOO_LOG4J_PROP="INFO,CONSOLE"*@ZOO_LOG4J_PROP="INFO,CONSOLE,ROLLINGFILE"@' $zkenv_path

    if [ "$IS_VAGRANT" == "true" ];then
        echo -e "\n" >> ${INSTALL_PATH}/zookeeper/bin/zkEnv.sh
        echo "export JAVA_HOME=/home/vagrant/apps/java" >> ${INSTALL_PATH}/zookeeper/bin/zkEnv.sh
        echo $MYID >>${INSTALL_PATH}/zookeeper/data/myid
    fi
    
    if [ $INSTALL_PATH != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@$INSTALL_PATH@g" `grep '/home/vagrant/apps' -rl $ZOOKEEPER_CONF_DIR/`
    fi
}

download_zookeeper() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $ZOOKEEPER_ARCHIVE; then
        installFromLocal $ZOOKEEPER_ARCHIVE
    else
        installFromRemote $ZOOKEEPER_ARCHIVE $ZOOKEEPER_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${ZOOKEEPER_VERSION}" ${INSTALL_PATH}/zookeeper
    sudo chown -R vagrant:vagrant $INSTALL_PATH/zookeeper
    rm $DOWNLOAD_PATH/$ZOOKEEPER_ARCHIVE
}

dispatch_zookeeper() {
    local app_name=$1
    log info "dispatch $app_name" 
    dispatch_app $app_name
    echo "1" >>${INSTALL_PATH}/zookeeper/data/myid
    ssh hdp-node-02 "echo '2' >> /home/vagrant/apps/zookeeper/data/myid"
    ssh hdp-node-03 "echo '3' >> /home/vagrant/apps/zookeeper/data/myid"
}

install_zookeeper() {
    local app_name="zookeeper"
    log info "setup $app_name"

    download_zookeeper $app_name
    setup_zookeeper $app_name
    setupEnv_app $app_name
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_zookeeper $app_name
    fi
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_zookeeper
fi
