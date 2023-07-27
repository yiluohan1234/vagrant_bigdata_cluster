#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/vbc-config.sh"
    source "/vagrant/scripts/vbc-function.sh"
fi

# sh setup-hosts.sh -hostname myid
# 4,5,6
while getopts i: option
do
    case "${option}"
    in
        i) id=${OPTARG};;
    esac
done

install_init(){
    log info "install init"
    # change hostname
    hostnamectl set-hostname ${HOSTNAME_LIST[$(( id-1 ))]}

    # Create a hadoop group, create each user and set a password
    groupadd hadoop
    # Modify the vagrant user information and add vagrant to the group hadoop
    usermod -a -G hadoop vagrant
    # Add atguigu user
    useradd atguigu -g hadoop -d /home/atguigu
    # Set password vagrant for atguigu user
    echo vagrant | passwd --stdin atguigu

    if [ "${IS_KERBEROS}" == "true" ];then

        for user in {"hdfs","yarn","mapred","hive"};
        do
            useradd $user -g hadoop -d /home/$user
            # The default password for each user is vagrant
            echo $user | passwd --stdin $user
        done
    fi

    # Configure atguigu and vagrant users with root privileges
    sed -i "/## Same thing without a password/iatguigu   ALL=(ALL)     NOPASSWD:ALL" /etc/sudoers
    sed -i "/## Same thing without a password/ivagrant   ALL=(ALL)     NOPASSWD:ALL" /etc/sudoers

    # Create build log directory
    APP_LOG=/opt/module/applog/log/
    [ ! -d $APP_LOG ] && mkdir -p $APP_LOG
    chown -R ${DEFAULT_USER}:${DEFAULT_GROUP} $APP_LOG
    [ ! -d ${INSTALL_PATH} ] && mkdir -p ${INSTALL_PATH}
    [ ! -d ${DOWNLOAD_PATH} ] && mkdir -p ${DOWNLOAD_PATH}
    [ ! -d ${INIT_SHELL_BIN} ] && mkdir -p ${INIT_SHELL_BIN}
    chown -R ${DEFAULT_USER}:$DEFAULT_GROUP ${INSTALL_PATH}
    chown -R ${DEFAULT_USER}:${DEFAULT_GROUP} ${DOWNLOAD_PATH}
    chown -R ${DEFAULT_USER}:${DEFAULT_GROUP} ${INIT_SHELL_BIN}


    # Copy the initialization program to the bin directory of the init shell
    # log info "copy init shell to ${INIT_SHELL_BIN}"
    for name in ${HOSTNAME_LIST[@]}; do host_list="${host_list:-} ""$name"; done
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" ${INIT_PATH}/jpsall
    fi

    # Replace the default host configuration
    sed -i "s@hdp{101..103}@${host_list}@g" `grep 'hdp{101..103}' -rl ${INIT_PATH}/`
    sed -i "s@hdp101@${HOSTNAME_LIST[0]}@g" `grep 'hdp101' -rl ${INIT_PATH}/`
    sed -i "s@hdp102@${HOSTNAME_LIST[1]}@g" `grep 'hdp102' -rl ${INIT_PATH}/`
    sed -i "s@hdp103@${HOSTNAME_LIST[2]}@g" `grep 'hdp103' -rl ${INIT_PATH}/`

    if [ -d /vagrant/scripts ];then
        host_list=`cat /vagrant/scripts/vbc-config.sh |grep '^HOSTNAME_LIST'`
        pass_wd=`cat /vagrant/scripts/vbc-config.sh |grep '^PASSWD_LIST'`
    else
        cur_dir=`dirname "${BASH_SOURCE-$0}"`
        cur_dir=`cd "$bin"; pwd`
        host_list=`cat ${cur_dir}/vbc-config.sh |grep '^HOSTNAME_LIST'`
        pass_wd=`cat ${cur_dir}/vbc-config.sh |grep '^PASSWD_LIST'`
    fi
    sed -i "6a${host_list}" ${INIT_PATH}/setssh
    sed -i "6a${pass_wd}" ${INIT_PATH}/setssh

    cp $INIT_PATH/jpsall ${INIT_SHELL_BIN}
    cp $INIT_PATH/bigstart ${INIT_SHELL_BIN}
    cp $INIT_PATH/setssh ${INIT_SHELL_BIN}
    cp $INIT_PATH/xsync ${INIT_SHELL_BIN}
    cp $INIT_PATH/xcall ${INIT_SHELL_BIN}
    cp $INIT_PATH/GitHub520 ${INIT_SHELL_BIN}
    cp $INIT_PATH/${DATAWARE_VERSION}/* ${INIT_SHELL_BIN}
    mkdir -p ${INSTALL_PATH}/dataware/log
    mkdir -p ${INSTALL_PATH}/dataware/db

    cp $INIT_PATH/complete_tool.sh /etc/profile.d
    source /etc/profile.d/complete_tool.sh

    echo "# init shell bin" >> ${PROFILE}
    echo "export INIT_SHELL_BIN=${INIT_SHELL_BIN}" >> ${PROFILE}
    echo 'export PATH=${INIT_SHELL_BIN}:$PATH' >> ${PROFILE}
    source ${PROFILE}

    # Set installation directory permissions
    chmod -R 755 ${INSTALL_PATH}
    chown -R ${DEFAULT_USER}:${DEFAULT_GROUP} ${INSTALL_PATH}

    # Uniform indentation to 4
    echo "set tabstop=4" >> ${PROFILE}
    echo "set softtabstop=4" >> ${PROFILE}
    echo "set shiftwidth=4" >> ${PROFILE}
    echo -e "\n" >> ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_init
fi
