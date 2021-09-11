#!/bin/bash
#set -x
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

setup_spark() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    # basic
    cp -f $SPARK_RES_DIR/slaves $SPARK_CONF_DIR
    cp -f $SPARK_RES_DIR/spark-defaults.conf $SPARK_CONF_DIR
    cp -f $SPARK_RES_DIR/spark-env.sh $SPARK_CONF_DIR
    wget_mysql_connector $INSTALL_PATH/spark/jars
    
    # yarn-site.xml
    #cp -f $HADOOP_RES_DIR/yarn-site.xml $SPARK_CONF_DIR
    
    # hive-site.xml
    #cp -f $HIVE_RES_DIR/hive-site.xml $SPARK_CONF_DIR
    #cp -rf $INSTALL_PATH/spark/jars/*.jar ${INSTALL_PATH}/hive/lib/
}

download_spark() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $SPARK_ARCHIVE; then
        installFromLocal $SPARK_ARCHIVE
    else
        installFromRemote $SPARK_ARCHIVE $SPARK_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${SPARK_VERSION}-bin-hadoop2.7" ${INSTALL_PATH}/$app_name
    sudo chown -R vagrant:vagrant $INSTALL_PATH/$app_name
    rm $DOWNLOAD_PATH/$SPARK_ARCHIVE
}

install_spark() {
    local app_name="spark"
    log info "setup $app_name"

    download_spark $app_name
    setup_spark $app_name
    setupEnv_app $app_name
    #dispatch_app $app_name
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_app $app_name
    fi
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_spark
fi

