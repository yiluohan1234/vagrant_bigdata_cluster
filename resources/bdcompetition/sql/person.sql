-- 创建数据库
CREATE DATABASE IF NOT EXISTS hive;

-- 切换到数据库
use hive;

-- 创建数据表格，并上传本地数据至表内
create table if not exists person(
age double,
workclass string,
fnlwgt string,
edu string,
edu_num string,
marital_status string,
occupation string,
relationship string,
race string,
sex string,
gain string,
loss string,
hours double,
native string,
income string)
row format delimited fields terminated by ',';
load data local inpath '/root/college/person.csv' into table person;

-- 2.统计表数据,结果写入本地 `/root/college000/` 中
insert overwrite local directory '/root/college000/'
row format delimited fields terminated by '\t'
select count(*) from person;

-- 3.计算较高收入人群占整体数据的比例
insert overwrite local directory '/root/college011/'
row format delimited fields terminated by '\t'
select round(v/s, 2) as ratio
from (
select
sum(case when income = '>50K' then 1 else 0 end) as v,
count(*) as s
from person
) t;

-- 4.计算学历为本科的人员在调查中的占比
insert overwrite local directory '/root/college012'
row format delimited fields terminated by '\t'
select round(bachelors_count / total_count, 2) as ratio
from (
select
sum(case when edu = 'Bachelors' then 1 else 0 end) as bachelors_count,
count(*) as total_count
from person
) t;

-- 5.计算青年群体中高收入年龄层排行
insert overwrite local directory '/root/college013'
row format delimited fields terminated by '\t'
select age, count(*) cnt from person
where age>=15 and age<=34 and income='>50K'
group by age
order by cnt desc, age limit 10;

-- 6.计算男性群体中高收入职业排行
insert overwrite local directory '/root/college014'
row format delimited fields terminated by '\t'
select occupation, count(*) cnt from person
where sex='Male' and income='>50K'
group by occupation
order by cnt desc, occupation limit 5;

-- 7.对未婚人群高收入职业排行
insert overwrite local directory '/root/college015'
row format delimited fields terminated by '\t'
select occupation, count(*) cnt from person
where marital_status='Never-married' and income='>50K'
group by occupation
order by cnt desc, occupation limit 5;

-- 8.统计性别对于收入的影响
set hive.strict.checks.cartesian.product=false;
insert overwrite local directory '/root/college016/'
row format delimited fields terminated by '\t'
select sex, round(v/s, 2) per from
(select sex, count(*) v from person where income='>50K' group by sex order by v desc)t1
cross join
(select count(*) s from person where income='>50K')t2;

-- 9.统计教育程度对于收入的影响
insert overwrite local directory '/root/college017/'
row format delimited fields terminated by '\t'
select edu, count(*) cnt from person
where income='>50K'
group by edu
order by cnt desc, edu;

-- 10.计算不同收入的平均工作时间
insert overwrite local directory '/root/college018/'
row format delimited fields terminated by '\t'
select income, round(avg(hours)) avg_hours from person
group by income order by avg_hours desc;
