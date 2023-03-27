#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

# Update the user owner permissions for the installation directory
chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}
# Delete the installation directory
[ -d ${INSTALL_PATH}/azkaban-3.84.4 ] && rm -rf ${INSTALL_PATH}/azkaban-3.84.4
[ -f /root/anaconda-ks.cfg ] && rm -rf /root/anaconda-ks.cfg
[ -f /root/original-ks.cfg ] && rm -rf /root/original-ks.cfg

# Delete the installation directory
if [ "${IS_DEL_VAGRANT}" == "true" ];then
    rm -rf /vagrant
fi
