#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setupEnv_java() {
    local app_name=$1
    log info "creating ${app_name} environment variables"
    app_path=${INSTALL_PATH}/${app_name}
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
        download_and_unzip_app ${app_name}
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
