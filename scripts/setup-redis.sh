#!/bin/bash
#set -x

if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

setup_redis() {
    local app_name=$1
    log info "make install"
    cd ${INSTALL_PATH}/${REDIS_VERSION}
    make install PREFIX=$INSTALL_PATH/redis
    cd ${INSTALL_PATH}
 
    log info "copying over $app_name configuration files"
    mkdir -p $INSTALL_PATH/redis/config
    cp $INSTALL_PATH/$REDIS_VERSION/redis.conf $REDIS_CONF_DIR

    rm $DOWNLOAD_PATH/$REDIS_ARCHIVE
    rm -rf $INSTALL_PATH/$REDIS_VERSION
}

download_redis() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $REDIS_ARCHIVE; then
        installFromLocal $REDIS_ARCHIVE
    else
        installFromRemote $REDIS_ARCHIVE $REDIS_MIRROR_DOWNLOAD
    fi
}

install_redis() {
    local app_name="redis"
    log info "setup $app_name"

    download_redis $app_name
    setup_redis $app_name
    setupEnv_app $app_name
    source $PROFILE
}


if [ "$IS_VAGRANT" == "true" ];then
    install_redis
fi
