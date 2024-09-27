#!/bin/bash
bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`
DEFAULT_DOWNLOAD_DIR="$bin"/download
DEFAULT_DOWNLOAD_DIR=${DEFAULT_DOWNLOAD_DIR:-$DEFAULT_DOWNLOAD_DIR}
[ ! -d $DEFAULT_DOWNLOAD_DIR ] && mkdir -p $DEFAULT_DOWNLOAD_DIR
INSTALL_PATH=/root/software
HOST_NAME=bigdata
PROFILE=/etc/profile
JAVA_URL=https://qingjiao-image-build-assets.oss-cn-beijing.aliyuncs.com/centos_7_hadoop3.1.3/jdk-8u212-linux-x64.tar.gz
HADOOP_URL=https://mirrors.huaweicloud.com/apache/hadoop/common/hadoop-3.1.3/hadoop-3.1.3.tar.gz
HIVE_URL=https://qingjiao-image-build-assets.oss-cn-beijing.aliyuncs.com/centos_7_hadoop3.1.3/apache-hive-3.1.2-bin.tar.gz
SCALA_URL=https://downloads.lightbend.com/scala/2.12.11/scala-2.12.11.tgz
SPARK_URL=https://mirrors.huaweicloud.com/apache/spark/spark-3.0.0/spark-3.0.0-bin-without-hadoop.tgz
ZOOKEEPER_URL=https://mirrors.huaweicloud.com/apache/zookeeper/zookeeper-3.5.7/apache-zookeeper-3.5.7-bin.tar.gz
KAFKA_URL=https://mirrors.huaweicloud.com/apache/kafka/2.4.1/kafka_2.12-2.4.1.tgz
SQOOP_URL=https://mirrors.huaweicloud.com/apache/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
FLUME_URL=https://mirrors.huaweicloud.com/apache/flume/1.11.0/apache-flume-1.11.0-bin.tar.gz
FLINK_URL=https://mirrors.huaweicloud.com/apache/flink/flink-1.14.0/flink-1.14.0-bin-scala_2.12.tgz

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

    if [ "$app_name" == "hadoop" ];then
        # 部署FLink On Yarn的时候用到的，但是会导致Hive产生大量info日志，所以先屏蔽掉
        # echo 'export HADOOP_CLASSPATH=`hadoop classpath`' >> $PROFILE
        echo 'export HDFS_NAMENODE_USER=root' >> $PROFILE
        # 指定Hadoop各个进程节点在启动时使用root用户身份运行，解决Hadoop各进程节点启动找不到用户问题
        echo 'export HDFS_DATANODE_USER=root' >> $PROFILE
        echo 'export HDFS_SECONDARYNAMENODE_USER=root' >> $PROFILE
        echo 'export YARN_RESOURCEMANAGER_USER=root' >> $PROFILE
        echo 'export YARN_NODEMANAGER_USER=root' >> $PROFILE
        echo 'export HDFS_JOURNALNODE_USER=root' >> $PROFILE
        echo 'export HDFS_ZKFC_USER=root' >> $PROFILE
    fi
    echo -e "\n" >> $PROFILE
    source $PROFILE
}

get_app_dir(){
    local url=$1
    if [[ $url =~ "tgz" ]];then
        filename=$(echo $url | awk -F'/' '{print $NF}' | sed 's/\.tgz//')
    else
        filename=$(echo $url | awk -F'/' '{print $NF}' | sed 's/\.tar\.gz//')
    fi
    echo $filename
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
    # if [[ $file =~ "tgz" ]];then
    #     mv ${INSTALL_PATH}/${file%.*} ${INSTALL_PATH}/${app}
    # else
    #     mv ${INSTALL_PATH}/${file%%.tar*} ${INSTALL_PATH}/${app}
    # fi
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
    # rpm -ivh https://opensource.wandisco.com/git/wandisco-git-release-7-2.noarch.rpm
    # yum install -y -q git
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
    echo "192.168.10.222  ${HOST_NAME}" >> /etc/hosts

    # 修改DNS
    sed -i "s@^nameserver.*@nameserver 114.114.114.114@" /etc/resolv.conf

    # 创建安装目录
    mkdir ${INSTALL_PATH}
    # chown -R vagrant:vagrant /opt/
    complete_url=https://gitee.com/yiluohan1234/vagrant_bigdata_cluster/raw/master/resources/single_node/complete_tool.sh
    bigstart_url=https://gitee.com/yiluohan1234/vagrant_bigdata_cluster/raw/master/resources/single_node/bigstart313
    curl -o /vagrant/complete_tool.sh -O -L ${complete_url}
    curl -o /vagrant/bigstart -O -L ${bigstart_url}
    # wget -P /vagrant/ ${complete_url}
    # wget -P /vagrant/ ${bigstart_url}

    [ -f /vagrant/bigstart ] && cp /vagrant/bigstart /usr/bin && chmod a+x /usr/bin/bigstart
    [ -f /vagrant/complete_tool.sh ] && cp /vagrant/complete_tool.sh /etc/profile.d
    rm -rf /root/anaconda-ks.cfg
    rm -rf /root/original-ks.cfg
}

install_jdk() {
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
        curl -o ${DEFAULT_DOWNLOAD_DIR}/${file} -O -L ${url}
    fi
    tar -zxf ${DEFAULT_DOWNLOAD_DIR}/${file} -C ${INSTALL_PATH}
    if [ -d ${INSTALL_PATH}/jdk1.8.0_212 ]
    then
        # 添加环境变量
        echo "# jdk environment" >> $PROFILE
        echo "export JAVA_HOME=${INSTALL_PATH}/jdk1.8.0_212" >> $PROFILE
        echo 'export PATH=${JAVA_HOME}/bin:$PATH' >> $PROFILE
        echo -e "\n" >> $PROFILE
        source $PROFILE
    fi
}

install_hadoop() {
    local app=hadoop
    local app_name_upper=${app^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local app_dir=${INSTALL_PATH}/`get_app_dir $url`
    download_and_unzip_app ${app}

    if [ -d ${app_dir} ]
    then
        # 配置 hadoop-env.sh core-site.xml hdfs-site.xml yarn-site.xml mapred-site.xml slaves
        echo "export JAVA_HOME=${INSTALL_PATH}/jdk1.8.0_212" >> ${app_dir}/etc/hadoop/hadoop-env.sh
        setkv "fs.defaultFS=hdfs://${HOST_NAME}:8020" ${app_dir}/etc/hadoop/core-site.xml
        setkv "hadoop.tmp.dir=${app_dir}/hadoopDatas" ${app_dir}/etc/hadoop/core-site.xml
        # 缓冲区大小，实际工作中根据服务器性能动态调整；默认值4096
        setkv "io.file.buffer.size=4096" ${app_dir}/etc/hadoop/core-site.xml
        # 开启HDFS的垃圾桶机制，删除掉的数据可以从垃圾桶中回收，单位分钟；默认值0
        setkv "fs.trash.interval=10080" ${app_dir}/etc/hadoop/core-site.xml
        # 配置代理用户提交任务到集群
        setkv "hadoop.proxyuser.root.hosts=*" ${app_dir}/etc/hadoop/core-site.xml
        setkv "hadoop.proxyuser.root.groups=*" ${app_dir}/etc/hadoop/core-site.xml
        setkv "hadoop.http.staticuser.user=root" ${app_dir}/etc/hadoop/core-site.xml
        setkv "hadoop.security.authorization=true" ${app_dir}/etc/hadoop/core-site.xml
        setkv "dfs.namenode.http-address=${HOST_NAME}:9870" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.namenode.secondary.http-address=${HOST_NAME}:9868" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.datanode.name.dir=${app_dir}/hadoopDatas/namenodeDatas" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.datanode.data.dir=${app_dir}/hadoopDatas/datanodeDatas" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.namenode.edits.dir=${app_dir}/hadoopDatas/dfs/nn/edits" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.namenode.checkpoint.dir=${app_dir}/hadoopDatas/dfs/snn/name" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.namenode.checkpoint.edits.dir=${app_dir}/hadoopDatas/dfs/nn/snn/edits" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.replication=1" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.permissions.enabled=true" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.webhdfs.enabled=true" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "dfs.permissions.superusergroup=root" ${app_dir}/etc/hadoop/hdfs-site.xml
        setkv "yarn.nodemanager.aux-services=mapreduce_shuffle" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.resourcemanager.hostname=${HOST_NAME}" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.resourcemanager.bind-host=${HOST_NAME}" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.nodemanager.bind-host=${HOST_NAME}" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.resourcemanager.webapp.address=0.0.0.0:0" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.resourcemanager.webapp.https.address=0.0.0.0:0" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.nodemanager.webapp.address=0.0.0.0:0" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.nodemanager.webapp.https.address=0.0.0.0:0" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.nodemanager.env-whitelist=JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.nodemanager.pmem-check-enabled=false" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.scheduler.minimum-allocation-mb=512" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.scheduler.maximum-allocation-mb=4096" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.nodemanager.resource.memory-mb=4096" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.nodemanager.vmem-check-enabled=false" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.log-aggregation-enable=true" ${app_dir}/etc/hadoop/yarn-site.xml
        setkv "yarn.log.server.url=http://${HOST_NAME}:19888/jobhistory/logs" ${app_dir}/etc/hadoop/yarn-site.xml

        # cp ${app_dir}/etc/hadoop/mapred-site.xml.template ${app_dir}/etc/hadoop/mapred-site.xml
        setkv "mapreduce.framework.name=yarn" ${app_dir}/etc/hadoop/mapred-site.xml
        setkv "mapreduce.jobhistory.address=${HOST_NAME}:10020" ${app_dir}/etc/hadoop/mapred-site.xml
        setkv "mapreduce.jobhistory.webapp.address=${HOST_NAME}:19888" ${app_dir}/etc/hadoop/mapred-site.xml
        setkv "yarn.app.mapreduce.am.env=HADOOP_MAPRED_HOME=${app_dir}" ${app_dir}/etc/hadoop/mapred-site.xml
        setkv "mapreduce.map.env=HADOOP_MAPRED_HOME=${app_dir}" ${app_dir}/etc/hadoop/mapred-site.xml
        setkv "mapreduce.reduce.env=HADOOP_MAPRED_HOME=${app_dir}" ${app_dir}/etc/hadoop/mapred-site.xml
        # slaves
        echo -e "${HOST_NAME}" > ${app_dir}/etc/hadoop/workers
        echo "export JAVA_HOME=${INSTALL_PATH}/jdk1.8.0_212" >> ${app_dir}/etc/hadoop/yarn-env.sh
        # 添加环境变量
        setenv ${app} ${app_dir} sbin
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
        GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION; \
        flush privileges;" --connect-expired-password

    # 删除
    yum -y remove mysql57-community-release-el7-11.noarch
    rm -rf /root/mysql57-community-release-el7-11.noarch.rpm

}

install_ssh() {
    local HOSTNAME_LIST=("${HOST_NAME}" "localhost")
    local PASSWD_LIST=("vagrant" "vagrant"vi )
    if [ `yum list installed |grep expect |wc -l` == 0 ];then
        # yum install -y -q expect
        curl -o /root/expect-5.45-14.el7_1.x86_64.rpm -O -L https://gitee.com/yiluohan1234/vagrant_bigdata_cluster/raw/master/resources/bdcompetition/other/expect-5.45-14.el7_1.x86_64.rpm
        curl -o /root/tcl-8.5.13-8.el7.x86_64.rpm -O -L https://gitee.com/yiluohan1234/vagrant_bigdata_cluster/raw/master/resources/bdcompetition/other/tcl-8.5.13-8.el7.x86_64.rpm
        yum install -y -q /root/tcl-8.5.13-8.el7.x86_64.rpm
        yum install -y -q /root/expect-5.45-14.el7_1.x86_64.rpm
        rm -rf /root/*.rpm
    fi
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
    local app_name_upper=${app^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local app_dir=${INSTALL_PATH}/`get_app_dir $url`

    download_and_unzip_app ${app}

    if [ -d ${app_dir} ]
    then
        # 配置 hive-site.xml
        setkv "javax.jdo.option.ConnectionURL=jdbc:mysql://${HOST_NAME}:3306/hivedb?createDatabaseIfNotExist=true&amp;useSSL=false&amp;useUnicode=true&amp;characterEncoding=UTF-8" ${app_dir}/conf/hive-site.xml true
        setkv "javax.jdo.option.ConnectionDriverName=com.mysql.jdbc.Driver" ${app_dir}/conf/hive-site.xml
        setkv "javax.jdo.option.ConnectionUserName=root" ${app_dir}/conf/hive-site.xml
        setkv "javax.jdo.option.ConnectionPassword=123456" ${app_dir}/conf/hive-site.xml
        setkv "hive.cli.print.current.db=true" ${app_dir}/conf/hive-site.xml
        setkv "hive.cli.print.header=true" ${app_dir}/conf/hive-site.xml
        setkv "spark.yarn.jars=hdfs://${HOST_NAME}:8020/spark/jars/*" ${app_dir}/conf/hive-site.xml
        setkv "hive.metastore.schema.verification=false" ${app_dir}/conf/hive-site.xml
        setkv "datanucleus.schema.autoCreateALL=true" ${app_dir}/conf/hive-site.xml
        setkv "hive.execution.engine=spark" ${app_dir}/conf/hive-site.xml
        setkv "hive.spark.client.connect.timeout=10000ms" ${app_dir}/conf/hive-site.xml
        setkv "hive.metastore.uris=thrift://${HOST_NAME}:9083" ${app_dir}/conf/hive-site.xml
        setkv "hive.server2.thrift.port=10000" ${app_dir}/conf/hive-site.xml
        setkv "hive.server2.thrift.bind.host=${HOST_NAME}" ${app_dir}/conf/hive-site.xml

        setkv "hive.metastore.local=false" ${app_dir}/conf/hive-site.xml
        setkv "hive.exec.mode.local.auto=true" ${app_dir}/conf/hive-site.xml
        setkv "hive.strict.checks.cartesian.product=false" ${app_dir}/conf/hive-site.xml
        setkv "hive.exec.dynamic.partition=true" ${app_dir}/conf/hive-site.xml
        setkv "hive.exec.dynamic.partition.mode=nonstrict" ${app_dir}/conf/hive-site.xml


        wget_mysql_connector ${app_dir}/lib
        mv ${app_dir}/lib/log4j-slf4j-impl-2.10.0.jar ${app_dir}/lib/log4j-slf4j-impl-2.10.0.jar_bak
        mv ${app_dir}/lib/guava-19.0.jar ${app_dir}/lib/guava-19.0.jar_bak
        cp ${HADOOP_HOME}/share/hadoop/common/lib/guava-27.0-jre.jar ${app_dir}/lib/
        # 添加环境变量
        setenv ${app} ${app_dir}
    fi
}

install_scala()
{
    local app=scala
    local app_name_upper=${app^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local app_dir=${INSTALL_PATH}/`get_app_dir $url`
    download_and_unzip_app ${app}

    if [ -d ${app_dir} ]
    then
        # 添加环境变量
        setenv ${app} ${app_dir}
    fi
}

install_spark()
{
    local app=spark
    local app_name_upper=${app^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local app_dir=${INSTALL_PATH}/`get_app_dir $url`
    download_and_unzip_app ${app}

    if [ -d ${app_dir} ]
    then
        # 配置
        cp ${app_dir}/conf/spark-env.sh.template ${app_dir}/conf/spark-env.sh
        echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ${app_dir}/conf/spark-env.sh
        echo 'export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ${app_dir}/conf/spark-env.sh
        echo 'export SPARK_DIST_CLASSPATH=$('${INSTALL_PATH}'/hadoop-3.3.3/bin/hadoop classpath)' >> ${app_dir}/conf/spark-env.sh

        cp ${app_dir}/conf/spark-defaults.conf.template ${app_dir}/conf/spark-defaults.conf
        echo "spark.master                     yarn" >> ${app_dir}/conf/spark-defaults.conf
        echo "spark.eventLog.enabled           true" >> ${app_dir}/conf/spark-defaults.conf
        echo "spark.eventLog.dir               hdfs://${HOST_NAME}:8020/spark/log" >> ${app_dir}/conf/spark-defaults.conf
        echo "spark.executor.memory            1g" >> ${app_dir}/conf/spark-defaults.conf
        echo "spark.driver.memory              1g" >> ${app_dir}/conf/spark-defaults.conf

        cp ${app_dir}/conf/slaves.template ${app_dir}/conf/slaves
        echo "${HOST_NAME}" > ${app_dir}/conf/slaves
        wget_mysql_connector ${app_dir}/jars
        # 添加环境变量
        setenv ${app} ${app_dir}
    fi
}

install_zk()
{
    local app=zookeeper
    local app_name_upper=${app^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local app_dir=${INSTALL_PATH}/`get_app_dir $url`
    download_and_unzip_app ${app}

    if [ -d ${app_dir} ]
    then
        # 配置
        cp  ${app_dir}/conf/zoo_sample.cfg ${app_dir}/conf/zoo.cfg
        sed -i "s@^dataDir=.*@dataDir=${app_dir}/data@" ${app_dir}/conf/zoo.cfg
        sed -i "/dataDir/ a\dataLogDir=${app_dir}/log" ${app_dir}/conf/zoo.cfg

        mkdir -p ${app_dir}/data
        echo "1" >> ${app_dir}/data/myid
        # 添加环境变量
        setenv ${app} ${app_dir}
    fi
}

install_kafka()
{
    local app=kafka
    local app_name_upper=${app^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local app_dir=${INSTALL_PATH}/`get_app_dir $url`
    download_and_unzip_app ${app}

    if [ -d ${app_dir} ]
    then
        # 配置
        value="PLAINTEXT://${HOST_NAME}:9092"
        sed -i 's@^broker.id=.*@broker.id=1@' ${app_dir}/config/server.properties
        sed -i 's@^#listeners=.*@listeners='${value}'@' ${app_dir}/config/server.properties
        sed -i 's@^#advertised.listeners=.*@advertised.listeners='${value}'@' ${app_dir}/config/server.properties
        sed -i "s@^log.dirs=.*@log.dirs=${app_dir}/logs@" ${app_dir}/config/server.properties
        sed -i "s@^zookeeper.connect=.*@zookeeper.connect=${HOST_NAME}:2181/kafka@" ${app_dir}/config/server.properties
        sed -i "/zookeeper.connect/ a\delete.topic.enable=true\nauto.create.topics.enable=false" ${app_dir}/config/server.properties
        sed -i "s@^zookeeper.connect=.*@zookeeper.connect=${HOST_NAME}:2181@" ${app_dir}/config/consumer.properties
        sed -i "s@^bootstrap.servers=.*@bootstrap.servers=${HOST_NAME}:9092@" ${app_dir}/config/producer.properties

        # 添加环境变量
        setenv ${app} ${app_dir}
    fi
}

install_sqoop() {
    local app=sqoop
    local app_name_upper=${app^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local app_dir=${INSTALL_PATH}/`get_app_dir $url`
    download_and_unzip_app ${app}

    if [ -d ${app_dir} ]
    then
        cp ${app_dir}/conf/sqoop-env-template.sh ${app_dir}/conf/sqoop-env.sh
        sed -i "s@^#export HADOOP_COMMON_HOME=.*@HADOOP_COMMON_HOME=${INSTALL_PATH}/hadoop-3.3.3@" ${app_dir}/conf/sqoop-env.sh
        sed -i "s@^#export HADOOP_MAPRED_HOME=.*@HADOOP_MAPRED_HOME=${INSTALL_PATH}/hadoop-3.3.3@" ${app_dir}/conf/sqoop-env.sh
        sed -i "s@^#export HIVE_HOME=.*@HIVE_HOME=${INSTALL_PATH}/apache-hive-3.1.2-bin@" ${app_dir}/conf/sqoop-env.sh
        wget_mysql_connector ${app_dir}/lib/

        # 添加环境变量
        setenv ${app} ${app_dir}
    fi
}

install_flume() {
    local app=flume
    local app_name_upper=${app^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local app_dir=${INSTALL_PATH}/`get_app_dir $url`
    download_and_unzip_app ${app}

    if [ -d ${app_dir} ]
    then
        cp ${app_dir}/conf/flume-env.sh.template ${app_dir}/conf/flume-env.sh
        sed -i "s@^# export JAVA_HOME=.*@export JAVA_HOME=${INSTALL_PATH}/jdk1.8.0_212@" ${app_dir}/conf/flume-env.sh

        # 添加环境变量
        setenv ${app} ${app_dir}
    fi
}

install_flink() {
    local app=flink
    local app_name_upper=${app^^}
    local url=$(eval echo \$${app_name_upper}_URL)
    local app_dir=${INSTALL_PATH}/`get_app_dir $url`
    download_and_unzip_app ${app}

    if [ -d ${app_dir} ]
    then

        # 添加环境变量
        setenv ${app} ${app_dir}
    fi
}
install_init
install_jdk
install_hadoop
install_mysql
install_ssh
install_hive
install_scala
install_spark
install_zk
install_kafka
install_sqoop
install_flume
install_flink
