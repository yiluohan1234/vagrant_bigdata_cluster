#!/bin/bash
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/vbc-function.sh"
    source "/vagrant/scripts/vbc-config.sh"
fi

TOTAL_NODES=3
# sh
# sh install_hosts.sh -s 1 -t 3
# 4,5,6
while getopts s:t: option
do
    case "${option}"
    in
        s) START=${OPTARG};;
        t) TOTAL_NODES=${OPTARG};;
    esac
done

install_hosts() {
    log info "modifying /etc/hosts file"
    sed -i '/^127.0.1.1/'d /etc/hosts

    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        entry="${IP_LIST[$i]} ${HOSTNAME_LIST[$i]}"
        log info "-------------adding ${entry}-------------"
        echo "${entry}" >> /etc/hosts
    done
    if [ "${IS_GITHUB}" == "true" ];then
        # https://github.com/521xueweihan/GitHub520
        sed -i "/# GitHub520 Host Start/Q" /etc/hosts && curl https://raw.hellogithub.com/hosts >> /etc/hosts
        # 设置定时更新任务
        echo "*/60 * * * * root /opt/module/bin/GitHub520" >> /etc/crontab
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_hosts
fi
