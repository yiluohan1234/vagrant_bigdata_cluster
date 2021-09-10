#!/bin/bash
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

download_java() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $JAVA_ARCHIVE; then
        installFromLocal $JAVA_ARCHIVE
    else
        installFromRemote $JAVA_ARCHIVE $JAVA_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/jdk1.8.0_201 ${INSTALL_PATH}/java
    chown -R vagrant:vagrant $INSTALL_PATH/java
    rm ${DOWNLOAD_PATH}/$JAVA_ARCHIVE
}

setupEnv_java() {
    local app_name=$1
    log info "creating $app_name environment variables"
    app_path=${INSTALL_PATH}/java
    echo "# jdk environment" >> $PROFILE
    echo "export JAVA_HOME=$app_path" >> $PROFILE
    echo 'export JRE_HOME=${JAVA_HOME}/jre' >> $PROFILE
    echo 'export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib' >> $PROFILE
    echo 'export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH' >> $PROFILE
    echo -e "\n" >> $PROFILE
}

install_java() {
    local app_name="java"
    log info "setup $app_name"
    download_java $app_name
    setupEnv_java $app_name
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_app $app_name
    fi
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_java
fi