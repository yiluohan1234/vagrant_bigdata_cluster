#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

# 删除安装目录
rm -rf ${INSTALL_PATH}/azkaban-3.84.4
