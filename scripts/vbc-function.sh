#!/bin/bash
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

# 将配置转换为xml
# eg: get_app_version_num $HIVE_VERSION "-" 2
create_property_xml() {
    local in=$1
    local out=$2

    log info "配置 $in"
    sed -i "/<configuration>/Q" $out
    echo "<configuration>" >> $out
    for line in `cat $in | grep -v '#'| grep -v '^$'`
    do
        name=`echo $line|cut -d "=" -f 1`
        value=`echo $line|cut -d "=" -f 2`

        echo "  <property>" >> $out
        echo "    <name>$name</name>" >> $out
        echo "    <value>$value</value>" >> $out
        echo "  </property>" >> $out
    done
    echo "</configuration>" >> $out
}

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

    echo $app_num
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

## @description 判断某一目录文件是否存在
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
## i=$(($i+1))
dispatch_app(){
    local app_name=$1
    log info "dispatch $app_name"
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        hostname=${HOSTNAME_LIST[$i]}
        cur_hostname=`cat /etc/hostname`
        if [ $cur_hostname != $hostname ];then
            log info "--------dispatch to $hostname--------"
            scp -r -q ${INSTALL_PATH}/$app_name $DEFAULT_USER@$hostname:${INSTALL_PATH}/
            scp -q $PROFILE $DEFAULT_USER@$hostname:$PROFILE
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
    log info "creating $app_name environment variables"
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

download_and_unzip_app() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local app_version=$(eval echo \$${app_name_upper}_VERSION)
    local archive=$(eval echo \$${app_name_upper}_ARCHIVE)
    local download_url=$(eval echo \$${app_name_upper}_MIRROR_DOWNLOAD)
    local app_dir_name=$(eval echo \$${app_name_upper}_DIR_NAME)

    log info "download_and_unzip_app ${app_name}"
    if resourceExists ${archive}; then
        installFromLocal ${archive}
    else
        installFromRemote ${archive} ${download_url}
    fi
    mv ${INSTALL_PATH}/${app_dir_name} ${INSTALL_PATH}/${app_name}
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_name}
    # rm ${DOWNLOAD_PATH}/${archive}
}

## @description 显示apps的版本号
## @param None
## @eg display_apps_num
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