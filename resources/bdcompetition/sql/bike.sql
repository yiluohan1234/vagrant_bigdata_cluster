-- 创建数据库
CREATE DATABASE IF NOT EXISTS hive;

-- 切换到数据库
use hive;

-- 创建数据表格，并上传本地数据至表内
create table if not exists bike(
duration int,
startdate string,
enddate string,
startnum int,
startstation string,
endnum int,
endstation string,
bikenum string,
type string)
row format delimited fields terminated by ',';

-- 2.统计本次数据所有单车数量（以单车车号进行计算，注意去重），结果写入本地/root/bike01/000000_0文件中。
load data local inpath '/root/bike/bike.csv' into table bike;

insert overwrite local directory '/root/bike01/'
row format delimited fields terminated by '\t'
select count(distinct bikenum) from bike;

-- 3.计算单车平均用时，结果写入本地/root/bike02/000000_0文件中，以分钟为单位，对数据结果取整数值（四舍五入）
insert overwrite local directory '/root/bike02/'
row format delimited fields terminated by '\t'
select round(avg(duration)/60000) from bike;

-- 4.统计常年用车紧张的地区站点top10，结果写入本地/root/bike03/000000_0文件中。(以stratstation为准)
insert overwrite local directory '/root/bike03/'
row format delimited fields terminated by '\t'
select startstation, count(*) as cnt from bike
group by startstation
order by cnt desc, startstation asc
limit 10;

-- 5.给出共享单车单日租赁排行榜，结果写入本地/root/bike04/000000_0文件中。（以startdate为准,结果格式为2021-09-14）
insert overwrite local directory '/root/bike04/'
row format delimited fields terminated by '\t'
select substr(startdate, 1, 10) as rental_date, count(*) as cnt from bike
group by substr(startdate, 1, 10)
order by cnt desc
limit 5;

-- 6.给出建议维修的单车编号（使用次数），结果写入本地/root/bike05/000000_0文件中
insert overwrite local directory '/root/bike05/'
row format delimited  fields terminated by '\t'
select bikenum, count(*) as usage_count from bike
group by bikenum
order by usage_count desc, bikenum asc
limit 10;

-- 7.给出可进行会员活动推广的地区，结果写入本地/root/bike06/000000_0文件中
insert overwrite local directory '/root/bike06/'
row format delimited  fields terminated by '\t'
select startstation, count(*) as cnt from bike
where type='Casual'
group by startstation
order by cnt desc, startstation asc
limit 10;

-- 8.给出可舍弃的单车站点，结果写入本地/root/bike07/000000_0文件中
insert overwrite local directory '/root/bike07/'
row format delimited  fields terminated by '\t'
select endstation, count(*) as cnt from bike
where type='Member'
group by endstation
order by cnt asc, endstation desc
limit 10;
