#!/bin/bash
#set -x
CUR=$(cd `dirname 0`;pwd)
. $CUR/setup-canal.sh
. $CUR/setup-es.sh
. $CUR/setup-flink.sh
. $CUR/setup-flume.sh
. $CUR/setup-hadoop.sh
. $CUR/setup-hbase.sh
. $CUR/setup-hive.sh
. $CUR/setup-java.sh
. $CUR/setup-kafka.sh
. $CUR/setup-kibana.sh
. $CUR/setup-maven.sh
. $CUR/setup-maxwell.sh
. $CUR/setup-mysql.sh
. $CUR/setup-nginx.sh
. $CUR/setup-phoenix.sh
. $CUR/setup-redis.sh
. $CUR/setup-scala.sh
. $CUR/setup-spark.sh
. $CUR/setup-sqoop.sh
. $CUR/setup-zookeeper.sh
. $CUR/setup-azkaban.sh
. $CUR/setup-presto.sh
. $CUR/setup-kylin.sh
#. $CUR/common.sh


usage()
{
    case $1 in
        "")
	    echo "Usage: main.sh command [options]"
	    echo "      main.sh canal"
	    echo "      main.sh es"
	    echo "      main.sh flink"
	    echo "      main.sh flume"
	    echo "      main.sh hadoop"
	    echo "      main.sh hbase"
	    echo "      main.sh hive"
	    echo "      main.sh hosts"
	    echo "      main.sh jdk"
	    echo "      main.sh kafka"
	    echo "      main.sh kibana"
	    echo "      main.sh mvn"
	    echo "      main.sh maxwell"
	    echo "      main.sh mysql"
	    echo "      main.sh nginx"
	    echo "      main.sh phoenix"
	    echo "      main.sh redis"
	    echo "      main.sh scala"
	    echo "      main.sh spark"
	    echo "      main.sh sqoop"
	    echo "      main.sh zookeeper"
	    echo "      main.sh ssh"
	    echo ""
	    ;;
    esac
}
# args for data_process.sh
args()
{
    if [ $# -ne 0 ]; then
	case $1 in
		azkaban)
		    install_azkaban
		    ;;
		canal)
		    install_canal
		    ;;
		es)
		    install_es
		    ;;
		flink)
		    install_flink
		    ;;
		flume)
		    install_flume
		    ;;
		hadoop)
		    install_hadoop
		    ;;
		hbase)
		    install_hbase
		    ;;
		hive)
		    install_hive
		    ;;
		jdk)
		    install_java
		    ;;
		kafka)
		    install_kafka
		    ;;
		kibana)
		    install_kibana
		    ;;
		mvn)
		    install_maven
		    ;;
		maxwell)
		    install_maxwell
		    ;;
		mysql)
		    install_mysql
		    ;;
		nginx)
		    install_nginx
		    ;;
		phoenix)
		    install_phoenix
		    ;;
		redis)
		    install_redis
		    ;;
		scala)
		    install_scala
		    ;;
		spark)
		    install_spark
		    ;;
		sqoop)
		    install_sqoop
		    ;;
		zookeeper)
		    install_zookeeper
		    ;;
		ssh)
		    install_ssh
		    ;;
		presto)
		    install_presto
		    ;;
		kylin)
		    install_kylin
		    ;;
		-h|--help)
		    usage
		    ;;
		*)
		    echo "Invalid command:$1"
		    usage
		    ;;
        esac
    else
        usage
    fi
}
args $@
