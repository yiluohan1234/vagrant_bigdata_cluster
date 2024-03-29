#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_nginx() {
    local app_name="nginx"
    log info "setup ${app_name}"

    # Install
    yum install -y -q nginx

    # Start and set up to start automatically
    systemctl start nginx.service
    systemctl enable nginx.service
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_nginx
fi
