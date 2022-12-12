#!/bin/bash
source "/vagrant/scripts/common.sh"

install_hosts() {
    log info "modifying /etc/hosts file"

    i=0
    for name in ${HOSTNAME_LIST[@]}
    do 
        entry="IST[$i]} $name"
        log info "-------------adding ${entry}-------------"
        echo "${entry}" >> /etc/hosts
        i=$(( i+1 ))
    done
}
install_ssh
