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
    mv ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/sbin/ ${INSTALL_PATH}/dataware
    mv ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/sql/ ${INSTALL_PATH}/dataware
    mv ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/flume/*.jar ${INSTALL_PATH}/flume/lib
    # flume conf
    mkdir -p ${INSTALL_PATH}/flume/job
    cp ${FLUME_RES_DIR}/${DATAWARE_VERSION}/*.conf ${INSTALL_PATH}/flume/job

    current_hostname=`cat /etc/hostname`
    if [ "$current_hostname" == "${HOSTNAME_LIST[0]}" ];then
        # 替换maxwell
        tar -zxf ${INSTALL_PATH}/tmp/dataware/${DATAWARE_VERSION}/${MAXWELL_ARCHIVE} -C ${INSTALL_PATH}
        cp ${INSTALL_PATH}/maxwell/config.properties ${INSTALL_PATH}/${MAXWELL_DIR_NAME}
        rm -rf ${INSTALL_PATH}/maxwell
        mv ${INSTALL_PATH}/${MAXWELL_DIR_NAME} ${INSTALL_PATH}/maxwell
        # spark依赖位置和hive执行引擎
        set_property ${INSTALL_PATH}/hive/conf/hive-site.xml "spark.yarn.jars=hdfs://${HOSTNAME_LIST[0]}:8020/spark-jars/*"
        set_property ${INSTALL_PATH}/hive/conf/hive-site.xml "hive.execution.engine=spark"
        # --------replace hive-------
        cat ${INSTALL_PATH}/tmp/dataware/${HIVE_ARCHIVE}.* > ${INSTALL_PATH}/tmp/dataware/${HIVE_ARCHIVE}
        tar -zxf ${INSTALL_PATH}/tmp/dataware/${HIVE_ARCHIVE} -C ${INSTALL_PATH}
        cp ${INSTALL_PATH}/hive/conf/hive-site.xml ${INSTALL_PATH}/${HIVE_DIR_NAME}/conf
        cp ${INSTALL_PATH}/hive/conf/hive-env.sh ${INSTALL_PATH}/${HIVE_DIR_NAME}/conf
        cp ${INSTALL_PATH}/hive/lib/mysql-connector-java-*.jar ${INSTALL_PATH}/${HIVE_DIR_NAME}/lib
        # mv ${INSTALL_PATH}/${HIVE_DIR_NAME}/lib/guava-19.0.jar ${INSTALL_PATH}/${HIVE_DIR_NAME}/lib/guava-19.0.jar_bak
        cp ${INSTALL_PATH}/hadoop/share/hadoop/common/lib/guava-27.0-jre.jar ${INSTALL_PATH}/${HIVE_DIR_NAME}/lib
        rm -rf ${INSTALL_PATH}/hive
        mv ${INSTALL_PATH}/${HIVE_DIR_NAME} ${INSTALL_PATH}/hive
    fi
    rm -rf ${INSTALL_PATH}/tmp

}
if [ "${IS_VAGRANT}" == "true" ];then
    install_dataware5
fi
