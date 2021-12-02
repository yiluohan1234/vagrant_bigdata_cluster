#!/bin/bash

# 是否用vagrant安装集群
IS_VAGRANT="false"

# 配置文件目录
if [ "${IS_VAGRANT}" == "true" ];then
    RESOURCE_PATH=/home/vagrant/resources
else
    RESOURCE_PATH=/home/vagrant/vagrant_bigdata_cluster/resources
fi

# 安装目录
INSTALL_PATH=/home/vagrant/.apps

# 组件下载目录
DOWNLOAD_PATH=/home/vagrant/vagrant_bigdata_cluster/downloads
if [ "${IS_VAGRANT}" == "true" ];then
    DOWNLOAD_PATH=/home/vagrant/downloads
else
    DOWNLOAD_PATH=/home/vagrant/vagrant_bigdata_cluster/downloads
fi

# 初始化集群目录
INIT_PATH=$RESOURCE_PATH/initialization
INIT_SHELL_BIN=$INSTALL_PATH/init_shell/bin

# 环境变量配置文件
PROFILE=~/.bashrc

# 下载组建的镜像地址
# 1:https://archive.apache.org/dist
# 2:https://mirrors.huaweicloud.com/apache
DOWNLOAD_REPO=https://mirrors.huaweicloud.com/apache
# hostname
HOSTNAME=("hdp101" "hdp102" "hdp103")

# ssh
SSH_CONF=/home/vagrant/resources/ssh

# app版本
HADOOP_VERSION=hadoop-3.1.3
HIVE_VERSION=hive-3.1.2
HBASE_VERSION=hbase-2.0.5
SPARK_VERSION=spark-3.0.0
FLINK_VERSION=flink-1.12.4
SQOOP_VERSION=sqoop-1.4.6
ZOOKEEPER_VERSION=zookeeper-3.5.7
KAFKA_VERSION=kafka_2.11-2.4.1
FLUME_VERSION=flume-1.9.0
SCALA_VERSION=scala-2.11.12
MAVEN_VERSION=apache-maven-3.2.5
MYSQL_CONNECTOR_VERSION=mysql-connector-java-5.1.49
MYSQL_VERSION=mysql-5.7.35
PHOENIX_VERSION=apache-phoenix-5.0.0-HBase-1.2-bin
NGINX_VERSION=nginx-1.18.0
ELASTICSEARCH_VERSION=elasticsearch-6.6.0
KIBANA_VERSION=kibana-6.6.0
REDIS_VERSION=redis-5.0.12
CANAL_VERSION=canal.deployer-1.1.5
MAXWELL_VERSION=maxwell-1.25.0

# 获取app的版本号
# eg: get_app_version_num $HIVE_VERSION "-" 2
get_app_version_num() {

    local app_version=$1
    local split=$2
    local field_num=$3

    app_num=`echo $app_version|cut -d $split -f $field_num`
    echo $app_num
}

# java
JAVA_ARCHIVE=jdk-8u201-linux-x64.tar.gz
JAVA_MIRROR_DOWNLOAD=https://repo.huaweicloud.com/java/jdk/8u201-b09/$JAVA_ARCHIVE

# hadoop
# 支持版本：3.3.1, 3.3.0, 3.2.2-3.2.0, 3.1.4-3.1.0, 3.0.3-3.0.0, 2.9.2-2.9.0, 2.8.5-2.8.0, 2.7.7-2.7.0等
#         https://archive.apache.org/dist/hadoop/core/hadoop-2.7.6/hadoop-2.7.6.tar.gz
# https://mirrors.huaweicloud.com/apache/hadoop/core/hadoop-2.7.6/hadoop-2.7.6.tar.gz
# https://archive.apache.org/dist => https://mirrors.huaweicloud.com/apache
HADOOP_VERSION_NUM=`get_app_version_num $HADOOP_VERSION "-" 2`
HADOOP_ARCHIVE=$HADOOP_VERSION.tar.gz
HADOOP_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hadoop/core/$HADOOP_VERSION/$HADOOP_ARCHIVE
HADOOP_RES_DIR=$RESOURCE_PATH/hadoop
HADOOP_PREFIX=$INSTALL_PATH/hadoop
HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop

# hive
# 支持版本：3.1.2-3.1.0, 3.0.0, 2.3.9,-2.3.0, 2.2.0, 2.1.1, 2.1.0, 2.0.1, 2.0.0等
#         https://archive.apache.org/dist/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz
HIVE_VERSION_NUM=`get_app_version_num $HIVE_VERSION "-" 2`
HIVE_ARCHIVE=apache-$HIVE_VERSION-bin.tar.gz
HIVE_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hive/$HIVE_VERSION/$HIVE_ARCHIVE
HIVE_RES_DIR=$RESOURCE_PATH/hive
HIVE_CONF_DIR=$INSTALL_PATH/hive/conf

# hbase
# 支持版本：2.4.5-2.4.0, 2.3.6-2.3.0, 2.2.7-2.2.0, 2.1.10-2.1.0, 2.0.6-2.0.0等
#         https://archive.apache.org/dist/hbase/1.2.6/hbase-1.2.6-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/hbase/1.2.6/hbase-1.2.6-bin.tar.gz
HBASE_VERSION_NUM=`get_app_version_num $HBASE_VERSION "-" 2`
HBASE_ARCHIVE=${HBASE_VERSION}-bin.tar.gz
HBASE_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hbase/$HBASE_VERSION_NUM/$HBASE_ARCHIVE
HBASE_RES_DIR=$RESOURCE_PATH/hbase
HBASE_CONF_DIR=$INSTALL_PATH/hbase/conf

# spark
# 支持版本：具体见下载地址
#         https://archive.apache.org/dist/spark/spark-2.4.6/spark-2.4.6-bin-hadoop2.7.tgz
# https://mirrors.huaweicloud.com/apache/spark/spark-2.4.6/spark-2.4.6-bin-hadoop2.7.tgz
SPARK_VERSION_NUM=`get_app_version_num $SPARK_VERSION "-" 2`
SPARK_ARCHIVE=$SPARK_VERSION-bin-hadoop2.7.tgz
SPARK_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/spark/$SPARK_VERSION/$SPARK_ARCHIVE
SPARK_RES_DIR=$RESOURCE_PATH/spark
SPARK_CONF_DIR=$INSTALL_PATH/spark/conf

# flink
# 支持版本：具体见下载地址
#         https://archive.apache.org/dist/flink/flink-1.12.4/flink-1.12.4-bin-scala_2.11.tgz
# https://mirrors.huaweicloud.com/apache/flink/flink-1.12.4/flink-1.12.4-bin-scala_2.11.tgz
FLINK_VERSION_NUM=`get_app_version_num $FLINK_VERSION "-" 2`
FLINK_ARCHIVE=$FLINK_VERSION-bin-scala_2.11.tgz
FLINK_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/flink/$FLINK_VERSION/$FLINK_VERSION-bin-scala_2.11.tgz
FLINK_RES_DIR=$RESOURCE_PATH/flink
FLINK_CONF_DIR=$INSTALL_PATH/flink/conf

# sqoop
# 支持版本：1.99.7-1.99.1, 1.4.7-1.4.2（版本和下载地址要对应）
#         https://archive.apache.org/dist/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
# https://mirrors.huaweicloud.com/apache/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
SQOOP_VERSION_NUM=`get_app_version_num $SQOOP_VERSION "-" 2`
SQOOP_ARCHIVE=${SQOOP_VERSION}.bin__hadoop-2.6.0.tar.gz
SQOOP_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/sqoop/$SQOOP_VERSION_NUM/$SQOOP_ARCHIVE
SQOOP_RES_DIR=$RESOURCE_PATH/sqoop
SQOOP_CONF_DIR=$INSTALL_PATH/sqoop/conf

# zookeeper
# 支持版本：3.7.0, 3.6.3-3.6.0, 3.5.9-3.5.5, 3.4.14-3.4.0, 3.3.6-3.3.3
#         https://archive.apache.org/dist/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz
# https://mirrors.huaweicloud.com/apache/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz
# https://mirrors.huaweicloud.com/apache/zookeeper/zookeeper-3.5.7/apache-zookeeper-3.5.7.tar.gz
ZOOKEEPER_VERSION_NUM=`get_app_version_num $ZOOKEEPER_VERSION "-" 2`
ZOOKEEPER_ARCHIVE=apache-${ZOOKEEPER_VERSION}-bin.tar.gz
ZOOKEEPER_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/zookeeper/$ZOOKEEPER_VERSION/$ZOOKEEPER_ARCHIVE
ZOOKEEPER_RES_DIR=$RESOURCE_PATH/zookeeper
ZOOKEEPER_CONF_DIR=$INSTALL_PATH/zookeeper/conf

# kafka
# 支持版本：具体查看下载地址
#         https://archive.apache.org/dist/kafka/0.11.0.3/kafka_2.11-0.11.0.3.tgz
# https://mirrors.huaweicloud.com/apache/kafka/0.11.0.3/kafka_2.11-0.11.0.3.tgz
KAFKA_VERSION_NUM=`get_app_version_num $KAFKA_VERSION "-" 2`
KAFKA_ARCHIVE=${KAFKA_VERSION}.tgz
KAFKA_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/kafka/$KAFKA_VERSION_NUM/$KAFKA_ARCHIVE
KAFKA_RES_DIR=$RESOURCE_PATH/kafka
KAFKA_CONF_DIR=$INSTALL_PATH/kafka/config

# flume
# 支持版本：1.9.0, 1.8.0, 1.7.0, 1.6.0, 1.5.2-1.5.0等
#        https://archive.apache.org/dist/flume/1.6.0/apache-flume-1.6.0-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/flume/1.6.0/apache-flume-1.6.0-bin.tar.gz
FLUME_VERSION_NUM=`get_app_version_num $FLUME_VERSION "-" 2`
FLUME_ARCHIVE=apache-${FLUME_VERSION}-bin.tar.gz
FLUME_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/flume/$FLUME_VERSION_NUM/$FLUME_ARCHIVE
FLUME_RES_DIR=$RESOURCE_PATH/flume
FLUME_CONF_DIR=$INSTALL_PATH/flume/conf

# maven
# 支持版本：具体见下载地址
# 注意：Maven 3.3.x 可以构建 Flink，但是不能正确地屏蔽掉指定的依赖。Maven 3.2.5 可以正确地构建库文件
#        https://archive.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz
MAVEN_VERSION_NUM=`get_app_version_num $MAVEN_VERSION "-" 3`
MAVEN_ARCHIVE=${MAVEN_VERSION}-bin.tar.gz
MAVEN_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/maven/maven-${MAVEN_VERSION_NUM%%.*}/$MAVEN_VERSION_NUM/binaries/$MAVEN_ARCHIVE
MAVEN_RES_DIR=$RESOURCE_PATH/maven
MAVEN_CONF_DIR=$INSTALL_PATH/maven/conf

# phoenix
# 支持版本：具体查看下载地址
#        https://archive.apache.org/dist/phoenix/apache-phoenix-4.14.0-HBase-1.2/bin/apache-phoenix-4.14.0-HBase-1.2-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/phoenix/apache-phoenix-4.14.0-HBase-1.2/bin/apache-phoenix-4.14.0-HBase-1.2-bin.tar.gz
PHOENIX_VERSION_NUM=`get_app_version_num $PHOENIX_VERSION "-" 3`
PHOENIX_ARCHIVE=${PHOENIX_VERSION}.tar.gz
PHOENIX_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/phoenix/apache-phoenix-${PHOENIX_VERSION_NUM}-HBase-${HBASE_VERSION_NUM:0:3}/bin/$PHOENIX_ARCHIVE
PHOENIX_RES_DIR=$RESOURCE_PATH/phoenix
PHOENIX_CONF_DIR=$INSTALL_PATH/phoenix/conf

# scala
# 支持版本：2.10.X, 2.11.X, 2.12.X, 2.13.X
SCALA_VERSION_NUM=`get_app_version_num $SCALA_VERSION "-" 2`
SCALA_ARCHIVE=${SCALA_VERSION}.tgz
# SCALA_MIRROR_DOWNLOAD=https://downloads.lightbend.com/scala/2.11.12/scala-2.11.12.tgz 
# https://distfiles.macports.org/scala2.11/scala-2.11.12.tgz
SCALA_MIRROR_DOWNLOAD=https://distfiles.macports.org/scala${SCALA_VERSION_NUM%.*}/$SCALA_ARCHIVE

# mysql_connector
# 支持版本：具体见下载地址
#                 http://mirrors.sohu.com/mysql/Connector-J/mysql-connector-java-5.1.49.tar.gz
# https://repo.huaweicloud.com/mysql/Downloads/Connector-J/mysql-connector-java-5.1.49.tar.gz
MYSQL_CONNECTOR_VERSION_NUM=`get_app_version_num $MYSQL_CONNECTOR_VERSION "-" 4`
MYSQL_CONNECTOR_ARCHIVE=${MYSQL_CONNECTOR_VERSION}.tar.gz
MYSQL_CONNECTOR_MIRROR_DOWNLOAD=https://repo.huaweicloud.com/mysql/Downloads/Connector-J/$MYSQL_CONNECTOR_ARCHIVE

# https://mirrors.huaweicloud.com/mysql/Downloads/MySQL-5.7/mysql-5.7.35-linux-glibc2.12-x86_64.tar.gz
MYSQL_VERSION_NUM=`get_app_version_num $ES_VERSION "-" 2`
MYSQL_ARCHIVE=$MYSQL_VERSION-linux-glibc2.12-x86_64.tar.gz
MYSQL_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/mysql/Downloads/MySQL-5.7/$MYSQL_ARCHIVE
MYSQL_RES_DIR=$RESOURCE_PATH/mysql
MYSQL_CONF_DIR=$INSTALL_PATH/mysql
# nginx
# 支持版本：具体见下载地址
# https://nginx.org/download/nginx-1.18.0.tar.gz
# https://repo.huaweicloud.com/nginx/nginx-1.18.0.tar.gz
NGINX_VERSION_NUM=`get_app_version_num $NGINX_VERSION "-" 2`
NGINX_ARCHIVE=${NGINX_VERSION}.tar.gz
NGINX_MIRROR_DOWNLOAD=https://repo.huaweicloud.com/nginx/$NGINX_ARCHIVE
NGINX_RES_DIR=$RESOURCE_PATH/nginx
NGINX_CONF_DIR=$INSTALL_PATH/nginx/conf

# es
# 支持版本：具体见下载地址
# https://mirrors.huaweicloud.com/elasticsearch/7.12.1/elasticsearch-7.12.1-linux-x86_64.tar.gz
# https://mirrors.huaweicloud.com/elasticsearch/6.6.0/elasticsearch-6.6.0.tar.gz
ELASTICSEARCH_VERSION_NUM=`get_app_version_num $ELASTICSEARCH_VERSION "-" 2`
ELASTICSEARCH_ARCHIVE=$ELASTICSEARCH_VERSION.tar.gz
ELASTICSEARCH_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/elasticsearch/$ELASTICSEARCH_VERSION_NUM/$ELASTICSEARCH_ARCHIVE
ELASTICSEARCH_RES_DIR=$RESOURCE_PATH/elasticsearch
ELASTICSEARCH_CONF_DIR=$INSTALL_PATH/elasticsearch/config

# kibana
# 支持版本：具体见下载地址
# https://mirrors.huaweicloud.com/kibana/6.6.0/kibana-6.6.0-linux-x86_64.tar.gz
KIBANA_VERSION_NUM=`get_app_version_num $KIBANA_VERSION "-" 2`
KIBANA_ARCHIVE=$KIBANA_VERSION-linux-x86_64.tar.gz
KIBANA_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/kibana/$KIBANA_VERSION_NUM/$KIBANA_ARCHIVE
KIBANA_RES_DIR=$RESOURCE_PATH/kibana
KIBANA_CONF_DIR=$INSTALL_PATH/kibana/config

# redis
# 支持版本：具体见下载地址
# https://mirrors.huaweicloud.com/redis/redis-6.2.1.tar.gz
# https://repo.huaweicloud.com/redis/redis-6.2.1.tar.gz
REDIS_VERSION_NUM=`get_app_version_num $REDIS_VERSION "-" 2`
REDIS_ARCHIVE=$REDIS_VERSION.tar.gz
REDIS_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/redis/$REDIS_ARCHIVE
REDIS_RES_DIR=$RESOURCE_PATH/redis
REDIS_CONF_DIR=$INSTALL_PATH/redis/conf

# canal
# 支持版本：具体见下载地址
# https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.deployer-1.1.5.tar.gz
CANAL_VERSION_NUM=`get_app_version_num $CANAL_VERSION "-" 2`
CANAL_ARCHIVE=${CANAL_VERSION}.tar.gz
CANAL_MIRROR_DOWNLOAD=https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.deployer-1.1.5.tar.gz
CANAL_RES_DIR=$RESOURCE_PATH/canal
CANAL_CONF_DIR=$INSTALL_PATH/canal/conf

# maxwell
# 支持版本：具体见下载地址
# https://github.com/zendesk/maxwell/releases/download/v1.25.0/maxwell-1.25.0.tar.gz
MAXWELL_VERSION_NUM=`get_app_version_num $MAXWELL_VERSION "-" 2`
MAXWELL_ARCHIVE=${MAXWELL_VERSION}.tar.gz
MAXWELL_MIRROR_DOWNLOAD=https://github.com/zendesk/maxwell/releases/download/v1.25.0/maxwell-1.25.0.tar.gz
MAXWELL_RES_DIR=$RESOURCE_PATH/maxwell
MAXWELL_CONF_DIR=$INSTALL_PATH/maxwell

# log
DATETIME=`date "+%F %T"`
 
success() {
    printf "\r$DATETIME [ \033[00;32mINFO\033[0m ]%s\n" "$1"
}
 
warn() {
    printf "\r$DATETIME [\033[0;33mWARNING\033[0m]%s\n" "$1"
}
 
fail() {
    printf "\r$DATETIME [ \033[0;31mERROR\033[0m ]%s\n" "$1"
}
 
usage() {
    echo "Usage: ${0##*/} {info|warn|err} MSG"
}
 
# log
# eg: log info/warn/err "This is a test.."
log() {
    if [ $# -lt 2 ]; then
        log err "Not enough arguments [$#] to log."
    fi
 
    __LOG_PRIO="$1"
    shift
    __LOG_MSG="$*"
 
    case "${__LOG_PRIO}" in
        crit) __LOG_PRIO="CRIT";;
        err) __LOG_PRIO="ERROR";;
        warn) __LOG_PRIO="WARNING";;
        info) __LOG_PRIO="INFO";;
        debug) __LOG_PRIO="DEBUG";;
    esac
 
    if [ "${__LOG_PRIO}" = "INFO" ]; then
        success " $__LOG_MSG"
    elif [ "${__LOG_PRIO}" = "WARNING" ]; then
        warn " $__LOG_MSG"
    elif [ "${__LOG_PRIO}" = "ERROR" ]; then
        fail " $__LOG_MSG"
    else
       usage
    fi
}

# 判断DOWN_PATH下文件是否存在
# eg: resourceExists hadoop2.7.2.tar.gz
resourceExists() 
{
    FILE=${DOWNLOAD_PATH}/$1
    if [ -e $FILE ]
    then
        return 0
    else
        return 1
    fi
}

# 判断某一目录文件是否存在
# eg: fileExists /home/vagrant/text.txt
fileExists()
{
    FILE=$1
    if [ -e $FILE ]
    then
        return 0
    else
        return 1
    fi
}

# 判断软件是否安装
# eg: command_exists expect
command_exists() {
    command -v "$@" > /dev/null 2>&1
}

# 将字符串变为大写
# eg: get_string_upper es
get_string_upper() {
    local app_name=$1
    app_name_upper=$(echo $app_name | tr '[a-z]' '[A-Z]')
    echo $app_name_upper
}

# 从本地DOWLOAD_PATH解压组件到INSTALL_PATH
# eg: installFromLocal $HADOOP_ARCHIVE
installFromLocal() {
    LOCAL_ARCHIVE=$1
    log info "install $LOCAL_ARCHIVE from local file"
    FILE=$DOWNLOAD_PATH/$LOCAL_ARCHIVE
    tar -xzf $FILE -C $INSTALL_PATH
}

# 从网上下载组件到DOWNLOAD_PATH，并解压到INSTALL_PATH
# eg: installFromRemote $HADOOP_ARCHIVE $HADOOP_MIRROR_DOWNLOAD
installFromRemote() {
    LOCAL_ARCHIVE=$1
    REMOTE_MIRROR_DOWNLOAD=$2
    FILE=$DOWNLOAD_PATH/$LOCAL_ARCHIVE
 
    log info "install $LOCAL_ARCHIVE from remote file"
    curl -o $FILE -O -L $REMOTE_MIRROR_DOWNLOAD
    tar -xzf $FILE -C $INSTALL_PATH
    #chown -R vagrant:vagrant $INSTALL_PATH
}

# 分发app目录
# eg:dispatch_app kafka
dispatch_app(){
    local app_name=$1
    log info "dispatch $app_name"
    for i in "${HOSTNAME[@]}"
    do
        cur_hostname=`cat /etc/hostname`
        if [ $cur_hostname != $i ];then
            log info "--------dispatch to $i--------"
            scp -r -q ${INSTALL_PATH}/$app_name vagrant@$i:${INSTALL_PATH}/
            scp -q $PROFILE vagrant@$i:$PROFILE
        fi
    done
}
# 设置app_name的环境变量
# eg:setupEnv_app kafka
setupEnv_app() {
    local app_name=$1
    local type_name=$2
    echo "creating $app_name environment variables"
    local app_path=${INSTALL_PATH}/$app_name
    local app_name_uppercase=$(echo $app_name | tr '[a-z]' '[A-Z]')
    #LOWERCASE=$(echo $app_name | tr '[A-Z]' '[a-z]') 
    echo "# $app_name environment" >> $PROFILE
    echo "export ${app_name_uppercase}_HOME=$app_path" >> $PROFILE
    if [ ! -n "$type_name" ];then
        echo 'export PATH=${'$app_name_uppercase'_HOME}/bin:$PATH' >> $PROFILE
    else
        echo 'export PATH=${'$app_name_uppercase'_HOME}/bin:${'$app_name_uppercase'_HOME}/sbin:$PATH' >> $PROFILE
    fi
    echo -e "\n" >> $PROFILE
}

# 下载mysql connector的jar到某一目录
# eg: wget_mysql_connector /home/vagrant/apps/hive/lib
wget_mysql_connector(){
    local CP_PATH=$1
    if resourceExists $MYSQL_CONNECTOR_ARCHIVE; then
        installFromLocal $MYSQL_CONNECTOR_ARCHIVE
    else
        installFromRemote $MYSQL_CONNECTOR_ARCHIVE $MYSQL_CONNECTOR_MIRROR_DOWNLOAD
    fi
    cp $INSTALL_PATH/$MYSQL_CONNECTOR_VERSION/${MYSQL_CONNECTOR_VERSION}.jar $CP_PATH
    rm -rf $INSTALL_PATH/mysql-connector-java-5.1.49
}

# 显示apps的版本号
# eg: display_apps_num
display_apps_num() {
    echo "Hadoop: $HADOOP_VERSION_NUM"
    echo "Hive: $HIVE_VERSION_NUM"
    echo "Hbase: $HBASE_VERSION_NUM"
    echo "Spark: $SPARK_VERSION_NUM"
    echo "Flink: $FLINK_VERSION_NUM"
    echo "Zookeeper: $ZOOKEEPER_VERSION_NUM"
    echo "Kafka: $KAFKA_VERSION_NUM"
    echo "Flume: $FLUME_VERSION_NUM"
    echo "Scala: $SCALA_VERSION_NUM"
    echo "Maven: $MAVEN_VERSION_NUM"
    echo "Sqoop: $SQOOP_VERSION_NUM"
    echo "MySQl Connector: $MYSQL_CONNECTOR_VERSION_NUM"
    echo "MySQL: $MYSQL_VERSION_NUM"
    echo "Phoenix: $PHOENIX_VERSION_NUM"
}
