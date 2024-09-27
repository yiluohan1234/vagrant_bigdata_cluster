#!/bin/bash
bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`
DEFAULT_DOWNLOAD_DIR="$bin"/download
DEFAULT_DOWNLOAD_DIR=${DEFAULT_DOWNLOAD_DIR:-$DEFAULT_DOWNLOAD_DIR}
[ ! -d $DEFAULT_DOWNLOAD_DIR ] && mkdir -p $DEFAULT_DOWNLOAD_DIR
INSTALL_PATH=/opt/module
HOST_NAME=hadoop000
PROFILE=/etc/profile
JAVA_URL_201=https://repo.huaweicloud.com/java/jdk/8u201-b09/jdk-8u201-linux-x64.tar.gz
JAVA_URL_221=https://qingjiao-image-build-assets.oss-cn-beijing.aliyuncs.com/centos_7_hadoop2.7.7/jdk-8u221-linux-x64.tar.gz
HADOOP_URL=https://mirrors.huaweicloud.com/apache/hadoop/core/hadoop-2.7.7/hadoop-2.7.7.tar.gz
HIVE_URL=https://mirrors.huaweicloud.com/apache/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz
SCALA_URL=https://downloads.lightbend.com/scala/2.11.11/scala-2.11.11.tgz
SPARK_URL=https://mirrors.huaweicloud.com/apache/spark/spark-2.4.3/spark-2.4.3-bin-hadoop2.7.tgz
ZOOKEEPER_URL=https://mirrors.huaweicloud.com/apache/zookeeper/zookeeper-3.6.3/apache-zookeeper-3.6.3-bin.tar.gz
HBASE_URL=https://mirrors.huaweicloud.com/apache/hbase/1.4.8/hbase-1.4.8-bin.tar.gz
PHOENIX_URL=https://mirrors.huaweicloud.com/apache/phoenix/apache-phoenix-4.15.0-HBase-1.4/bin/apache-phoenix-4.15.0-HBase-1.4-bin.tar.gz
# KAFKA_URL=https://mirrors.huaweicloud.com/apache/kafka/2.4.1/kafka_2.11-2.4.1.tgz
KAFKA_URL=https://mirrors.huaweicloud.com/apache/kafka/0.10.2.2/kafka_2.11-0.10.2.2.tgz
TEZ_URL=https://mirrors.huaweicloud.com/apache//tez/0.8.4/apache-tez-0.8.4-bin.tar.gz

setenv() {
    local app_name=$1
    local app_path=$2
    local type_name=$3

    local app_name_uppercase=$(echo $app_name | tr '[a-z]' '[A-Z]')
    echo "# $app_name environment" >> $PROFILE
    echo "export ${app_name_uppercase}_HOME=$app_path" >> $PROFILE
    if [ ! -n "$type_name" ];then
        echo 'export PATH=$PATH:${'$app_name_uppercase'_HOME}/bin' >> $PROFILE
    else
        echo 'export PATH=$PATH:${'$app_name_uppercase'_HOME}/bin:${'$app_name_uppercase'_HOME}/sbin' >> $PROFILE
    fi
    echo -e "\n" >> $PROFILE
    source $PROFILE
}

# 将配置转换为xml
# setkv "fs.defaultFS=hdfs://master:9000" ${HADOOP_HOME}/etc/hadoop/core-site.xml true
setkv() {
    local key_value=$1
    local properties_file=$2
    local is_create=$3
    [ -z "${is_create}" ] && is_create=false

    if [ "${is_create}" == "false" ]
    then
        sed -i "/<\/configuration>/Q" ${properties_file}
    else
        [ ! -f ${properties_file} ] && touch ${properties_file}
        echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' >> ${properties_file}
        echo '<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>' >> ${properties_file}
        echo '<configuration>' >> ${properties_file}
    fi
    name=`echo $key_value|cut -d "=" -f 1`
    value=`echo $key_value|cut -d "=" -f 2-`
    echo "  <property>" >> ${properties_file}
    echo "    <name>$name</name>" >> ${properties_file}
    echo "    <value>$value</value>" >> ${properties_file}
    echo "  </property>" >> ${properties_file}
    echo "</configuration>" >> ${properties_file}
}

download_and_unzip_app() {
    local app_name=$1
    local app_name_upper=${app_name^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local file=${url##*/}

    echo "install ${app}"
    # 安装
    if [ ! -f ${DEFAULT_DOWNLOAD_DIR}/${file} ]
    then
        curl -o ${DEFAULT_DOWNLOAD_DIR}/${file} -O -L ${url}
    fi
    tar -zxf ${DEFAULT_DOWNLOAD_DIR}/${file} -C ${INSTALL_PATH}
    if [[ $file =~ "tgz" ]];then
        mv ${INSTALL_PATH}/${file%.*} ${INSTALL_PATH}/${app}
    else
        mv ${INSTALL_PATH}/${file%%.tar*} ${INSTALL_PATH}/${app}
    fi
}

wget_mysql_connector(){
    local cp_path=$1
    local file=mysql-connector-java-5.1.49.tar.gz
    local url=https://repo.huaweicloud.com/mysql/Downloads/Connector-J/mysql-connector-java-5.1.49.tar.gz
    if [ ! -f ${DEFAULT_DOWNLOAD_DIR}/${file} ]
    then
        curl -o ${DEFAULT_DOWNLOAD_DIR}/${file} -O -L ${url}
    fi
    tar -zxf ${DEFAULT_DOWNLOAD_DIR}/${file} -C ${DEFAULT_DOWNLOAD_DIR}/
    cp ${DEFAULT_DOWNLOAD_DIR}/${file%%.tar*}/${file%%.tar*}.jar $cp_path
    rm -rf ${DEFAULT_DOWNLOAD_DIR}/${file%%.tar*}
}

install_init(){
    echo "install init"
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
    yum clean all && yum makecache && yum -y update
    # 安装git
    rpm -ivh https://opensource.wandisco.com/git/wandisco-git-release-7-2.noarch.rpm
    yum install -y -q git
    # ssh 设置允许密码登录
    sed -i 's@^PasswordAuthentication no@PasswordAuthentication yes@g' /etc/ssh/sshd_config
    sed -i 's@^#PubkeyAuthentication yes@PubkeyAuthentication yes@g' /etc/ssh/sshd_config
    systemctl restart sshd.service

    # 安装基础软件
    yum install -y -q net-tools vim-enhanced sshpass expect wget

    # 配置vagrant用户具有root权限
    # sed -i "/## Same thing without a password/ivagrant   ALL=(ALL)     NOPASSWD:ALL" /etc/sudoers

    # 添加hosts
    sed -i '/^127.0.1.1/'d /etc/hosts
    echo "192.168.10.111  ${HOST_NAME}" >> /etc/hosts

    # 修改DNS
    sed -i "s@^nameserver.*@nameserver 114.114.114.114@" /etc/resolv.conf

    # 创建安装目录
    mkdir /opt/module
    # chown -R vagrant:vagrant /opt/
    complete_url=https://gitee.com/yiluohan1234/vagrant_bigdata_cluster/raw/master/resources/single_node/complete_tool.sh
    bigstart_url=https://gitee.com/yiluohan1234/vagrant_bigdata_cluster/raw/master/resources/single_node/bigstart
    curl -o /vagrant/complete_tool.sh -O -L ${complete_url}
    curl -o /vagrant/bigstart -O -L ${bigstart_url}
    # wget -P /vagrant/ ${complete_url}
    # wget -P /vagrant/ ${bigstart_url}

    [ -f /vagrant/bigstart ] && cp /vagrant/bigstart /usr/bin && chmod a+x /usr/bin/bigstart
    [ -f /vagrant/complete_tool.sh ] && cp /vagrant/complete_tool.sh /etc/profile.d
    rm -rf /root/anaconda-ks.cfg
    rm -rf /root/original-ks.cfg
}

install_jdk()
{
    local app=java
    local url=${JAVA_URL}
    local file=${url##*/}
    if [ `yum list installed | grep java-${jdk_version}|wc -l` -gt 0 ];then
        yum -y remove java-${jdk_version}-openjdk*
        yum -y remove tzdata-java.noarch
    fi

    echo "install ${app}"
    # 安装
    if [ ! -f ${DEFAULT_DOWNLOAD_DIR}/${file} ]
    then
        git clone https://gitee.com/yiluohan1234/bdc-dataware ${INSTALL_PATH}/tmp
        cat ${INSTALL_PATH}/tmp/jdk221/jdk-8u221-linux-x64_* > ${DEFAULT_DOWNLOAD_DIR}/${file}
        cp ${INSTALL_PATH}/tmp/scala/scala-2.11.11.tgz ${DEFAULT_DOWNLOAD_DIR}
        rm -rf ${INSTALL_PATH}/tmp
    fi
    tar -zxf ${DEFAULT_DOWNLOAD_DIR}/${file} -C ${INSTALL_PATH}
    mv ${INSTALL_PATH}/jdk1.8.0_221 ${INSTALL_PATH}/${app}
    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 添加环境变量
        echo "# jdk environment" >> $PROFILE
        echo "export JAVA_HOME=${INSTALL_PATH}/${app}" >> $PROFILE
        echo 'export JRE_HOME=${JAVA_HOME}/jre' >> $PROFILE
        echo 'export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib' >> $PROFILE
        echo 'export PATH=${JAVA_HOME}/bin:${JAVA_HOME}/sbin:${JRE_HOME}/bin:$PATH' >> $PROFILE
        echo -e "\n" >> $PROFILE
        source $PROFILE
    fi

}

install_jdk221()
{
    local app=java
    local url=${JAVA_URL_221}
    local file=${url##*/}
    if [ `yum list installed | grep java-${jdk_version}|wc -l` -gt 0 ];then
        yum -y remove java-${jdk_version}-openjdk*
        yum -y remove tzdata-java.noarch
    fi

    echo "install ${app}"
    # 安装
    if [ ! -f ${DEFAULT_DOWNLOAD_DIR}/${file} ]
    then
        curl -o ${DEFAULT_DOWNLOAD_DIR}/${file} -O -L ${url}
    fi
    tar -zxf ${DEFAULT_DOWNLOAD_DIR}/${file} -C ${INSTALL_PATH}
    mv ${INSTALL_PATH}/jdk1.8.0_221 ${INSTALL_PATH}/java
    if [ -d ${INSTALL_PATH}/java ]
    then
        # 添加环境变量
        echo "# jdk environment" >> $PROFILE
        echo "export JAVA_HOME=${INSTALL_PATH}/java" >> $PROFILE
        echo 'export PATH=${JAVA_HOME}/bin:$PATH' >> $PROFILE
        echo -e "\n" >> $PROFILE
        source $PROFILE
    fi
}

install_hadoop()
{
    local app=hadoop
    download_and_unzip_app ${app}

    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 配置 hadoop-env.sh core-site.xml hdfs-site.xml yarn-site.xml mapred-site.xml slaves
        sed -i "s@^export JAVA_HOME=.*@export JAVA_HOME=${INSTALL_PATH}/java@" ${INSTALL_PATH}/${app}/etc/hadoop/hadoop-env.sh
        setkv "fs.defaultFS=hdfs://${HOST_NAME}:9000" ${INSTALL_PATH}/${app}/etc/hadoop/core-site.xml
        setkv "hadoop.tmp.dir=${INSTALL_PATH}/hadoop/hadoopdata" ${INSTALL_PATH}/${app}/etc/hadoop/core-site.xml
        setkv "hadoop.http.staticuser.user=root" ${INSTALL_PATH}/${app}/etc/hadoop/core-site.xml
        setkv "hadoop.proxyuser.root.hosts=*" ${INSTALL_PATH}/${app}/etc/hadoop/core-site.xml
        setkv "hadoop.proxyuser.root.groups=*" ${INSTALL_PATH}/${app}/etc/hadoop/core-site.xml
        setkv "hadoop.proxyuser.root.users=*" ${INSTALL_PATH}/${app}/etc/hadoop/core-site.xml
        setkv "dfs.replication=1" ${INSTALL_PATH}/${app}/etc/hadoop/hdfs-site.xml
        setkv "dfs.datanode.name.dir=${INSTALL_PATH}/hadoop/hadoopdata/name" ${INSTALL_PATH}/${app}/etc/hadoop/hdfs-site.xml
        setkv "dfs.datanode.data.dir=${INSTALL_PATH}/hadoop/hadoopdata/data" ${INSTALL_PATH}/${app}/etc/hadoop/hdfs-site.xml
        setkv "dfs.webhdfs.enabled=true" ${INSTALL_PATH}/${app}/etc/hadoop/hdfs-site.xml
        setkv "dfs.permissions.enabled=false" ${INSTALL_PATH}/${app}/etc/hadoop/hdfs-site.xml
        setkv "yarn.nodemanager.aux-services=mapreduce_shuffle" ${INSTALL_PATH}/${app}/etc/hadoop/yarn-site.xml
        setkv "yarn.resourcemanager.hostname=${HOST_NAME}" ${INSTALL_PATH}/${app}/etc/hadoop/yarn-site.xml
        setkv "yarn.nodemanager.aux-services.mapreduce.shuffle.class=org.apache.hadoop.mapred.ShuffleHandler" ${INSTALL_PATH}/${app}/etc/hadoop/yarn-site.xml
        setkv "yarn.nodemanager.vmem-check-enabled=false" ${INSTALL_PATH}/${app}/etc/hadoop/yarn-site.xml
        cp ${INSTALL_PATH}/${app}/etc/hadoop/mapred-site.xml.template ${INSTALL_PATH}/${app}/etc/hadoop/mapred-site.xml
        setkv "mapreduce.framework.name=yarn" ${INSTALL_PATH}/${app}/etc/hadoop/mapred-site.xml
        # 防止大部分资源都被Application Master占用，而导致Map/Reduce Task无法执行
        sed -i "s@0.1@0.8@g" ${INSTALL_PATH}/${app}/etc/hadoop/capacity-scheduler.xml
        # slaves
        echo -e "${HOST_NAME}" > ${INSTALL_PATH}/${app}/etc/hadoop/slaves
        echo "export JAVA_HOME=${INSTALL_PATH}/java" >> ${INSTALL_PATH}/${app}/etc/hadoop/yarn-env.sh
        # 添加环境变量
        setenv ${app} ${INSTALL_PATH}/${app} sbin
    fi
}

install_mysql() {
    # 安装mysql57
    curl -o /root/mysql57-community-release-el7-11.noarch.rpm -O -L http://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
    yum -y -q install /root/mysql57-community-release-el7-11.noarch.rpm
    yum -y -q install mysql-community-server

    # 启动并设置开机自启
    systemctl start mysqld.service
    systemctl enable mysqld.service

    # 更改初始密码
    #1获取安装时的临时密码（在第一次登录时就是用这个密码）：
    local PASSWORD=`grep 'temporary password' /var/log/mysqld.log|awk -F "root@localhost: " '{print $2}'`
    local USERNAME="root"
    local MYSQL_PASSWORD="123456"
    local PORT="3306"

    mysql -u${USERNAME} -p${PASSWORD} -e "set global validate_password_policy=0; \
        set global validate_password_length=4; \
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}'; \
        use mysql; \
        update user set host='%' where user='root'; \
        create user 'hive'@'%' IDENTIFIED BY 'hive'; \
        CREATE DATABASE hive; \
        GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION; \
        flush privileges;" --connect-expired-password

    # 删除
    yum -y remove mysql57-community-release-el7-11.noarch
    rm -rf /root/mysql57-community-release-el7-11.noarch.rpm

}

install_ssh() {
    local HOSTNAME_LIST=("${HOST_NAME}" "localhost")
    local PASSWD_LIST=("vagrant")
    yum install -y -q expect
    if [ ! -f ~/.ssh/id_rsa ];then
        expect -c "
            spawn ssh-keygen
            expect {
                \"Enter file in which to save the*\" { send \"\r\"; exp_continue}
                \"Overwrite*\" { send \"n\r\" ; exp_continue}
                \"Enter passphrase*\" { send \"\r\"; exp_continue}
                \"Enter same passphrase again:\" { send \"\r\" ; exp_continue}
            }";
    fi

    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        expect -c "
            set timeout 5;
            spawn ssh-copy-id -i ${HOSTNAME_LIST[$i]};
            expect {
                \"*assword\" { send \"${PASSWD_LIST[$i]}\r\";exp_continue}
                \"yes/no\" { send \"yes\r\"; exp_continue }
                eof {exit 0;}
            }";
        echo "========The hostname is: ${HOSTNAME_LIST[$i]}, and the password free login is completed ========"
    done
}

install_hive()
{
    local app=hive
    download_and_unzip_app ${app}

    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 配置 hive-site.xml
        setkv "javax.jdo.option.ConnectionURL=jdbc:mysql://${HOST_NAME}:3306/hive?createDatabaseIfNotExist=true&amp;useSSL=false" ${INSTALL_PATH}/${app}/conf/hive-site.xml true
        setkv "javax.jdo.option.ConnectionDriverName=com.mysql.jdbc.Driver" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "javax.jdo.option.ConnectionUserName=hive" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "javax.jdo.option.ConnectionPassword=hive" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.metastore.schema.verification=false" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "datanucleus.schema.autoCreateALL=true" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.cli.print.current.db=true" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.cli.print.header=true" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.metastore.local=false" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.server2.thrift.port=10000" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.server2.thrift.bind.host=${HOST_NAME}" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.metastore.uris=thrift://${HOST_NAME}:9083" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.exec.mode.local.auto=true" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.strict.checks.cartesian.product=false" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.exec.dynamic.partition=true" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.exec.dynamic.partition.mode=nonstrict" ${INSTALL_PATH}/${app}/conf/hive-site.xml
        setkv "hive.execution.engine=tez" ${INSTALL_PATH}/${app}/conf/hive-site.xml

        wget_mysql_connector ${INSTALL_PATH}/${app}/lib
        # 添加环境变量
        setenv ${app} ${INSTALL_PATH}/${app}
    fi
}

install_scala()
{
    local app=scala
    download_and_unzip_app ${app}

    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 添加环境变量
        setenv ${app} ${INSTALL_PATH}/${app}
    fi
}

install_spark()
{
    local app=spark
    download_and_unzip_app ${app}

    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 配置
        cp ${INSTALL_PATH}/${app}/conf/spark-env.sh.template ${INSTALL_PATH}/${app}/conf/spark-env.sh
        echo "export SPARK_MASTER_IP=${HOST_NAME}" >> ${INSTALL_PATH}/${app}/conf/spark-env.sh
        echo "export SCALA_HOME=${INSTALL_PATH}/scala" >> ${INSTALL_PATH}/${app}/conf/spark-env.sh
        echo "export SPARK_WORKER_MEMORY=1g" >> ${INSTALL_PATH}/${app}/conf/spark-env.sh
        echo "export JAVA_HOME=${INSTALL_PATH}/java" >> ${INSTALL_PATH}/${app}/conf/spark-env.sh
        echo "export HADOOP_HOME=${INSTALL_PATH}/hadoop" >> ${INSTALL_PATH}/${app}/conf/spark-env.sh
        echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ${INSTALL_PATH}/${app}/conf/spark-env.sh
        echo 'export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ${INSTALL_PATH}/${app}/conf/spark-env.sh
        echo 'export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.retainedApplications=3 -Dspark.history.fs.logDirectory=hdfs://'${HOST_NAME}':9000/spark-log"' >> ${INSTALL_PATH}/${app}/conf/spark-env.sh

        cp ${INSTALL_PATH}/${app}/conf/spark-defaults.conf.template ${INSTALL_PATH}/${app}/conf/spark-defaults.conf
        echo "spark.master                     yarn" >> ${INSTALL_PATH}/${app}/conf/spark-defaults.conf
        echo "spark.eventLog.enabled           true" >> ${INSTALL_PATH}/${app}/conf/spark-defaults.conf
        echo "spark.eventLog.dir               hdfs://${HOST_NAME}:9000/spark-log" >> ${INSTALL_PATH}/${app}/conf/spark-defaults.conf
        echo "spark.eventLog.compress          true" >> ${INSTALL_PATH}/${app}/conf/spark-defaults.conf
        echo "spark.serializer                 org.apache.spark.serializer.KryoSerializer" >> ${INSTALL_PATH}/${app}/conf/spark-defaults.conf
        echo "spark.executor.memory            1g" >> ${INSTALL_PATH}/${app}/conf/spark-defaults.conf
        echo "spark.driver.memory              1g" >> ${INSTALL_PATH}/${app}/conf/spark-defaults.conf
        echo 'spark.executor.extraJavaOptions  -XX:+PrintGCDetails -Dkey=value -Dnumbers="one two three"' >> ${INSTALL_PATH}/${app}/conf/spark-defaults.conf

        cp ${INSTALL_PATH}/${app}/conf/slaves.template ${INSTALL_PATH}/${app}/conf/slaves
        echo "${HOST_NAME}" > ${INSTALL_PATH}/${app}/conf/slaves
        wget_mysql_connector ${INSTALL_PATH}/${app}/jars
        # 添加环境变量
        setenv ${app} ${INSTALL_PATH}/${app}
    fi
}

install_zk()
{
    local app=zookeeper
    download_and_unzip_app ${app}

    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 配置
        cp  ${INSTALL_PATH}/${app}/conf/zoo_sample.cfg ${INSTALL_PATH}/${app}/conf/zoo.cfg
        sed -i "s@^dataDir=.*@dataDir=${INSTALL_PATH}/${app}/data@" ${INSTALL_PATH}/${app}/conf/zoo.cfg
        mkdir -p ${INSTALL_PATH}/${app}/data
        echo "1" >> ${INSTALL_PATH}/${app}/data/myid
        # 添加环境变量
        setenv ${app} ${INSTALL_PATH}/${app}
    fi
}

install_hbase()
{
    local app=hbase
    local url=${HBASE_URL}
    local file=${url##*/}

    echo "install ${app}"
    # 安装
    if [ ! -f ${DEFAULT_DOWNLOAD_DIR}/${file} ]
    then
        curl -o ${DEFAULT_DOWNLOAD_DIR}/${file} -O -L ${url}
    fi
    tar -zxf ${DEFAULT_DOWNLOAD_DIR}/${file} -C ${INSTALL_PATH}
    mv ${INSTALL_PATH}/${file:0:11} ${INSTALL_PATH}/${app}

    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 配置
        sed -i "s@^# export HBASE_MANAGES_ZK=.*@export HBASE_MANAGES_ZK=false@" ${INSTALL_PATH}/${app}/conf/hbase-env.sh
        sed -i "s@^# export JAVA_HOME=.*@export JAVA_HOME=${INSTALL_PATH}/java@" ${INSTALL_PATH}/${app}/conf/hbase-env.sh
        setkv "hbase.rootdir=hdfs://${HOST_NAME}:9000/hbase" ${INSTALL_PATH}/${app}/conf/hbase-site.xml
        setkv "hbase.zookeeper.quorum=${HOST_NAME}" ${INSTALL_PATH}/${app}/conf/hbase-site.xml
        setkv "hbase.cluster.distributed=true" ${INSTALL_PATH}/${app}/conf/hbase-site.xml
        setkv "phoenix.schema.isNamespaceMappingEnabled=true" ${INSTALL_PATH}/${app}/conf/hbase-site.xml
        setkv "phoenix.schema.mapSystemTablesToNamespace=true" ${INSTALL_PATH}/${app}/conf/hbase-site.xml
        echo -e "${HOST_NAME}" > ${INSTALL_PATH}/${app}/conf/regionservers
        # 添加环境变量
        setenv ${app} ${INSTALL_PATH}/${app}
    fi
}

install_phoenix()
{
    local app=phoenix
    download_and_unzip_app ${app}

    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 配置
        cp ${INSTALL_PATH}/${app}/phoenix*server*jar ${INSTALL_PATH}/hbase/lib
        cp ${INSTALL_PATH}/hbase/conf/hbase-site.xml ${INSTALL_PATH}/phoenix/bin
        # 添加环境变量
        setenv ${app} ${INSTALL_PATH}/${app}
    fi
}

install_kafka()
{
    local app=kafka
    download_and_unzip_app ${app}

    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 配置
        value="PLAINTEXT://${HOST_NAME}:9092"
        sed -i 's@^#listeners=.*@listeners='${value}'@' ${INSTALL_PATH}/${app}/config/server.properties
        sed -i 's@^#advertised.listeners=.*@advertised.listeners='${value}'@' ${INSTALL_PATH}/${app}/config/server.properties
        sed -i "s@^zookeeper.connect=.*@zookeeper.connect=${HOST_NAME}:2181/kafka@" ${INSTALL_PATH}/${app}/config/server.properties
        sed -i "s@^zookeeper.connect=.*@zookeeper.connect=${HOST_NAME}:2181@" ${INSTALL_PATH}/${app}/config/consumer.properties
        sed -i "s@^bootstrap.servers=.*@bootstrap.servers=${HOST_NAME}:9092@" ${INSTALL_PATH}/${app}/config/producer.properties


        # 添加环境变量
        setenv ${app} ${INSTALL_PATH}/${app}
    fi
}

install_tez()
{
    local app=tez
    download_and_unzip_app ${app}

    if [ -d ${INSTALL_PATH}/${app} ]
    then
        # 配置
        setkv 'tez.lib.uris=${fs.defaultFS}/tez/0.8.4/tez.tar.gz' ${INSTALL_PATH}/hive/conf/tez-site.xml true
        setkv "tez.container.max.java.heap.fraction=0.2" ${INSTALL_PATH}/hive/conf/tez-site.xml
        rm -rf ${INSTALL_PATH}/tez/lib/slf4j-log4j12-*.jar
        # 添加环境变量
        echo "# tez environment"
        echo "export TEZ_CONF_DIR=${INSTALL_PATH}/hive/conf" >> $PROFILE
        echo "export TEZ_JARS=${INSTALL_PATH}/tez/*:${INSTALL_PATH}/tez/lib/*" >> $PROFILE
        echo 'export HADOOP_CLASSPATH=$TEZ_CONF_DIR:$TEZ_JARS:$HADOOP_CLASSPATH' >> $PROFILE
        echo -e "\n" >> $PROFILE
    fi
}

install_init
install_jdk221
install_hadoop
install_mysql
install_ssh
install_hive
install_scala
install_spark
install_zk
install_hbase
install_phoenix
install_kafka
install_tez
