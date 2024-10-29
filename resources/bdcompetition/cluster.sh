# basic
# IP_LIST=("192.168.10.101" "192.168.10.102" "192.168.10.103")
IP_LIST=("ips" "ips" "ips")
HOSTNAME_LIST=("master" "slave1" "slave2")
PASSWD_LIST=('passwd' 'passwd' 'passwd')
INSTALL_PATH=/usr
PROFILE=/etc/profile
# 2.7.7版本
SOFT_PATH=/usr/package277
# 3.1.3版本
SOFTWARE_PATH=/root/software/package
DATA_PATH=/usr/etx.txt
IS_XCALL=false

setvar(){
# 定义三个空数组来存储内部IP、主机名和密码
local ip_list=()
local hostname_list=()
local passwd_list=()

while IFS=',' read -r hostname internal_ip public_ip password; do
    if [[ $hostname == "master" || $hostname == "slave1" || $hostname == "slave2" || $hostname == "node01" || $hostname == "node02" || $hostname == "node03" ]];then
        ip_list+=("$internal_ip")
        hostname_list+=("$hostname")
        passwd_list+=("$password")
    fi
done < ${DATA_PATH}

ip_list_str="IP_LIST=("
for ip in "${ip_list[@]}"; do
    ip_list_str+="'$ip' "
done
ip_list_str=${ip_list_str% *} # 移除最后一个多余的空格
ip_list_str+=")"

host_list_str="HOSTNAME_LIST=("
for host in "${hostname_list[@]}"; do
    host_list_str+="'$host' "
done
host_list_str=${host_list_str% *} # 移除最后一个多余的空格
host_list_str+=")"

passwd_list_str="PASSWD_LIST=("
for host in "${passwd_list[@]}"; do
    passwd_list_str+="'`escape_special_chars $host`' "
done
passwd_list_str=${passwd_list_str% *} # 移除最后一个多余的空格
passwd_list_str+=")"

sed -i "s@^IP_LIST=.*@$ip_list_str@" /etc/profile.d/my.sh
sed -i "s@^HOSTNAME_LIST=.*@$host_list_str@" /etc/profile.d/my.sh
sed -i "s@^PASSWD_LIST=.*@$passwd_list_str@" /etc/profile.d/my.sh
}

escape_special_chars() {
# 函数，用于检查字符串是否包含特殊字符并转义
local input_str="$1"
local escaped_str=""
special_char=('@' '!' '$' '&')

for ((i=0; i<${#input_str}; i++)); do
    # 检查当前字符是否在特殊字符数组中
    if [[ " ${special_char[*]} " =~ "${input_str:i:1} " ]]; then
        # 如果包含特殊字符，则转义
        escaped_str+="\\"
    fi
    # 将当前字符添加到转义后的字符串中
    escaped_str+="${input_str:i:1}"
done
echo "$escaped_str"
}

setip() {
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    entry="${IP_LIST[$i]} ${HOSTNAME_LIST[$i]}"
    echo "${entry}" >> /etc/hosts
done
hostset_ip_local_num=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|grep 192|wc -l`
if [ ${hostset_ip_local_num} == 0 ];then
    hostset_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'`
else
    hostset_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|grep 192`
fi
hostset_name=`cat /etc/hosts|grep $hostset_ip|tail -1|awk '{print $2}'`
hostnamectl set-hostname $hostset_name
# bash
}

settimezone() {
echo "setup timezone"
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    echo -e "\033[31m--------- Current ${HOSTNAME_LIST[$i]} timezone is UTC ----------\033[0m"
    ssh ${HOSTNAME_LIST[$i]} "date"
    ssh ${HOSTNAME_LIST[$i]} "timedatectl set-timezone Asia/Shanghai"
    echo -e "\033[31m--------- Current ${HOSTNAME_LIST[$i]} timezone is Asia/Shanghai ----------\033[0m"
    ssh ${HOSTNAME_LIST[$i]} "date"
done
}

setntp() {
echo "setup ntp"
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    echo -e "\033[31m--------- ${HOSTNAME_LIST[$i]} set ntp ----------\033[0m"
    ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setup_ntp"
done
}

setup_ntp() {
systemctl stop firewalld
sed -i "s@^SELINUX=.*@SELINUX=disabled@g" /etc/selinux/config
if [ `yum list installed |grep ntp |wc -l` == 0 ];then
    yum install -y -q ntp
fi

current_hostname=`cat /etc/hostname`
# master
if [ "$current_hostname" == "${HOSTNAME_LIST[0]}" ];then
    sed -i '/centos.pool.ntp.org iburst/s/^/#/g' /etc/ntp.conf
    # sed -i 's/^server/#&/'  /etc/ntp.conf
    echo "server 127.127.1.0
fudge 127.127.1.0 stratum 10" >> /etc/ntp.conf
    # echo -e "server 127.127.1.0\nfudge 127.127.1.0 stratum 10" >> /etc/ntp.conf
    systemctl restart ntpd.service
fi

# slave1 and slave2
if [ "$current_hostname" != "${HOSTNAME_LIST[0]}" ];then
    ntpdate ${HOSTNAME_LIST[0]}
    (crontab -l;echo "*/30 10-17 * * * usr/sbin/ntpdate ${HOSTNAME_LIST[0]}")| crontab
    crontab -l
fi
}

setjava221() {
echo "setup java"
local java_dir=${INSTALL_PATH}/java/jdk1.8.0_221
mkdir ${INSTALL_PATH}/java
tar -zxf ${SOFT_PATH}/jdk-8u221-linux-x64.tar.gz -C ${INSTALL_PATH}/java/
#setenv java ${java_dir}
if [ "${IS_XCALL}" == "false" ];then
    # dispatch
    xsync ${java_dir}
    # set environment
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv java ${java_dir}"
    done
    source $PROFILE
    xcall java -version
else
    setenv java ${java_dir}
    source $PROFILE
    java -version
fi
}

setjava212() {
echo "setup java"
local java_dir=${INSTALL_PATH}/jdk1.8.0_212
tar -zxf ${SOFTWARE_PATH}/jdk-8u212-linux-x64.tar.gz -C ${INSTALL_PATH}/
#setenv java ${java_dir}
if [ "${IS_XCALL}" == "false" ];then
    # dispatch
    xsync ${java_dir}
    # set environment
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv java ${java_dir}"
    done
    source $PROFILE
    xcall java -version
else
    setenv java ${java_dir}
    source $PROFILE
    java -version
fi
}

setzk363() {
echo "setup zookeeper-3.6.3"
local zookeeper_dir=${INSTALL_PATH}/zookeeper/apache-zookeeper-3.6.3-bin
mkdir ${INSTALL_PATH}/zookeeper
tar -zxf ${SOFT_PATH}/apache-zookeeper-3.6.3-bin.tar.gz -C ${INSTALL_PATH}/zookeeper/
# setup
cp ${zookeeper_dir}/conf/zoo_sample.cfg ${zookeeper_dir}/conf/zoo.cfg
sed -i "s@^dataDir=.*@dataDir=${zookeeper_dir}/zkdata@" ${zookeeper_dir}/conf/zoo.cfg
echo "dataLogDir=${zookeeper_dir}/zkdatalog" >> ${zookeeper_dir}/conf/zoo.cfg
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    echo "server.$(($i+1))=${HOSTNAME_LIST[$i]}:2888:3888" >> ${zookeeper_dir}/conf/zoo.cfg
done
mkdir ${zookeeper_dir}/zkdata ${zookeeper_dir}/zkdatalog
# dispatch
xsync ${zookeeper_dir}
# set environment
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv zookeeper ${zookeeper_dir}"
    ssh ${HOSTNAME_LIST[$i]} "echo $(($i+1)) >> ${zookeeper_dir}/zkdata/myid"
done
source $PROFILE
zk start
jpsall
}

setzk314() {
echo "setup zookeeper-3.4.14"
local zookeeper_dir=${INSTALL_PATH}/zookeeper/zookeeper-3.4.14
mkdir ${INSTALL_PATH}/zookeeper
tar -zxf ${SOFT_PATH}/zookeeper-3.4.14.tar.gz -C ${INSTALL_PATH}/zookeeper/
# setup
cp ${zookeeper_dir}/conf/zoo_sample.cfg ${zookeeper_dir}/conf/zoo.cfg
sed -i "s@^dataDir=.*@dataDir=${zookeeper_dir}/zkdata@" ${zookeeper_dir}/conf/zoo.cfg
echo "dataLogDir=${zookeeper_dir}/zkdatalog" >> ${zookeeper_dir}/conf/zoo.cfg
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    echo "server.$(($i+1))=${HOSTNAME_LIST[$i]}:2888:3888" >> ${zookeeper_dir}/conf/zoo.cfg
done
mkdir ${zookeeper_dir}/zkdata ${zookeeper_dir}/zkdatalog
# dispatch
xsync ${zookeeper_dir}
# set environment
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv zookeeper ${zookeeper_dir}"
    ssh ${HOSTNAME_LIST[$i]} "echo $(($i+1)) >> ${zookeeper_dir}/zkdata/myid"
done
source $PROFILE
zk start
jpsall
}

sethadoop() {
echo "setup hadoop"
local hadoop_dir=${INSTALL_PATH}/hadoop/hadoop-2.7.7
mkdir ${INSTALL_PATH}/hadoop
tar -zxf ${SOFT_PATH}/hadoop-2.7.7.tar.gz -C ${INSTALL_PATH}/hadoop/

# hadoop-env.sh
sed -i "s@^export JAVA_HOME=.*@export JAVA_HOME=${JAVA_HOME}@" ${hadoop_dir}/etc/hadoop/hadoop-env.sh

# core-site.xml
setkv "fs.default.name=hdfs://${HOSTNAME_LIST[0]}:9000" ${hadoop_dir}/etc/hadoop/core-site.xml
setkv "hadoop.tmp.dir=/root/hadoopData/tmp" ${hadoop_dir}/etc/hadoop/core-site.xml

# hdfs-site.xml
setkv "dfs.replication=2" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.namenode.name.dir=/root/hadoopData/name" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.datanode.data.dir=/root/hadoopData/data" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.permissions=false" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.datanode.use.datanode.hostname=true" ${hadoop_dir}/etc/hadoop/hdfs-site.xml

# yarn-env.sh
echo "export JAVA_HOME=${JAVA_HOME}" >> ${hadoop_dir}/etc/hadoop/yarn-env.sh

# yarn-site.xml
setkv "yarn.resourcemanager.admin.address=${HOSTNAME_LIST[0]}:18141" ${hadoop_dir}/etc/hadoop/yarn-site.xml
setkv "yarn.nodemanager.auxservices.mapreduce.shuffle.class=org.apache.hadoop.mapred.shuffleHandler" ${hadoop_dir}/etc/hadoop/yarn-site.xml
setkv "yarn.nodemanager.aux-services=mapreduce_shuffle" ${hadoop_dir}/etc/hadoop/yarn-site.xml
setkv "yarn.resourcemanager.hostname=${HOSTNAME_LIST[0]}" ${hadoop_dir}/etc/hadoop/yarn-site.xml

# mapred-site.xml
cp ${hadoop_dir}/etc/hadoop/mapred-site.xml.template ${hadoop_dir}/etc/hadoop/mapred-site.xml
setkv "mapreduce.framework.name=yarn" ${hadoop_dir}/etc/hadoop/mapred-site.xml

# master and slaves
echo "${HOSTNAME_LIST[0]}" >> ${hadoop_dir}/etc/hadoop/master
sed -i '1,$d' ${hadoop_dir}/etc/hadoop/slaves
echo "${HOSTNAME_LIST[1]}
${HOSTNAME_LIST[2]}" >> ${hadoop_dir}/etc/hadoop/slaves
# echo -e "${HOSTNAME_LIST[1]}\n${HOSTNAME_LIST[2]}" >> ${hadoop_dir}/etc/hadoop/slaves

if [ "${IS_XCALL}" == "false" ];then
    # dispatch
    xsync ${hadoop_dir}

    # set environment
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv hadoop ${hadoop_dir} true"
    done
    source $PROFILE
    hadoop namenode -format
    ${HADOOP_HOME}/sbin/start-all.sh
    jpsall
else
    setenv hadoop ${hadoop_dir} true
    source $PROFILE
fi
}

sethadoop313() {
echo "setup hadoop313"
local hadoop_dir=${INSTALL_PATH}/hadoop-3.1.3
tar -zxf ${SOFTWARE_PATH}/hadoop-3.1.3.tar.gz -C ${INSTALL_PATH}/

# hadoop-env.sh
sed -i "s@^# export JAVA_HOME.*@export JAVA_HOME=${JAVA_HOME}@" ${hadoop_dir}/etc/hadoop/hadoop-env.sh
echo "export HDFS_NAMENODE_USER=root" >>${hadoop_dir}/etc/hadoop/hadoop-env.sh
echo "export HDFS_DATANODE_USER=root" >>${hadoop_dir}/etc/hadoop/hadoop-env.sh
echo "export HDFS_SECONDARYNAMENODE_USER=root" >>${hadoop_dir}/etc/hadoop/hadoop-env.sh
echo "export YARN_RESOURCEMANAGER_USER=root" >>${hadoop_dir}/etc/hadoop/hadoop-env.sh
echo "export YARN_NODEMANAGER_USER=root" >>${hadoop_dir}/etc/hadoop/hadoop-env.sh

# core-site.xml
setkv "fs.default.name=hdfs://${HOSTNAME_LIST[0]}:9000" ${hadoop_dir}/etc/hadoop/core-site.xml
setkv "hadoop.tmp.dir=${hadoop_dir}/data" ${hadoop_dir}/etc/hadoop/core-site.xml
setkv "hadoop.http.staticuser.user=root" ${hadoop_dir}/etc/hadoop/core-site.xml
setkv "hadoop.proxyuser.root.hosts=*" ${hadoop_dir}/etc/hadoop/core-site.xml
setkv "hadoop.proxyuser.root.groups=*" ${hadoop_dir}/etc/hadoop/core-site.xml

# hdfs-site.xml
setkv "dfs.namenode.http-address=${HOSTNAME_LIST[0]}:9870" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.namenode.secondary.http-address=${HOSTNAME_LIST[2]}:9868" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.replication=2" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.namenode.name.dir=/var/bigdata/dfs/name" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.datanode.data.dir=/var/bigdata/dfs/data" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.permissions=false" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.datanode.use.datanode.hostname=true" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.namenode.heartbeat.recheck-interval=60000" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.permissions.enabled=true" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.webhdfs.enabled=true" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.permissions.superusergroup=root" ${hadoop_dir}/etc/hadoop/hdfs-site.xml

# yarn-env.sh
echo "export JAVA_HOME=${JAVA_HOME}" >> ${hadoop_dir}/etc/hadoop/yarn-env.sh

# yarn-site.xml
setkv "yarn.nodemanager.aux-services=mapreduce_shuffle" ${hadoop_dir}/etc/hadoop/yarn-site.xml
setkv "yarn.resourcemanager.hostname=${HOSTNAME_LIST[0]}" ${hadoop_dir}/etc/hadoop/yarn-site.xml
setkv "yarn.nodemanager.env-whitelist=JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME" ${hadoop_dir}/etc/hadoop/yarn-site.xml

# mapred-site.xml
setkv "mapreduce.framework.name=yarn" ${hadoop_dir}/etc/hadoop/mapred-site.xml
setkv "mapreduce.jobhistory.address=${HOSTNAME_LIST[0]}:10020" ${hadoop_dir}/etc/hadoop/mapred-site.xml
setkv "mapreduce.jobhistory.webapp.address=${HOSTNAME_LIST[0]}:19888" ${hadoop_dir}/etc/hadoop/mapred-site.xml
setkv "yarn.app.mapreduce.am.env=HADOOP_MAPRED_HOME=${hadoop_dir}" ${hadoop_dir}/etc/hadoop/mapred-site.xml
setkv "mapreduce.map.env=HADOOP_MAPRED_HOME=${hadoop_dir}" ${hadoop_dir}/etc/hadoop/mapred-site.xml
setkv "mapreduce.reduce.env=HADOOP_MAPRED_HOME=${hadoop_dir}" ${hadoop_dir}/etc/hadoop/mapred-site.xml

# workers
sed -i '1,$d' ${hadoop_dir}/etc/hadoop/workers
echo "${HOSTNAME_LIST[0]}
${HOSTNAME_LIST[1]}
${HOSTNAME_LIST[2]}" >> ${hadoop_dir}/etc/hadoop/workers

if [ "${IS_XCALL}" == "false" ];then
    # dispatch
    xsync ${hadoop_dir}

    # set environment
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv hadoop ${hadoop_dir} true"
    done
    source $PROFILE
    hadoop namenode -format
    ${HADOOP_HOME}/sbin/start-all.sh
    jpsall
else
    setenv hadoop ${hadoop_dir} true
    source $PROFILE
fi
}

setmysql() {
echo "setup mysql"
systemctl disable mysqld.service
systemctl start mysqld.service
grep "temporary password" /var/log/mysqld.log
PASSWORD=`grep 'temporary password' /var/log/mysqld.log|awk -F "root@localhost: " '{print $2}'`

PORT="3306"
USERNAME="root"
mysql -u${USERNAME} -p${PASSWORD} -e "set global validate_password_policy=0; set global validate_password_length=4; ALTER USER 'root'@'localhost' IDENTIFIED BY '123456'; create user 'root'@'%' identified by '123456'; grant all privileges on *.* to 'root'@'%' with grant option; flush privileges;" --connect-expired-password
}

sethive() {
echo "setup hive"
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    echo -e "\033[31m--------- ${HOSTNAME_LIST[$i]} set hive ----------\033[0m"
    ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setup_hive"
done
}

setup_hive(){
local hive_dir=${INSTALL_PATH}/hive/apache-hive-2.3.4-bin

current_hostname=`cat /etc/hostname`
# slave2
if [ "$current_hostname" == "${HOSTNAME_LIST[2]}" ];then
    setmysql
fi

# master and slave1
if [ "$current_hostname" == "${HOSTNAME_LIST[0]}" -o "$current_hostname" == "${HOSTNAME_LIST[1]}" ];then
    mkdir ${INSTALL_PATH}/hive
    tar -zxf ${SOFT_PATH}/apache-hive-2.3.4-bin.tar.gz -C ${INSTALL_PATH}/hive/
    setenv hive ${hive_dir}
    source $PROFILE

    # hive-env.sh
    cp ${hive_dir}/conf/hive-env.sh.template ${hive_dir}/conf/hive-env.sh
    echo "export HADOOP_HOME=${HADOOP_HOME}
export HIVE_CONF_DIR=${HIVE_HOME}/conf
export HIVE_AUX_JARS_PATH=${HIVE_HOME}/lib" >> ${hive_dir}/conf/hive-env.sh
    # echo -e "export HADOOP_HOME=${HADOOP_HOME}\nexport HIVE_CONF_DIR=${HIVE_HOME}/conf\nexport HIVE_AUX_JARS_PATH=${HIVE_HOME}/lib" >> ${hive_dir}/conf/hive-env.sh
    cp ${hive_dir}/lib/jline-2.12.jar ${HADOOP_HOME}/share/hadoop/yarn/lib
fi
# slave1
if [ "$current_hostname" == "${HOSTNAME_LIST[1]}" ];then
    # mysql driver
    cp ${SOFT_PATH}/mysql-connector-java-*.jar ${hive_dir}/lib/
    # hive-site.xml
    setkv "hive.metastore.warehouse.dir=/user/hive_remote/warehouse" ${hive_dir}/conf/hive-site.xml true
    setkv "javax.jdo.option.ConnectionURL=jdbc:mysql://${HOSTNAME_LIST[2]}:3306/hive?createDatabaseIfNotExist=true&amp;characterEncoding=UTF-8&amp;useSSL=false" ${hive_dir}/conf/hive-site.xml
    setkv "javax.jdo.option.ConnectionDriverName=com.mysql.jdbc.Driver" ${hive_dir}/conf/hive-site.xml
    setkv "javax.jdo.option.ConnectionUserName=root" ${hive_dir}/conf/hive-site.xml
    setkv "javax.jdo.option.ConnectionPassword=123456" ${hive_dir}/conf/hive-site.xml
    setkv "hive.metastore.schema.verification=false" ${hive_dir}/conf/hive-site.xml
    setkv "datanucleus.schema.autoCreateALL=true" ${hive_dir}/conf/hive-site.xml
fi

# master
if [ "$current_hostname" == "${HOSTNAME_LIST[0]}" ];then
    # hive-site.xml
    setkv "hive.metastore.warehouse.dir=/user/hive_remote/warehouse" ${hive_dir}/conf/hive-site.xml true
    setkv "hive.metastore.local=false" ${hive_dir}/conf/hive-site.xml
    setkv "hive.metastore.uris=thrift://${HOSTNAME_LIST[1]}:9083" ${hive_dir}/conf/hive-site.xml
fi
source $PROFILE
}

setscala211() {
echo "setup scala"
local scala_dir=${INSTALL_PATH}/scala/scala-2.11.11
mkdir ${INSTALL_PATH}/scala
tar -zxf ${SOFT_PATH}/scala-2.11.11.tgz -C ${INSTALL_PATH}/scala/

if [ "${IS_XCALL}" == "false" ];then
    # dispatch
    xsync ${scala_dir}
    # set environment
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv scala ${scala_dir}"
    done
    source $PROFILE
    xcall scala -version
else
    setenv scala ${scala_dir}
    source $PROFILE
    scala -version
fi
}

setscala210() {
echo "setup scala"
local scala_dir=${INSTALL_PATH}/scala/scala-2.10.6
mkdir ${INSTALL_PATH}/scala
tar -zxf ${SOFT_PATH}/scala-2.10.6.tgz -C ${INSTALL_PATH}/scala/

if [ "${IS_XCALL}" == "false" ];then
    # dispatch
    xsync ${scala_dir}
    # set environment
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv scala ${scala_dir}"
    done
    source $PROFILE
    xcall scala -version
else
    setenv scala ${scala_dir}
    source $PROFILE
    scala -version
fi
}

setspark() {
echo "setup spark"
local spark_dir=${INSTALL_PATH}/spark/spark-2.4.3-bin-hadoop2.7
mkdir ${INSTALL_PATH}/spark
tar -zxf ${SOFT_PATH}/spark-2.4.3-bin-hadoop2.7.tgz -C ${INSTALL_PATH}/spark/
# setup
cp ${spark_dir}/conf/spark-env.sh.template ${spark_dir}/conf/spark-env.sh
echo "export SPARK_MASTER_IP=${HOSTNAME_LIST[0]}
export SCALA_HOME=${SCALA_HOME}
export SPARK_WORKER_MEMORY=8g
export JAVA_HOME=${JAVA_HOME}
export HADOOP_HOME=${HADOOP_HOME}
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop" >> ${spark_dir}/conf/spark-env.sh

cp ${spark_dir}/conf/slaves.template ${spark_dir}/conf/slaves
sed -i '1,$d' ${spark_dir}/conf/slaves

echo "${HOSTNAME_LIST[1]}
${HOSTNAME_LIST[2]}" >> ${spark_dir}/conf/slaves

if [ "${IS_XCALL}" == "false" ];then
    # dispatch
    xsync ${spark_dir}
    # set environment
    length=${#HOSTNAME_LIST[@]}
    for ((i=0; i<$length; i++));do
        ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv spark ${spark_dir}"
    done
    source $PROFILE
    ${SPARK_HOME}/sbin/start-all.sh
    jpsall
else
    setenv spark ${spark_dir}
    source $PROFILE
fi
}

# set_property "fs.defaultFS=hdfs://master:9000" ${HADOOP_HOME}/etc/hadoop/core-site.xml true
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

setssh(){
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
    current_hostname=`cat /etc/hostname`
    for ((i=0; i<$length; i++));do
        # master
        if [ "$current_hostname" == "${HOSTNAME_LIST[$i]}" ];then
            expect -c "
            set timeout 5;
            spawn ssh-copy-id -i localhost;
            expect {
                \"*assword\" { send \"${PASSWD_LIST[$i]}\r\";exp_continue}
                \"yes/no\" { send \"yes\r\"; exp_continue }
                eof {exit 0;}
            }";
        fi
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
        echo 'CLASSPATH=$CLASSPATH:$HADOOP_HOME/lib' >> $PROFILE
    fi
    echo -e "\n" >> /etc/profile
}

jpsall() {
    for host in ${HOSTNAME_LIST[*]};
    do
        echo -e "\033[31m--------------------- $host host ---------------------\033[0m"
        ssh $host "${JAVA_HOME}/bin/jps" | grep -v Jps
    done
}

xsync() {
    pcount=$#
    if [ $pcount -eq 0 ]
    then
        echo "no parameter find !";
        exit;
    fi

    p1=$1
    filename=`basename $p1`
    echo "load file $p1 success !"

    pdir=`cd -P $(dirname $p1); pwd`
    echo "file path is $pdir"

    user=`whoami`

    for host in ${HOSTNAME_LIST[*]};
    do
        current_hostname=`cat /etc/hostname`
        if [ "$current_hostname" != "$host" ];then
            echo "================current host is $host================="
            #rsync -rvl $pdir/$filename $user@$host:$pdir
            rsync -rl $pdir/$filename $user@$host:$pdir
        fi
        source /etc/profile
    done

    echo "complate !"
}

hdp(){
    usage="Usage: $0 (start|stop|format)"

    if [ $# -lt 1 ]; then
        echo $usage
        exit 1
    fi
    case $1 in
        start)
            ssh ${HOSTNAME_LIST[0]} "source /etc/profile;${HADOOP_HOME}/sbin/start-all.sh"
            ;;
        stop)
            ssh ${HOSTNAME_LIST[0]} "source /etc/profile;${HADOOP_HOME}/sbin/stop-all.sh"
            ;;
        restart)
            hadoop stop
            hadoop start
            ;;
        format)
            ssh ${HOSTNAME_LIST[0]} "source /etc/profile;${HADOOP_HOME}/bin/hdfs namenode -format"
            ;;
        init)
            schematool -dbType mysql -initSchema
            ;;
        meta)
            nohup hive --service metastore > /dev/null 2>&1 &
            ;;
        create)
            hive -e "create database if not exists $2"
            ;;
        *)
            echo $usage
            ;;
    esac
}

zk(){
    usage="Usage: $0 (start|stop|status)"

    if [ $# -lt 1 ]; then
        echo $usage
        exit 1
    fi
    case $1 in
        start)
            for i in ${HOSTNAME_LIST[*]};
            do
                echo "-----$1 $i zookeeper-------"
                ssh $i "source /etc/profile;${ZOOKEEPER_HOME}/bin/zkServer.sh start"
            done
            ;;
        stop)
            for i in ${HOSTNAME_LIST[*]};
            do
                echo "------$1 $i zookeeper-------"
                ssh $i "source /etc/profile;${ZOOKEEPER_HOME}/bin/zkServer.sh stop"
            done
            ;;
        status)
            for i in ${HOSTNAME_LIST[*]};
            do
                echo "------$i status-------"
                ssh $i "source /etc/profile;${ZOOKEEPER_HOME}/bin/zkServer.sh status"
            done
            ;;
        *)
            echo $usage
            ;;
    esac
}

kafka(){
    usage="Usage: $0 (start|stop)"

    if [ $# -lt 1 ]; then
        echo $usage
        exit 1
    fi
    case $1 in
        start)
            for i in ${HOSTNAME_LIST[*]};
            do
                echo "-----$1 $i kafka-------"
                ssh $i "source /etc/profile;${KAFKA_HOME}/bin/kafka-server-start.sh -daemon ${KAFKA_HOME}/config/server.properties"
            done
            ;;
        stop)
            for j in ${HOSTNAME_LIST[*]};
            do
                echo "-----$1 $j kafka-------"
                ssh $j  "kill -9 \$(ps ax |grep -i 'Kafka'| grep java| grep -v grep| awk '{print \$1}')"
            done
            ;;
        *)
            echo $usage
            ;;
    esac
}

spark(){
    usage="Usage(spark): $0 (start|stop)"

    if [ $# -lt 1 ]; then
        echo $usage
        exit 1
    fi
    case $1 in
        start)
            ssh ${HOSTNAME_LIST[0]} "source /etc/profile;${SPARK_HOME}/sbin/start-all.sh"
            ;;
        stop)
            ssh ${HOSTNAME_LIST[0]} "source /etc/profile;${SPARK_HOME}/sbin/stop-all.sh"
            ;;
        *)
            echo $usage
            ;;
    esac
}

xcall() {
    for host in ${HOSTNAME_LIST[*]};
    do
        echo -e "\033[31m--------- Current hostname is $host, exec $* ----------\033[0m"
        ssh $host "source /etc/profile;$@"
    done
}

setsqoop() {
local sqoop_dir=${INSTALL_PATH}/sqoop-1.4.7.bin__hadoop-2.6.0
tar -zxf ${SOFT_PATH}/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz -C ${INSTALL_PATH}
# setup
cp ${sqoop_dir}/conf/sqoop-env-template.sh ${sqoop_dir}/conf/sqoop-env.sh
echo "export HADOOP_COMMON_HOME=${HADOOP_HOME}" >> ${sqoop_dir}/conf/sqoop-env.sh
echo "export HADOOP_MAPRED_HOME=${HADOOP_HOME}" >> ${sqoop_dir}/conf/sqoop-env.sh

cp ${SOFT_PATH}/mysql-connector-java-*.jar ${sqoop_dir}/lib/

# set environment
setenv sqoop ${sqoop_dir}
source $PROFILE

# sqoop import --connect "jdbc:mysql://localhost:3306/major?useSSL=false&serverTimezone=UTC" --username root --password 123456 --table school --target-dir '/major/school' --fields-terminated-by ',' -m 1
# sqoop import --connect "jdbc:mysql://localhost:3306/major?useSSL=false&serverTimezone=UTC" --username root --password 123456 --table professional --target-dir '/major/professional' --fields-terminated-by ',' -m 1

}

setflume() {
local flume_dir=${INSTALL_PATH}/apache-flume-1.9.0-bin
tar -zxf ${SOFT_PATH}/apache-flume-1.9.0-bin.tar.gz -C ${INSTALL_PATH}
# setup
cp ${flume_dir}/conf/flume-env.sh.template ${flume_dir}/conf/flume-env.sh
sed -i "s@^# export JAVA_HOME=.*@export JAVA_HOME=${JAVA_HOME}@" ${flume_dir}/conf/flume-env.sh

# set environment
setenv flume ${flume_dir}
source $PROFILE
#nohup /opt/module/flume/bin/flume-ng agent -n a1 -c /opt/module/flume/conf -f /opt/module/flume/job/kafka_to_hdfs_log.conf >/dev/null 2>&1 &

}

lab(){
nohup jupyter lab > /dev/null 2>&1 &
}

notebook(){
nohup jupyter notebook > /dev/null 2>&1 &
}

envclear() {
current_hostname=`cat /etc/hostname`
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    echo -e "\033[31m--------- ${HOSTNAME_LIST[$i]} set clear ----------\033[0m"
    ssh ${HOSTNAME_LIST[$i]} "rm -rf /usr/java"
    ssh ${HOSTNAME_LIST[$i]} "rm -rf /usr/hadoop"
    ssh ${HOSTNAME_LIST[$i]} "rm -rf /usr/zookeeper"
    if [ "$current_hostname" == "${HOSTNAME_LIST[0]}" -o "$current_hostname" == "${HOSTNAME_LIST[1]}" ];then
        ssh ${HOSTNAME_LIST[$i]} "rm -rf /usr/hive"
    else
        rpm -qa | grep -i -E mysql\|mariadb | xargs -n1 sudo rpm -e --nodeps
    fi
    ssh ${HOSTNAME_LIST[$i]} "rm -rf /usr/spark"
    ssh ${HOSTNAME_LIST[$i]} "rm -rf /usr/scala"
    ssh ${HOSTNAME_LIST[$i]} "rm -rf /root/hadoopData/"
    ssh ${HOSTNAME_LIST[$i]} "sed -i '/# java environment/Q' /etc/profile"
done
}

create_hive_table() {
    local database_name=$1
    local table_name=$2
    local fields_txt="/root/hive.txt"

    # 声明一个空数组
    lines=()

    # 读取文件的每一行到数组
    while IFS= read -r line
    do
        lines+=("$line")
    done < "$fields_txt"

    # 使用printf将数组转换为以逗号分隔的字符串
    # 注意：这种方法会移除数组中元素之间的所有空格
    fields_def=$(printf ",\n%s" "${lines[@]}")
    fields_def=${fields_def:2}  # 移除字符串开头的逗号

    # Hive表创建语句的初始部分
    local create_table_sql="CREATE TABLE IF NOT EXISTS ${database_name}.${table_name} (
${fields_def})"
    end_str="
-- COMMENT 'Test'
-- partitioned by (dt string, hr string)
-- clustered by (customer_id) into 10 buckets
row format delimited fields terminated by '\t'
-- collection items terminated by ','
-- map keys terminated by ':'
-- stored by TEXTFILE
-- location '/behavior/dim/dim_date'
-- tblproperties('skip.header.line.count'='1');
"
    create_table_sql+=$end_str

    # 打印出创建的表语句
    echo "${create_table_sql}"
}

create_mysql_table() {
    local table_name=$1
    local path="/root/schema.csv"

    table_name_cn=`head -1 "$path" | cut -d "," -f 1`
    primary_keys=$(awk -F, '$7=="Y" {printf ",`%s`", $2}' "$path" | cut -c 2-)
    lines=()

    # 读取数据行
    while read -r line || [ -n "$line" ]
    do
        column_name=$(echo $line | cut -d "," -f 2)
        column_exp=$(echo $line | cut -d "," -f 3)
        type=$(echo $line | cut -d "," -f 4)
        null_key=$(echo $line | cut -d "," -f 8)
        index_key=$(echo $line | cut -d "," -f 9)
        default_value=$(echo $line | cut -d "," -f 10)
        auto_increment=$(echo $line | cut -d "," -f 11)

        column_name=$(echo "$column_name" | tr '[:upper:]' '[:lower:]')
        type=$(echo "$type" | tr '[:lower:]' '[:upper:]')
        null_key_str=$(if [ "$null_key" == "Y" ]; then echo "NULL"; else echo "NOT NULL"; fi)
        default_value_str=$(if [ -n "$default_value" ]; then echo " DEFAULT '$default_value'"; fi)
        auto_increment_str=$(if [ "$auto_increment" == "Y" ]; then echo " AUTO_INCREMENT"; fi)
        column_exp_str=" COMMENT '$column_exp'"
        lines+=("    \`${column_name}\` ${type} ${null_key_str}${auto_increment_str}${default_value_str}${column_exp_str}")
        if [ "$index_key" == "Y" ]; then
            lines+=("    KEY \`idx_${table_name}_${column_name}\` (\`${column_name}\`) USING BTREE")
        fi
    done < "$path"

    # 添加主键
    if [ -n "$primary_keys" ]; then
        lines+=("    PRIMARY KEY (${primary_keys})")
    fi
    fields_def=$(printf ",\n%s" "${lines[@]}")
    fields_def=${fields_def:2}  # 移除字符串开头的逗号
    local create_mysql_sql="create table if not exists ${table_name} (
${fields_def}"
    create_mysql_sql+="
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='${table_name_cn}';"
    echo "${create_mysql_sql}"
}

load_mysql_data() {
    local table_name=$1
    local file_path=$2
    echo "LOAD DATA local INFILE '${file_path}'
INTO TABLE ${table_name}
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;"
}
