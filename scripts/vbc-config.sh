#!/bin/bash
bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`

DEFAULT_MAIN_DIR="$bin"/..
VGC_MAIN_DIR=${VGC_MAIN_DIR:-$DEFAULT_MAIN_DIR}

# ip,hostname
IP_LIST=("192.168.10.101" "192.168.10.102" "192.168.10.103")
# HOSTNAME_LIST=("hdp101" "hdp102" "hdp103")
HOSTNAME_LIST=("hadoop102" "hadoop103" "hadoop104")
PASSWD_LIST=("vagrant" "vagrant" "vagrant")
# PASSWD_LIST=("atguigu" "atguigu" "atguigu")

# default user and group
DEFAULT_USER=atguigu
DEFAULT_GROUP=hadoop

# installation directory
INSTALL_PATH=/opt/module

# Environment variable configuration file
PROFILE=/etc/profile

# Whether to install the cluster with vagrant
IS_VAGRANT="true"

# Whether to use kerberos
IS_KERBEROS="false"

# Whether to install the Chinese pack
IS_CHINESE="false"

# Whether to update git
IS_UPDATE_GIT="false"

# Whether to install Github520
IS_GITHUB="false"

# Whether to delete /vagrant
IS_DEL_VAGRANT="true"

# configuration file directory
RESOURCE_PATH=$VGC_MAIN_DIR/resources

# Component download directory
DOWNLOAD_PATH=$VGC_MAIN_DIR/downloads

# Initialize the cluster directory
INIT_PATH=$RESOURCE_PATH/init_bin
INIT_SHELL_BIN=$INSTALL_PATH/init_bin

# Download url of component
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
