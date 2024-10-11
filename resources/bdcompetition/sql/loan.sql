-- 创建hive数据库
CREATE DATABASE IF NOT EXISTS hive;

-- 切换到hive数据库
use hive;

-- 创建数据表格loan，并上传本地数据至表内
create table if not exists loan (
LoanStatus string,
BorroweRate decimal(10,5),
ProsperScore int,
Occupation string,
EmploymentStatus string,
IsBorrowerHomeowner string,
CreditScoreRangeLower int,
CreditScoreRangeUpper int,
IncomRange string)
row format delimited fields terminated by ',';

-- 4.将提供的分析数据导入到表loan中，并统计数据至本地/root/college000/000000_0文件中
load data local inpath '/root/loan/loan.csv' into table loan;

insert overwrite local directory '/root/college000'
row format delimited fields terminated by '\t'
select count(*) from loan;

-- 5.以信用得分ProsperScore为变量，对借款进行计数统计（降序），结果写入本地/root/college001/000000_0文件中
insert overwrite local directory '/root/college001'
row format delimited fields terminated by '\t'
select ProsperScore,
count(*) as sum
from loan
group by ProsperScore
order by sum desc;

-- 6.给出贷款较多的行业top5，结果写入到本地/root/college002/000000_0文件中
insert overwrite local directory '/root/college002'
row format delimited fields terminated by '\t'
select Occupation,
count(*) as sum
from loan
group by Occupation
order by sum desc
limit 5;

-- 7.分析贷款为违约状态(Defaulted)的贷款人就业信息，将结果top3写入/root/college003/000000_0文件中
insert overwrite local directory '/root/college003'
row format delimited fields terminated by '\t'
select EmploymentStatus,
count(*) as sum
from loan
where LoanStatus = "Defaulted"
group by EmploymentStatus
order by sum desc
limit 3;

-- 8.对数据中收入范围进行分组统计（降序），查看贷款人收入情况，将结果写入/root/college004/000000_0文件中
insert overwrite local directory '/root/college004'
row format delimited fields terminated by '\t'
select IncomRange,
count(*) as sum
from loan
group by IncomRange
order by sum desc;

-- 9.对信用得分上限及下限进行中间数求值作为职业信用分，对职业进行分组，计算职业信用分top5（具体步骤见说明）。结果写入/root/college005/000000_0文件
insert overwrite local directory '/root/college005'
row format delimited fields terminated by '\t'
select Occupation, max(CreditScore) as c from
(select Occupation, CreditScoreRangeLower, CreditScoreRangeUpper,(CreditScoreRangeLower+CreditScoreRangeUpper)/2 as CreditScore from loan)t1
group by Occupation
order by c desc, Occupation asc limit 5;

-- 10.支持度写到本地/root/college006/000000_0文件中（保留五位小数）
set hive.strict.checks.cartesian.product=false;

insert overwrite local directory '/root/college006'
select round(t2.s/t4.s, 5)
from (select t1.Occupation as c, count(*) as s from loan t1
where t1.LoanStatus = "Defaulted"
group by t1.Occupation
order by s desc, t1.Occupation asc limit 1)t2
JOIN (select count(*) as s from loan t3)t4;

-- 11.置信度写到本地/root/college007/000000_0文件中（保留五位小数）
insert overwrite local directory '/root/college007'
select round(t2.s/t4.s, 5)
from (select t1.Occupation as c, count(*) as s from loan t1
where t1.LoanStatus = "Defaulted"
group by t1.Occupation
order by s desc, t1.Occupation asc limit 1)t2
JOIN (select count(*) as s from loan t3 where Occupation = "Other")t4;
