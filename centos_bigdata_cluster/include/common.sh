#!/bin/bash
CUR=$(cd `dirname 0`;pwd)
RESOURCE_PATH=$CUR/downloads
[ ! -d $RESOURCE_PATH ] && mkdir -p $RESOURCE_PATH
INSTALL_PATH=/home/vagrant/apps
[ ! -d $INSTALL_PATH ] && mkdir -p $INSTALL_PATH
PROFILE=~/.bashrc
HOSTNAME=("hdp-node-01" "hdp-node-02" "hdp-node-03")

# java
JAVA_ARCHIVE=jdk-8u201-linux-x64.tar.gz
JAVA_MIRROR_DOWNLOAD=https://repo.huaweicloud.com/java/jdk/8u201-b09/jdk-8u201-linux-x64.tar.gz

# hadoop
HADOOP_VERSION=hadoop-2.7.2
HADOOP_ARCHIVE=$HADOOP_VERSION.tar.gz
HADOOP_MIRROR_DOWNLOAD=http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_ARCHIVE
HADOOP_RES_DIR=$CUR/conf/hadoop
HADOOP_PREFIX=$INSTALL_PATH/hadoop
HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop

# hive
HIVE_VERSION=hive-2.3.4
HIVE_ARCHIVE=apache-$HIVE_VERSION-bin.tar.gz
HIVE_MIRROR_DOWNLOAD=http://archive.apache.org/dist/hive/$HIVE_VERSION/$HIVE_ARCHIVE
HIVE_RES_DIR=$CUR/conf/hive
HIVE_CONF_DIR=$INSTALL_PATH/hive/conf

# sqoop
SQOOP_VERSION=sqoop-1.4.6
SQOOP_ARCHIVE=${SQOOP_VERSION}.bin__hadoop-2.0.4-alpha.tar.gz
SQOOP_MIRROR_DOWNLOAD=http://archive.apache.org/dist/sqoop/1.4.6/sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz
SQOOP_RES_DIR=$CUR/conf/sqoop
SQOOP_CONF_DIR=$INSTALL_PATH/sqoop/conf

# zookeeper
ZOOKEEPER_VERSION=zookeeper-3.4.10
ZOOKEEPER_ARCHIVE=${ZOOKEEPER_VERSION}.tar.gz
ZOOKEEPER_MIRROR_DOWNLOAD=http://archive.apache.org/dist/zookeeper/$ZOOKEEPER_VERSION/$ZOOKEEPER_ARCHIVE
ZOOKEEPER_RES_DIR=$CUR/conf/zookeeper
ZOOKEEPER_CONF_DIR=$INSTALL_PATH/zookeeper/conf

# kafka
KAFKA_VERSION=kafka_2.11-0.11.0.3
KAFKA_ARCHIVE=${KAFKA_VERSION}.tgz
KAFKA_MIRROR_DOWNLOAD=https://archive.apache.org/dist/kafka/0.11.0.3/kafka_2.11-0.11.0.3.tgz
KAFKA_RES_DIR=$CUR/conf/kafka
KAFKA_CONF_DIR=$INSTALL_PATH/kafka/config

# hbase
HBASE_VERSION=hbase-1.2.5
HBASE_ARCHIVE=${HBASE_VERSION}-bin.tar.gz
HBASE_MIRROR_DOWNLOAD=http://archive.apache.org/dist/hbase/1.2.5/hbase-1.2.5-bin.tar.gz 
HBASE_RES_DIR=$CUR/conf/hbase
HBASE_CONF_DIR=$INSTALL_PATH/hbase/conf

# phoenix
PHOENIX_VERSION=apache-phoenix-4.8.1-HBase-1.2-bin
PHOENIX_ARCHIVE=${PHOENIX_VERSION}.tar.gz
PHOENIX_MIRROR_DOWNLOAD=https://archive.apache.org/dist/phoenix/apache-phoenix-4.8.1-HBase-1.2/bin/apache-phoenix-4.8.1-HBase-1.2-bin.tar.gz
PHOENIX_RES_DIR=$CUR/conf/phoenix
PHOENIX_CONF_DIR=$INSTALL_PATH/phoenix/conf

# flume
FLUME_VERSION=apache-flume-1.6.0-bin
FLUME_ARCHIVE=${FLUME_VERSION}.tar.gz
FLUME_MIRROR_DOWNLOAD=https://archive.apache.org/dist/flume/1.6.0/apache-flume-1.6.0-bin.tar.gz
FLUME_RES_DIR=$CUR/conf/flume
FLUME_CONF_DIR=$INSTALL_PATH/phoenix/conf



# scala
SCALA_VERSION=scala-2.12.8
SCALA_ARCHIVE=${SCALA_VERSION}.tgz
#SCALA_MIRROR_DOWNLOAD=https://downloads.lightbend.com/scala/2.11.8/scala-2.11.8.tgz 
SCALA_MIRROR_DOWNLOAD=https://distfiles.macports.org/scala2.12/scala-2.12.8.tgz 

# maven
# 注意：Maven 3.3.x 可以构建 Flink，但是不能正确地屏蔽掉指定的依赖。Maven 3.2.5 可以正确地构建库文件
MAVEN_VERSION=apache-maven-3.2.5
MAVEN_ARCHIVE=${MAVEN_VERSION}-bin.tar.gz
MAVEN_MIRROR_DOWNLOAD=https://archive.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz
MAVEN_RES_DIR=$CUR/conf/maven
MAVEN_CONF_DIR=$INSTALL_PATH/maven/conf

# spark
SPARK_VERSION=spark-2.4.6
SPARK_ARCHIVE=$SPARK_VERSION-bin-hadoop2.tgz
SPARK_MIRROR_DOWNLOAD=http://archive.apache.org/dist/spark/$SPARK_VERSION/$SPARK_VERSION-bin-hadoop2.7.tgz
SPARK_RES_DIR=$CUR/conf/spark
SPARK_CONF_DIR=$INSTALL_PATH/spark/conf

# flink
FLINK_VERSION=flink-1.12.4
FLINK_ARCHIVE=$FLINK_VERSION-bin-scala_2.12.tgz
FLINK_MIRROR_DOWNLOAD=https://archive.apache.org/dist/flink/flink-1.12.4/flink-1.12.4-bin-scala_2.12.tgz
FLINK_RES_DIR=$CUR/conf/flink
FLINK_CONF_DIR=$INSTALL_PATH/flink/conf


# mysql_connector
MYSQL_CONNECTOR_VERSION=mysql-connector-java-5.1.49
MYSQL_CONNECTOR_ARCHIVE=${MYSQL_CONNECTOR_VERSION}.tar.gz
MYSQL_CONNECTOR_MIRROR_DOWNLOAD=http://mirrors.sohu.com/mysql/Connector-J/$MYSQL_CONNECTOR_ARCHIVE

# mysql
MYSQL_VERSION=mysql-5.7.30
MYSQL_ARCHIVE=${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.gz
MYSQL_MIRROR_DOWNLOAD=https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz
MYSQL_RES_DIR=$CUR/conf/mysql
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
# 判断resource文件是否存在
# eg: resourceExists hadoop2.7.2.tar.gz
resourceExists() 
{
    FILE=${RESOURCE_PATH}/$1
    if [ -e $FILE ]
    then
        return 0
    else
        return 1
    fi
}
# 判断文件是否存在
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

# 从本地安装
# eg: installFromLocal $HADOOP_ARCHIVE
installFromLocal() {
    LOCAL_ARCHIVE=$1
    log info "install $LOCAL_ARCHIVE from local file"
    FILE=$RESOURCE_PATH/$LOCAL_ARCHIVE
    tar -xzf $FILE -C $INSTALL_PATH
	sudo chown -R vagrant:vagrant $INSTALL_PATH
}

# 从网上下载安装
# eg: installFromRemote $HADOOP_ARCHIVE $HADOOP_MIRROR_DOWNLOAD
installFromRemote() {
    LOCAL_ARCHIVE=$1
    REMOTE_MIRROR_DOWNLOAD=$2
    FILE=$RESOURCE_PATH/$LOCAL_ARCHIVE
 
    log info "install $LOCAL_ARCHIVE from remote file"
    curl -o $FILE -O -L $REMOTE_MIRROR_DOWNLOAD
    tar -xzf $FILE -C $INSTALL_PATH
    sudo chown -R vagrant:vagrant $INSTALL_PATH
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
# set app variable
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
wget_mysql_connector(){
    local CP_PATH=$1
    LOCAL_ARCHIVE=MYSQL_CONNECTOR_ARCHIVE
    REMOTE_MIRROR_DOWNLOAD=MYSQL_CONNECTOR_MIRROR_DOWNLOAD
    FILE=$RESOURCE_PATH/$LOCAL_ARCHIVE

    log info "install $LOCAL_ARCHIVE from remote file"
    curl -o $FILE -O -L $REMOTE_MIRROR_DOWNLOAD
    tar -xzf $FILE -C $RESOURCE_PATH
    cp $RESOURCE_PATH/$MYSQL_CONNECTOR_VERSION/${MYSQL_CONNECTOR_VERSION}.jar $CP_PATH
    rm -rf $RESOURCE_PATH/mysql-connector-java-5.1.49*
}
