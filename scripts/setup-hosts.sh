#!/bin/bash
source "/vagrant/scripts/common.sh"

install_hosts() {
    log info "modifying /etc/hosts file"

    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
    do 
        entry="${IP_LIST[$i]} ${HOSTNAME_LIST[$i]}"
        log info "-------------adding ${entry}-------------"
        echo "${entry}" >> /etc/hosts
    done
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_hosts $@
fi
