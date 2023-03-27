#!/bin/bash
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

log info "Basic configuration"
#yum remove -y  -q git
rpm -ivh https://opensource.wandisco.com/git/wandisco-git-release-7-2.noarch.rpm
yum install -y -q git

# Set timezone
log info "Set timezone"
timedatectl set-timezone Asia/Shanghai

# Ssh:Set to allow password login
log info "Set ssh"
sed -i 's@^PasswordAuthentication no@PasswordAuthentication yes@g' /etc/ssh/sshd_config
sed -i 's@^#PubkeyAuthentication yes@PubkeyAuthentication yes@g' /etc/ssh/sshd_config
systemctl restart sshd.service
log info "Set the maximum number of file handles, maximum number of threads and maximum number of processes"
# Set the maximum number of file handles and maximum number of threads
echo -e "* soft nofile 65536\n* hard nofile 65536\n* soft nproc 131072\n* hard nproc 131072" >> /etc/security/limits.conf
# Set the number of processes
sed -i 's@4096@65536@g' /etc/security/limits.d/20-nproc.conf
# CentOS canel SELINUX
sed -i "s@^SELINUX=.*@SELINUX=disabled@g" /etc/selinux/config
# Virtual memory expansion
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# Install basic software: -q (do not display the installation process)
log info "Install sshpass lrzsz expect unzip zip vim-enhanced lzop nmap-ncat net-tools nc wget lsof"
for app in ${CENTOS_BASIC_APPS[@]};do
    yum install -y -q ${app}
done

##
mkdir /usr/package277
log info "download jdk"
curl -o /usr/package277/jdk-8u221-linux-x64.tar.gz -O -L https://repo.huaweicloud.com/java/jdk/8u201-b09/jdk-8u201-linux-x64.tar.gz
log info "download hadoop"
curl -o /usr/package277/hadoop-2.7.7.tar.gz -O -L https://mirrors.huaweicloud.com/apache/hadoop/core/hadoop-2.7.7/hadoop-2.7.7.tar.gz
log info "download spark"
curl -o /usr/package277/spark-2.4.3-bin-hadoop2.7.tgz -O -L https://mirrors.huaweicloud.com/apache/spark/spark-2.4.3/spark-2.4.3-bin-hadoop2.7.tgz
log info "download hive"
curl -o /usr/package277/apache-hive-2.3.4-bin.tar.gz -O -L https://mirrors.huaweicloud.com/apache/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz
log info "download sqoop"
curl -o /usr/package277/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz -O -L https://mirrors.huaweicloud.com/apache/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
log info "download kafka"
curl -o /usr/package277/kafka_2.10-0.10.2.2.tgz -O -L https://mirrors.huaweicloud.com/apache/kafka/0.10.2.2/kafka_2.10-0.10.2.2.tgz
log info "download hbase"
curl -o /usr/package277/hbase-1.6.0-bin.tar.gz -O -L https://mirrors.huaweicloud.com/apache/hbase/1.6.0/hbase-1.6.0-bin.tar.gz
log info "download zookeeper"
curl -o /usr/package277/apache-zookeeper-3.6.3-bin.tar.gz -O -L https://mirrors.huaweicloud.com/apache/zookeeper/zookeeper-3.6.3/apache-zookeeper-3.6.3-bin.tar.gz
log info "download scala"
curl -o /usr/package277/scala-2.11.11.tgz -O -L https://downloads.lightbend.com/scala/2.11.11/scala-2.11.11.tgz
log info "download mysql-connector-java-5.1.47"
curl -o /usr/package277/mysql-connector-java-5.1.47.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.47/mysql-connector-java-5.1.47.jar

hostname=`cat /etc/hostname`
if [ "$hostname" == "hdp103" ];then
    curl -o /usr/package277/mysql-5.7.35-1.el7.x86_64.rpm-bundle.tar  -O -L https://repo.huaweicloud.com/mysql/Downloads/MySQL-5.7/mysql-5.7.35-1.el7.x86_64.rpm-bundle.tar
fi
