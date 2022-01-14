#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

# 设置安装目录权限
chmod -R 660 $INSTALL_PATH
chown -R $DEFAULT_USER:$DEFAULT_GROUP $INSTALL_PATH
# 删除安装目录
rm -rf ${INSTALL_PATH}/azkaban-3.84.4
