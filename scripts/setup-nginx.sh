#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_nginx() {
    local app_name="nginx"
    log info "setup ${app_name}"

    # 安装
    yum install --y nginx

    # 启动并设置开机自启
    systemctl start nginx.service
    systemctl enable nginx.service
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_nginx
fi
