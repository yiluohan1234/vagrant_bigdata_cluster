#!/bin/bash
#set -x
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

setup_nginx() {
    local app_name=$1
    log info "install dependency packages"
    sudo yum install -y make zlib zlib-devel gcc-c++ libtool  openssl openssl-devel
    cd ${INSTALL_PATH}/${NGINX_VERSION}
    log info "configure ${INSTALL_PATH}/nginx"
    ./configure --prefix=${INSTALL_PATH}/nginx
    log info "make && make install"
    make&&make install
    rm $DOWNLOAD_PATH/$NGINX_ARCHIVE
    rm -rf $INSTALL_PATH/$NGINX_VERSION
    
}

download_nginx() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $NGINX_ARCHIVE; then
        installFromLocal $NGINX_ARCHIVE
    else
        installFromRemote $NGINX_ARCHIVE $NGINX_MIRROR_DOWNLOAD
    fi
}

install_nginx() {
    local app_name="nginx"
    log info "setup $app_name"

    download_nginx $app_name
    setup_nginx $app_name
    setupEnv_app $app_name sbin
    source $PROFILE
}


if [ "$IS_VAGRANT" == "true" ];then
    install_nginx
fi
