#!/bin/bash
source "/vagrant/scripts/common.sh"
TOTAL_NODES=3
# sh 
# sh setup-hosts.sh -s 4 -t 3
# 4,5,6
while getopts s:t: option
do
    case "${option}"
    in
        s) START=${OPTARG};;
        t) TOTAL_NODES=${OPTARG};;
    esac
done

function setupHosts {
    log info "modifying /etc/hosts file"
    echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" >> /etc/nhosts
    echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/nhosts
    for i in $(seq $START $(($START+$TOTAL_NODES-1)))
    do 
        entry="192.168.10.10${i} hdp10${i}"
        log info "-------------adding ${entry}-------------"
        echo "${entry}" >> /etc/nhosts
    done
    mv /etc/nhosts /etc/hosts
}


log info "setup centos hosts file"
setupHosts
