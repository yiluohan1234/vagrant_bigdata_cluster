-- 创建数据库
CREATE DATABASE IF NOT EXISTS comm;

-- 切换到数据库
use comm;

-- 创建数据表格，并上传本地数据至表内
create table if not exists comm.dim_date (
date_id string,
week_id string,
week_day string,
day string,
month string,
quarter string,
year string,
is_workday string,
holiday_id string
)
row format delimited fields terminated by '\t'
location '/behavior/dim/dim_date'
tblproperties('skip.header.line.count'='1');
load data local inpath '/root/bigdata/data/dim_date_2023.txt' into table comm.dim_date;

-- 2.在 comm 数据库下创建一个名为 dim_area 的外部表，如果表已存在，则先删除。
drop table if exists comm.dim_area;
create external table comm.dim_area (
city string,
province string,
area string
)
row format delimited fields terminated by '\t'
location '/behavior/dim/dim_area';
load data local inpath '/root/bigdata/data/dim_area.txt' into table comm.dim_area;

-- 3.统计不同省份用户访问量
insert overwrite local directory '/root/bigdata/result/ads_user_pro'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
select
province,
count(*) as cnt
from comm.dwd_behavior_log
group by province;

-- 4.统计每天不同经济大区用户访问量
INSERT OVERWRITE LOCAL DIRECTORY '/root/bigdata/result/ads_user_region'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT a.dt, b.area, COUNT(*) AS cnt
FROM dws_behavior_log a
JOIN dim_area b
ON a.province = b.province AND a.city = b.city
GROUP BY a.dt, b.area;

-- 5.统计不同时间段s的网页浏览量
insert overwrite local directory '/root/bigdata/result/ads_user_hour'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
select
substring(from_utc_timestamp(ts,'Asia/Shanghai'), 12, 2) as diff_hour,
count(*) as cnt
from comm.dws_behavior_log
group by substring(from_utc_timestamp(ts,'Asia/Shanghai'), 12, 2);

-- 6.统计节假日和工作日的各个时间段内网页的平均浏览量
insert overwrite local directory '/root/bigdata/result/ads_hol_work_user'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT
substring(from_utc_timestamp(ts,'Asia/Shanghai'), 12, 2) as visit_hour,
sum(CASE WHEN is_workday = 0 THEN 1 ELSE 0 END) AS holiday,
sum(CASE WHEN is_workday = 1 THEN 1 ELSE 0 END) AS workday
FROM dws_behavior_log  a
join dim_date b
on to_date(from_utc_timestamp(a.ts,'Asia/Shanghai'))=b.date_id
GROUP BY substring(from_utc_timestamp(ts,'Asia/Shanghai'), 12, 2);

-- 7.不同网站访客的设备类型统计
insert overwrite local directory '/root/bigdata/result/ads_visit_mode'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
select
url, device_type,
count(*) as cnt
from comm.dws_behavior_log
group by url, device_type;

-- 8.不同网站的上网模式统计
insert overwrite local directory '/root/bigdata/result/ads_online_type'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
select
url, type,
count(*) as cnt
from comm.dws_behavior_log
group by url, type;

-- 9.不同域名的用户访问量
insert overwrite local directory '/root/bigdata/result/ads_user_domain'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT
split(url, '\\.')[1] as domain,
count(*) as cnt
FROM dws_behavior_log
group by split(url, '\\.')[1];
