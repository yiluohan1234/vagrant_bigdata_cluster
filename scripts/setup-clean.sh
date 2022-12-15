#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

# 删除安装目录
[ -d ${INSTALL_PATH}/azkaban-3.84.4 ] && rm -rf ${INSTALL_PATH}/azkaban-3.84.4
[ -f /root/anaconda-ks.cfg ] && rm -rf /root/anaconda-ks.cfg  
[ -f /root/original-ks.cfg ] && rm -rf /root/original-ks.cfg
