#!/usr/bin/python
# coding=utf-8
import json
import pandas as pd
#https://api-prod.qingjiao.art/api/match/record/123110/resource/list
def get_resource_list():
    ret = []
    file = "C:\\Users\\cuiyufei\\resource_list.json"
    with open(file,'r', encoding='utf8') as f:
        data = json.load(f)

    resources = data['data']['resources']
    for i, res in enumerate(resources):
        host_name = {}
        host_name['resource_name'] = res['content']['name']
        host_name['resource_id'] = res['resource_id']
        ret.append(host_name)

    return ret

#https://api.region-bj02.qingjiao.link//api/v3/virtual-resource/all/status
def get_resource_status():
    ret = []
    file = "C:\\Users\\cuiyufei\\resource_status.json"
    with open(file,'r', encoding='utf8') as f:
        data = json.load(f)

    resources = data['data']
    for i, res in enumerate(resources):
        host_info = {}
        host_info['ip'] = res['ip']
        host_info['public_ip'] = res['public_ip']
        host_info['password'] = res['password']
        host_info['resource_id'] = res['resource_id']
        ret.append(host_info)
    return ret
host_name = get_resource_list()
df_name = pd.DataFrame(host_name)
host_info = get_resource_status()
df_info = pd.DataFrame(host_info)
df = pd.merge(df_name, df_info,on='resource_id')

save_file = open("D:/Portable/WindTerm_2.5.0/data.txt", "w")
print("cat > /root/etx.txt <<EOF")
for index, row in df.iterrows():
    save_file.write(row['resource_name']+"_ip="+row['ip']+"\n")
    save_file.write(row['resource_name']+"_public_ip="+row['public_ip']+"\n")
    save_file.write(row['resource_name']+"_password="+row['password']+"\n")
    print(row['resource_name']+"_ip="+row['ip'])
    print(row['resource_name']+"_public_ip="+row['public_ip'])
    print(row['resource_name']+"_password="+row['password'])
print("EOF")
save_file.close()
