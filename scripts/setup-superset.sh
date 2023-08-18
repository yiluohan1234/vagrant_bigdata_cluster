#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_miniconda() {
    # install Miniconda3
    log info "install Miniconda3"
    set -e
    #wget "https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O $INSTALL_PATH/miniconda.sh
    curl -o $INSTALL_PATH/miniconda.sh -O -L "https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    bash $INSTALL_PATH/miniconda.sh -b -p $INSTALL_PATH/miniconda3
    $INSTALL_PATH/miniconda3/bin/conda init $(echo $SHELL | awk -F '/' '{print $NF}')
    echo 'Successfully installed miniconda...'
    echo -n 'Conda version: '
    $INSTALL_PATH/miniconda3/bin/conda --version
    $INSTALL_PATH/miniconda3/bin/conda config --set auto_activate_base false
    $INSTALL_PATH/miniconda3/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
    $INSTALL_PATH/miniconda3/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
    $INSTALL_PATH/miniconda3/bin/conda config --set show_channel_urls yes
    echo -e '\n'
    exec bash

    source ${PROFILE}
}

setup_superset(){

    echo "setup superset"
    yum install -y -q gcc gcc-c++ libffi-devel python-devel python-pip python-wheel python-setuptools openssl-devel cyrus-sasl-devel openldap-devel
    export FLASK_APP=superset
    echo y |conda create --name superset python=3.8
    conda activate superset
    pip install --upgrade setuptools pip
    /opt/module/miniconda3/envs/superset/bin/pip install apache-superset
    /opt/module/miniconda3/envs/superset/bin/pip install markupsafe==2.0.1
    /opt/module/miniconda3/envs/superset/bin/pip install importlib-metadata==4.13.0
    /opt/module/miniconda3/envs/superset/bin/pip install sqlparse==0.4.3
    /opt/module/miniconda3/envs/superset/bin/pip install marshmallow_enum
    mv ${RESOURCE_PATH}/superset/superset_config.py ${INSTALL_PATH}/miniconda3/envs/superset/lib/python3.8/

    # Initialize the Supetset database
    superset db upgrade
    # Create an admin user
    # superset fab create-admin
    expect -c "
        spawn superset fab create-admin
        expect {
            \"Username*\" { send \"yiluohan\r\"; exp_continue}
            \"User first name*\" { send \"yi\r\" ; exp_continue}
            \"User last name*\" { send \"luohan\r\"; exp_continue}
            \"Email*\" { send \"1111@qq.com\r\" ; exp_continue}
            \"Password*\" { send \"123456\r\" ; exp_continue}
            \"Repeat for confirmation*\" { send \"123456\r\" ; exp_continue}
        }";
    # Superset initialization
    superset init

    gunicorn --workers 5 --timeout 120 --bind hdp101:8787 "superset.app:create_app()" --daemon
    conda install mysqlclient
}

if [ "${IS_VAGRANT}" == "true" ];then
    setup_superset
fi
