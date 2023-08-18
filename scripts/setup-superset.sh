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
    # pip install --upgrade setuptools pip -i https://pypi.douban.com/simple/
    /opt/module/miniconda3/envs/superset/bin/pip install apache-superset -i https://pypi.douban.com/simple/
    /opt/module/miniconda3/envs/superset/bin/pip install gunicorn -i https://pypi.douban.com/simple/

    # Initialize the Supetset database
    superset db upgrade
    # Create an admin user
    superset fab create-admin
    expect -c "
        spawn superset fab create-admin
        expect {
            \"Enter file in which to save the*\" { send \"\r\"; exp_continue}
            \"Overwrite*\" { send \"n\r\" ; exp_continue}
            \"Enter passphrase*\" { send \"\r\"; exp_continue}
            \"Enter same passphrase again:\" { send \"\r\" ; exp_continue}
        }";
    # Superset initialization
    superset init

    gunicorn --workers 5 --timeout 120 --bind hdp101:8787 "superset.app:create_app()" --daemon
    conda install mysqlclient
}

if [ "${IS_VAGRANT}" == "true" ];then
    setup_superset
fi
