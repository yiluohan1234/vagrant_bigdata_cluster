#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_dataware() {
    local app_name="dataware"
    log info "setup ${app_name}"
    mkdir -p ${INSTALL_PATH}/dataware/log
    mkdir -p ${INSTALL_PATH}/dataware/db

    cp $INIT_PATH/${DATAWARE_VERSION}/* ${INIT_SHELL_BIN}

    curl -o ${INSTALL_PATH}/dataware/db/application.properties -O -L https://gitee.com/yiluohan1234/vagrant_bigdata/blob/master/dataware/${DATAWARE_VERSION}/mock/db/application.properties
    curl -o ${INSTALL_PATH}/dataware/db/gmall2020-mock-db-2021-11-14.jar -O -L https://gitee.com/yiluohan1234/vagrant_bigdata/blob/master/dataware/${DATAWARE_VERSION}/mock/db/gmall2020-mock-db-2021-11-14.jar

    curl -o ${INSTALL_PATH}/dataware/log/application.yml -O -L https://gitee.com/yiluohan1234/vagrant_bigdata/blob/master/dataware/${DATAWARE_VERSION}/mock/log/application.yml
    curl -o ${INSTALL_PATH}/dataware/log/gmall2020-mock-log-2021-10-10.jar -O -L https://gitee.com/yiluohan1234/vagrant_bigdata/blob/master/dataware/${DATAWARE_VERSION}/mock/log/gmall2020-mock-log-2021-10-10.jar
    curl -o ${INSTALL_PATH}/dataware/log/logback.xml -O -L https://gitee.com/yiluohan1234/vagrant_bigdata/blob/master/dataware/${DATAWARE_VERSION}/mock/log/logback.xml
    curl -o ${INSTALL_PATH}/dataware/log/path.json -O -L https://gitee.com/yiluohan1234/vagrant_bigdata/blob/master/dataware/${DATAWARE_VERSION}/mock/log/path.json

}
if [ "${IS_VAGRANT}" == "true" ];then
    install_dataware
fi
