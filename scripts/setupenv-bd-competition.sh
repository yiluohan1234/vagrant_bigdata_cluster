#!/bin/bash

set_init() {
    # 安装git
    rpm -ivh https://opensource.wandisco.com/git/wandisco-git-release-7-2.noarch.rpm
    yum install -y -q git
    # ssh 设置允许密码登录
    echo "Set ssh"
    sed -i 's@^PasswordAuthentication no@PasswordAuthentication yes@g' /etc/ssh/sshd_config
    sed -i 's@^#PubkeyAuthentication yes@PubkeyAuthentication yes@g' /etc/ssh/sshd_config
    systemctl restart sshd.service

    # 安装基础软件
    CENTOS_BASIC_APPS=("epel-release" "sshpass" "unzip" "zip" "vim-enhanced" "net-tools")
    for app in ${CENTOS_BASIC_APPS[@]};do
        yum install -y -q ${app}
    done

    echo "Set the maximum number of file handles, maximum number of threads and maximum number of processes"
    # Set the maximum number of file handles and maximum number of threads
    echo -e "* soft nofile 65536\n* hard nofile 65536\n* soft nproc 131072\n* hard nproc 131072" >> /etc/security/limits.conf
    # Set the number of processes
    sed -i 's@4096@65536@g' /etc/security/limits.d/20-nproc.conf
    # Virtual memory expansion
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf

    # 创建目录
    mkdir /usr/package277

    complete_url=https://ghproxy.com/https://raw.githubusercontent.com/yiluohan1234/vagrant_bigdata_cluster/master/resources/init_bin/complete_tool.sh
    bigstart_url=https://ghproxy.com/https://raw.githubusercontent.com/yiluohan1234/vagrant_bigdata_cluster/master/resources/single_node/bigstart
    curl -o /vagrant/complete_tool.sh -O -L ${complete_url}
    curl -o /vagrant/bigstart -O -L ${bigstart_url}

    [ -f /vagrant/bigstart ] && cp /vagrant/bigstart /usr/bin && chmod a+x /usr/bin/bigstart
    [ -f /vagrant/complete_tool.sh ] && cp /vagrant/complete_tool.sh /etc/profile.d
}

download_package() {
    hostname=`cat /etc/hostname`
    if [ "$hostname" == "hdp101" ];then
        ##
        echo "download jdk"
        git clone https://gitee.com/yiluohan1234/bdc-dataware /usr/package277/tmp
        cat /usr/package277/tmp/jdk221/jdk-8u221-linux-x64_* > /usr/package277/jdk-8u221-linux-x64.tar.gz
        rm -rf /usr/package277/tmp
        # curl -o /usr/package277/jdk-8u201-linux-x64.tar.gz -O -L https://repo.huaweicloud.com/java/jdk/8u201-b09/jdk-8u201-linux-x64.tar.gz
        echo "download hadoop"
        curl -o /usr/package277/hadoop-2.7.7.tar.gz -O -L https://mirrors.huaweicloud.com/apache/hadoop/core/hadoop-2.7.7/hadoop-2.7.7.tar.gz
        echo "download spark"
        curl -o /usr/package277/spark-2.4.3-bin-hadoop2.7.tgz -O -L https://mirrors.huaweicloud.com/apache/spark/spark-2.4.3/spark-2.4.3-bin-hadoop2.7.tgz
        echo "download hive"
        curl -o /usr/package277/apache-hive-2.3.4-bin.tar.gz -O -L https://mirrors.huaweicloud.com/apache/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz
        echo "download sqoop"
        curl -o /usr/package277/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz -O -L https://mirrors.huaweicloud.com/apache/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
        echo "download kafka"
        curl -o /usr/package277/kafka_2.10-0.10.2.2.tgz -O -L https://mirrors.huaweicloud.com/apache/kafka/0.10.2.2/kafka_2.10-0.10.2.2.tgz
        echo "download hbase"
        curl -o /usr/package277/hbase-1.6.0-bin.tar.gz -O -L https://mirrors.huaweicloud.com/apache/hbase/1.6.0/hbase-1.6.0-bin.tar.gz
        echo "download zookeeper"
        curl -o /usr/package277/zookeeper-3.4.14.tar.gz -O -L https://mirrors.huaweicloud.com/apache/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz
        echo "download scala"
        curl -o /usr/package277/scala-2.10.6.tgz -O -L https://distfiles.macports.org/scala2.10/scala-2.10.6.tgz
        echo "download mysql-connector-java-5.1.47"
        curl -o /usr/package277/mysql-connector-java-5.1.47.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.47/mysql-connector-java-5.1.47.jar
    elif [ "$hostname" == "hdp103" ];then
        echo "download mysql-5.7.35"
        curl -o /usr/package277/mysql-5.7.35-1.el7.x86_64.rpm-bundle.tar  -O -L https://repo.huaweicloud.com/mysql/Downloads/MySQL-5.7/mysql-5.7.35-1.el7.x86_64.rpm-bundle.tar
        tar -xvf /usr/package277/mysql-5.7.35-1.el7.x86_64.rpm-bundle.tar -C  /usr/package277/
        # 卸载自带的Mysql-libs
        rpm -qa | grep -i -E mysql\|mariadb | xargs -n1 sudo rpm -e --nodeps
        rpm -ivh /usr/package277/mysql-community-common-5.7.35-1.el7.x86_64.rpm
        rpm -ivh /usr/package277/mysql-community-libs-5.7.35-1.el7.x86_64.rpm
        rpm -ivh /usr/package277/mysql-community-libs-compat-5.7.35-1.el7.x86_64.rpm
        rpm -ivh /usr/package277/mysql-community-client-5.7.35-1.el7.x86_64.rpm
        rpm -ivh /usr/package277/mysql-community-server-5.7.35-1.el7.x86_64.rpm
        # https://repo.huaweicloud.com/mysql/Downloads/MySQL-8.0/mysql-8.0.29-1.el7.x86_64.rpm-bundle.tar

    fi
}
set_init
download_package
