#!/bin/bash
#set -x
# log: f1->f2->lg
# db: gen_import_config.sh->mysql_to_hdfs_full.sh all 2020-06-14->f3->db->mysql_to_kafka_inc_init.sh all


if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_dataware() {
    local app_name="dataware"
    log info "setup ${app_name}"
    mkdir -p ${INSTALL_PATH}/dataware

    # 防止大部分资源都被Application Master占用，而导致Map/Reduce Task无法执行
    sed -i "s@0.1@0.8@g" ${INSTALL_PATH}/hadoop/etc/hadoop/capacity-scheduler.xml

    cp $INIT_PATH/${DATAWARE_VERSION}/* ${INIT_SHELL_BIN}

    git clone https://gitee.com/yiluohan1234/vagrant_bigdata ${INSTALL_PATH}/tmp
    mv ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/mock/* ${INSTALL_PATH}/dataware
    mv ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/flume/*.jar ${INSTALL_PATH}/flume/lib
    #rm -rf ${INSTALL_PATH}/tmp

}
if [ "${IS_VAGRANT}" == "true" ];then
    install_dataware
fi
