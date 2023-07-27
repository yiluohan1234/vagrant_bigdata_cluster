#!/bin/bash

bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`

DEFAULT_SCRIPTS_DIR="$bin"/../scripts
VGC_SCRIPTS_DIR=${VGC_SCRIPTS_DIR:-$DEFAULT_SCRIPTS_DIR}
. $VGC_SCRIPTS_DIR/vbc-config.sh
. $VGC_SCRIPTS_DIR/vbc-function.sh

# Version information
# HADOOP_VERSION=hadoop-2.7.7
HADOOP_VERSION=hadoop-3.2.2
# HIVE_VERSION=hive-2.3.4
HIVE_VERSION=hive-3.1.3
# HBASE_VERSION=hbase-1.6.0
# PHOENIX_VERSION=phoenix-hbase-1.6-4.16.0
HBASE_VERSION=hbase-2.0.5
PHOENIX_VERSION=apache-phoenix-5.0.0-HBase-2.0
# SCALA_VERSION=scala-2.11.11
SCALA_VERSION=scala-2.12.16
SPARK_VERSION=spark-3.2.3
ZOOKEEPER_VERSION=zookeeper-3.6.3
# KAFKA_VERSION=kafka_2.11-2.4.1
KAFKA_VERSION=kafka_2.12-3.0.0
# KAFKA_VERSION=kafka_2.10-0.10.2.2
SQOOP_VERSION=sqoop-1.4.7
FLINK_VERSION=flink-1.13.4

NIFI_VERSION=nifi-1.13.0
FLUME_VERSION=flume-1.9.0
MAVEN_VERSION=maven-3.6.1
MYSQL_CONNECTOR_VERSION=mysql-connector-java-5.1.49
PRESTO_VERSION=presto-server-0.196
ELASTICSEARCH_VERSION=elasticsearch-6.6.0
KIBANA_VERSION=kibana-6.6.0
CANAL_VERSION=canal.deployer-1.1.5
MAXWELL_VERSION=maxwell-1.29.2
AZKABAN_VERSION=azkaban-3.84.4
KYLIN_VERSION=kylin-3.0.2
MYSQL_VERSION=mysql-5.7.35
NGINX_VERSION=nginx-1.18.0
REDIS_VERSION=redis-5.0.12

# java
JAVA_ARCHIVE=jdk-8u201-linux-x64.tar.gz
JAVA_MIRROR_DOWNLOAD=https://repo.huaweicloud.com/java/jdk/8u201-b09/$JAVA_ARCHIVE
JAVA_DIR_NAME=jdk1.8.0_201

# hadoop
#         https://archive.apache.org/dist/hadoop/core/hadoop-2.7.7/hadoop-2.7.7.tar.gz
# https://mirrors.huaweicloud.com/apache/hadoop/core/hadoop-3.2.2/hadoop-3.2.2.tar.gz
# https://archive.apache.org/dist => https://mirrors.huaweicloud.com/apache
HADOOP_VERSION_NUM=`get_app_version_num $HADOOP_VERSION "-" 2`
HADOOP_VERSION_NUM_TWO=`echo ${HADOOP_VERSION:7:3}`
HADOOP_ARCHIVE=$HADOOP_VERSION.tar.gz
HADOOP_DIR_NAME=$HADOOP_VERSION
HADOOP_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hadoop/core/$HADOOP_VERSION/$HADOOP_ARCHIVE
HADOOP_RES_DIR=$RESOURCE_PATH/hadoop
HADOOP_PREFIX=$INSTALL_PATH/hadoop
HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop

# hive
#         https://archive.apache.org/dist/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz
HIVE_VERSION_NUM=`get_app_version_num $HIVE_VERSION "-" 2`
HIVE_ARCHIVE=apache-$HIVE_VERSION-bin.tar.gz
HIVE_DIR_NAME=apache-${HIVE_VERSION}-bin
HIVE_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hive/$HIVE_VERSION/$HIVE_ARCHIVE
HIVE_RES_DIR=$RESOURCE_PATH/hive
HIVE_CONF_DIR=$INSTALL_PATH/hive/conf

# hbase
#         https://archive.apache.org/dist/hbase/1.2.6/hbase-1.2.6-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/hbase/2.4.12/hbase-2.4.12-bin.tar.gz
HBASE_VERSION_NUM=`get_app_version_num $HBASE_VERSION "-" 2`
HBASE_ARCHIVE=${HBASE_VERSION}-bin.tar.gz
HBASE_DIR_NAME=${HBASE_VERSION}
HBASE_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/hbase/$HBASE_VERSION_NUM/$HBASE_ARCHIVE
HBASE_RES_DIR=$RESOURCE_PATH/hbase
HBASE_CONF_DIR=$INSTALL_PATH/hbase/conf

# spark
#         https://archive.apache.org/dist/spark/spark-2.4.3/spark-2.4.3-bin-hadoop2.7.tgz
# https://mirrors.huaweicloud.com/apache/spark/spark-3.2.3/spark-3.2.3-bin-hadoop3.2.tgz
SPARK_VERSION_NUM=`get_app_version_num $SPARK_VERSION "-" 2`
SPARK_ARCHIVE=$SPARK_VERSION-bin-hadoop${HADOOP_VERSION_NUM_TWO}.tgz
SPARK_DIR_NAME=${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION_NUM_TWO}
SPARK_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/spark/$SPARK_VERSION/$SPARK_ARCHIVE
SPARK_RES_DIR=$RESOURCE_PATH/spark
SPARK_CONF_DIR=$INSTALL_PATH/spark/conf

# nifi
#         https://archive.apache.org/dist/nifi/1.13.0/nifi-1.13.0-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/nifi/1.13.0/nifi-1.13.0-bin.tar.gz
NIFI_VERSION_NUM=`get_app_version_num $NIFI_VERSION "-" 2`
NIFI_ARCHIVE=$NIFI_VERSION-bin.tar.gz
NIFI_DIR_NAME=${NIFI_VERSION}
NIFI_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/nifi/$NIFI_VERSION/$NIFI_ARCHIVE
NIFI_RES_DIR=$RESOURCE_PATH/nifi
NIFI_CONF_DIR=$INSTALL_PATH/nifi/conf

# scala
SCALA_VERSION_NUM=`get_app_version_num $SCALA_VERSION "-" 2`
SCALA_ARCHIVE=${SCALA_VERSION}.tgz
SCALA_DIR_NAME=${SCALA_VERSION}
# SCALA_MIRROR_DOWNLOAD=https://downloads.lightbend.com/scala/2.11.12/scala-2.11.12.tgz
# https://distfiles.macports.org/scala2.11/scala-2.12.10.tgz
# SCALA_MIRROR_DOWNLOAD=https://distfiles.macports.org/scala${SCALA_VERSION_NUM%.*}/$SCALA_ARCHIVE
SCALA_MIRROR_DOWNLOAD=https://downloads.lightbend.com/scala/${SCALA_VERSION_NUM}/$SCALA_ARCHIVE

# sqoop
#         https://archive.apache.org/dist/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
# https://mirrors.huaweicloud.com/apache/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
SQOOP_VERSION_NUM=`get_app_version_num $SQOOP_VERSION "-" 2`
SQOOP_ARCHIVE=${SQOOP_VERSION}.bin__hadoop-2.6.0.tar.gz
SQOOP_DIR_NAME=${SQOOP_VERSION}.bin__hadoop-2.6.0
SQOOP_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/sqoop/$SQOOP_VERSION_NUM/$SQOOP_ARCHIVE
SQOOP_RES_DIR=$RESOURCE_PATH/sqoop
SQOOP_CONF_DIR=$INSTALL_PATH/sqoop/conf

# flink
#         https://archive.apache.org/dist/flink/flink-1.12.4/flink-1.12.4-bin-scala_2.11.tgz
# https://mirrors.huaweicloud.com/apache/flink/flink-1.12.4/flink-1.12.4-bin-scala_2.11.tgz
FLINK_VERSION_NUM=`get_app_version_num $FLINK_VERSION "-" 2`
FLINK_ARCHIVE=$FLINK_VERSION-bin-scala_${SCALA_VERSION_NUM%.*}.tgz
FLINK_DIR_NAME=$FLINK_VERSION
FLINK_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/flink/$FLINK_VERSION/$FLINK_VERSION-bin-scala_${SCALA_VERSION_NUM%.*}.tgz
FLINK_RES_DIR=$RESOURCE_PATH/flink
FLINK_CONF_DIR=$INSTALL_PATH/flink/conf

# flume
#        https://archive.apache.org/dist/flume/1.6.0/apache-flume-1.6.0-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/flume/1.9.0/apache-flume-1.9.0-bin.tar.gz
FLUME_VERSION_NUM=`get_app_version_num $FLUME_VERSION "-" 2`
FLUME_ARCHIVE=apache-${FLUME_VERSION}-bin.tar.gz
FLUME_DIR_NAME=apache-${FLUME_VERSION}-bin
FLUME_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/flume/$FLUME_VERSION_NUM/$FLUME_ARCHIVE
FLUME_RES_DIR=$RESOURCE_PATH/flume
FLUME_CONF_DIR=$INSTALL_PATH/flume/conf

# zookeeper
#         https://archive.apache.org/dist/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz
# https://mirrors.huaweicloud.com/apache/zookeeper/zookeeper-3.5.7/apache-zookeeper-3.5.7-bin.tar.gz
ZOOKEEPER_VERSION_NUM=`get_app_version_num $ZOOKEEPER_VERSION "-" 2`
ZOOKEEPER_ARCHIVE=apache-${ZOOKEEPER_VERSION}-bin.tar.gz
ZOOKEEPER_DIR_NAME=apache-${ZOOKEEPER_VERSION}-bin
ZOOKEEPER_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/zookeeper/$ZOOKEEPER_VERSION/$ZOOKEEPER_ARCHIVE
ZOOKEEPER_RES_DIR=$RESOURCE_PATH/zookeeper
ZOOKEEPER_CONF_DIR=$INSTALL_PATH/zookeeper/conf

# kafka
#         https://archive.apache.org/dist/kafka/0.11.0.3/kafka_2.11-0.11.0.3.tgz
# https://mirrors.huaweicloud.com/apache/kafka/3.0.0/kafka_2.12-3.0.0.tgz
KAFKA_VERSION_NUM=`get_app_version_num $KAFKA_VERSION "-" 2`
KAFKA_ARCHIVE=${KAFKA_VERSION}.tgz
KAFKA_DIR_NAME=${KAFKA_VERSION}
KAFKA_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/kafka/$KAFKA_VERSION_NUM/$KAFKA_ARCHIVE
KAFKA_RES_DIR=$RESOURCE_PATH/kafka
KAFKA_CONF_DIR=$INSTALL_PATH/kafka/config

# phoenix 1.6
#        https://archive.apache.org/dist/phoenix/phoenix-4.16.0/phoenix-hbase-1.6-4.16.0-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/phoenix/phoenix-4.16.0/phoenix-hbase-1.6-4.16.0-bin.tar.gz
# PHOENIX_VERSION_NUM=`get_app_version_num $PHOENIX_VERSION "-" 4`
# PHOENIX_HBASE_VERSION_NUM=`get_app_version_num $PHOENIX_VERSION "-" 3`
# PHOENIX_ARCHIVE=${PHOENIX_VERSION}-bin.tar.gz
# PHOENIX_DIR_NAME=${PHOENIX_VERSION}-bin
# PHOENIX_MIRROR_DOWNLOAD=${DOWNLOAD_REPO}/phoenix/phoenix-${PHOENIX_VERSION_NUM}/$PHOENIX_ARCHIVE
# PHOENIX_RES_DIR=$RESOURCE_PATH/phoenix
# PHOENIX_CONF_DIR=$INSTALL_PATH/phoenix/conf

# phoenix 2.0
# https://archive.apache.org/dist/phoenix/apache-phoenix-5.0.0-HBase-2.0/bin/apache-phoenix-5.0.0-HBase-2.0-bin.tar.gz
PHOENIX_VERSION_NUM=`get_app_version_num $PHOENIX_VERSION "-" 3`
PHOENIX_HBASE_VERSION_NUM=`get_app_version_num $PHOENIX_VERSION "-" 5`
PHOENIX_ARCHIVE=${PHOENIX_VERSION}-bin.tar.gz
PHOENIX_DIR_NAME=${PHOENIX_VERSION}-bin
PHOENIX_MIRROR_DOWNLOAD=${DOWNLOAD_REPO}/phoenix/${PHOENIX_VERSION}/bin/$PHOENIX_ARCHIVE
PHOENIX_RES_DIR=$RESOURCE_PATH/phoenix
PHOENIX_CONF_DIR=$INSTALL_PATH/phoenix/conf

# mysql_connector
#                 http://mirrors.sohu.com/mysql/Connector-J/mysql-connector-java-5.1.49.tar.gz
# https://repo.huaweicloud.com/mysql/Downloads/Connector-J/mysql-connector-java-5.1.49.tar.gz
MYSQL_CONNECTOR_VERSION_NUM=`get_app_version_num $MYSQL_CONNECTOR_VERSION "-" 4`
MYSQL_CONNECTOR_ARCHIVE=${MYSQL_CONNECTOR_VERSION}.tar.gz
MYSQL_CONNECTOR_MIRROR_DOWNLOAD=https://repo.huaweicloud.com/mysql/Downloads/Connector-J/$MYSQL_CONNECTOR_ARCHIVE

# MYSQL
# https://mirrors.huaweicloud.com/mysql/Downloads/MySQL-5.7/mysql-5.7.35-linux-glibc2.12-x86_64.tar.gz
MYSQL_VERSION_NUM=`get_app_version_num $ES_VERSION "-" 2`
MYSQL_ARCHIVE=$MYSQL_VERSION-linux-glibc2.12-x86_64.tar.gz
MYSQL_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/mysql/Downloads/MySQL-5.7/$MYSQL_ARCHIVE
MYSQL_RES_DIR=$RESOURCE_PATH/mysql
MYSQL_CONF_DIR=$INSTALL_PATH/mysql

# maven
#        https://archive.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz
# https://mirrors.huaweicloud.com/apache/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz
MAVEN_VERSION_NUM=`get_app_version_num $MAVEN_VERSION "-" 2`
MAVEN_ARCHIVE=apache-${MAVEN_VERSION}-bin.tar.gz
MAVEN_DIR_NAME=apache-${MAVEN_VERSION}
MAVEN_MIRROR_DOWNLOAD=$DOWNLOAD_REPO/maven/maven-${MAVEN_VERSION_NUM%%.*}/$MAVEN_VERSION_NUM/binaries/$MAVEN_ARCHIVE
MAVEN_RES_DIR=$RESOURCE_PATH/maven
MAVEN_CONF_DIR=$INSTALL_PATH/maven/conf

# maxwell
# https://ghproxy.com/https://github.com/zendesk/maxwell/releases/download/v1.25.0/maxwell-1.25.0.tar.gz
MAXWELL_VERSION_NUM=`get_app_version_num $MAXWELL_VERSION "-" 2`
MAXWELL_ARCHIVE=${MAXWELL_VERSION}.tar.gz
MAXWELL_DIR_NAME=${MAXWELL_VERSION}
MAXWELL_MIRROR_DOWNLOAD=${GITHUB_DOWNLOAD_REPO}/https://github.com/zendesk/maxwell/releases/download/v${MAXWELL_VERSION_NUM}/$MAXWELL_ARCHIVE
MAXWELL_RES_DIR=$RESOURCE_PATH/maxwell
MAXWELL_CONF_DIR=$INSTALL_PATH/maxwell

# nginx
# https://nginx.org/download/nginx-1.18.0.tar.gz
# https://repo.huaweicloud.com/nginx/nginx-1.18.0.tar.gz
NGINX_VERSION_NUM=`get_app_version_num $NGINX_VERSION "-" 2`
NGINX_ARCHIVE=${NGINX_VERSION}.tar.gz
NGINX_MIRROR_DOWNLOAD=https://repo.huaweicloud.com/nginx/$NGINX_ARCHIVE
NGINX_RES_DIR=$RESOURCE_PATH/nginx
NGINX_CONF_DIR=$INSTALL_PATH/nginx/conf

# es
# https://mirrors.huaweicloud.com/elasticsearch/7.12.1/elasticsearch-7.12.1-linux-x86_64.tar.gz
# https://mirrors.huaweicloud.com/elasticsearch/6.6.0/elasticsearch-6.6.0.tar.gz
ELASTICSEARCH_VERSION_NUM=`get_app_version_num $ELASTICSEARCH_VERSION "-" 2`
ELASTICSEARCH_ARCHIVE=$ELASTICSEARCH_VERSION.tar.gz
ELASTICSEARCH_DIR_NAME=$ELASTICSEARCH_VERSION
ELASTICSEARCH_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/elasticsearch/$ELASTICSEARCH_VERSION_NUM/$ELASTICSEARCH_ARCHIVE
ELASTICSEARCH_RES_DIR=$RESOURCE_PATH/elasticsearch
ELASTICSEARCH_CONF_DIR=$INSTALL_PATH/elasticsearch/config

# kibana
# https://mirrors.huaweicloud.com/kibana/6.6.0/kibana-6.6.0-linux-x86_64.tar.gz
KIBANA_VERSION_NUM=`get_app_version_num $KIBANA_VERSION "-" 2`
KIBANA_ARCHIVE=$KIBANA_VERSION-linux-x86_64.tar.gz
KIBANA_DIR_NAME=${KIBANA_VERSION}-linux-x86_64
KIBANA_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/kibana/$KIBANA_VERSION_NUM/$KIBANA_ARCHIVE
KIBANA_RES_DIR=$RESOURCE_PATH/kibana
KIBANA_CONF_DIR=$INSTALL_PATH/kibana/config

# redis
# https://mirrors.huaweicloud.com/redis/redis-6.2.1.tar.gz
# https://repo.huaweicloud.com/redis/redis-6.2.1.tar.gz
REDIS_VERSION_NUM=`get_app_version_num $REDIS_VERSION "-" 2`
REDIS_ARCHIVE=$REDIS_VERSION.tar.gz
REDIS_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/redis/$REDIS_ARCHIVE
REDIS_RES_DIR=$RESOURCE_PATH/redis
REDIS_CONF_DIR=$INSTALL_PATH/redis/conf

# canal
# https://ghproxy.com/https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.deployer-1.1.5.tar.gz
CANAL_VERSION_NUM=`get_app_version_num $CANAL_VERSION "-" 2`
CANAL_ARCHIVE=${CANAL_VERSION}.tar.gz
CANAL_MIRROR_DOWNLOAD=${GITHUB_DOWNLOAD_REPO}/https://github.com/alibaba/canal/releases/download/canal-${CANAL_VERSION_NUM}/${CANAL_ARCHIVE}
CANAL_RES_DIR=$RESOURCE_PATH/canal
CANAL_CONF_DIR=$INSTALL_PATH/canal/conf

# azkaban
AZKABAN_VERSION_NUM=`get_app_version_num $AZKABAN_VERSION "-" 2`
AZKABAN_ARCHIVE=${AZKABAN_VERSION_NUM}.tar.gz
AZKABAN_MIRROR_DOWNLOAD=${GITHUB_DOWNLOAD_REPO}/https://github.com/azkaban/azkaban/archive/$AZKABAN_ARCHIVE
AZKABAN_RES_DIR=$RESOURCE_PATH/azkaban

# presto
PRESTO_VERSION_NUM=`get_app_version_num $AZKABAN_VERSION "-" 3`
PRESTO_ARCHIVE=${PRESTO_VERSION}.tar.gz
PRESTO_DIR_NAME=${PRESTO_VERSION}
PRESTO_MIRROR_DOWNLOAD=http://maven.aliyun.com/nexus/content/groups/public/com/facebook/presto/presto-server/0.196/presto-server-0.196.tar.gz
PRESTO_RES_DIR=$RESOURCE_PATH/presto
PRESTO_CONF_DIR=$INSTALL_PATH/presto/etc
#wget http://maven.aliyun.com/nexus/content/groups/public/com/facebook/presto/presto-cli/0.196/presto-cli-0.196-executable.jar

# kylin
# https://mirrors.huaweicloud.com/apache/kylin/apache-kylin-3.0.2/apache-kylin-3.0.2-bin-hadoop3.tar.gz
# https://mirrors.huaweicloud.com/apache/kylin/apache-kylin-3.0.2/apache-kylin-3.0.2-bin-hbase1x.tar.gz
KYLIN_VERSION_NUM=`get_app_version_num $AZKABAN_VERSION "-" 3`
KYLIN_ARCHIVE=apache-${KYLIN_VERSION}-bin-hbase1x.tar.gz
KYLIN_DIR_NAME=apache-${KYLIN_VERSION}-bin-hbase1x
KYLIN_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/apache/kylin/apache-$KYLIN_VERSION/$KYLIN_ARCHIVE
KYLIN_RES_DIR=$RESOURCE_PATH/kylin
KYLIN_CONF_DIR=$INSTALL_PATH/kylin/bin

# datax
DATAX_VERSION_NUM=datax
DATAX_ARCHIVE=${DATAX_VERSION_NUM}.tar.gz
DATAX_DIR_NAME=datax
DATAX_MIRROR_DOWNLOAD=http://datax-opensource.oss-cn-hangzhou.aliyuncs.com/datax.tar.gz


