#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

install_init(){
    # 创建hadoop组、创建各用户并设置密码
    groupadd hadoop
    for user in {"hdfs","yarn","mapred","hive"};
    do
        useradd $user -g hadoop -d /home/$user
        # 各个用户的默认密码是vagrant
        echo $user | passwd --stdin $user
    done
    # 修改vagrant用户信息，把vagrant添加到组hadoop中
    usermod -a -G hadoop vagrant

    # 创建生成日志目录
    # APP_LOG=/opt/module/applog/log/
    # [ ! -d $APP_LOG ] && mkdir -p $APP_LOG
    # chown -R ${DEFAULT_USER}:${DEFAULT_GROUP} $APP_LOG
    [ ! -d ${INSTALL_PATH} ] && mkdir -p ${INSTALL_PATH}
    [ ! -d ${DOWNLOAD_PATH} ] && mkdir -p ${DOWNLOAD_PATH}
    [ ! -d ${INIT_SHELL_BIN} ] && mkdir -p ${INIT_SHELL_BIN}
    chown -R ${DEFAULT_USER}:$DEFAULT_GROUP ${INSTALL_PATH}
    chown -R ${DEFAULT_USER}:${DEFAULT_GROUP} ${DOWNLOAD_PATH}
    chown -R ${DEFAULT_USER}:${DEFAULT_GROUP} ${INIT_SHELL_BIN}


    # 复制初始化程序到init_shell的bin目录
    log info "copy init shell to ${INIT_SHELL_BIN}"
    for name in ${HOSTNAME_LIST[@]}; do host_list="${host_list:-} ""$name"; done
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${INIT_PATH}/`
        sed -i "s@hdp{101..103}@${host_list}@g"  ${INIT_PATH}/xsync
        sed -i "s@hdp{101..103}@${host_list}@g"  ${INIT_PATH}/xcall
        sed -i "s@hdp{101..103}@${host_list}@g"  ${INIT_PATH}/jpsall
    fi
    cp $INIT_PATH/jpsall ${INIT_SHELL_BIN}
    cp $INIT_PATH/bigstart ${INIT_SHELL_BIN}
    cp $INIT_PATH/setssh ${INIT_SHELL_BIN}
    cp $INIT_PATH/xsync ${INIT_SHELL_BIN}
    cp $INIT_PATH/xcall ${INIT_SHELL_BIN}
    cp $INIT_PATH/GitHub520 ${INIT_SHELL_BIN}

    cp $INIT_PATH/complete_tool.sh /etc/profile.d
    source /etc/profile.d/complete_tool.sh

    echo "# init shell bin" >> ${PROFILE}
    echo "export INIT_SHELL_BIN=${INIT_SHELL_BIN}" >> ${PROFILE}
    echo 'export PATH=${INIT_SHELL_BIN}:$PATH' >> ${PROFILE}
    source ${PROFILE}

    # 设置安装目录权限
    chmod -R 755 ${INSTALL_PATH}
    chown -R ${DEFAULT_USER}:${DEFAULT_GROUP} ${INSTALL_PATH}

    # 生成免密登录
    log info "生成免密登录"
    setssh

    # 统一缩进为4
    echo "set tabstop=4" >> ${PROFILE}
    echo "set softtabstop=4" >> ${PROFILE}
    echo "set shiftwidth=4" >> ${PROFILE}
    echo -e "\n" >> ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_init
fi