#!/bin/bash
source "/vagrant/scripts/common.sh"

download_scala() {
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
    mkdir ${INSTALL_PATH}/${app_name}
    mv ${INSTALL_PATH}/"${app_version}" ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    # rm ${DOWNLOAD_PATH}/${archive}
}

setupEnv_scala() {
    local app_name=$1
    log info "creating ${app_name} environment variables"
    # app_path=${INSTALL_PATH}/java
    app_path=${INSTALL_PATH}/${app_name}/${SCALA_VERSION}
    echo "# $app_name environment" >> ${PROFILE}
    echo "export SCALA_HOME=${app_path}" >> ${PROFILE}
    echo 'export PATH=${SCALA_HOME}/bin:$PATH' >> ${PROFILE}
    echo -e "\n" >> ${PROFILE}
}

install_scala() {
    local app_name="scala"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_scala ${app_name}
        setupEnv_scala ${app_name}
    fi

    # 主机长度
    host_name_list_len=${#HOSTNAME_LIST[@]}
    if [ "${IS_VAGRANT}" != "true" ] && [ ${host_name_list_len} -gt 1 ];then
        dispatch_app ${app_name}
    fi
    source ${PROFILE}
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_scala
fi
