-- 创建数据库
CREATE DATABASE IF NOT EXISTS project;

-- 切换到数据库
use project;

-- 创建数据表格，并上传本地数据至表内
create table if not exists theft(
id string,
case_type string,
case_subtype string,
casename string,
loss string,
case_source string,
time_toplimit string,
time_lowerlimit string,
address string,
accept_time string,
report_time string
)
row format delimited
fields terminated by ',';

load data local inpath '/root/college/theft.csv' into table theft;

-- 统计2021年5月份发生的案件总数
insert overwrite local directory '/root/theft/result01/'
row format delimited fields terminated by '\t'
select count(*) from theft where report_time like '2021年05月%';

-- 统计2021年4月份经济损失总额
insert overwrite local directory '/root/theft/result02/'
row format delimited fields terminated by '\t'
select sum(split(loss,'元')[0]) from theft where report_time like '2021年04月%';

-- 查询室发频次最高的地区及对应的案发频次
insert overwrite local directory '/root/theft/result03/'
row format delimited fields terminated by '\t'
select address, count(*) cnt from theft group by address order by cnt desc limit 1;

-- 统计“经济损失”最少的案件副类别
insert overwrite local directory '/root/theft/result04/'
row format delimited fields terminated by '\t'
select case_subtype, sum(split(loss,'元')[0]) sum_loss from theft group by case_subtype order by sum_loss limit 1;
