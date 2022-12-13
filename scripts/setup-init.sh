#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

install_init(){
    yum install -y -q expect 

    # 创建生成日志目录
    [ ! -d $INSTALL_PATH ] && mkdir -p $INSTALL_PATH
    [ ! -d $DOWNLOAD_PATH ] && mkdir -p $DOWNLOAD_PATH
    [ ! -d $INIT_SHELL_BIN ] && mkdir -p $INIT_SHELL_BIN
    chown -R $DEFAULT_USER:$DEFAULT_GROUP $INSTALL_PATH
    chown -R $DEFAULT_USER:$DEFAULT_GROUP $DOWNLOAD_PATH
    chown -R $DEFAULT_USER:$DEFAULT_GROUP $INIT_SHELL_BIN

    host_list="for host in"
    for i in ${HOSTNAME_LIST[@]}; do host_list="$host_list ""$i"; done
    host_list="$host_list"";"
    # 复制初始化程序到init_shell的bin目录
    log info "copy init shell to ${INIT_SHELL_BIN}"
    jdk_path=${INSTALL_PATH}/java/jdk1.8.0_221
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${INIT_PATH}/`
        sed -i "s@for host in hdp{101..103};@${host_list}@g"  ${INIT_PATH}/xsync
        sed -i "s@for host in hdp{101..103};@${host_list}@g"  ${INIT_PATH}/xcall
        sed -i "s@for host in hdp{101..103};@${host_list}@g"  ${INIT_PATH}/jpsall
        sed -i "s@/home/vagrant/apps/java/bin/jps@${jdk_path}/bin/jps@g"  ${INIT_PATH}/jpsall
    fi

    cp -f $INIT_PATH/jpsall ${INIT_SHELL_BIN}
    cp -f $INIT_PATH/bigstart ${INIT_SHELL_BIN}
    cp -f $INIT_PATH/setssh ${INIT_SHELL_BIN}
    cp -f $INIT_PATH/xsync ${INIT_SHELL_BIN}
    cp -f $INIT_PATH/xcall ${INIT_SHELL_BIN}


    echo "# init shell bin" >> ${PROFILE}
    echo "export INIT_SHELL_BIN=${INIT_SHELL_BIN}" >> ${PROFILE}
    echo 'export PATH=${INIT_SHELL_BIN}:$PATH' >> ${PROFILE}
    source ${PROFILE}

    # 设置安装目录权限
    chmod -R 755 $INSTALL_PATH
    chown -R $DEFAULT_USER:$DEFAULT_GROUP $INSTALL_PATH


    # 统一缩进为4
    echo "set tabstop=4" >> $PROFILE
    echo "set softtabstop=4" >> $PROFILE
    echo "set shiftwidth=4" >> $PROFILE
}
if [ "${IS_VAGRANT}" == "true" ];then
    install_init
fi
