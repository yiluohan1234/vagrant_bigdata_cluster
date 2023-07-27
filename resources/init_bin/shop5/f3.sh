#!/bin/bash

case $1 in
"start")
        echo " --------启动 hdp103 业务数据flume-------"
        ssh hdp103 "source /etc/profile; nohup /opt/module/flume/bin/flume-ng agent -n a1 -c /opt/module/flume/conf -f /opt/module/flume/job/kafka_to_hdfs_db.conf >/dev/null 2>&1 &"
;;
"stop")

        echo " --------停止 hdp103 业务数据flume-------"
        ssh hdp103 "ps -ef | grep kafka_to_hdfs_db | grep -v grep |awk '{print \$2}' | xargs -n1 kill"
;;
esac
