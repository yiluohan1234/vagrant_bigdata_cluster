#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

install_miniconda() {
    local app_name="miniconda"

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


if [ "${IS_VAGRANT}" == "true" ];then
    install_miniconda
fi
