# atguigu_bigdata_cluster

## 一、基本介绍

本集群创建的组件如下表所示。

| 组件      | hadoop102                                             | hadoop103                     | hadoop104            |
| :-: | ---  | -------------------------- | ----------------- |
| OS   | centos7.6  | centos7.6             | centos7.6         |
| JDK  | jdk1.8                                             | jdk1.8                     | jdk1.8            |
| HDFS      | NameNode<br/>DataNode | DataNode<br/>JobHistoryServer | DataNode<br/>SecondaryNameNode |
| YARN      | NodeManager    | ResourceManager<br/>NodeManager | NodeManager       |
| Hive | Hive | NA | NA |
| HBase     | HMaster<br>HRegionServer                           | HRegionServer              | HRegionServer     |
| Spark     | master<br/>worker        | worker                     | worker            |
| Flink     | StandaloneSessionClusterEntrypoint<br/>TaskManagerRunner | TaskManagerRunner          | TaskManagerRunner |
| Zookeeper | QuorumPeerMain                                     | QuorumPeerMain             | QuorumPeerMain    |
| Kafka     | kafka                                              | Kafka                      | Kafka             |
| Flume     | flume                                              | flume                      | flume             |
| Scala     | scala                                              | scala                      | scala             |
| Maven     | mvn                                                | NA                         | NA                |
| Sqoop     | sqoop                                              | NA                         | NA                |
| MySQL     | NA                                                 | NA                         | MySQL Server      |
| Nginx | Nginx | NA | NA |
| Redis | Redis | NA                            | NA |
| Elasticsearch | Elasticsearch | Elasticsearch | Elasticsearch |
| Kibana | Kibana | NA | NA |


组件版本：

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
MySQL: 5.7.40（yum安装）
Nginx: 1.20.1（yum安装）
Redis: 3.2.12（yum安装）
Elasticsearch: 6.6.0
Kibana: 6.6.0
Canal: 1.25.0
Maxwell: 3.84.4
Presto: 0.196
Kylin: 3.0.2
```

## 二、基本准备

1. 集群默认启动三个节点，每个节点的默认内存是2G，所以你的机器至少需要6G
2. 我的测试环境软件版本：vagrant 2.2.14， Virtualbox 6.0.14

## 三、安装集群环境

1. [下载和安装VirtualBOX](https://www.virtualbox.org/wiki/Downloads)

2. [下载和安装vagrant](http://www.atguiguup.com/downloads.html)

3. 克隆本项目到本地，并cd到项目所在目录

   ```
   git clone https://github.com/yiluohan1234/vagrant_bigdata_cluster
   cd vagrant_bigdata_cluster
   ```

4. 执行`vagrant up` 创建虚拟机

5. 可以通过执行 `vagrant ssh` 登录到你创建的虚拟机，或通过SecureCRT等工具进行登录

6. 如果你想要删除虚拟机，可以通过执行`vagrant destroy` 来实现

## 四、自定义集群环境配置
基本目录结构

```
resources
scripts
.gitignore
README.md
VagrantFile
```

你可以通过修改`VagrantFile`、`scripts/common.sh`文件和`resources/组件名称`目录下各个组件的配置文件文件来实现自定义集群。

1. `VagrantFile`
   这个文件可以设置虚拟机的的版本、个数、名称、主机名、IP、内存、CPU等，根据自己需要更改即可。

2. `scripts/common.sh`
   这个文件可以设置各个组件的版本。

   > 注意：部分组件需要同步更改`XXX_VERSION`和`XXX_MIRROR_DOWNLOAD`，保证能下载到组件版本。


## 五、集群安装完毕后相关组件初始化及启动

### 1、ssh免登陆

在每台机器上执行以下

```
setssh
```

### 2、启动hadoop与测试

#### 1）启动

在 `hadoop102` 机器上执行以下命令对hadoop集群进行格式化，并启动hdfs和yarn。

```
hdfs namenode -format
start-dfs.sh
```

在 `hadoop103` 机器上执行以下命令，启动yarn和jobhistory。

```
start-yarn.sh
mr-jobhistory-daemon.sh start historyserver (mapred --damon)
```

或者

```
bigstart hdp format
bigstart hdp start
```

#### 2）测试

通过执行下列命令可以测试yarn是否安装成功。

```
yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples*.jar pi 2 100
```

### 3、启动Spark（Standalone ）与测试

#### 1）启动

在 `hadoop102` 机器上执行以下命令。

```
$SPARK_HOME/sbin/start-all.sh
```

或者

```
bigstart spark start
```

#### 2）测试

通过执行下列命令可以测试spark是否安装成功。

```
hdfs dfs -mkdir /spark-log

spark-submit --class org.apache.spark.examples.SparkPi \
--master yarn \
--num-executors 1 \
--executor-cores 2 \
$SPARK_HOME/examples/jars/spark-examples*.jar 100
```

### 4、启动Flink

#### 1）启动

在 `hadoop102` 机器上执行以下命令。

```
$FLINK_HOME/bin/start-cluster.sh
```

或者

```
bigstart flink start
```

#### 2）测试

通过执行下列命令可以测试Flink是否安装成功。

```
# 批量WordCount
flink run $FLINK_HOME/examples/batch/WordCount.jar
```

### 5、启动Hive与测试

#### 1）启动

~~在 `hadoop104` 节点登录MySQL数据库，创建hive的元数据库。~~（已在mysql安装时完成，**mysql默认密码为199037**）

```
# 创建hive的元数据库
mysql -uroot -p199037 -e "create user 'hive'@'%' IDENTIFIED BY 'hive';GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION;grant all on *.* to 'hive'@'localhost' identified by 'hive';flush privileges;"
```

在 `hadoop102` 节点，初始化元数据，看到 schemaTool completed ，即初始化成功！

```
schematool -initSchema -dbType mysql
```
报错：Exception in thread "main" java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument(ZLjava/lang/String;Ljava/lang/Object;)V

hadoop和hive的两个guava.jar版本不一致

两个位置分别位于下面两个目录：

- /usr/local/hive/lib/
- /usr/local/hadoop/share/hadoop/common/lib/

解决办法：
删除低版本的那个，将高版本的复制到低版本目录下

#### 2）Hive服务启动与测试

在 `hadoop102` 节点，创建测试数据

```
# 创建数据文件
vi ~/stu.txt
```

内容如下：

```
00001,zhangsan
00002,lisi
00003,wangwu
00004,zhaoliu
```

创建库表并加载数据到Hive表

```
# 启动hive
[atguigu@hadoop102 ~]$ hive
# 创建表
hive (default)>  CREATE TABLE stu(id INT,name STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
# 加载数据
hive (default)> load data local inpath '/home/atguigu/stu.txt' into table stu;

hive (default)> SET hive.exec.mode.local.auto=true;

hive (default)> insert overwrite table stu
values ('00001','zhangsan'),
('00002','lisi'),
('00003','wangwu'),
('00004','zhaoliu');

# 查看库表
hive (default)> select * from stu;
OK
1       zhangsan
2       lisi
3       wangwu
4       zhaoliu
Time taken: 3.301 seconds, Fetched: 4 row(s)
```
### 6、启动Zookeeper

在 `hadoop102` 节点登录执行以下命令。（注意：不能以root执行）

```
bigstart zookeeper start(或stop)
```

jpsall查看一下进程：

```
[atguigu@hadoop102 ~]$ jpsall 
--------------------- hadoop102节点 ---------------------
2899 QuorumPeerMain
--------------------- hadoop103节点 ---------------------
25511 QuorumPeerMain
--------------------- hadoop104节点 ---------------------
25993 QuorumPeerMain
```

[PrettyZoo](https://github.com/vran-dev/PrettyZoo)

### 7、启动Elasticsearch

在 `hadoop102` 节点登录执行以下命令。（注意：不能以root执行）

```
bigstart elasticsearch start(或stop)
```

jpsall查看一下进程：

```
[atguigu@hadoop102 ~]$ jpsall 
--------------------- hadoop102节点 ---------------------
3185 Kafka
2899 QuorumPeerMain
3365 Elasticsearch
--------------------- hadoop103节点 ---------------------
25511 QuorumPeerMain
25800 Kafka
25964 Elasticsearch
--------------------- hadoop104节点 ---------------------
26276 Kafka
26440 Elasticsearch
25993 QuorumPeerMain
```

访问 http://hadoop102:9200/_cat/nodes?v 查看节点状态。

### 8、启动Kibana

在 `hadoop102` 节点登录执行以下命令。

```
bigstart kibana start(或stop)
```

```
WARN: Establishing SSL connection without server's identity verification is not recommended. According to MySQL 5.5.45+, 5.6.26+ and 5.7.6+ requirements SSL connection must be established by default if explicit option isn't set. For compliance with existing applications not using SSL the verifyServerCertificate property is set to 'false'. You need either to explicitly disable SSL by setting useSSL=false, or set useSSL=true and provide truststore for server certificate verification.
```

访问 http://hadoop102:5601/ 查看。

### 9、启动Kafka

#### 1）启动

在 `hadoop102` 节点登录执行以下命令：

```
bigstart zookeeper start
bigstart kafka start(或stop)
```

#### 2）测试

在 `hadoop102` 节点执行以下命令，创建topic：test

```
# 2.2之前
kafka-topics.sh --zookeeper hadoop102:2181,hadoop103:2181,hadoop104:2181/kafka --create --topic test --replication-factor 1 --partitions 3
# 3.0.0
kafka-topics.sh --bootstrap-server hadoop102:9092,hadoop103:9092,hadoop104:9092 --create --topic test --replication-factor 1 --partitions 3
```

[Kafka报错：Exception in thread “main“ joptsimple.UnrecognizedOptionException: zookeeper is not a recogn](https://blog.csdn.net/succing/article/details/127334561)

在 `hadoop102` 节点执行以下命令，生产者生产数据

```
kafka-console-producer.sh --broker-list hadoop102:9092,hadoop103:9092,hadoop104:9092 --topic test
hello world
```

在 `hadoop104` 节点执行以下命令，消费者消费数据

```
kafka-console-consumer.sh --bootstrap-server hadoop102:9092,hadoop103:9092,hadoop104:9092 --topic test --from-beginning
```

### 10、启动Hbase

#### 1）启动

在 `hadoop102` 节点登录执行以下命令：

```
bigstart zookeeper start
bigstart hbase start(或stop)
```

#### 2）测试

```
[atguigu@hadoop102 ~]$ jpsall 
--------------------- hadoop102节点 ---------------------
1507 DataNode
5224 HRegionServer
1401 NameNode
5065 HMaster
3099 QuorumPeerMain
--------------------- hadoop103节点 ---------------------
1175 DataNode
2620 QuorumPeerMain
3372 HRegionServer
--------------------- hadoop104节点 ---------------------
1280 SecondaryNameNode
1218 DataNode
1988 QuorumPeerMain
3102 HRegionServer
```

## 六. Web UI

可以通过以下链接访问大数据组件的web页面。

[HDFS](http://hadoop102:9870)

[ResourceManager](http://hadoop103:8088)

[JobHistory](http://hadoop103:19888/jobhistory)

[Spark](http://hadoop102:8080/)

[Flink](http://hadoop102:8381/)

[Elasticsearch](http://hadoop102:9200/_cat/nodes?v)

[Kibana](http://hadoop102:5601/)

[Hbase](http://hadoop102:16010/)
