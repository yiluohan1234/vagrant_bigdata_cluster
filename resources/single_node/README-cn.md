# 单节点伪集群安装

## 一、基本介绍

本集群创建的组件如下表所示。

| 组件      | hadoop000                                           |
| :-: | ---  |
| OS   | centos7.6  |
| JDK  | jdk1.8.221                                         |
| Hadoop    | 2.7.7 |
| Hive      | 2.3.4 |
| Tez | 0.8.4 |
| Scala | 2.11.11 |
| Spark     | 2.4.3                      |
| Zookeeper | 3.6.3                                 |
| Kafka     | kafka                                              |
| Hbase | 1.4.8 |
| Phoenix | 4.15.0 |

## 二、基本准备

1. 集群节点的默认内存是8G，CPU2核
2. 我的测试环境软件版本：vagrant 2.3.7， Virtualbox 6.1.42

## 三、安装集群环境

1. [下载和安装VirtualBOX](https://www.virtualbox.org/wiki/Downloads)

2. [下载和安装vagrant](http://www.atguiguup.com/downloads.html)

3. 创建 `D:\javaEnv\bigdata_single_node`，并cd到目录中执行如下命令进行安装

   ```
   curl -O https://ghproxy.com/https://raw.githubusercontent.com/yiluohan1234/vagrant_bigdata_cluster/master/resources/single_node/VagrantFile | vagrant up
   ```

## 四、初始化
```
bigstart dfs format 
bigstart dfs start
bigstart dfs initTez
bigstart dfs initSpark
```
