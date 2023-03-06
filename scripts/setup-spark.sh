#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_spark() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "modifying over ${app_name} configuration files"
    # spark-env.sh
    cp ${conf_dir}/spark-env.sh.template ${conf_dir}/spark-env.sh
    echo "export SPARK_MASTER_IP=${HOSTNAME_LIST[0]}" >> ${conf_dir}/spark-env.sh
    echo "export SCALA_HOME=${INSTALL_PATH}/scala" >> ${conf_dir}/spark-env.sh
    echo "export JAVA_HOME=${INSTALL_PATH}/java" >> ${conf_dir}/spark-env.sh
    echo "export SPARK_WORKER_MEMORY=1g" >> ${conf_dir}/spark-env.sh
    echo "export HADOOP_HOME=${INSTALL_PATH}/hadoop" >> ${conf_dir}/spark-env.sh
    echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ${conf_dir}/spark-env.sh
    echo 'export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ${conf_dir}/spark-env.sh

    # echo 'export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.retainedApplications=3 -Dspark.history.fs.logDirectory=hdfs://'${HOSTNAME_LIST[0]}':9000/spark-log"' >> ${conf_dir}/spark-env.sh
    echo 'export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.retainedApplications=3 -Dspark.history.fs.logDirectory=hdfs://'${HOSTNAME_LIST[0]}':8020/spark-log"' >> ${conf_dir}/spark-env.sh
    # spark-defaults.conf
    cp ${conf_dir}/spark-defaults.conf.template ${conf_dir}/spark-defaults.conf
    echo "spark.master                     yarn" >> ${conf_dir}/spark-defaults.conf
    echo "spark.eventLog.enabled           true" >> ${conf_dir}/spark-defaults.conf
    #echo "spark.eventLog.dir               hdfs://${HOSTNAME_LIST[0]}:9000/spark-log" >> ${conf_dir}/spark-defaults.conf
    echo "spark.eventLog.dir               hdfs://${HOSTNAME_LIST[0]}:8020/spark-log" >> ${conf_dir}/spark-defaults.conf
    echo "spark.eventLog.compress          true" >> ${conf_dir}/spark-defaults.conf
    echo "spark.serializer                 org.apache.spark.serializer.KryoSerializer" >> ${conf_dir}/spark-defaults.conf
    echo "spark.executor.memory            1g" >> ${conf_dir}/spark-defaults.conf
    echo "spark.driver.memory              1g" >> ${conf_dir}/spark-defaults.conf
    echo 'spark.executor.extraJavaOptions  -XX:+PrintGCDetails -Dkey=value -Dnumbers="one two three"' >> ${conf_dir}/spark-defaults.conf
    # slaves or workers
    if [ ! -f ${conf_dir}/slaves.template ]
    then
        cp ${conf_dir}/workers.template ${conf_dir}/workers
        sed -i "/localhost/Q" ${conf_dir}/workers
        echo -e "${HOSTNAME_LIST[0]}\n${HOSTNAME_LIST[1]}\n${HOSTNAME_LIST[2]}" >> ${conf_dir}/workers
        echo "export JAVA_HOME=${INSTALL_PATH}/java" >> ${conf_dir}/../sbin/spark-config.sh
    else
        cp ${conf_dir}/slaves.template ${conf_dir}/slaves
        sed -i "/localhost/Q" ${conf_dir}/slaves
        echo -e "${HOSTNAME_LIST[0]}\n${HOSTNAME_LIST[1]}\n${HOSTNAME_LIST[2]}" >> ${conf_dir}/slaves
    fi

    wget_mysql_connector ${INSTALL_PATH}/${app_name}/jars

    # yarn-site.xml
    #cp -f ${INSTALL_PATH}/hadoop/etc/hadoop/yarn-site.xml ${conf_dir}

    # hive-site.xml
    #cp -f ${INSTALL_PATH}/hive/conf/hive-site.xml ${conf_dir}
    #cp -rf ${INSTALL_PATH}/spark/jars/*.jar ${INSTALL_PATH}/hive/lib/
}

install_spark() {
    local app_name="spark"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setup_spark ${app_name}
        setupEnv_app ${app_name}
        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_spark
fi
