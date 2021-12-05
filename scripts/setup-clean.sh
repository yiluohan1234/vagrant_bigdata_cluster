#!/bin/bash
#set -x
if [ "${IS_VAGRANT}" == "true" ];then
    source "/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
else
    source "/home/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
fi

# 删除安装目录
rm -rf /home/vagrant/vagrant_bigdata_cluster/resources
rm -rf /home/vagrant/vagrant_bigdata_cluster/scripts
rm -rf /home/vagrant/downloads
