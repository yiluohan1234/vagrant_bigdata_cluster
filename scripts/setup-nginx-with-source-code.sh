#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_nginx() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "install dependency packages"
    yum install -y make zlib zlib-devel gcc-c++ libtool openssl openssl-devel
    cd ${INSTALL_PATH}/${NGINX_VERSION}

    log info "configure ${INSTALL_PATH}/nginx"
    ./configure --prefix=${INSTALL_PATH}/nginx

    log info "make && make install"
    make&&make install

    rm ${DOWNLOAD_PATH}/${NGINX_ARCHIVE}
    rm -rf ${INSTALL_PATH}/${NGINX_VERSION}

    # Allow an application of the current user to use ports below 1024
    setcap cap_net_bind_service=+eip ${INSTALL_PATH}/nginx/sbin/nginx

    cp ${res_dir}/* ${conf_dir}
    chown -R vagrant:vagrant ${INSTALL_PATH}/${app_name}

}

download_nginx() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local app_version=$(eval echo \$${app_name_upper}_VERSION)
    local archive=$(eval echo \$${app_name_upper}_ARCHIVE)
    local download_url=$(eval echo \$${app_name_upper}_MIRROR_DOWNLOAD)

    log info "install ${app_name}"
    if resourceExists ${archive}; then
        installFromLocal ${archive}
    else
        installFromRemote ${archive} ${download_url}
    fi

    #rm ${DOWNLOAD_PATH}/${archive}
}

install_nginx() {
    local app_name="nginx"
    log info "setup ${app_name}"

    download_nginx ${app_name}
    setup_nginx ${app_name}
    setupEnv_app ${app_name} sbin
    source ${PROFILE}
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_nginx
fi
