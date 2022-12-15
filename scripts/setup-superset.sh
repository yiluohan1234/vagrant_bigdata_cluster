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
    echo -e '\n'
    exec bash

    source ${PROFILE}
}

setup_conda(){

    echo "setup conda"
    conda config --set auto_activate_base false
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
    conda config --set show_channel_urls yes
    export FLASK_APP=superset
    conda create --name superset python=3.7
    conda activate superset
}

yum install -y gcc gcc-c++ libffi-devel python-devel python-pip python-wheel python-setuptools openssl-devel cyrus-sasl-devel openldap-devel

pip install apache-superset -i https://pypi.douban.com/simple/
pip install pillow -i https://pypi.douban.com/simple/
pip install gunicorn -i https://pypi.douban.com/simple/

# 初始化 Supetset 数据库
superset db upgrade
export FLASK_APP=superset
# 创建管理员用户
superset fab create-admin
# Superset 初始化
superset init

gunicorn --workers 5 --timeout 120 --bind hdp101:8787 "superset.app:create_app()" --daemon
conda install mysqlclient
