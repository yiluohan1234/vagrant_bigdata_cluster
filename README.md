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
Hadoop: 2.7.6
Hive: 2.3.4
Hbase: 1.2.6
Spark: 2.4.6
Flink: 1.12.4
Zookeeper: 3.4.10
Kafka: 0.11.0.3
Flume: 1.6.0
Scala: 2.11.12
Maven: 3.2.5
Sqoop: 1.4.7
MySQl Connector: 5.1.49
MySQL: 5.7.30
Nginx: 1.18.0
Redis: 6.2.1
Elasticsearch: 7.6.0
Kibana: 7.6.0
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

在hdp101机器上执行以下命令对hadoop集群进行格式化，并启动hdfs和yarn。

```
[vagrant@hdp101 ~]$ hdfs namenode -format
[vagrant@hdp101 ~]$ start-dfs.sh
[vagrant@hdp101 ~]$ start-yarn.sh
[vagrant@hdp101 ~]$ mr-jobhistory-daemon.sh start historyserver 
```

或者

```
[vagrant@hdp101 ~]$ bigstart dfs start
[vagrant@hdp101 ~]$ bigstart yarn start
```

#### 2）测试

通过执行下列命令可以测试yarn是否安装成功。

```
[vagrant@hdp101 ~]$ yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples*.jar pi 2 100
```

### 3、启动Spark（Standalone ）与测试

#### 1）启动

在hdp101机器上执行以下命令。

```
[vagrant@hdp101 ~]$ $SPARK_HOME/sbin/start-all.sh
```

或者

```
[vagrant@hdp101 ~]$ bigstart spark start
```

#### 2）测试

通过执行下列命令可以测试spark是否安装成功。

```
[vagrant@hdp101 ~]$ hdfs dfs -mkdir /spark-log
[vagrant@hdp101 ~]$ spark-submit --master spark://hdp101:7077 --deploy-mode cluster --class org.apache.spark.examples.SparkPi $SPARK_HOME/examples/jars/spark-examples*.jar 100
[vagrant@hdp101 ~]$ spark-submit --class org.apache.spark.examples.SparkPi --master yarn --num-executors 1 --executor-cores 2 $SPARK_HOME/examples/jars/spark-examples*.jar 100
```

### 4、启动Flink

#### 1）启动

在hdp101机器上执行以下命令。

```
[vagrant@hdp101 ~]$ $FLINK_HOME/bin/start-cluster.sh
```

或者

```
[vagrant@hdp101 ~]$ bigstart flink start
```

#### 2）测试

通过执行下列命令可以测试Flink是否安装成功。

```
# 批量WordCount
[vagrant@hdp101 ~]$ flink run $FLINK_HOME/examples/batch/WordCount.jar
```

### 5、启动Hive与测试

#### 1）启动

在hdp103节点登录MySQL数据库，创建hive的元数据库。

```
# 创建hive的元数据库
[vagrant@hdp103 ~]$ mysql -uroot -p199037 -e "create user 'hive'@'%' IDENTIFIED BY 'hive';GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION;grant all on *.* to 'hive'@'localhost' identified by 'hive';flush privileges;"
```

在hdp101节点，初始化元数据，看到 schemaTool completed ，即初始化成功！

```
[vagrant@hdp101 ~]$ schematool -initSchema -dbType mysql
```

#### 2）Hive服务启动与测试

```
# 创建数据文件
[vagrant@hdp101 ~]$ vi ~/stu.txt

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

在hdp101节点登录执行以下命令。

```
[vagrant@hdp101 ~]$ bigstart es start(或stop)
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

在hdp101节点登录执行以下命令。

```
[vagrant@hdp101 ~]$ bigstart kibana start(或stop)
```



## 六. Web UI

可以通过以下链接访问大数据组件的web页面。

[NameNode](http://hdp101:50070)

[ResourceManager](http://hdp101:8088)

[JobHistory](http://hdp101:19888/jobhistory)

[Spark](http://hdp101:8080/)

[Flink](http://hdp101:8381/)

[Elasticsearch](http://hdp101:9200/_cat/nodes?v)