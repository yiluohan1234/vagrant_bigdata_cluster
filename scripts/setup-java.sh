#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

download_java() {
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
    mv ${INSTALL_PATH}/jdk1.8.0_201 ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    rm ${DOWNLOAD_PATH}/${archive}
}

setupEnv_java() {
    local app_name=$1
    log info "creating ${app_name} environment variables"
    app_path=${INSTALL_PATH}/java
    echo "# jdk environment" >> ${PROFILE}
    echo "export JAVA_HOME=${app_path}" >> ${PROFILE}
    echo 'export JRE_HOME=${JAVA_HOME}/jre' >> ${PROFILE}
    echo 'export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib' >> ${PROFILE}
    echo 'export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH' >> ${PROFILE}
    echo -e "\n" >> ${PROFILE}
}

install_java() {
    local app_name="java"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_java ${app_name}
        setupEnv_java ${app_name}
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_java
fi
