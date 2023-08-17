#!/bin/bash

python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_activity_stats
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_coupon_stats
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_new_buyer_stats
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_order_by_province
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_page_path
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_repeat_purchase_by_tm
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_sku_cart_num_top3_by_cate
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_trade_stats
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_trade_stats_by_cate
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_trade_stats_by_tm
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_traffic_stats_by_channel
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_user_action
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_user_change
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_user_retention
python /home/vagrant/apps/init_bin/gen_export_config.py -d gmall_report -t ads_user_stats
