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
cp $INIT_PATH/jpsall ${INIT_SHELL_BIN}
cp $INIT_PATH/bigstart ${INIT_SHELL_BIN}
cp $INIT_PATH/setssh ${INIT_SHELL_BIN}
cp $INIT_PATH/xsync ${INIT_SHELL_BIN}
cp $INIT_PATH/xcall ${INIT_SHELL_BIN}

chmod 777 ${INIT_SHELL_BIN}/*

cp ${RESOURCE_PATH}/INIT_PATH/complete_tool.sh /etc/profile.d

echo "# init shell bin" >> ${PROFILE}
echo "export INIT_SHELL_BIN=${INIT_SHELL_BIN}" >> ${PROFILE}
echo 'export PATH=${INIT_SHELL_BIN}:$PATH' >> ${PROFILE}
source ${PROFILE}

# 删除安装目录
rm -rf /home/vagrant/vagrant_bigdata_cluster
