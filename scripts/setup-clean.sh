#!/bin/bash
#set -x
if [ "${IS_VAGRANT}" == "true" ];then
    source "/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
else
    source "/home/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
fi

# 统一缩进为4
echo "set tabstop=4" > /home/vagrant/.vimrc
echo "set softtabstop=4" > /home/vagrant/.vimrc
echo "set shiftwidth=4" > /home/vagrant/.vimrc

# 复制初始化程序到init_shell的bin目录
log info "copy init shell to ${INIT_SHELL_BIN}"
if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
    sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${INIT_PATH}/`
fi
cp $INIT_PATH/* ${INIT_SHELL_BIN}
chmod 777 ${INIT_SHELL_BIN}/jpsall
chmod 777 ${INIT_SHELL_BIN}/bigstart
chmod 777 ${INIT_SHELL_BIN}/setssh
chmod 777 ${INIT_SHELL_BIN}/xsync
chmod 777 ${INIT_SHELL_BIN}/xcall
chmod 777 ${INIT_SHELL_BIN}/complete_tool
echo "export INIT_SHELL_BIN=${INIT_SHELL_BIN}" >> ${PROFILE}
echo 'export PATH=${INIT_SHELL_BIN}:$PATH' >> ${PROFILE}
source ${PROFILE}

# 删除安装目录
rm -rf /home/vagrant/vagrant_bigdata_cluster
