# basic
# IP_LIST=("192.168.10.101" "192.168.10.102" "192.168.10.103")
IP_LIST=("ips" "ips" "ips")
HOSTNAME_LIST=("master" "slave1" "slave2")
PASSWD_LIST=('passwd' 'passwd' 'passwd')
INSTALL_PATH=/root/software/
PROFILE=/etc/profile
SOFT_PATH=/root/software/package
DATA_PATH=/root/etx.txt

setvar() {
updateip `get_item master_ip` `get_item slave1_ip` `get_item slave2_ip`
updatepd `get_item master_password` `get_item slave1_password` `get_item slave2_password`
}

get_item() {
local type=$1
local path=${2:-$DATA_PATH}
if [ -f ${path} ];then
    ret=`cat ${path} |grep ${type} |awk -F '=' '{print $2}'`
    echo ${ret}
else
    echo "$path not exists!"
fi
}

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
hostset_name=`cat /etc/hosts|grep $hostset_ip|tail -1|awk '{print $2}'`
hostnamectl set-hostname $hostset_name
bash
}

setjava() {
local java_dir=${INSTALL_PATH}/jdk1.8.0_212
tar -zxf ${SOFT_PATH}/jdk-8u212-linux-x64.tar.gz -C ${INSTALL_PATH}/
#setenv java ${java_dir}
# dispatch
xsync ${java_dir}
# set environment
length=${#HOSTNAME_LIST[@]}
for ((i=0; i<$length; i++));do
    ssh ${HOSTNAME_LIST[$i]} "source /etc/profile;setenv java ${java_dir}"
done
source $PROFILE
xcall java -version
}

sethadoop() {
local hadoop_dir=${INSTALL_PATH}/hadoop-3.1.3
tar -zxf ${SOFT_PATH}/hadoop-3.1.3.tar.gz -C ${INSTALL_PATH}/

# hadoop-env.sh
sed -i "s@^# export JAVA_HOME=.*@export JAVA_HOME=${JAVA_HOME}@" ${hadoop_dir}/etc/hadoop/hadoop-env.sh

# core-site.xml
setkv "fs.default.name=hdfs://${HOSTNAME_LIST[0]}:9000" ${hadoop_dir}/etc/hadoop/core-site.xml
setkv "hadoop.tmp.dir=${hadoop_dir}/data" ${hadoop_dir}/etc/hadoop/core-site.xml
setkv "hadoop.security.authorization=true" ${hadoop_dir}/etc/hadoop/core-site.xml

# hdfs-site.xml
setkv "dfs.namenode.http-address=${HOSTNAME_LIST[0]}:9870" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.replication=3" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.permissions.enabled=true" ${hadoop_dir}/etc/hadoop/hdfs-site.xml
setkv "dfs.permissions.superusergroup=root" ${hadoop_dir}/etc/hadoop/hdfs-site.xml

# yarn-env.sh
echo "export JAVA_HOME=${JAVA_HOME}" >> ${hadoop_dir}/etc/hadoop/yarn-env.sh

# yarn-site.xml
setkv "yarn.nodemanager.aux-services=mapreduce_shuffle" ${hadoop_dir}/etc/hadoop/yarn-site.xml
setkv "yarn.resourcemanager.hostname=${HOSTNAME_LIST[0]}" ${hadoop_dir}/etc/hadoop/yarn-site.xml
setkv "yarn.nodemanager.env-whitelist=JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME" ${hadoop_dir}/etc/hadoop/yarn-site.xml

# mapred-site.xml
setkv "mapreduce.framework.name=yarn" ${hadoop_dir}/etc/hadoop/mapred-site.xml
setkv "yarn.app.mapreduce.am.env=HADOOP_MAPRED_HOME=${hadoop_dir}" ${hadoop_dir}/etc/hadoop/mapred-site.xml
setkv "mapreduce.map.env=HADOOP_MAPRED_HOME=${hadoop_dir}" ${hadoop_dir}/etc/hadoop/mapred-site.xml
setkv "mapreduce.reduce.env=HADOOP_MAPRED_HOME=${hadoop_dir}" ${hadoop_dir}/etc/hadoop/mapred-site.xml

# workers
sed -i '1,$d' ${hadoop_dir}/etc/hadoop/workers
echo "${HOSTNAME_LIST[0]}
${HOSTNAME_LIST[1]}
${HOSTNAME_LIST[2]}" >> ${hadoop_dir}/etc/hadoop/workers

# hadoop-policy.xml
setkv "security.client.protocol.acl=root" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.client.datanode.protocol.acl=root" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.datanode.protocol.acl=root" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.inter.datanode.protocol.acl=root" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.namenode.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.admin.operations.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.refresh.user.mappings.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.refresh.policy.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.ha.service.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.zkfc.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.qjournal.service.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.interqjournal.service.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.mrhs.client.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.resourcetracker.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.resourcemanager-administration.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.applicationclient.protocol.acl=root" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.applicationmaster.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.containermanagement.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.resourcelocalizer.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.job.task.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.job.client.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.applicationhistory.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.collector-nodemanager.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.applicationmaster-nodemanager.applicationmaster.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml
setkv "security.distributedscheduling.protocol.acl=*" ${hadoop_dir}/etc/hadoop/hadoop-policy.xml

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
}

setmysql() {
echo "setup mysql"
# 解压数据库
tar -xf ${SOFT_PATH}/mysql-5.7.25-1.el7.x86_64.rpm-bundle.tar -C ${SOFT_PATH}/
# 删除依赖库
yum remove -y mariadb-libs
# 安装mysql各个组件
rpm -ivh ${SOFT_PATH}/mysql-community-common-5.7.25-1.el7.x86_64.rpm
rpm -ivh ${SOFT_PATH}/mysql-community-libs-5.7.25-1.el7.x86_64.rpm
rpm -ivh ${SOFT_PATH}/mysql-community-libs-compat-5.7.25-1.el7.x86_64.rpm
rpm -ivh ${SOFT_PATH}/mysql-community-client-5.7.25-1.el7.x86_64.rpm
rpm -ivh ${SOFT_PATH}/mysql-community-server-5.7.25-1.el7.x86_64.rpm
# 初始化
/usr/sbin/mysqld --initialize-insecure --console --user=mysql
# 启动服务
systemctl start mysqld.service
mysql -e "grant all privileges on *.* to root@'localhost' identified by '123456' with grant option;"

mysql -uroot -p123456 -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '123456'; create user 'root'@'%' identified by '123456'; grant all privileges on *.* to 'root'@'%' with grant option; flush privileges;" --connect-expired-password
}

sethive(){
echo "setup hive"
local hive_dir=${INSTALL_PATH}/apache-hive-3.1.2-bin

current_hostname=`cat /etc/hostname`
# master
if [ "$current_hostname" == "${HOSTNAME_LIST[0]}" ];then
    setmysql
fi

# master
if [ "$current_hostname" == "${HOSTNAME_LIST[0]}" ];then
    tar -zxf ${SOFT_PATH}/apache-hive-3.1.2-bin.tar.gz -C ${INSTALL_PATH}/
    setenv hive ${hive_dir}
    source $PROFILE

    # hive-env.sh
    cp ${hive_dir}/conf/hive-env.sh.template ${hive_dir}/conf/hive-env.sh
    echo "export HADOOP_HOME=${HADOOP_HOME}
export HIVE_CONF_DIR=${HIVE_HOME}/conf
export HIVE_AUX_JARS_PATH=${HIVE_HOME}/lib" >> ${hive_dir}/conf/hive-env.sh
    # hive-site.xml
    setkv "javax.jdo.option.ConnectionURL=jdbc:mysql://${HOSTNAME_LIST[0]}:3306/hivedb?createDatabaseIfNotExist=true&amp;useSSL=false&amp;useUnicode=true&amp;characterEncoding=UTF-8" ${hive_dir}/conf/hive-site.xml true
    setkv "javax.jdo.option.ConnectionDriverName=com.mysql.jdbc.Driver" ${hive_dir}/conf/hive-site.xml
    setkv "javax.jdo.option.ConnectionUserName=root" ${hive_dir}/conf/hive-site.xml
    setkv "javax.jdo.option.ConnectionPassword=123456" ${hive_dir}/conf/hive-site.xml
    # mysql driver
    cp ${SOFT_PATH}/mysql-connector-java-5.1.47-bin.jar ${hive_dir}/lib/
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
        yum install -y -q expect
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
        echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> $PROFILE
        echo 'export HADOOP_CLASSPATH=$(hadoop classpath)' >> $PROFILE
        echo 'export HDFS_NAMENODE_USER=root' >> $PROFILE
        echo 'export HDFS_DATANODE_USER=root' >> $PROFILE
        echo 'export HDFS_SECONDARYNAMENODE_USER=root' >> $PROFILE
        echo 'export YARN_RESOURCEMANAGER_USER=root' >> $PROFILE
        echo 'export YARN_NODEMANAGER_USER=root' >> $PROFILE
        echo 'export HDFS_JOURNALNODE_USER=root' >> $PROFILE
        echo 'export HDFS_ZKFC_USER=root' >> $PROFILE
    fi
    echo -e "\n" >> $PROFILE
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

xcall() {
for host in ${HOSTNAME_LIST[*]};
do
    echo -e "\033[31m--------- Current hostname is $host, exec $* ----------\033[0m"
    ssh $host "source /etc/profile;$@"
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
    ssh ${HOSTNAME_LIST[$i]} "rm -rf /root/hadoopData/"
    ssh ${HOSTNAME_LIST[$i]} "sed -i '/# java environment/Q' /etc/profile"
done
}

load_mysql_data() {
local file=$1
local table_name=$2
local fields=${3:-','}
local lines=${4:-'\n'}

mysql -uroot -p123456 -e "LOAD DATA local INFILE '${file}' \
INTO TABLE ${table_name} \
FIELDS TERMINATED BY '${fields}' \
LINES TERMINATED BY '${lines}' \
IGNORE 1 ROWS;"
}

load_hive_data() {
local file=$1
local table_name=$2

echo "hive -e \"load data local inpath '${file}' into table ${table_name};\""
hive -e "load data local inpath '${file}' into table ${table_name};"
}

load_mysqle() {
systemctl start mysqld.service
# MySQL数据库连接信息
DB_USER="root"
DB_PASSWORD="123456"
DB_NAME="test"

# 连接到MySQL数据库并执行SQL语句
mysql -u$DB_USER -p$DB_PASSWORD << EOF
create database if not exists test;
create table test.fooditems (
`id` INT NOT NULL AUTO_INCREMENT COMMENT '行号',
`city` VARCHAR(255) NOT NULL COMMENT '城市',
`food_name` VARCHAR(255) NOT NULL COMMENT '美食名称',
`likelihood_of_liking` INT NOT NULL COMMENT '喜爱度',
`restaurant_list` TEXT NOT NULL COMMENT '餐馆列表',
`food_detail_link` TEXT NOT NULL COMMENT '美食详情链接',
`food_image_link` TEXT NOT NULL COMMENT '美食图片链接',
`food_description` TEXT NOT NULL COMMENT '美食介绍',
PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='fooditems';

drop table if exists test.shopping;
create table test.shopping (
`id` INT NOT NULL AUTO_INCREMENT COMMENT '行号',
`city` VARCHAR(255) NOT NULL COMMENT '城市',
`shop_name` VARCHAR(500) NOT NULL COMMENT '购物地名称',
`address` VARCHAR(50) NOT NULL COMMENT '地址',
`contact_phone` VARCHAR(100) NOT NULL COMMENT '联系电话',
`business_hours` VARCHAR(100) NOT NULL COMMENT '营业时间',
`ranking` VARCHAR(100) NOT NULL COMMENT '排名',
`overall_rating` VARCHAR(50) NOT NULL COMMENT '综合评分',
`reviews_count` VARCHAR(50) NOT NULL COMMENT '点评数',
`review_category` VARCHAR(100) NOT NULL COMMENT '评价类别',
`visitor_rating` VARCHAR(100) NOT NULL COMMENT '游客评分',
`visitor_review` TEXT NOT NULL COMMENT '游客评价',
PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='shopping';

LOAD DATA local INFILE '/root/travel/hotel/shopping.csv'
INTO TABLE test.shopping
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA local INFILE '/root/travel/hotel/fooditems.csv'
INTO TABLE test.fooditems
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

create view test.view_table01 as
select substring(visitor_rating, LOCATE('环境：', visitor_rating)+3, 1) '环境评分'
from test.shopping where shop_name='';

create view test.view_table02 as
select count(distinct(food_name)) '美食个数'
from test.fooditems where city = '北京' group by city;

ALTER TABLE test.shopping ADD overall_rating_new varchar(255);
UPDATE test.shopping SET overall_rating_new = SUBSTRING(overall_rating, 1, LOCATE('分', overall _rating)-1);

create view test.view_table03 as
select count(*) '个数' from test.shopping
where overall_rafing_new > 4.5 and ranking !=';

create view test.view_table04 as
select city from test.fooditems were food_name '麻豆腐';

EOF
}
