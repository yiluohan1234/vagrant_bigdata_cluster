#!/bin/bash
#set -x
CUR=$(cd `dirname 0`;pwd)
. $CUR/setup-init.sh
. $CUR/setup-hosts.sh
. $CUR/setup-hadoop.sh
. $CUR/setup-hbase.sh
. $CUR/setup-hive.sh
. $CUR/setup-java.sh
. $CUR/setup-kafka.sh
. $CUR/setup-mysql.sh
. $CUR/setup-scala.sh
. $CUR/setup-spark.sh
. $CUR/setup-sqoop.sh
. $CUR/setup-zookeeper.sh
#. $CUR/common.sh


usage()
{
    case $1 in
        "")
	    echo "Usage: main.sh command [options]"
	    echo "      main.sh init"
	    echo "      main.sh host"
	    echo "      main.sh hadoop"
	    echo "      main.sh hbase"
	    echo "      main.sh hive"
	    echo "      main.sh jdk"
	    echo "      main.sh kafka"
	    echo "      main.sh mysql"
	    echo "      main.sh scala"
	    echo "      main.sh spark"
	    echo "      main.sh sqoop"
	    echo "      main.sh zookeeper"
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
		mysql)
		    install_mysql
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
