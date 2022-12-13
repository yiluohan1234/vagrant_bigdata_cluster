#!/bin/bash

# 是否用vagrant安装集群
IS_VAGRANT="false"

# default user
DEFAULT_USER=root
DEFAULT_GROUP=root

# 配置文件目录
RESOURCE_PATH=/vagrant/resources

# 安装目录
INSTALL_PATH=/usr

# 组件下载目录
DOWNLOAD_PATH=/usr/package277

# 初始化集群目录
INIT_PATH=$RESOURCE_PATH/initialization
INIT_SHELL_BIN=$INSTALL_PATH/init_bin

# 环境变量配置文件
PROFILE=/etc/profile

# 下载组建的镜像地址
# 1:https://archive.apache.org/dist
# 2:https://mirrors.huaweicloud.com/apache
DOWNLOAD_REPO=https://mirrors.huaweicloud.com/apache
# DOWNLOAD_REPO_APACHE=https://archive.apache.org/dist

# hostname
IP_LIST=("172.18.39.77" "172.18.39.78" "172.18.39.79")
HOSTNAME_LIST=("master" "slave1" "slave2")
PASSWD_LIST=("CuSlShBA!sN" "VQZ2e8SA!wG" "grmDssKA@xM")

# mysql
MYSQL_HOST=hdp103
MYSQL_USER=root
MYSQL_PASSWORD=199037

# app版本
HADOOP_VERSION=hadoop-2.7.7
HIVE_VERSION=hive-2.3.4
HBASE_VERSION=hbase-1.6.0
SPARK_VERSION=spark-2.4.3
SQOOP_VERSION=sqoop-1.4.7
ZOOKEEPER_VERSION=zookeeper-3.6.3
KAFKA_VERSION=kafka_2.10-0.10.2.2
SCALA_VERSION=scala-2.11.11

# 获取app的版本号
# eg: get_app_version_num $HIVE_VERSION "-" 2
get_app_version_num() {
    local app_version=$1
    local split=$2
    local field_num=$3
    if [ "x${field_num}" == "x" ];
    then
        field_num=2
    fi

    app_num=`echo $app_version|cut -d $split -f $field_num`
    #app_num=`echo $app_version|awk -F $split '{print $2}'`
    echo $app_num
}

# java
JAVA_ARCHIVE=jdk-8u221-linux-x64.tar.gz
JAVA_MIRROR_DOWNLOAD=https://repo.huaweicloud.com/java/jdk/8u201-b09/$JAVA_ARCHIVE

# hadoop
HADOOP_VERSION_NUM=`get_app_version_num $HADOOP_VERSION "-" 2`
HADOOP_VERSION_NUM_TWO=`echo ${HADOOP_VERSION:7:3}`
HADOOP_ARCHIVE=$HADOOP_VERSION.tar.gz
HADOOP_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hadoop/core/$HADOOP_VERSION/$HADOOP_ARCHIVE
HADOOP_RES_DIR=$RESOURCE_PATH/hadoop
HADOOP_PREFIX=$INSTALL_PATH/hadoop/$HADOOP_VERSION
HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop

# hive
HIVE_VERSION_NUM=`get_app_version_num $HIVE_VERSION "-" 2`
HIVE_ARCHIVE=apache-$HIVE_VERSION-bin.tar.gz
HIVE_SRC_ARCHIVE=apache-$HIVE_VERSION-src.tar.gz
HIVE_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hive/$HIVE_VERSION/$HIVE_ARCHIVE
HIVE_SRC_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hive/$HIVE_VERSION/$HIVE_SRC_ARCHIVE
HIVE_RES_DIR=$RESOURCE_PATH/hive
HIVE_CONF_DIR=$INSTALL_PATH/hive/conf

# hbase
HBASE_VERSION_NUM=`get_app_version_num $HBASE_VERSION "-" 2`
HBASE_ARCHIVE=${HBASE_VERSION}-bin.tar.gz
HBASE_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hbase/$HBASE_VERSION_NUM/$HBASE_ARCHIVE
HBASE_RES_DIR=$RESOURCE_PATH/hbase
HBASE_CONF_DIR=$INSTALL_PATH/hbase/$HBASE_VERSION/conf

# spark
SPARK_VERSION_NUM=`get_app_version_num $SPARK_VERSION "-" 2`
SPARK_ARCHIVE=$SPARK_VERSION-bin-hadoop${HADOOP_VERSION_NUM_TWO}.tgz
SPARK_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/spark/$SPARK_VERSION/$SPARK_ARCHIVE
SPARK_RES_DIR=$RESOURCE_PATH/spark
SPARK_CONF_DIR=$INSTALL_PATH/spark/$SPARK_VERSION-bin-hadoop${HADOOP_VERSION_NUM_TWO}/conf

# scala
SCALA_VERSION_NUM=`get_app_version_num $SCALA_VERSION "-" 2`
SCALA_ARCHIVE=${SCALA_VERSION}.tgz
SCALA_MIRROR_DOWNLOAD=https://distfiles.macports.org/scala${SCALA_VERSION_NUM%.*}/$SCALA_ARCHIVE

# sqoop
SQOOP_VERSION_NUM=`get_app_version_num $SQOOP_VERSION "-" 2`
SQOOP_ARCHIVE=${SQOOP_VERSION}.bin__hadoop-2.6.0.tar.gz
SQOOP_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/sqoop/$SQOOP_VERSION_NUM/$SQOOP_ARCHIVE
SQOOP_RES_DIR=$RESOURCE_PATH/sqoop
SQOOP_CONF_DIR=$INSTALL_PATH/sqoop/${SQOOP_VERSION}.bin__hadoop-2.6.0/conf

# zookeeper
ZOOKEEPER_VERSION_NUM=`get_app_version_num $ZOOKEEPER_VERSION "-" 2`
ZOOKEEPER_ARCHIVE=apache-${ZOOKEEPER_VERSION}-bin.tar.gz
ZOOKEEPER_DIR_NAME=apache-${ZOOKEEPER_VERSION}-bin
ZOOKEEPER_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/zookeeper/$ZOOKEEPER_VERSION/$ZOOKEEPER_ARCHIVE
ZOOKEEPER_RES_DIR=$RESOURCE_PATH/zookeeper
ZOOKEEPER_CONF_DIR=$INSTALL_PATH/zookeeper/${ZOOKEEPER_DIR_NAME}/conf

# kafka
KAFKA_VERSION_NUM=`get_app_version_num $KAFKA_VERSION "-" 2`
KAFKA_ARCHIVE=${KAFKA_VERSION}.tgz
KAFKA_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/kafka/$KAFKA_VERSION_NUM/$KAFKA_ARCHIVE
KAFKA_RES_DIR=$RESOURCE_PATH/kafka
KAFKA_CONF_DIR=$INSTALL_PATH/kafka/${KAFKA_VERSION}/config
KAFKA_LOG_DIR=$INSTALL_PATH/kafka/${KAFKA_VERSION}/logs

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

## @description log
## @param info/warn/err
## @param info
## @eg log info/warn/err "This is a test.."
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

## @description 判断DOWN_PATH下文件是否存在
## @param 压缩文件名字
## @eg  resourceExists hadoop2.7.2.tar.gz
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

## @description 判断软件是否安装
## @eg command_exists expect
command_exists() {
    command -v "$@" > /dev/null 2>&1
}

## @description 将字符串变为大写
## @param app_name
## @eg get_string_upper es
get_string_upper() {
    local app_name=$1
    app_name_upper=$(echo $app_name | tr '[a-z]' '[A-Z]')
    echo $app_name_upper
}

## @description 从本地DOWLOAD_PATH解压组件到INSTALL_PATH
## @param local_archieve文件名称
## @eg installFromLocal $HADOOP_ARCHIVE
installFromLocal() {
    LOCAL_ARCHIVE=$1
    log info "install $LOCAL_ARCHIVE from local file"
    FILE=${DOWNLOAD_PATH}/${LOCAL_ARCHIVE}
    tar -xzf ${FILE} -C ${INSTALL_PATH}
}

## @description 从网上下载组件到DOWNLOAD_PATH，并解压到INSTALL_PATH
## @param local_archieve文件名称
## @eg installFromRemote $HADOOP_ARCHIVE $HADOOP_MIRROR_DOWNLOAD
installFromRemote() {
    LOCAL_ARCHIVE=$1
    REMOTE_MIRROR_DOWNLOAD=$2
    FILE=${DOWNLOAD_PATH}/${LOCAL_ARCHIVE}
    [ ! -d ${DOWNLOAD_PATH} ] && mkdir -p ${DOWNLOAD_PATH}

    log info "install $LOCAL_ARCHIVE from remote file"
    curl -o ${FILE} -O -L ${REMOTE_MIRROR_DOWNLOAD}
    tar -xzf ${FILE} -C ${INSTALL_PATH}
}

## @description 分发app目录
## @param app_name
## @eg dispatch_app kafka
dispatch_app(){
    local app_name=$1
    log info "dispatch $app_name"
    for hostname in "${HOSTNAME_LIST[@]}"
    do
        cur_hostname=`cat /etc/hostname`
        if [ $cur_hostname != $hostname ];then
            log info "--------dispatch to $hostname--------"
            scp -r -q ${INSTALL_PATH}/$app_name $DEFAULT_USER@$hostname:${INSTALL_PATH}/
            scp -q $PROFILE $DEFAULT_USER@$hostname:$PROFILE
            ssh $DEFAULT_USER@$hostname "source $PROFILE"
        fi
    done
}

## @description 设置app_name的环境变量
## @param app_name
## @param type
## @eg setupEnv_app kafka
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

## @description 下载mysql connector的jar到某一目录
## @param directory
## @eg wget_mysql_connector /home/vagrant/apps/hive/lib
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

## @description 显示apps的版本号
## @param None
## @eg display_apps_num
display_apps_num() {
    echo "Hadoop: $HADOOP_VERSION_NUM"
    echo "Hive: $HIVE_VERSION_NUM"
    echo "Hbase: $HBASE_VERSION_NUM"
    echo "Spark: $SPARK_VERSION_NUM"
    echo "Zookeeper: $ZOOKEEPER_VERSION_NUM"
    echo "Kafka: $KAFKA_VERSION_NUM"
    echo "Scala: $SCALA_VERSION_NUM"
    echo "Sqoop: $SQOOP_VERSION_NUM"
    echo "MySQL: $MYSQL_VERSION_NUM"
}
