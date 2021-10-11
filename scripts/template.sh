#!/bin/bash
#set -x

:<<skip
if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi
skip

###########################start test###########################
# 获取app的版本号
# eg: get_app_version_num $HIVE_VERSION '-' 2
get_app_version_num() {

    local app_version=$1
    local split=$2
    local field_num=$3

    app_num=`echo $app_version|cut -d $split -f $field_num`
    echo $app_num
}

# 配置文件目录
RESOURCE_PATH=/home/vagrant/resources

# 安装目录
INSTALL_PATH=/home/vagrant/.apps

# 组件下载目录
DOWNLOAD_PATH=/home/vagrant/downloads

# 初始化集群目录
INIT_PATH=$RESOURCE_PATH/initialization
INIT_SHELL_BIN=$INSTALL_PATH/init_shell/bin

# 是否用vagrant安装集群
IS_VAGRANT="true"

# 环境变量配置文件
PROFILE=~/.bashrc

# 下载组建的镜像地址
# 1:https://archive.apache.org/dist
# 2:https://mirrors.huaweicloud.com/apache
DOWNLOAD_REPO=https://mirrors.huaweicloud.com/apache
# hostname
HOSTNAME=("hdp101" "hdp102" "hdp103")

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
# ---------------------------------------------
ES_VERSION=elasticsearch-7.6.0

# es
# 支持版本：具体见下载地址
# https://mirrors.huaweicloud.com/elasticsearch/7.12.1/elasticsearch-7.12.1-linux-x86_64.tar.gz
ES_VERSION_NUM=`get_app_version_num $ES_VERSION '-' 2`
ES_ARCHIVE=$ES_VERSION-linux-x86_64.tar.gz
ES_MIRROR_DOWNLOAD=https://mirrors.huaweicloud.com/elasticsearch/$ES_VERSION_NUM/$ES_ARCHIVE
ES_RES_DIR=$RESOURCE_PATH/elasticsearch
ES_CONF_DIR=$INSTALL_PATH/elasticsearch/config
# ---------------------------------------------
###########################end test###########################

setup_es() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    mkdir -p $INSTALL_PATH/elasticsearch/datas
    mkdir -p $INSTALL_PATH/elasticsearch/logs
    cp -f $ES_RES_DIR/* $ES_CONF_DIR
    if [ "$IS_VAGRANT" == "true" ];then
        hostname=`cat /etc/hostname`
        node_host=`cat /etc/hosts |grep $hostname|awk '{print $1}'`
        file_path=$INSTALL_PATH/$app_name/config/elasticsearch.yml
        
        echo "------modify $i server.properties-------"
        #sed -i 's/^node.name: .*/node.name: '$hostname'/' $file_path
        sed -i 's@^network.host: .*@network.host: '$node_host'@' $file_path
    fi
}

download_es() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $ES_ARCHIVE; then
        installFromLocal $ES_ARCHIVE
    else
        installFromRemote $ES_ARCHIVE $ES_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/${ES_VERSION} ${INSTALL_PATH}/$app_name
    sudo chown -R vagrant:vagrant $INSTALL_PATH/$app_name
    rm $DOWNLOAD_PATH/$ES_ARCHIVE
}

dispatch_es() {
    local app_name=$1
    dispatch_app $app_name
    for i in {"hdp102","hdp103"};
    do
        node_name=$i
        node_host=`cat /etc/hosts |grep $i|awk '{print $1}'`
        file_path=$INSTALL_PATH/$app_name/config/elasticsearch.yml

        echo "------modify $i server.properties-------"
        #ssh $i "sed -i 's/^node.name: .*/node.name: '$node_name'/' $file_path"
        ssh $i "sed -i 's@^network.host: .*@network.host: '$node_host'@' $file_path"
    done
}

install_es() {
    local app_name="elasticsearch"
    log info "setup $app_name"

    download_es $app_name
    setup_es $app_name
    #setupEnv_app $app_name
    #dispatch_app $app_name
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_es $app_name
    fi
    source $PROFILE
}


if [ "$IS_VAGRANT" == "true" ];then
    install_es
fi
install_es
