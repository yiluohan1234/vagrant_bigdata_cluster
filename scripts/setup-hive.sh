#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_hive() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/hive/logs
    mkdir -p ${INSTALL_PATH}/hive/tmpdir
	
    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/hive* ${conf_dir}

    if [ "${IS_KERBEROS}" != "true" ];then
        sed -i '77,113d' ${conf_dir}/hive-site.xml
    fi

    # 安装phoenix后hive启动失败
    #rm ${INSTALL_PATH}/hive/lib/icu4j-4.8.1.jar
    # java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument
    #rm ${INSTALL_PATH}/hive/lib/guava-19.0.jar
    #cp ${INSTALL_PATH}/hadoop/share/hadoop/common/lib/guava-27.0-jre.jar ${INSTALL_PATH}/hive/lib
    # 解决log4j冲突
    mv ${INSTALL_PATH}/hive/lib/log4j-slf4j-impl-2.10.0.jar ${INSTALL_PATH}/hive/lib/log4j-slf4j-impl-2.10.0.jar_bak
    mv ${conf_dir}/hivefunction-1.0-SNAPSHOT.jar ${INSTALL_PATH}/hive/lib/
    
    wget_mysql_connector ${INSTALL_PATH}/hive/lib

    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
    chmod -R 755 $INSTALL_PATH
    chown -R $DEFAULT_USER:$DEFAULT_GROUP $INSTALL_PATH
}

setup_hive_src() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local hive_src_dir=$INSTALL_PATH/hive-src

    log info "creating $app_name directories"
    mkdir -p ${INSTALL_PATH}/hive/logs
    mkdir -p ${INSTALL_PATH}/hive/tmpdir
	
    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/update_files/pom.xml $hive_src_dir
    cp -f ${res_dir}/update_files/DruidScanQueryRecordReader.java $hive_src_dir/druid-handler/src/java/org/apache/hadoop/hive/druid/serde/
    cp -f ${res_dir}/update_files/llap-server/* $hive_src_dir/llap-server/src/java/org/apache/hadoop/hive/llap/daemon/impl/
    cp -f ${res_dir}/update_files/ql/* $hive_src_dir/ql/src/java/org/apache/hadoop/hive/ql/exec/tez/
    cp -f ${res_dir}/update_files/LlapTaskSchedulerService.java $hive_src_dir/llap-tez/src/java/org/apache/hadoop/hive/llap/tezplugins/
    cp -f ${res_dir}/update_files/AsyncPbRpcProxy.java $hive_src_dir/llap-common/src/java/org/apache/hadoop/hive/llap/

    cp -f ${res_dir}/update_files/TestStatsUtils.java $hive_src_dir/ql/src/test/org/apache/hadoop/hive/ql/stats/
    cp -f ${res_dir}/update_files/ShuffleWriteMetrics.java $hive_src_dir/spark-client/src/main/java/org/apache/hive/spark/client/metrics/
    cp -f ${res_dir}/update_files/SparkCounter.java $hive_src_dir/spark-client/src/main/java/org/apache/hive/spark/counter/

    cp -f ${res_dir}/update_files/ColumnsStatsUtils.java $hive_src_dir/standalone-metastore/src/main/java/org/apache/hadoop/hive/metastore/columnstats/
    cp -f ${res_dir}/update_files/aggr/* $hive_src_dir/standalone-metastore/src/main/java/org/apache/hadoop/hive/metastore/columnstats/aggr/
    cp -f ${res_dir}/update_files/cache/* $hive_src_dir/standalone-metastore/src/main/java/org/apache/hadoop/hive/metastore/columnstats/cache/
    cp -f ${res_dir}/update_files/merge/* $hive_src_dir/standalone-metastore/src/main/java/org/apache/hadoop/hive/metastore/columnstats/merge/

    cd $hive_src_dir
    mvn clean package -Pdist -DskipTests -Dmaven.javadoc.skip=true
    cp $hive_src_dir/packaging/target/apache-hive-3.1.2-bin.tar.gz /vagrant/downloads

}

download_hive() {
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
    mv ${INSTALL_PATH}/"apache-${HIVE_VERSION}-bin" ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    rm ${DOWNLOAD_PATH}/${archive}
}

download_hive_src() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local app_version=$(eval echo \$${app_name_upper}_VERSION)
    local archive=$(eval echo \$${app_name_upper}_SRC_ARCHIVE)
    local download_url=$(eval echo \$${app_name_upper}_SRC_MIRROR_DOWNLOAD)

    log info "install ${app_name}"
    if resourceExists ${archive}; then
        installFromLocal ${archive}
    else
        installFromRemote ${archive} ${download_url}
    fi
    mv ${INSTALL_PATH}/"apache-${HIVE_VERSION}-src" ${INSTALL_PATH}/${app_name}-src
    #chown -R vagrant:vagrant ${INSTALL_PATH}/${app_name}-src
    rm ${DOWNLOAD_PATH}/${archive}
}

install_hive() {
    local app_name="hive"
    log info "setup ${app_name}"

    download_hive ${app_name}
    setup_hive ${app_name}
    setupEnv_app ${app_name}
    # if [ "$IS_VAGRANT" != "true" ];then
    #     dispatch_app ${app_name}
    # fi
    source ${PROFILE}
}
if [ "${IS_VAGRANT}" == "true" ];then
    install_hive
fi
