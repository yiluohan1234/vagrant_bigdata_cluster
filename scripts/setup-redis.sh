#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_redis() {
    local app_name="redis"
    log info "setup ${app_name}"

    yum install -y -q redis

    # Modify the configuration file
    sed -i 's@^bind 127.0.0.1.*@#bind 127.0.0.1 -::1@' /etc/redis.conf
    sed -i 's@^daemonize no.*@daemonize yes@' /etc/redis.conf
    sed -i 's@protected-mode yes@protected-mode no@' /etc/redis.conf
    # sed -i 's@^# requirepass.*@requirepass LtG\!\&t42@g' /etc/redis.conf

    # Start redis and set it to start automatically
    service redis start
    chkconfig redis on
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_redis
fi
