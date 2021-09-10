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
    mkdir -p ${INSTALL_PATH}/zookeeper/log
    touch ${INSTALL_PATH}/zookeeper/data/myid
    log info "copying over $app_name configuration files"
    cp -f $ZOOKEEPER_RES_DIR/* $ZOOKEEPER_CONF_DIR
    if [ "$IS_VAGRANT" == "true" ];then
        echo -e "\n" >> ${INSTALL_PATH}/zookeeper/bin/zkEnv.sh
        echo "export JAVA_HOME=/home/vagrant/apps/java" >> ${INSTALL_PATH}/zookeeper/bin/zkEnv.sh
        echo $MYID >>${INSTALL_PATH}/zookeeper/data/myid
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