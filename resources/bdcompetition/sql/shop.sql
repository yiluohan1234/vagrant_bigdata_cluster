-- 创建shop数据库
create database if not exists shop;

-- 切换到数据库
use shop;


-- 创建商品表product，并上传本地数据至表内
create table if not exists product(
product_id string,
product_name string,
marque string,
barcode string,
price double,
brand_id string,
market_price double,
stock int,
status int)
row format delimited fields terminated by ',';

load data local inpath '/root/shop/product.txt' into table product;

-- 创建地区表area，并上传本地数据至表内
create table if not exists area(
area_id string,
area_name string)
row format delimited fields terminated by ',';

load data local inpath '/root/shop/area.txt' into table area;

-- 创建用户点击信息user_click，并上传本地数据至表内
create table if not exists user_click(
user_id string,
user_ip string,
url string,
click_time string,
action_type string,
area_id string)
row format delimited fields terminated by ',';

load data local inpath '/root/shop/user_click.txt' into table user_click;

-- 创建用户点击商品日志表clicklog，解析user_click用户点击信息表中的product_id
create table if not exists clicklog(
user_id string,
user_ip string,
product_id string,
click_time string,
action_type string,
area_id string)
row format delimited fields terminated by ',';

insert overwrite table clicklog
select
user_id,
user_ip,
-- substring(url,31) as product_id,
substring(url, instr(url, '=')+1) as product_id,
click_time,
action_type,
area_id
from user_click;


-- 创建结果分析区域热门商品表area_hot_product,统计各地区热门商品访问量pv
create table if not exists area_hot_product(
area_id string,
area_name string,
product_id string,
product_name string,
pv BIGINT)
row format delimited fields terminated by ',';

insert overwrite table area_hot_product
select
a.area_id,
b.area_name,
a.product_id,
c.product_name,
count(a.product_id) pv
from clicklog a
join area b
on a.area_id=b.area_id
join product c
on a.product_id=c.product_id
group by a.area_id, b.area_name, a.product_id, c.product_name;

-- 查询表area_hot_product全部数据，结果写入本地目录/root/data/shop/area_hot_product
insert overwrite local directory '/root/data/shop/area_hot_product'
row format delimited fields terminated by '\t'
select * from area_hot_product;
