-- 创建数据库
CREATE DATABASE IF NOT EXISTS msg;

-- 切换到数据库
use msg;

-- 创建数据表格，并上传本地数据至表内
create table if not exists ods_chat(
msg_time           string,
sender_name        string,
sender_account     string,
sender_gender      string,
sender_ip          string,
sender_os          string,
sender_phonemodel  string,
sender_network     string,
sender_gps         string,
receiver_name      string,
receiver_ip        string,
receiver_account   string,
receiver_os        string,
receiver_phonetype string,
receiver_network   string,
receiver_gps       string,
receiver_gender    string,
msg_type           string,
distance           string)
row format delimited fields terminated by '\t';

load data local inpath '/root/chat.tsv' into table ods_chat;

create table if not exists dwd_chat_etl(
msg_time           string,
sender_name        string,
sender_account     string,
sender_gender      string,
sender_ip          string,
sender_os          string,
sender_phonemodel  string,
sender_network     string,
sender_gps         array<string>,
receiver_name      string,
receiver_ip        string,
receiver_account   string,
receiver_os        string,
receiver_phonetype string,
receiver_network   string,
receiver_gps       string,
receiver_gender    string,
msg_type           string,
distance           string)
partitioned by (dt string, hr string)
row format delimited fields terminated by '\t';


--动态分区配置
set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.exec.max.dynamic.partitions.pernode=100000;
set hive.exec.max.dynamic.partitions=100000;
set hive.exec.max.created.files=100000;
--本地模式
--set hive.exec.mode.local.auto=true;
--set mapreduce.map.memory.mb=1025;
--set mapreduce.reduce.memory.mb=1025;
--set hive.exec.mode.local.auto.input.files.max=25;

insert overwrite table dwd_chat_etl partition(dt, hr)
select
msg_time,
sender_name,
sender_account,
sender_gender,
sender_ip,
sender_os,
sender_phonemodel,
sender_network,
split(sender_gps, ',') as sender_gps,
receiver_name,
receiver_ip,
receiver_account,
receiver_os,
receiver_phonetype,
receiver_network,
receiver_gps,
receiver_gender,
msg_type,
distance,
substring(msg_time,9,2) as dt,
substring(msg_time,12,2) as hr
from ods_chat
where sender_gps is not null AND length(sender_gps) > 0;


-- 统计单日消息量，结果到出至本地/msg/ads/hour_msg_cn路径下
insert overwrite local directory '/msg/ads/hour_msg_cn'
row format delimited fields terminated by ','
SELECT
dt,
COUNT(*)
FROM dwd_chat_etl
GROUP BY dt;

-- 统计单日内不同时段消息量分布，将统计结果导出到本地的 /msg/ads/hour_msg_cnt
insert overwrite local directory '/msg/ads/hour_msg_cnt'
row format delimited fields terminated by ','
select
hr,
count(*)
from dwd_chat_etl
group by hr;

-- 统计单日不同时段下不同性别发送消息数，将统计结果导出到本地的/msg/ads/hour_gender_cnt
insert overwrite local directory '/msg/ads/hour_gender_cnt'
row format delimited fields terminated by ','
select
  dt,
  case
    when hr in ('01', '02', '03', '04') then '凌晨'
    else 'Other'
  end as time_of_day,
  sender_gender,
  count(*) as msg_count
from msg.dwd_chat_etl
where sender_gender is not null
group by
  dt,
  case
    when hr in ('01', '02', '03', '04') then '凌晨'
    else 'Other'
  end,
  sender_gender;

-- 统计单日发送消息最多的Top10用户
insert overwrite local directory '/msg/ads/susr_top10'
row format delimited fields terminated by ','
SELECT
dt,
sender_name,
COUNT(*) AS msg_count
FROM msg.dwd_chat_etl
GROUP BY dt, sender_name
order by msg_count desc
limit 10;

-- 统计单日接收消息最多的Top10用户
insert overwrite local directory '/msg/ads/rusr_top10'
row format delimited fields terminated by ','
SELECT
dt,
receiver_name,
COUNT(*) AS msg_count
FROM msg.dwd_chat_etl
GROUP BY dt, receiver_name
order by msg_count desc
limit 10;

-- 查找关系最亲密的10对好友
insert overwrite local directory '/msg/ads/chat_friend'
row format delimited fields terminated by ','
SELECT
dt,
sender_name,
receiver_name,
COUNT(*) AS msg_count
FROM msg.dwd_chat_etl
GROUP BY dt, sender_name, receiver_name
order by msg_count desc
limit 10;

-- 统计单日各地区发送消息数据量
insert overwrite local directory '/msg/ads/loc_msg_cnt'
row format delimited fields terminated by ','
SELECT
dt,
sender_gps[0],
sender_gps[1],
COUNT(*) AS msg_count
FROM msg.dwd_chat_etl
GROUP BY dt, sender_gps[0], sender_gps[1]
order by msg_count desc;
