#!/bin/bash
# http://unix.stackexchange.com/questions/59003/why-ssh-copy-id-prompts-for-the-local-user-password-three-times
# http://linuxcommando.blogspot.com/2008/10/how-to-disable-ssh-host-key-checking.html
# http://linuxcommando.blogspot.ca/2013/10/allow-root-ssh-login-with-public-key.html
# http://stackoverflow.com/questions/12118308/command-line-to-execute-ssh-with-password-authentication
# http://www.cyberciti.biz/faq/noninteractive-shell-script-ssh-password-provider/
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
echo "cur nodes = $CURRENT_NODES"

function installSSHPass {
	yum -y install sshpass
}

function overwriteSSHCopyId {
	cp -f $SSH_CONF/ssh-copy-id.modified /usr/bin/ssh-copy-id
}


function createSSHKey {
	log info "generating ssh key"
	ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
	#cp -f $SSH_CONF/config ~/.ssh
}

function sshCopyId {
	log info "executing ssh-copy-id"
	for i in $(seq $START $(($START+$TOTAL_NODES-1)))
	do
        if [ $i -ne $CURRENT_NODES ];then
            node="hdp10${i}"
            log info "copy ssh key to ${node}"
            ssh-copy-id -i ~/.ssh/id_rsa.pub $node
        fi
	done
}

log info "setup ssh"
#installSSHPass
createSSHKey
overwriteSSHCopyId
sshCopyId