# vagrant_bigdata_cluster

## 一、基本介绍

本集群创建的组件如下表所示。



| 组件      | hdp101                                             | hdp102                     | hdp103            |
| :-: | ---  | -------------------------- | ----------------- |
| OS   | centos7.6  | centos7.6             | centos7.6         |
| JDK  | jdk1.8                                             | jdk1.8                     | jdk1.8            |
| HDFS      | NameNode<br>JobHistoryServer<br>ApplicationHistoryServer | DataNode<br>SecondaryNameNode | DataNode          |
| YARN      | ResourceManager                                    | NodeManager                | NodeManager       |
| Hive | Hive | NA | NA |
| HBase     | HMaster                                            | HRegionServer              | HRegionServer     |
| Spark     | master<br>HistoryServer                               | worker                     | worker            |
| Flink     | StandaloneSession<br>ClusterEntrypoint                 | TaskManagerRunner          | TaskManagerRunner |
| Zookeeper | QuorumPeerMain                                     | QuorumPeerMain             | QuorumPeerMain    |
| Kafka     | kafka                                              | Kafka                      | Kafka             |
| Flume     | flume                                              | flume                      | flume             |
| Scala     | scala2.11.12                                       | scala2.11.12               | scala2.11.12      |
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
Hadoop: 3.1.3
Hive: 2.3.4
Hbase: 2.0.5
Spark: 2.4.6
Flink: 1.12.4
Zookeeper: 3.5.7
Kafka: 2.4.1
Flume: 1.9.0
Scala: 2.11.12
Maven: 3.2.5
Sqoop: 1.4.7
MySQl Connector: 5.1.49
MySQL: 5.7.35
Nginx: 1.18.0
Redis: 5.0.12
Elasticsearch: 6.6.0
Kibana: 6.6.0
```

## 二、基本硬件准备

1. 集群默认启动三个节点，每个节点的默认内存是2G，所以你的机器至少需要6G
2. 我的测试环境：Vagrant 2.2.14， Virtualbox 6.0.14

## 三、安装集群环境

1. [下载和安装VirtualBOX](https://www.virtualbox.org/wiki/Downloads)

2. [下载和安装Vagrant](http://www.vagrantup.com/downloads.html)

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

在`hdp101`机器上执行以下命令对hadoop集群进行格式化，并启动hdfs和yarn。

```
hdfs namenode -format
start-dfs.sh
start-yarn.sh
mr-jobhistory-daemon.sh start historyserver 
```

或者

```
bigstart dfs start
bigstart yarn start
```

#### 2）测试

通过执行下列命令可以测试yarn是否安装成功。

```
yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples*.jar pi 2 100
```

### 3、启动Spark（Standalone ）与测试

#### 1）启动

（1）上传并解压spark-3.0.0-bin-without-hadoop.tgz

```
tar -zxvf /opt/software/spark-3.0.0-bin-without-hadoop.tgz
```

（2）上传Spark纯净版jar包到HDFS

```
hadoop fs -mkdir /spark-jars
hadoop fs -put spark-3.0.0-bin-without-hadoop/jars/* /spark-jars
```

在`hdp101`机器上执行以下命令。

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

spark-submit --master spark://hdp101:7077 \
--deploy-mode cluster \
--class org.apache.spark.examples.SparkPi \
$SPARK_HOME/examples/jars/spark-examples*.jar 100

spark-submit --class org.apache.spark.examples.SparkPi \
--master yarn \
--num-executors 1 \
--executor-cores 2 \
$SPARK_HOME/examples/jars/spark-examples*.jar 100
```

### 4、启动Flink

#### 1）启动

在`hdp101`机器上执行以下命令。

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

~~在`hdp103`节点登录MySQL数据库，创建hive的元数据库。~~（已在mysql安装时完成，**mysql默认密码为199037**）

```
# 创建hive的元数据库
mysql -uroot -p199037 -e "create user 'hive'@'%' IDENTIFIED BY 'hive';GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION;grant all on *.* to 'hive'@'localhost' identified by 'hive';flush privileges;"
```

在`hdp101`节点，初始化元数据，看到 schemaTool completed ，即初始化成功！

```
schematool -initSchema -dbType mysql
```

#### 2）Hive服务启动与测试

在`hdp101`节点，创建测试数据

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
[vagrant@hdp101 ~]$ hive
# 创建表
hive (default)>  CREATE TABLE stu(id INT,name STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
# 加载数据
hive (default)> load data local inpath '/home/vagrant/stu.txt' into table stu;
# 查看库表
hive (default)> select * from stu;
OK
1       zhangsan
2       lisi
3       wangwu
4       zhaoliu
Time taken: 3.301 seconds, Fetched: 4 row(s)
```

### 6、启动Elasticsearch

在`hdp101`节点登录执行以下命令。

```
bigstart es start(或stop)
```

jpsall查看一下进程：

```
[vagrant@hdp101 ~]$ jpsall 
--------------------- hdp101节点 ---------------------
3185 Kafka
2899 QuorumPeerMain
3365 Elasticsearch
--------------------- hdp102节点 ---------------------
25511 QuorumPeerMain
25800 Kafka
25964 Elasticsearch
--------------------- hdp103节点 ---------------------
26276 Kafka
26440 Elasticsearch
25993 QuorumPeerMain
```

### 7、启动Kibana

在`hdp101`节点登录执行以下命令。

```
bigstart kibana start(或stop)
```



## 六. Web UI

可以通过以下链接访问大数据组件的web页面。

[HDFS](http://hdp101:9870)

[ResourceManager](http://hdp102:8088)

[JobHistory](http://hdp101:19888/jobhistory)

[Spark](http://hdp101:8080/)

[Flink](http://hdp101:8381/)

[Elasticsearch](http://hdp101:9200/_cat/nodes?v)

[Kibana](http://hdp101:5601/)

[Hbase](http://hdp101:16010/)
