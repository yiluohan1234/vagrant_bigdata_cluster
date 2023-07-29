#!/bin/bash
#set -x
# log: f1->f2->lg
# db: gen_import_config.sh->mysql_to_hdfs_full.sh all 2020-06-14->f3->db->mysql_to_kafka_inc_init.sh all


if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

install_dataware5() {
    local app_name="dataware"
    log info "setup ${app_name}"
    mkdir -p ${INSTALL_PATH}/dataware

    # 防止大部分资源都被Application Master占用，而导致Map/Reduce Task无法执行
    sed -i "s@0.1@0.8@g" ${INSTALL_PATH}/hadoop/etc/hadoop/capacity-scheduler.xml

    cp $INIT_PATH/${DATAWARE_VERSION}/* ${INIT_SHELL_BIN}

    git clone https://gitee.com/yiluohan1234/vagrant_bigdata ${INSTALL_PATH}/tmp
    mv ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/mock/* ${INSTALL_PATH}/dataware
    mv ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/flume/*.jar ${INSTALL_PATH}/flume/lib
    # 替换maxwell
    current_hostname=`cat /etc/hostname`
    if [ "$current_hostname" == "${HOSTNAME_LIST[0]}" ];then
        tar -zxvf ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/${MAXWELL_ARCHIVE} -C ${INSTALL_PATH}
        cp ${INSTALL_PATH}/maxwell/config.properties ${INSTALL_PATH}/${MAXWELL_DIR_NAME}
        rm -rf ${INSTALL_PATH}/maxwell
        mv ${INSTALL_PATH}/${MAXWELL_DIR_NAME} ${INSTALL_PATH}/maxwell
    fi
    rm -rf ${INSTALL_PATH}/tmp

}
if [ "${IS_VAGRANT}" == "true" ];then
    install_dataware5
fi
