#!/bin/bash
#set -x
CUR=$(cd `dirname 0`;pwd)
. $CUR//setup_hadoop.sh
. $CUR//setup_sqoop.sh
. $CUR//setup_zookeeper.sh
. $CUR//setup_kafka.sh
. $CUR//setup_scala.sh
. $CUR//setup_spark.sh
. $CUR//setup_maven.sh
. $CUR//setup_hbase.sh
. $CUR//setup_flink.sh
. $CUR//setup_hive.sh
. $CUR//setup_java.sh
. $CUR//setup_mysql.sh
. $CUR//setup_mysql.sh
. $CUR//setup_phoenix.sh
. $CUR//setup_flume.sh
. $CUR//common.sh


usage()
{
    case $1 in
        "")
            echo "Usage: main.sh command [options]"
            echo "      main.sh jdk"
            echo "      main.sh hadoop"
            echo "      main.sh hive"
            echo "      main.sh scala"
            echo "      main.sh spark"
            echo "      main.sh hbase"
            echo "      main.sh flume"
            echo "      main.sh docker"
            echo "      main.sh sqoop"
            echo "      main.sh flink"
            echo "      main.sh zookeeper"
            echo "      main.sh kafka"
            echo "      main.sh ssh"
            echo "      main.sh mvn"
            echo "      main.sh mysql"
            echo "      main.sh phoenix"
            echo ""
            ;;
    esac
}
# args for data_process.sh
args()
{
    if [ $# -ne 0 ]; then
        case $1 in
            flume)
                install_flume
                ;;
            phoenix)
                install_phoenix
                ;;
            mvn)
                install_maven
                ;;
	    kafka)
		install_kafka
		;;
	    ssh)
		install_ssh
		;;
	    jdk)
		install_java
		;;
	    zookeeper)
		install_zookeeper
		;;
	    hadoop)
		install_hadoop
		;;
	    hive)
		install_hive
		;;
	    scala)
		install_scala
		;;
	    spark)
		install_spark
		;;
	    hbase)
		install_hbase
		;;
	    mysql)
		install_mysql
		;;
	    sqoop)
		install_sqoop
		;;
	    flink)
		install_flink
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
