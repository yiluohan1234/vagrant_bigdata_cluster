#!/bin/bash
source "/vagrant/scripts/common.sh"

log info "Centos 基本配置" 
log info "安装 epel-release" 
yum install -y -q epel-release
#yum remove -y  -q git
rpm -ivh https://opensource.wandisco.com/git/wandisco-git-release-7-2.noarch.rpm
yum install -y -q git

# 设置系统时区
log info "设置时区" 
timedatectl set-timezone Asia/Shanghai 

# ssh 设置允许密码登录
log info "设置ssh" 
sed -i 's@^PasswordAuthentication no@PasswordAuthentication yes@g' /etc/ssh/sshd_config
sed -i 's@^#PubkeyAuthentication yes@PubkeyAuthentication yes@g' /etc/ssh/sshd_config
systemctl restart sshd.service
log info "设置最大文件句柄数、最大线程数和最大进程数" 
# 设置最大文件句柄数和最大线程数
echo -e "* soft nofile 65536\n* hard nofile 65536\n* soft nproc 131072\n* hard nproc 131072" >> /etc/security/limits.conf
# 设置进程数
sed -i 's@4096@65536@g' /etc/security/limits.d/20-nproc.conf
# CentOS取消SELINUX
sed -i "s@^SELINUX=.*@SELINUX=disabled@g" /etc/selinux/config
# 虚拟内存扩容
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# 安装基本的软件：-q（不显示安装的过程）
# 高质量软件包管理
log info "安装 sshpass lrzsz expect unzip zip vim-enhanced lzop"
yum install -y -q sshpass
yum install -y -q lrzsz 
yum install -y -q expect 
yum install -y -q unzip 
yum install -y -q zip 
yum install -y -q vim-enhanced 
yum install -y -q lzop 
yum install -y -q dos2unix
log info "安装 nmap-ncat net-tools nc wget lsof"
yum install -y -q nmap-ncat 
yum install -y -q net-tools 
yum install -y -q nc 
yum install -y -q wget 
yum install -y -q lsof 
yum install -y -q telnet 
yum install -y -q tcpdump 
yum install -y -q ntp

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