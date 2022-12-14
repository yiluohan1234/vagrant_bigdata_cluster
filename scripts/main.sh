#!/bin/bash
#set -x
bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`

DEFAULT_SCRIPTS_DIR="$bin"/
VBC_SCRIPTS_DIR=${VBC_SCRIPTS_DIR:-$DEFAULT_SCRIPTS_DIR}

. $VBC_SCRIPTS_DIR/setup-canal.sh
. $VBC_SCRIPTS_DIR/setup-es.sh
. $VBC_SCRIPTS_DIR/setup-flink.sh
. $VBC_SCRIPTS_DIR/setup-flume.sh
. $VBC_SCRIPTS_DIR/setup-hadoop.sh
. $VBC_SCRIPTS_DIR/setup-hbase.sh
. $VBC_SCRIPTS_DIR/setup-hive.sh
. $VBC_SCRIPTS_DIR/setup-java.sh
. $VBC_SCRIPTS_DIR/setup-kafka.sh
. $VBC_SCRIPTS_DIR/setup-kibana.sh
. $VBC_SCRIPTS_DIR/setup-maven.sh
. $VBC_SCRIPTS_DIR/setup-maxwell.sh
. $VBC_SCRIPTS_DIR/setup-mysql.sh
. $VBC_SCRIPTS_DIR/setup-nginx.sh
. $VBC_SCRIPTS_DIR/setup-phoenix.sh
. $VBC_SCRIPTS_DIR/setup-redis.sh
. $VBC_SCRIPTS_DIR/setup-scala.sh
. $VBC_SCRIPTS_DIR/setup-spark.sh
. $VBC_SCRIPTS_DIR/setup-sqoop.sh
. $VBC_SCRIPTS_DIR/setup-zookeeper.sh
. $VBC_SCRIPTS_DIR/setup-azkaban.sh
. $VBC_SCRIPTS_DIR/setup-presto.sh
. $VBC_SCRIPTS_DIR/setup-kylin.sh


usage()
{
    case $1 in
        "")
	    echo "Usage: main.sh command [options]"
	    echo "      main.sh init"
	    echo "      main.sh host"
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
		init)
		    install_init
		    ;;
		host)
		    install_hosts
		    ;;
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
