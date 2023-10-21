# basic
# IP_LIST=("192.168.10.101" "192.168.10.102" "192.168.10.103")
IP_LIST=("ips" "ips" "ips")
HOSTNAME_LIST=("master" "slave1" "slave2")
PASSWD_LIST=('passwd' 'passwd' 'passwd')
INSTALL_PATH=/usr
PROFILE=/etc/profile
SOFT_PATH=/usr/package277

updateip() {
local master=$1
local slave1=$2
local slave2=$3
usage="Usage: updateip master_ip slave1_ip slave2_ip(internal)"
if [ $# -ne 3 ]; then
    echo $usage
    exit 1
fi
sed -i 's@^IP_LIST=.*@IP_LIST=("'$master'" "'$slave1'" "'$slave2'")@' /etc/profile.d/my.sh
}

updatepd() {
local master=`change_string_passwd $1`
local slave1=`change_string_passwd $2`
local slave2=`change_string_passwd $3`
usage="Usage: updatepd master_pd slave1_pd slave2_pd"
if [ $# -ne 3 ]; then
    echo $usage
    exit 1
fi
sed -i "s@^PASSWD_LIST=.*@PASSWD_LIST=('$master' '$slave1' '$slave2')@" /etc/profile.d/my.sh
}

change_string_passwd() {
local passwd=$1
local new_passwd=""
special_char=('@' '!' '$' '&')

len=${#passwd}
for((i=0;i<$len;i++)){
    c=${passwd:$i:1}
    if [[ "${special_char[@]}" =~ "$c" ]];then
        c='\'$c
    fi
    new_passwd=$new_passwd$c
}
echo $new_passwd
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
hostset_name=`cat /etc/hosts|grep $hostset_ip|awk '{print $2}'`
hostnamectl set-hostname $hostset_name
bash
}

settimezone() {
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
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    echo -e "\033[31m--------- ${HOSTNAME_LIST[$i]} set ntp ----------\033[0m"
    ssh ${HOSTNAME_LIST[$i]} "setup_ntp"
done
}

setup_ntp() {
systemctl stop firewalld
sed -i "s@^SELINUX=.*@SELINUX=disabled@g" /etc/selinux/config
if [ `yum list installed |grep ntp |wc -l` == 0 ];then
    yum install -y ntp
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

setjava() {
local java_dir=${INSTALL_PATH}/java/jdk1.8.0_221
mkdir ${INSTALL_PATH}/java
tar -zvf ${SOFT_PATH}/jdk-8u221-linux-x64.tar.gz -C ${INSTALL_PATH}/java/
#setenv java ${java_dir}
# dispatch
xsync ${java_dir}
# set environment
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    ssh ${HOSTNAME_LIST[$i]} "setenv java ${java_dir}"
done
source $PROFILE
xcall java -version
}

setzk363() {
local zookeeper_dir=${INSTALL_PATH}/zookeeper/apache-zookeeper-3.6.3-bin
mkdir ${INSTALL_PATH}/zookeeper
tar -zvf ${SOFT_PATH}/apache-zookeeper-3.6.3-bin.tar.gz -C ${INSTALL_PATH}/zookeeper/
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
    ssh ${HOSTNAME_LIST[$i]} "setenv zookeeper ${zookeeper_dir}"
    ssh ${HOSTNAME_LIST[$i]} "echo $(($i+1)) >> ${zookeeper_dir}/zkdata/myid"
done
source $PROFILE
zk start
jpsall
}

setzk314() {
local zookeeper_dir=${INSTALL_PATH}/zookeeper/zookeeper-3.4.14
mkdir ${INSTALL_PATH}/zookeeper
tar -zvf ${SOFT_PATH}/zookeeper-3.4.14.tar.gz -C ${INSTALL_PATH}/zookeeper/
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
    ssh ${HOSTNAME_LIST[$i]} "setenv zookeeper ${zookeeper_dir}"
    ssh ${HOSTNAME_LIST[$i]} "echo $(($i+1)) >> ${zookeeper_dir}/zkdata/myid"
done
source $PROFILE
zk start
jpsall
}

sethadoop() {
local hadoop_dir=${INSTALL_PATH}/hadoop/hadoop-2.7.7
mkdir ${INSTALL_PATH}/hadoop
tar -zvf ${SOFT_PATH}/hadoop-2.7.7.tar.gz -C ${INSTALL_PATH}/hadoop/

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

# dispatch
xsync ${hadoop_dir}

# set environment
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    ssh ${HOSTNAME_LIST[$i]} "setenv hadoop ${hadoop_dir} true"
done
source $PROFILE
hadoop namenode -format
${HADOOP_HOME}/sbin/start-all.sh
jpsall
}

setmysql() {
systemctl disable mysqld.service
systemctl start mysqld.service
grep "temporary password" /var/log/mysqld.log
PASSWORD=`grep 'temporary password' /var/log/mysqld.log|awk -F "root@localhost: " '{print $2}'`

PORT="3306"
USERNAME="root"
mysql -u${USERNAME} -p${PASSWORD} -e "set global validate_password_policy=0; set global validate_password_length=4; ALTER USER 'root'@'localhost' IDENTIFIED BY '123456'; create user 'root'@'%' identified by '123456'; grant all privileges on *.* to 'root'@'%' with grant option; flush privileges;" --connect-expired-password
}

sethive() {
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    echo -e "\033[31m--------- ${HOSTNAME_LIST[$i]} set hive ----------\033[0m"
    ssh ${HOSTNAME_LIST[$i]} "setup_hive"
done
}

setup_hive(){
local hive_dir=${INSTALL_PATH}/hive/apache-hive-2.3.4-bin
# master and slave1
current_hostname=`cat /etc/hostname`
if [ "$current_hostname" == "${HOSTNAME_LIST[0]}" -o "$current_hostname" == "${HOSTNAME_LIST[1]}" ];then
    mkdir ${INSTALL_PATH}/hive
    tar -zvf ${SOFT_PATH}/apache-hive-2.3.4-bin.tar.gz -C ${INSTALL_PATH}/hive/
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
}

setscala211() {
local scala_dir=${INSTALL_PATH}/scala/scala-2.11.11
mkdir ${INSTALL_PATH}/scala
tar -zvf ${SOFT_PATH}/scala-2.11.11.tgz -C ${INSTALL_PATH}/scala/
# dispatch
xsync ${scala_dir}
# set environment
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    ssh ${HOSTNAME_LIST[$i]} "setenv scala ${scala_dir}"
done
source $PROFILE
xcall scala -version
}

setscala210() {
local scala_dir=${INSTALL_PATH}/scala/scala-2.10.6
mkdir ${INSTALL_PATH}/scala
tar -zvf ${SOFT_PATH}/scala-2.10.6.tgz -C ${INSTALL_PATH}/scala/
# dispatch
xsync ${scala_dir}
# set environment
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    ssh ${HOSTNAME_LIST[$i]} "setenv scala ${scala_dir}"
done
source $PROFILE
xcall scala -version
}

setspark() {
local spark_dir=${INSTALL_PATH}/spark/spark-2.4.3-bin-hadoop2.7
mkdir ${INSTALL_PATH}/spark
tar -zvf ${SOFT_PATH}/spark-2.4.3-bin-hadoop2.7.tgz -C ${INSTALL_PATH}/spark/
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

# dispatch
xsync ${spark_dir}
# set environment
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    ssh ${HOSTNAME_LIST[$i]} "setenv spark ${spark_dir}"
done
source $PROFILE
${SPARK_HOME}/sbin/start-all.sh
jpsall
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
        yum install -y expect
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
        rsync -rvl $pdir/$filename $user@$host:$pdir
    fi
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
            ssh ${HOSTNAME_LIST[0]} "${HADOOP_HOME}/bin/hdfs namenode -format"
            ;;
        init)
            schematool -dbType mysql -initSchema
            ;;
        meta)
            nohup hive --service metastore &
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
    ssh $host "source /etc/profile;$*"
done
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
done
}
