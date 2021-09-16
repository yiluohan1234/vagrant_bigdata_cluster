#!/bin/bash
#set -x
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi
# 统一缩进为4
echo "set tabstop=4" > /home/vagrant/.vimrc
echo "set softtabstop=4" > /home/vagrant/.vimrc
echo "set shiftwidth=4" > /home/vagrant/.vimrc

# 复制初始化程序到init_shell的bin目录
log info "copy init shell to $INIT_SHELL_PATH"
cp $INIT_PATH/* $INIT_SHELL_PATH
chmod 777 $INIT_SHELL_PATH/jpsall
chmod 777 $INIT_SHELL_PATH/bigstart
chmod 777 $INIT_SHELL_PATH/setssh
chmod 777 $INIT_SHELL_PATH/xsync
echo "export INIT_SHELL_HOME=$INIT_SHELL_PATH" >> $PROFILE
echo 'export PATH=${INIT_SHELL_HOME}/bin:$PATH' >> $PROFILE
source $PROFILE

# 删除安装目录
rm -rf /home/vagrant/resources
rm -rf /home/vagrant/scripts
rm -rf /home/vagrant/downloads
