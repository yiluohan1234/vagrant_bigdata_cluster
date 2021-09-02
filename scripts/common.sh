#!/bin/bash
RESOURCE_PATH=/home/vagrant/downloads
INSTALL_PATH=/home/vagrant/apps
PROFILE=~/.bashrc
# java
JAVA_ARCHIVE=jdk-8u201-linux-x64.tar.gz
JAVA_MIRROR_DOWNLOAD=https://repo.huaweicloud.com/java/jdk/8u201-b09/jdk-8u201-linux-x64.tar.gz

# hadoop
HADOOP_VERSION=hadoop-2.7.2
HADOOP_ARCHIVE=$HADOOP_VERSION.tar.gz
HADOOP_MIRROR_DOWNLOAD=http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_ARCHIVE
HADOOP_RES_DIR=/vagrant/resources/hadoop
HADOOP_PREFIX=$INSTALL_PATH/hadoop
HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop

# hive
HIVE_VERSION=hive-1.2.1
HIVE_ARCHIVE=apache-$HIVE_VERSION-bin.tar.gz
HIVE_MIRROR_DOWNLOAD=http://archive.apache.org/dist/hive/$HIVE_VERSION/$HIVE_ARCHIVE
HIVE_RES_DIR=/vagrant/resources/hive
HIVE_CONF=/usr/local/hive/conf

# spark
SPARK_VERSION=spark-2.4.6
SPARK_ARCHIVE=$SPARK_VERSION-bin-hadoop2.tgz
SPARK_MIRROR_DOWNLOAD=http://archive.apache.org/dist/spark/$SPARK_VERSION/$SPARK_VERSION-bin-hadoop2.7.tgz
SPARK_RES_DIR=/vagrant/resources/spark
SPARK_CONF_DIR=/usr/local/spark/conf

# ssh
SSH_RES_DIR=/vagrant/resources/ssh
RES_SSH_COPYID_ORIGINAL=$SSH_RES_DIR/ssh-copy-id.original
RES_SSH_COPYID_MODIFIED=$SSH_RES_DIR/ssh-copy-id.modified
RES_SSH_CONFIG=$SSH_RES_DIR/config
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
# installFromLocal
#       $1 archive name
# eg: installFromLocal $HADOOP_ARCHIVE
installFromLocal() {
    LOCAL_ARCHIVE=$1
    log info "install $LOCAL_ARCHIVE from local file"
    FILE=$RESOURCE_PATH/$LOCAL_ARCHIVE
    tar -xzf $FILE -C $INSTALL_PATH
	sudo chown -R vagrant:vagrant $INSTALL_PATH
}

# 从网上下载安装
# installFromRemote
#     $1 archive name
#     $2 remote download url
# eg: installFromRemote $HADOOP_ARCHIVE $HADOOP_MIRROR_DOWNLOAD
installFromRemote() {
    LOCAL_ARCHIVE=$1
    REMOTE_MIRROR_DOWNLOAD=$2
    FILE=$RESOURCE_PATH/$LOCAL_ARCHIVE
 
    log info "install hadoop from remote file"
    curl -o $FILE -O -L $REMOTE_MIRROR_DOWNLOAD
    tar -xzf $FILE -C $INSTALL_PATH
	sudo chown -R vagrant:vagrant $INSTALL_PATH
}