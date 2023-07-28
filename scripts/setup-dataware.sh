#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_dataware() {
    local app_name="dataware"
    log info "setup ${app_name}"
    mkdir -p ${INSTALL_PATH}/dataware

    cp $INIT_PATH/${DATAWARE_VERSION}/* ${INIT_SHELL_BIN}

    git clone https://gitee.com/yiluohan1234/vagrant_bigdata ${INSTALL_PATH}/tmp
    mv ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/mock/* ${INSTALL_PATH}/dataware
    mv ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/flume/*.jar ${INSTALL_PATH}/flume/lib
    #rm -rf ${INSTALL_PATH}/tmp
    mysql -uroot -p${MYSQL_PASSWORD} -Dgmall < ${INSTALL_PATH}/dataware/db/gmall.sql

}
if [ "${IS_VAGRANT}" == "true" ];then
    install_dataware
fi
