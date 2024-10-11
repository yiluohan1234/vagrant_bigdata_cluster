-- 创建hive数据库
CREATE DATABASE IF NOT EXISTS hive;

-- 切换到hive数据库
use hive;

-- 创建数据表格shopping，并上传本地数据至表内
create table if not exists shopping (
user_id int,
age_range int,
gender int,
merchant_id int,
label int,
activity_log string)
row format delimited fields terminated by ','
tblproperties("skip.header.line.count"="1");

load data local inpath '/root/shopping/shopping.csv' into table shopping;

-- 3.在hive数据库下创建result中间表，注意数据切分，相关要求参看步骤说明
create table if not exists result (
user_id int,
item_id int,
brand_id int,
action_type int)
row format delimited fields terminated by ',';

-- item_id:category_id:brand_id:time_stamp:action_type”
insert overwrite table result
SELECT
a.user_id,
cast(split(ss.item, ':')[0] as int),
cast(split(ss.item, ':')[2] as int),
cast(split(ss.item, ':')[4] as int)
FROM shopping a
lateral view explode(split(a.activity_log,'#')) ss AS item;

-- 4.在hive数据库下创建click表，统计数据中点击次数top10的商品信息,结果写入文件/root/click_top_10/000000_0
create table if not exists click (
user_id int,
item_id int,
brand_id int,
action_type int)
row format delimited fields terminated by ',';

insert overwrite table click
SELECT
user_id,
item_id,
brand_id,
action_type
FROM result
where action_type=0;

-- 其中0表示点击，1表示加入购物车，2表示购买，3表示加入收藏
insert overwrite local directory '/root/click_top_10'
row format delimited fields terminated by '\t'
select
item_id,
brand_id,
count(*) cn
from click
where action_type=0
group by item_id, brand_id
order by cn desc
limit 10;

-- 5.统计数据中购买次数top10的商品信息,结果写入文件/root/emp_top_10/000000_0
insert overwrite local directory '/root/emp_top_10'
row format delimited fields terminated by '\t'
SELECT
item_id,
brand_id,
count(*) cn
FROM result
where action_type=2
group by item_id, brand_id
order by cn desc
limit 10;
-- cat /root/emp_top_10/000000_0  | grep  2462
-- 631714

-- 6.统计数据中收藏次数top10的商品信息,结果写入文件/root/collect_top_10/000000_0
insert overwrite local directory '/root/collect_top_10'
row format delimited fields terminated by '\t'
SELECT
brand_id,
item_id,
count(*) cn
FROM result
where action_type=3
group by brand_id, item_id
order by cn desc
limit 10;
-- cat /root/collect_top_10/000000_0 | grep 2455
-- 67897

-- 7.根据用户浏览(点击)最多的品牌，计算该品牌的的收藏购买转化率,结果写入/root/collect_emption路径下
with ClickMaxBrand as (
    select brand_id from result where action_type=0 group by brand_id order by COUNT(*) desc limit 1
),
Purchases as (
    SELECT
    brand_id,
    count(*) purchase_count
    FROM result
    where action_type=2 and brand_id=(select brand_id from ClickMaxBrand)
    group by brand_id
),
Collections as (
    SELECT
    brand_id,
    count(*) collect_count
    FROM result
    where action_type=3 and brand_id=(select brand_id from ClickMaxBrand)
    group by brand_id
)
insert overwrite local directory '/root/collect_emption'
row format delimited fields terminated by '\t'
select
a.brand_id,
round(a.purchase_count/b.collect_count, 3) collect_emption
from Purchases a
join Collections b
on a.brand_id=b.brand_id;
-- cat /root/collect_emption/000001_0  |  grep 1360
-- 0.469

-- 8.查找最活跃用户，求出该用户对应的点击购买转化率最高的品牌信息,并将结果写入/root/click_emption路径下
with ActiveUser  as (
SELECT user_id FROM result group by user_id ORDER BY COUNT(*) DESC LIMIT 1
)
insert overwrite local directory '/root/click_emption'
row format delimited fields terminated by '\t'
SELECT
user_id,
brand_id,
round(sum(if(action_type=2, 1, 0))/sum(if(action_type=0, 1, 0)), 3) click_emption
FROM result
where user_id=(select user_id from ActiveUser)
group by user_id, brand_id
order by click_emption desc
limit 1;

-- cat /root/click_emption/000000_0 | grep 23106
-- 0.003
-- WITH ActiveUser AS (
--   SELECT user_id
--   FROM result
--   WHERE action_type = 0
--   GROUP BY user_id
--   ORDER BY COUNT(*) DESC
--   LIMIT 1
-- ),
-- UserPurchases AS (
--   SELECT
--     user_id,
--     brand_id,
--     COUNT(*) AS purchase_count
--   FROM result
--   WHERE action_type = 2 AND user_id IN (SELECT user_id FROM ActiveUser)
--   GROUP BY user_id, brand_id
-- ),
-- UserClicks AS (
--   SELECT
--     user_id,
--     brand_id,
--     COUNT(*) AS click_count
--   FROM result
--   WHERE action_type = 0 AND user_id IN (SELECT user_id FROM ActiveUser)
--   GROUP BY user_id, brand_id
-- ),
-- ConversionRates AS (
--   SELECT
--     ucp.user_id,
--     ucp.brand_id,
--     round((ucp.purchase_count * 1.0) / ucc.click_count, 3) AS conversion_rate
--   FROM UserPurchases ucp
--   JOIN UserClicks ucc ON ucp.user_id = ucc.user_id AND ucp.brand_id = ucc.brand_id
-- )
-- INSERT OVERWRITE DIRECTORY '/root/click_emption'
-- ROW FORMAT DELIMITED
-- FIELDS TERMINATED BY '\t'
-- SELECT
--   ac.user_id,
--   cr.brand_id,
--   cr.conversion_rate
-- FROM ConversionRates cr
-- JOIN ActiveUser ac ON cr.user_id = ac.user_id
-- ORDER BY cr.conversion_rate DESC
-- LIMIT 1;
