# vagrant_bigdata_cluster

## Ⅰ. Basic Introduction

The components created by this cluster are listed in the following table.

| Component     | hadoop102                                                | hadoop103                       | hadoop104                      |
| ------------- | -------------------------------------------------------- | ------------------------------- | ------------------------------ |
| OS            | centos7.6                                                | centos7.6                       | centos7.6                      |
| JDK           | jdk1.8                                                   | jdk1.8                          | jdk1.8                         |
| HDFS          | NameNode<br/>DataNode                                    | DataNode<br/>JobHistoryServer   | DataNode<br/>SecondaryNameNode |
| YARN          | NodeManager                                              | ResourceManager<br/>NodeManager | NodeManager                    |
| Hive          | Hive                                                     | NA                              | NA                             |
| HBase         | HMaster                                                  |                                 |                                |
| HRegionServer | HRegionServer                                            | HRegionServer                   |                                |
| Spark         | master<br/>worker                                        | worker                          | worker                         |
| Flink         | StandaloneSessionClusterEntrypoint<br/>TaskManagerRunner | TaskManagerRunner               | TaskManagerRunner              |
| Zookeeper     | QuorumPeerMain                                           | QuorumPeerMain                  | QuorumPeerMain                 |
| Kafka         | kafka                                                    | Kafka                           | Kafka                          |
| Flume         | flume                                                    | flume                           | flume                          |
| Scala         | scala                                                    | scala                           | scala                          |
| Maven         | mvn                                                      | NA                              | NA                             |
| Sqoop         | sqoop                                                    | NA                              | NA                             |
| MySQL         | NA                                                       | NA                              | MySQL Server                   |
| Nginx         | Nginx                                                    | NA                              | NA                             |
| Redis         | Redis                                                    | NA                              | NA                             |
| Elasticsearch | Elasticsearch                                            | Elasticsearch                   | Elasticsearch                  |
| Kibana        | Kibana                                                   | NA                              | NA                             |

Component versions:

```
Java: 1.8
Hadoop: 3.2.2
Hive: 3.1.3
Hbase: 2.0.5
Spark: 3.2.3
Flink: 1.13.4
Zookeeper: 3.6.3
Kafka: kafka_2.12-3.0.0
Flume: 1.9.0
Scala: 2.12.16
Maven: 3.6.1
Sqoop: 1.4.7
MySQl Connector: 5.1.49
MySQL: 5.7.40 (yum installation)
Nginx: 1.20.1 (yum installation)
Redis: 3.2.12 (yum installation)
Elasticsearch: 6.6.0
Kibana: 6.6.0
Canal: 1.25.0
Maxwell: 3.84.4
Presto: 0.196
Kylin: 3.0.2
```

## Ⅱ. Basic Preparation

1. The cluster defaults to three nodes, and each node has a default memory of 2G, so your machine needs at least 6G.
2. My test environment software version: vagrant 2.2.14, Virtualbox 6.0.14

## Ⅲ. Install Cluster Environment

1. [Download and install VirtualBOX](https://www.virtualbox.org/wiki/Downloads)

2. [Download and install vagrant](http://www.atguiguup.com/downloads.html)

3. Clone this project to the local machine and cd to the directory where the project is located.

   ```
   git clone <https://github.com/yiluohan1234/vagrant_bigdata_cluster>
   cd vagrant_bigdata_cluster
   ```

4. Execute 'vagrant up' to create the virtual machine.

5. You can log in to the virtual machine you created by executing `vagrant ssh` or logging in through tools such as SecureCRT.

6. If you want to delete a virtual machine, you can do so by executing `vagrant destroy`.

## Ⅳ. Customizing the Cluster Environment Configuration

Basic directory structure

```
resources
scripts
.gitignore
README.md
VagrantFile
```

You can customize the cluster by modifying the files `VagrantFile`, `scripts/common.sh`, and the configuration files of each component in the `resources/component name` directory.

1. `VagrantFile` This file can set the version, number, name, hostname, IP, memory, CPU, etc. of the virtual machine, and can be modified according to your needs.

2. `scripts/common.sh` This file can set the version of each component.

   > Note: some components need to synchronize changes to XXX_VERSION and XXX_MIRROR_DOWNLOAD to ensure that the component version can be downloaded.

## Ⅴ. Initialization and Startup of Relevant Components After Installing the Cluster

### 1. SSH login

Execute the following command on each machine to enable passwordless login.

```
setssh
```

### 2. Start Hadoop and Test

#### 1) Startup

Execute the following commands on the `hadoop102` machine to format and start the Hadoop cluster.

```
hdfs namenode -format
start-dfs.sh
```

Execute the following commands on the `hadoop103` machine to start yarn and jobhistory.

```
start-yarn.sh
mr-jobhistory-daemon.sh start historyserver (mapred --damon)
```

or

```
bigstart hdp format
bigstart hdp start
```

#### 2) Test

Execute the following command to test whether yarn is successfully installed.

```
yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples*.jar pi 2 100
```

### 3. Start Spark (Standalone) and Test

#### 1) Startup

Execute the following command on the `hadoop102` machine.

```
$SPARK_HOME/sbin/start-all.sh
```

or

```
bigstart spark start
```

#### 2) Test

Execute the following command to test whether Spark is successfully installed.

```
hdfs dfs -mkdir /spark-log

spark-submit --class org.apache.spark.examples.SparkPi \\\\
--master yarn \\\\
--num-executors 1 \\\\
--executor-cores 2 \\\\
$SPARK_HOME/examples/jars/spark-examples*.jar 100
```

### 4. Start Flink

#### 1) Startup

Execute the following command on the `hadoop102` machine.

```
$FLINK_HOME/bin/start-cluster.sh
```

or

```
bigstart flink start
```

#### 2) Test

Execute the following command to test whether Flink is successfully installed.

```
# Batch WordCount
flink run $FLINK_HOME/examples/batch/WordCount.jar
```

### 5. Start Hive and Test

#### 1) Startup

Log in to the MySQL database on the `hadoop104` node to create the hive metadata database.(Completed during MySQL installation, **the default password for MySQL is 199037**)

```
# Create the hive metadata database
mysql -uroot -p199037 -e "create user 'hive'@'%' IDENTIFIED BY 'hive';GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION;grant all on *.* to 'hive'@'localhost' identified by 'hive';flush privileges;"
```

On the `hadoop102` node, initialize the metadata. When you see schemaTool completed, the initialization is successful!

```
schematool -initSchema -dbType mysql
```

Error: Exception in thread "main" java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument(ZLjava/lang/String;Ljava/lang/Object;)V

The two guava.jar versions of hadoop and hive are inconsistent.

The two locations are located in the following two directories:

- /usr/local/hive/lib/
- /usr/local/hadoop/share/hadoop/common/lib/

Solution: Delete the lower version, copy the higher version to the lower version directory.

#### 2) Hive Service Startup and Test

On the `hadoop102` node, create test data.

```
# Create data file
vi ~/stu.txt
```

The content is as follows:

```
00001,zhangsan
00002,lisi
00003,wangwu
00004,zhaoliu
```

Create a library table and load data into the Hive table.

```
# Start Hive
[atguigu@hadoop102 ~]$ hive
# Create table
hive (default)>  CREATE TABLE stu(id INT,name STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
# Load data
hive (default)> load data local inpath '/home/atguigu/stu.txt' into table stu;

hive (default)> SET hive.exec.mode.local.auto=true;

hive (default)> insert overwrite table stu
values ('00001','zhangsan'),
('00002','lisi'),
('00003','wangwu'),
('00004','zhaoliu');

# View library tables
hive (default)> select * from stu;
OK
1       zhangsan
2       lisi
3       wangwu
4       zhaoliu
Time taken: 3.301 seconds, Fetched: 4 row(s)
```

### 6. Start Zookeeper

Log in to the `hadoop102` node and execute the following command. (Note: cannot be executed as root)

```
bigstart zookeeper start(or stop)
```

Check the process by running `jpsall`:

```
[atguigu@hadoop102 ~]$ jpsall
--------------------- hadoop102 node ---------------------
2899 QuorumPeerMain
--------------------- hadoop103 node ---------------------
25511 QuorumPeerMain
--------------------- hadoop104 node ---------------------
25993 QuorumPeerMain
```

[PrettyZoo](https://github.com/vran-dev/PrettyZoo)

### 7. Start Elasticsearch

Log in to the `hadoop102` node and execute the following command. (Note: do not execute as root)

```
bigstart elasticsearch start (or stop)
```

Check the process by running `jpsall`:

```
[atguigu@hadoop102 ~]$ jpsall
--------------------- hadoop102 node ---------------------
3185 Kafka
2899 QuorumPeerMain
3365 Elasticsearch
--------------------- hadoop103 node ---------------------
25511 QuorumPeerMain
25800 Kafka
25964 Elasticsearch
--------------------- hadoop104 node ---------------------
26276 Kafka
26440 Elasticsearch
25993 QuorumPeerMain
```

Access http://hadoop102:9200/_cat/nodes?v to check the node status.

### 8. Start Kibana

Log in to the `hadoop102` node and execute the following command.

```
bigstart kibana start (or stop)
WARN: Establishing SSL connection without server's identity verification is not recommended. According to MySQL 5.5.45+, 5.6.26+ and 5.7.6+ requirements SSL connection must be established by default if explicit option isn't set. For compliance with existing applications not using SSL the verifyServerCertificate property is set to 'false'. You need either to explicitly disable SSL by setting useSSL=false, or set useSSL=true and provide truststore for server certificate verification.
```

Access http://hadoop102:5601/ to view.

### 9. Start Kafka

#### 1) Start

Log in to the `hadoop102` node and execute the following command:

```
bigstart zookeeper start
bigstart kafka start (or stop)
```

#### 2) Test

On the `hadoop102` node, execute the following command to create topic: test

```
# Before 2.2
kafka-topics.sh --zookeeper hadoop102:2181,hadoop103:2181,hadoop104:2181/kafka --create --topic test --replication-factor 1 --partitions 3

# 3.0.0
kafka-topics.sh --bootstrap-server hadoop102:9092,hadoop103:9092,hadoop104:9092 --create --topic test --replication-factor 1 --partitions 3
```

[Kafka error: Exception in thread "main" joptsimple.UnrecognizedOptionException: zookeeper is not a recogn](https://blog.csdn.net/succing/article/details/127334561)

On the `hadoop102` node, the producer produces data by executing the following command:

```
kafka-console-producer.sh --broker-list hadoop102:9092,hadoop103:9092,hadoop104:9092 --topic test
hello world
```

On the `hadoop104` node, the consumer consumes data by executing the following command:

```
kafka-console-consumer.sh --bootstrap-server hadoop102:9092,hadoop103:9092,hadoop104:9092 --topic test --from-beginning
```

### 10. Start Hbase

#### 1) Start

Log in to the `hadoop102` node and execute the following command:

```
bigstart zookeeper start
bigstart hbase start (or stop)
```

#### 2) Test

```
[atguigu@hadoop102 ~]$ jpsall
--------------------- hadoop102 node ---------------------
1507 DataNode
5224 HRegionServer
1401 NameNode
5065 HMaster
3099 QuorumPeerMain
--------------------- hadoop103 node ---------------------
1175 DataNode
2620 QuorumPeerMain
3372 HRegionServer
--------------------- hadoop104 node ---------------------
1280 SecondaryNameNode
1218 DataNode
1988 QuorumPeerMain
3102 HRegionServer
```

## VI. Web UI

The web pages of the big data components can be accessed through the following links.

[HDFS](http://hadoop102:9870/)

[ResourceManager](http://hadoop103:8088/)

[JobHistory](http://hadoop103:19888/jobhistory)

[Spark](http://hadoop102:8080/)

[Flink](http://hadoop102:8381/)

[Elasticsearch](http://hadoop102:9200/_cat/nodes?v)

[Kibana](http://hadoop102:5601/)

[Hbase](http://hadoop102:16010/)