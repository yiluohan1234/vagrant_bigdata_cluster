#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

# 更新安装目录的用户
chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}
# 删除安装目录
[ -d ${INSTALL_PATH}/azkaban-3.84.4 ] && rm -rf ${INSTALL_PATH}/azkaban-3.84.4
[ -f /root/anaconda-ks.cfg ] && rm -rf /root/anaconda-ks.cfg  
[ -f /root/original-ks.cfg ] && rm -rf /root/original-ks.cfg

# 删除安装目录
if [ "${IS_DEL_VAGRANT}" == "true" ];then
    rm -rf /vagrant
fi
