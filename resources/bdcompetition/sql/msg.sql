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
distance           string,
message            string)
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
sender_gps         string,
sender_lng         string,
sender_lat         string,
receiver_name      string,
receiver_ip        string,
receiver_account   string,
receiver_os        string,
receiver_phonetype string,
receiver_network   string,
receiver_gps       string,
receiver_gender    string,
msg_type           string,
distance           string,
message            string)
partitioned by (dt string, hr string)
stored as orc;

--动态分区配置
set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;

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
sender_gps,
split(sender_gps,',')[0] as sender_lng,
split(sender_gps,',')[1] as sender_lat,
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
message,
to_date(msg_time) as dt,
substring(msg_time,12,2) as hr
from ods_chat
where length(sender_gps) > 0;

-- create table dws_chat(
-- msg_time           string,
-- sender_name        string,
-- sender_account     string,
-- sender_gender      string,
-- sender_ip          string,
-- sender_os          string,
-- sender_phonemodel  string,
-- sender_network     string,
-- sender_gps         string,
-- sender_lng         string,
-- sender_lat         string,
-- receiver_name      string,
-- receiver_ip        string,
-- receiver_account   string,
-- receiver_os        string,
-- receiver_phonetype string,
-- receiver_network   string,
-- receiver_gps       string,
-- receiver_gender    string,
-- msg_type           string,
-- distance           string,
-- message            string)
-- partitioned by (dt string, hr string)
-- stored as orc
-- tblproperties('orc.compress'='snappy');

-- insert overwrite table dws_chat partition(dt, hr)
-- select * from dwd_chat_etl;

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
dt,
hr,
count(*)
from dwd_chat_etl
group by dt, hr;

-- 统计单日不同时段下不同性别发送消息数，将统计结果导出到本地的/msg/ads/hour_gender_cnt
insert overwrite local directory '/msg/ads/hour_gender_cnt'
row format delimited fields terminated by ','
select
  dt,
  case
    when hr < 1 or hr >= 23 then '子夜'
    when hr < 5 then '凌晨'
    when hr < 8 then '早上'
    when hr < 11 then '上午'
    when hr < 13 then '中午'
    when hr < 17 then '下午'
    when hr < 19 then '傍晚'
    when hr < 23 then '晚上'
  end as time_of_day,
  sender_gender,
  count(*) as msg_count
from msg.dwd_chat_etl
group by
  dt,
  case
    when hr < 1 or hr >= 23 then '子夜'
    when hr < 5 then '凌晨'
    when hr < 8 then '早上'
    when hr < 11 then '上午'
    when hr < 13 then '中午'
    when hr < 17 then '下午'
    when hr < 19 then '傍晚'
    when hr < 23 then '晚上'
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
case when sender_name <= receiver_name then sender_name else receiver_name end as user1,
case when sender_name > receiver_name then sender_name else receiver_name end as user2,
COUNT(*) AS msg_count
FROM msg.dwd_chat_etl
GROUP BY
case when sender_name <= receiver_name then sender_name else receiver_name end,
case when sender_name > receiver_name then sender_name else receiver_name end
order by msg_count desc
limit 10;

-- 统计单日各地区发送消息数据量
insert overwrite local directory '/msg/ads/loc_msg_cnt'
row format delimited fields terminated by '\t'
SELECT
dt,
sender_gps,
cast(sender_lng as double) as longitude,
cast(sender_lat as double) as latitude,
COUNT(*) AS msg_count
FROM msg.dwd_chat_etl
GROUP BY dt, sender_gps, sender_lng, sender_lat
order by msg_count desc;
