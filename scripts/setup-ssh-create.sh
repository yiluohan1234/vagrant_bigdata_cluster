#!/bin/bash
source "/vagrant/scripts/common.sh"

START=4
TOTAL_NODES=3
# sh setup-ssh.sh -s 4 -t 3 -c 4
while getopts s:t:c: option
do
	case "${option}"
	in
		s) START=${OPTARG};;
		t) TOTAL_NODES=${OPTARG};;
        c) CURRENT_NODES=${OPTARG};;
	esac
done

create_ssh_key() {
	log info "generating ssh key"
	ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
	#cp -f $SSH_CONF/config ~/.ssh
}

log info "setup ssh"
create_ssh_key
