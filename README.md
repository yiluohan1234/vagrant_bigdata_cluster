# vagrant_bigdata_cluster

## 一、基本介绍

本集群创建的组件如下表所示。

| 组件      | hdp101                                             | hdp102                     | hdp103            |
| :-: | :-------------  | -------------------------- | ----------------- |
| OS   | centos7.6                                          | centos7.6             | centos7.6         |
| JDK  | jdk1.8                                             | jdk1.8                     | jdk1.8            |
| HDFS      | NameNode <br> JobHistoryServer <br> ApplicationHistoryServer | DataNode <br> SecondaryNameNode | DataNode          |
| YARN      | ResourceManager                                    | NodeManager                | NodeManager       |
| Sqoop     | sqoop                                              | NA                         | NA                |
| MySQL     | NA                                                 | NA                         | MySQL Server      |
| Kafka     | kafka                                              | Kafka                      | Kafka             |
| Zookeeper | QuorumPeerMain                                     | QuorumPeerMain             | QuorumPeerMain    |
| HBase     | HMaster                                            | HRegionServer              | HRegionServer     |
| Scala     | scala2.11.12                                       | scala2.11.12               | scala2.11.12      |
| Spark     | master/HistoryServer                               | worker                     | worker            |
| Maven     | mvn                                                | NA                         | NA                |
| Flink     | StandaloneSession <br> ClusterEntrypoint                 | TaskManagerRunner          | TaskManagerRunner |
| Flume     | flume                                              | flume                      | flume             |

组件版本：

```
Java：1.8
Hadoop：2.7.2
Sqoop：1.4.6
MySQL：5.6
Kafka：0.11.0.3
Zookeeper：3.4.10
Hbase：1.2.5
Scala：2.11.12
Spark：2.4.6
Maven：3.2.5
Flink：1.12.4
Flume：1.6
```

## 二、基本硬件准备

1. 每个节点的默认内存是2G，集群默认启动三个节点，你的机器至少需要6G
2. 我的测试环境：Vagrant 2.2.14， Virtualbox 6.0.14

```
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} -e "create user 'hive'@'%' IDENTIFIED BY 'hive';GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION;grant all on *.* to 'hive'@'localhost' identified by 'hive';flush privileges; quit"

mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} -e "use mysql; update user set host = '%' where user = 'root';update user set authentication_string=password('199037') where user='root'; update user set authentication_string=password('199037'),plugin='mysql_native_password' where user='root';grant all on *.* to root@'%' identified by '199037' with grant option;grant all privileges on *.* to 'root'@'%' identified by '199037' with grant option;flush privileges;quit
```



## 三、安装集群环境

1. [下载和安装VirtualBOX](https://www.virtualbox.org/wiki/Downloads)
2. [下载和安装Vagrant](http://www.vagrantup.com/downloads.html)
3. 克隆本项目到本地，并cd到项目所在目录
4. 执行`vagrant up` 创建虚拟机
5. 执行 `vagrant ssh` 登录到你创建的虚拟机，或通过SecureCRT等工具进行登录
6. 如果你想要删除虚拟机，可以通过执行`vagrant destroy` 实现

## 四、自定义集群环境配置

你可以通过修改`VagrantFile`、`scripts/common.sh`文件和`resources/组件名称`目录下各个组件的配置文件文件来实现自定义集群。

1. `VagrantFile`
   这个文件可以设置虚拟机的的版本、个数、名称、主机名、IP、内存、CPU等，根据自己需要更改即可。

2. `scripts/common.sh`
   这个文件可以设置各个组件的版本。

   注意：要同步更改`KAFKA_VERSION`和`KAFKA_MIRROR_DOWNLOAD`，保证对应版本可以下载。


## 五、集群安装完毕后相关组件初始化及启动

### 1、ssh免登陆

在每台机器上执行`init_shell/setup-ssh.sh`

### 2、启动hadoop

在hdp101机器上执行以下命令对hadoop集群进行格式化，并启动hdfs和yarn。

```
[vagrant@hdp101 ~]$ hdfs namenode -format
[vagrant@hdp101 ~]$ start-dfs.sh
[vagrant@hdp101 ~]$ start-yarn.sh
[vagrant@hdp101 ~]$ mr-jobhistory-daemon.sh start historyserver 
```

通过执行下列命令可以测试yarn是否安装成功。

```
[vagrant@hdp101 ~]$ yarn jar /home/vagrant/apps/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.2.jar pi 2 100
```

### 3、启动Spark（Standalone ）

在hdp01机器上执行以下命令。

```
[vagrant@hdp101 ~]$ $SPARK_HOME/sbin/start-all.sh
```

通过执行下列命令可以测试spark是否安装成功。

```
[vagrant@hdp101 ~]$ spark-submit --class org.apache.spark.examples.SparkPi \
    --master yarn \
    --num-executors 1 \
    --executor-cores 2 \
   /home/vagrant/apps/spark/examples/jars/spark-examples*.jar \
    100
```

## 六. Web UI

可以通过以下链接访问插件的页面。

[NameNode](http://hdp101:50070)

[ResourceManager](http://hdp101:8088)

[JobHistory](http://hdp101:19888/jobhistory)

[Spark](http://hdp101:8080/)

[Flink](http://hdp101:8381/)