setssh() {
ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'`
echo "$ip hadoop000" >> /etc/hosts
ssh -o StrictHostKeyChecking=no hadoop000
}

hdp(){
usage="Usage: hdp (format|start|stop)"

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
        hive -e "create database if not exists $2;"
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

echo -e "\033[31m--------------------- ${file} key:value ---------------------\033[0m"
echo "${key}=${val}"

if [ `cat ${file} |grep "^${key}" |wc -l` -ne 0 ];then
    sed -i "s@^${key}=.*@${key}=${val}@" ${file}
    echo "${key} replace success!"
else
    echo "${key}=${val}" >> ${file}
    echo "add ${key} success!"
fi
}

setazkaban() {
local azkaban_path=/root/software/azkaban
local azkaban_raw_path=/root/software/azkaban-3.90.0
local db_file=${azkaban_path}/azkaban-db-0.1.0-SNAPSHOT/create-all-sql-0.1.0-SNAPSHOT.sql
local web_server_file=${azkaban_path}/azkaban-web-server-0.1.0-SNAPSHOT/conf/azkaban.properties
local exec_server_file=${azkaban_path}/azkaban-exec-server-0.1.0-SNAPSHOT/conf/azkaban.properties
local web_user_file=${azkaban_path}/azkaban-web-server-0.1.0-SNAPSHOT/conf/azkaban-users.xml

mysql -uroot -p123456 -e "create database if not exists azkaban;grant all privileges ON azkaban.* to 'qingjiao'@'%' with grant option;flush privileges;"

[ ! -d ${azkaban_path} ] && mkdir -p ${azkaban_path}
tar -zxvf ${azkaban_raw_path}/azkaban-db/build/distributions/azkaban-db-0.1.0-SNAPSHOT.tar.gz -C ${azkaban_path}

mysql -uroot -p123456 azkaban < ${db_file}

tar -zxvf ${azkaban_raw_path}/azkaban-web-server/build/distributions/azkaban-web-server-0.1.0-SNAPSHOT.tar.gz -C ${azkaban_path}

# gen key
key_path=${azkaban_path}/azkaban-web-server-0.1.0-SNAPSHOT/keystore
keytool -keystore ${key_path} -alias jetty -genkey -keyalg RSA  << EOF
123456
123456





CN
Y
123456
123456
EOF

# modify web server configuration
echo "web server configuration"
replace_keyword "default.timezone.id" "Asia/Shanghai" ${web_server_file}
replace_keyword "mysql.user" "qingjiao" ${web_server_file}
replace_keyword "mysql.password" "123456" ${web_server_file}
# jetty configuration
replace_keyword "jetty.use.ssl" "true" ${web_server_file}
replace_keyword "jetty.ssl.port" "8443" ${web_server_file}
replace_keyword "jetty.keystore" "${key_path}" ${web_server_file}
replace_keyword "jetty.password" "123456" ${web_server_file}
replace_keyword "jetty.keypassword" "123456" ${web_server_file}
replace_keyword "jetty.truststore" "${key_path}" ${web_server_file}
replace_keyword "jetty.trustpassword" "123456" ${web_server_file}

# modify web server user configuration
sed -i '/user password/a\  <user password="admin" roles="metrics,admin" username="admin"/>' ${web_user_file}
# modify exec server configuration
tar -zxvf ${azkaban_raw_path}/azkaban-exec-server/build/distributions/azkaban-exec-server-0.1.0-SNAPSHOT.tar.gz -C ${azkaban_path}
replace_keyword "default.timezone.id" "Asia/Shanghai" ${exec_server_file}
replace_keyword "mysql.user" "qingjiao" ${exec_server_file}
replace_keyword "mysql.password" "123456" ${exec_server_file}
replace_keyword "executor.port" "12321" ${exec_server_file}

# derby auto import
cp ${HIVE_HOME}/lib/derby-10.10.2.0.jar ${azkaban_path}/azkaban-web-server-0.1.0-SNAPSHOT/lib/
cp ${HIVE_HOME}/lib/derby-10.10.2.0.jar ${azkaban_path}/azkaban-exec-server-0.1.0-SNAPSHOT/lib/

# log4j conflict
mv ${azkaban_path}/azkaban-exec-server-0.1.0-SNAPSHOT/lib/slf4j-log4j12-1.7.21.jar ${azkaban_path}/azkaban-exec-server-0.1.0-SNAPSHOT/lib/slf4j-log4j12-1.7.21.jar.bak
mv ${azkaban_path}/azkaban-web-server-0.1.0-SNAPSHOT/lib/slf4j-log4j12-1.7.18.jar ${azkaban_path}/azkaban-web-server-0.1.0-SNAPSHOT/lib/slf4j-log4j12-1.7.18.jar.bak
}

mr_azkaban() {
echo "type=command" >> /root/data/put.job
echo "command=hdfs dfs -put /root/data/word.txt /" >> /root/data/put.job

echo "type=command" >> /root/data/mapreduce.job
echo "dependencies=put" >> /root/data/mapreduce.job
echo "command=hadoop jar /root/software/hadoop-2.7.7/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.7.jar wordcount /word.txt /wordcount" >> /root/data/mapreduce.job
[ -f /root/mapreduce.zip ] && rm -rf /root/mapreduce.zip
zip /root/mapreduce.zip /root/data/put.job /root/data/mapreduce.job

}

hive_azkaban() {
cat > /root/data/hivef.sql << EOF
use default;
create table if not exists student(id int, name string)
row format delimited fields terminated by ',';
load data local inpath '/root/data/student.txt' into table student;
insert into student values (1100,'qingjiao');
insert overwrite local directory '/root/data/student'
row format delimited fields terminated by '\t'
select * from student;
EOF

echo "type=command" >> /root/data/hivef.job
echo "command=hive -f /root/data/hivef.sql" >> /root/data/hivef.job

[ -f /root/hivef.zip ] && rm -rf /root/hivef.zip
zip /root/hivef.zip /root/data/hivef.job

}


azkaban(){
    usage="Usage: azkaban (start|stop)"

    if [ $# -lt 1 ]; then
        echo $usage
        exit 1
    fi
    case $1 in
        start)
            echo "============ start azkaban-web-and-exec-server ============"
            cd /root/software/azkaban/azkaban-exec-server-0.1.0-SNAPSHOT && bin/start-exec.sh && cd
            sleep 3s
            cd /root/software/azkaban/azkaban-exec-server-0.1.0-SNAPSHOT && curl -G "localhost:$(<./executor.port)/executor?action=activate" && echo && cd
            cd /root/software/azkaban/azkaban-web-server-0.1.0-SNAPSHOT && bin/start-web.sh && cd
            ;;
        stop)
            echo "============ stop azkaban-web-and-exec-server ============"
            cd /root/software/azkaban/azkaban-web-server-0.1.0-SNAPSHOT && bin/shutdown-web.sh && cd
            cd /root/software/azkaban/azkaban-exec-server-0.1.0-SNAPSHOT && bin/shutdown-exec.sh && cd
            ;;
        *)
            echo $usage
            ;;
    esac
}
