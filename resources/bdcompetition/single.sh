INSTALL_PATH=/root/software
PROFILE=/etc/profile
SOFT_PATH=/root/software

sethadoop000() {
ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'`
echo "$ip hadoop000" >> /etc/hosts
ssh -o StrictHostKeyChecking=no hadoop000
#ssh hadoop000
#cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
#ssh-copy-id hadoop000
}

setbigdata(){
ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'`
name="bigdata"
echo "$ip $name" >> /etc/hosts
ssh-keygen -R $name && ssh $name
hostname $name && bash
bash /root/software/script/hybigdata.sh start
}

hdp(){
usage="Usage: hdp (start|stop|format)"

if [ $# -lt 1 ]; then
    echo $usage
    exit 1
fi
case $1 in
    start)
        ${HADOOP_HOME}/sbin/start-all.sh
        ;;
    stop)
        ${HADOOP_HOME}/sbin/stop-all.sh
        ;;
    format)
        hadoop namenode -format
        ;;
    leave)
        echo "hdfs dfsadmin -safemode enter/leave/get"
        hdfs dfsadmin -safemode leave
        ;;
    nocheck)
        echo 'export HADOOP_SSH_OPTS="-o StrictHostKeyChecking=no"' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
        ;;
    *)
        echo $usage
        ;;
esac
}

sethive(){
usage="Usage: sethive (start|init|create)"

if [ $# -lt 1 ]; then
    echo $usage
    exit 1
fi
case $1 in
    start)
        systemctl start mysqld
        ;;
    init)
        schematool -dbType mysql -initSchema
        ;;
    create)
        hive -e "create database hive;"
        ;;
    *)
        echo $usage
        ;;
esac
}

replace_keyword() {
local key=$1
local val=$2
local file=$3

# backup
[ ! -f ${file}_back ] && cp ${file} ${file}_back

echo -e "\033[31m------------------- ${file} key:value -------------------\033[0m"
echo "${key}=${val}"

if [ `cat ${file} |grep "^${key}" |wc -l` -ne 0 ];then
    sed -i "s@^${key}=.*@${key}=${val}@" ${file}
    echo "${key} replace success!"
else
    echo "${key}=${val}" >> ${file}
    echo "add ${key} success!"
fi
}

updatekafka() {
local host_external=$1
local host_internal=hadoop000
local file=${KAFKA_HOME}/config/server.properties
# backup
echo -n "is or not backup? (y/N) "
read is_backup
if [ "${is_backup}" == "y" ];then
    cp ${file} ${file}_bak
fi
replace_keyword "listeners" "PLAINTEXT://${host_internal}:9092" ${file}
replace_keyword "host.name" "${host_internal}" ${file}
replace_keyword "advertised.listeners" "PLAINTEXT://${host_external}:9092" ${file}
replace_keyword "advertised.host.name" "${host_external}" ${file}
replace_keyword "zookeeper.connect" "${host_external}:2181" ${file}
}

updatezk() {
local host_external=$1
local file=${ZOOKEEPER_HOME}/conf/zoo.cfg
# backup
echo -n "is or not backup? (y/N) "
read is_backup
if [ "${is_backup}" == "y" ];then
    cp ${file} ${file}_back
fi
replace_keyword "server.1" "${host_external}:2888:3888" ${file}
}

updatehbase(){
local host_external=$1
local file=${HBASE_HOME}/conf/hbase-site.xml
# backup
echo -n "is or not backup? (y/N) "
read is_backup
if [ "${is_backup}" == "y" ];then
    cp ${file} ${file}_back
fi
sed -i "s/X.X.X.X/${host_external}/" ${file}
}

kafka(){
    usage="Usage: kafka (start|stop)"

    local type=$1
    local table_name=${2:-"iotTopic"}
    if [ $# -lt 1 ]; then
        echo $usage
        exit 1
    fi
    case $type in
        start)
            ${KAFKA_HOME}/bin/kafka-server-start.sh -daemon ${KAFKA_HOME}/config/server.properties
            ;;
        stop)
            ps -ef | awk '/Kafka/ && !/awk/{print $2}' | xargs kill -9
            ;;
        create)
            echo "kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 3 --topic ${table_name}"
            ;;
        *)
            echo $usage
            ;;
    esac
}

zk(){
    usage="Usage: zk (start|stop|status)"

    if [ $# -lt 1 ]; then
        echo $usage
        exit 1
    fi
    case $1 in
        start)
            ${ZOOKEEPER_HOME}/bin/zkServer.sh start
            ;;
        stop)
            ${ZOOKEEPER_HOME}/bin/zkServer.sh stop
            ;;
        status)
            ${ZOOKEEPER_HOME}/bin/zkServer.sh status
            ;;
        *)
            echo $usage
            ;;
    esac
}

hb(){
    usage="Usage(hbase): hbase (start|stop)"

    if [ $# -lt 1 ]; then
        echo $usage
        exit 1
    fi
    case $1 in
        start)
            ${HBASE_HOME}/bin/start-hbase.sh
            ;;
        stop)
            ${HBASE_HOME}/bin/stop-hbase.sh
            ;;
        create)
            echo "echo \"create 'default:spark_iot','info'\" |hbase shell"
            echo "kafka-console-consumer.sh --bootstrap-server qingjiao:9092 --topic iotTopic --from-beginning"
            ;;
        *)
            echo $usage
            ;;
    esac
}

spark(){
    usage="Usage(spark): spark (start|stop)"

    if [ $# -lt 1 ]; then
        echo $usage
        exit 1
    fi
    case $1 in
        start)
            ${SPARK_HOME}/sbin/start-all.sh
            ;;
        stop)
            ${SPARK_HOME}/sbin/stop-all.sh
            ;;
        *)
            echo $usage
            ;;
    esac
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
    echo -e "\n" >> $PROFILE
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
#sed -i 's@^# export JAVA_OPTS=".-*@export JAVA_OPTS="-Xms100m -Xmx2000m -Dcom.sun.management.jmxremote"@' ${flume_dir}/conf/flume-env.sh

mv ${flume_dir}/lib/guava-11.0.2.jar ${flume_dir}/lib/guava-11.0.2.jar.bak

log4j_path=${flume_dir}/conf/log4j.properties
log_path=${flume_dir}/logs
sed -i 's@^flume.log.dir=.*@flume.log.dir='${log_path}'@' ${log4j_path}

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
