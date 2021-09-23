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
    mkdir -p $INSTALL_PATH/redis/conf
    mkdir -p $INSTALL_PATH/redis/run
    mkdir -p $INSTALL_PATH//redis/logs
    mkdir -p $INSTALL_PATH//redis/data
    cp $INSTALL_PATH/$REDIS_VERSION/redis.conf $REDIS_CONF_DIR
    
    #bind 127.0.0.1 -::1
    sed -i 's@^bind 127.0.0.1*@#bind 127.0.0.1 -::1@' $REDIS_CONF_DIR/redis.conf
    sed -i 's@^daemonize no*@daemonize yes@' $REDIS_CONF_DIR/redis.conf
    sed -i 's@^pidfile /var/run/redis_6379.pid*@pidfile '$INSTALL_PATH'/redis/run/redis_6379.pid@' $REDIS_CONF_DIR/redis.conf
    #sed -i 's@^logfile ""*@logfile "'$INSTALL_PATH'/redis/logs"@' $REDIS_CONF_DIR/redis.conf
    sed -i 's@^dir ./*@dir '$INSTALL_PATH'/redis/data@' $REDIS_CONF_DIR/redis.conf
    sed -i 's@protected-mode yes@protected-mode no@' $REDIS_CONF_DIR/redis.conf
    
    if [ $INSTALL_PATH != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@$INSTALL_PATH@g" `grep '/home/vagrant/apps' -rl $REDIS_CONF_DIR/`
    fi
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
