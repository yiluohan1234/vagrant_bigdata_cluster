#!/bin/bash
source "/vagrant/scripts/common.sh"
#source "/home/vagrant/scripts/common.sh"

installJava() {
    log info "install java"
    if resourceExists $JAVA_ARCHIVE; then
        installFromLocal $JAVA_ARCHIVE
    else
        installFromRemote $JAVA_ARCHIVE $JAVA_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/jdk1.8.0_201 ${INSTALL_PATH}/java
}

setupEnvVars() {
    log info "creating java environment variables"
    jdk_path=${INSTALL_PATH}/java
    echo "# jdk environment" >> $PROFILE
    echo "export JAVA_HOME=$jdk_path" >> $PROFILE
    echo 'export JRE_HOME=${JAVA_HOME}/jre' >> $PROFILE
    echo 'export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib' >> $PROFILE
    echo 'export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH' >> $PROFILE
    echo -e "\n" >> $PROFILE
}

log info "setup java"
installJava
setupEnvVars
source $PROFILE