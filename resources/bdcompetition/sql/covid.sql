-- 创建数据库
CREATE DATABASE IF NOT EXISTS covid_ods;
--动态分区配置
set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;

-- 创建数据表格，并上传本地数据至表内
create table if not exists covid_ods.covid(
continerName string,
countryName string,
provinceName string,
province_confirm int,
province_suspect int,
province_cured int,
province_dead int,
cityName string,
city_confirm int,
city_suspect int,
city_cured int,
city_dead int,
updateTime string)
row format delimited fields terminated by ','
TBLPROPERTIES ('skip.header.line.count'='1');

load data local inpath '/root/covid/covid_area.csv' into table covid_ods.covid;

-- 3.数据库covid_ods下创建covid_time表，用于提取有用数据，过滤重复值，只保留每天最后更新的数据
create table if not exists covid_ods.covid_time(
provinceName string,
cityName string,
city_confirm int,
city_suspect int,
city_cured int,
city_dead int,
updateTime string)
row format delimited fields terminated by ',';

-- 4.按照要求向covid_ods.covid_time插入过滤后的数据
insert overwrite table covid_ods.covid_time
select provinceName, cityName, city_confirm, city_suspect, city_cured, city_dead, updateTime
from
(select *,
row_number() over(partition by cityName, substr(updateTime,1,10) order by substr(updateTime,12,2) desc, substr(updateTime,15,2) desc, substr(updateTime,18,2) desc) rk from covid_ods.covid
where countryName='中国' and provinceName != '中国' and cityName !='')t1
where rk=1;

-- 5.创建名为covid_dwd的数据库，此层将数据进行分区，便于数据的快速获取
create database if not exists covid_dwd;

-- 6.数据库covid_dwd下创建province表，按照年、月分区，要求根据当天时间获取昨天对应时间列，并插入对应数据
create table if not exists covid_dwd.province(
provinceName string,
cityName string,
city_confirm int,
city_suspect int,
city_cured int,
city_dead int,
updateTime string,
yesterday string)
partitioned by(yearinfo string, monthinfo string)
row format delimited fields terminated by ',';

insert overwrite table covid_dwd.province partition(yearinfo, monthinfo)
select
provinceName,cityName,city_confirm,city_suspect,city_cured,city_dead,
substr(updateTime,1,10) updateTime,
date_sub(updateTime,1) yesterday,
substr(updateTime,1,4) yearinfo,
substr(updateTime,6,2) monthinfo
from covid_ods.covid_time;

-- 7.创建名为covid_dwm的数据库，用于统计每个省份的各指标增长量
create database if not exists covid_dwm;

-- 8.数据库covid_dwm下创建two_day表，将province中当天数据和前一天的数据进行汇总，通过join方式将数据合并为一条数据
create table if not exists covid_dwm.two_day(
provinceName string,
cityName string,
city_confirm int,
city_suspect int,
city_cured int,
city_dead int,
updateTime string,
city_confirm_before int,
city_suspect_before int,
city_cured_before int,
city_dead_before int,
yesterday string)
partitioned by(yearinfo string, monthinfo string)
row format delimited fields terminated by ',';

-- 检测
insert overwrite table covid_dwm.two_day partition(yearinfo, monthinfo)
select a.provinceName,a.cityName,
a.city_confirm,a.city_suspect,a.city_cured,a.city_dead,a.updateTime,
b.city_confirm,b.city_suspect,b.city_cured,b.city_dead,a.yesterday,
substr(a.updateTime,1,4) yearinfo,
substr(a.updateTime,6,2) monthinfo
from covid_dwd.province a
join
covid_dwd.province b
on a.provinceName=b.provinceName and a.cityName=b.cityName and a.yesterday=b.updateTime;

-- 9.将表two_day中所有内容保存至云主机/root/covid/two_day.csv
insert overwrite local directory '/root/covid/two_day.csv'
row format delimited fields terminated by '\t'
select * from covid_dwm.two_day;

-- 10.创建数据库covid_dws
create database if not exists covid_dws;

-- 11.数据库covid_dws下创建day表，用于计算地区每日指标增量
create table if not exists covid_dws.day(
provinceName string,
cityName string,
new_city_confirm int,
new_city_suspect int,
new_city_cured int,
new_city_dead int,
updateTime string)
partitioned by(yearinfo string, monthinfo string)
row format delimited fields terminated by ',';

-- updateTime为实际更新日期(ppt)
insert overwrite table covid_dws.day partition(yearinfo,monthinfo)
select * from
(select provinceName,cityName,
(city_confirm-city_confirm_before) as new_city_confirm,
(city_suspect-city_suspect_before) as new_city_suspect,
(city_cured-city_cured_before) as new_city_cured,
(city_dead-city_dead_before) as new_city_dead,
updateTime,
substr(updateTime,1,4) yearinfo,
substr(updateTime,6,2) monthinfo
from covid_dwm.two_day)c
where
new_city_confirm>=0
and new_city_suspect>=0
and new_city_cured>=0
and new_city_dead>=0;

-- 12.将表day中所有内容保存至云主机/root/covid/day.csv
insert overwrite local directory '/root/covid/day.csv'
row format delimited fields terminated by '\t'
select * from covid_dws.day;

-- 13.创建名为covid_app的数据库
create database if not exists covid_app;

-- 14.数据库covid_app下创建day_app层业务表，进行各个省份每日的指标增量情况统计
create table if not exists covid_app.day_app(
provinceName string,
new_city_confirm int,
new_city_suspect int,
new_city_cured int,
new_city_dead int,
updateTime string)
partitioned by(yearinfo string, monthinfo string)
row format delimited fields terminated by ',';

-- 统计各个省份每日指标增量
insert overwrite table covid_app.day_app partition(yearinfo, monthinfo)
select provinceName,
sum(new_city_confirm) new_city_confirm,
sum(new_city_suspect) new_city_suspect,
sum(new_city_cured) new_city_cured,
sum(new_city_dead) new_city_dead,
updateTime,
substr(updateTime,1,4) yearinfo,
substr(updateTime,6,2) monthinfo
from covid_dws.day
group by yearinfo,monthinfo,provinceName,updateTime;

-- 15.将表day_app中所有内容保存至云主机/root/covid/day_app.csv
insert overwrite local directory '/root/covid/day.csv'
row format delimited fields terminated by '\t'
select * from covid_app.day_app;

