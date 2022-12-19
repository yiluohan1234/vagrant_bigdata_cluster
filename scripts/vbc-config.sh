#!/bin/bash
bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`

DEFAULT_MAIN_DIR="$bin"/..
VGC_MAIN_DIR=${VGC_MAIN_DIR:-$DEFAULT_MAIN_DIR}

# ip,hostname
IP_LIST=("192.168.10.101" "192.168.10.102" "192.168.10.103")
HOSTNAME_LIST=("hdp101" "hdp102" "hdp103")
PASSWD_LIST=("vagrant" "vagrant" "vagrant")

# 安装目录
INSTALL_PATH=/opt/module

# 环境变量配置文件
PROFILE=/etc/profile

# 是否用vagrant安装集群
IS_VAGRANT="true"

# 是否用kerberos
IS_KERBEROS="false"

# 是否安装中文包
IS_CHINESE="false"

# 是否更新git
IS_UPDATE_GIT="false"

# 是否安装Github520
IS_GITHUB="false"

# default user and group
DEFAULT_USER=vagrant
DEFAULT_GROUP=root

# 配置文件目录
RESOURCE_PATH=$VGC_MAIN_DIR/resources

# 组件下载目录
DOWNLOAD_PATH=$VGC_MAIN_DIR/downloads

# 初始化集群目录
INIT_PATH=$RESOURCE_PATH/init_bin
INIT_SHELL_BIN=$INSTALL_PATH/init_bin

# 下载组建的镜像地址
# 1:https://archive.apache.org/dist
# 2:https://mirrors.huaweicloud.com/apache
DOWNLOAD_REPO=https://mirrors.huaweicloud.com/apache
# DOWNLOAD_REPO_APACHE=https://archive.apache.org/dist
GITHUB_DOWNLOAD_REPO=https://ghproxy.com

# Centos basic apps list.
CENTOS_BASIC_APPS=("epel-release" "sshpass" "lrzsz" "expect" "unzip" "zip" "vim-enhanced" "lzop" "dos2unix" "net-tools" "nc" "wget" "lsof" "telnet" "tcpdump" "ntp")
# CENTOS_BASIC_APPS=("epel-release" "sshpass" "lrzsz" "expect" "wget")

# mysql
MYSQL_HOST=${HOSTNAME_LIST[2]}
MYSQL_USER=root
MYSQL_PASSWORD=199037