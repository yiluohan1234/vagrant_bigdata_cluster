#!/bin/bash

# ip,hostname
IP_LIST=("192.168.10.101" "192.168.10.102" "192.168.10.103")
HOSTNAME_LIST=("master" "slave1" "slave2")
PASSWD_LIST=("vagrant" "vagrant" "vagrant")

# 是否用vagrant安装集群
IS_VAGRANT="false"

# 是否用kerberos
IS_KERBEROS="false"

# default user and group
DEFAULT_USER=root
DEFAULT_GROUP=root

# 配置文件目录
RESOURCE_PATH=/vagrant/resources

# 安装目录
INSTALL_PATH=/opt/module

# 组件下载目录
DOWNLOAD_PATH=/vagrant/downloads

# 初始化集群目录
INIT_PATH=$RESOURCE_PATH/init_bin
INIT_SHELL_BIN=$INSTALL_PATH/init_bin

# 环境变量配置文件
PROFILE=/etc/profile.d/hdp_env.sh

# 下载组建的镜像地址
# 1:https://archive.apache.org/dist
# 2:https://mirrors.huaweicloud.com/apache
DOWNLOAD_REPO=https://mirrors.huaweicloud.com/apache
# DOWNLOAD_REPO_APACHE=https://archive.apache.org/dist

# ssh
SSH_CONF=/home/vagrant/resources/ssh