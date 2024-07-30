mkdir -p /root/travel/hotel/code/M2/
cat > /root/travel/hotel/code/M2/M2-T1-S1-1.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/hotel.txt', sep ='\t')
print(da.head(10))
EOF
python /root/travel/hotel/code/M2/M2-T1-S1-1.py

cat > /root/travel/hotel/code/M2/M2-T1-S1-2.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/hotels.txt', sep ='\t')
print(da.head(10))
EOF
python /root/travel/hotel/code/M2/M2-T1-S1-2.py

cat > /root/travel/hotel/code/M2/M2-T1-S2-1.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/hotel.txt', sep = '\t')
# 缺失数量
num = da['酒店类型'].isnull().sum()
num
# 删除指定列的缺失行
da = da.dropna(subset=['酒店类型'])
file_name ='/root/travel/hotel/hotel2_c1_'+ str(num)+'.csv'
da.to_csv(file_name, index=False,encoding='utf8')
EOF
python /root/travel/hotel/code/M2/M2-T1-S2-1.py

cat > /root/travel/hotel/code/M2/M2-T1-S2-2.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/hotel.txt', sep ='\t')
a = da['起价']
a=list(a)
a = [a.replace("¥","").replace("起","") for a in a]
print(a)
a= pd.Series(a)
a.head()
d = pd.DataFrame({'最低价': a})
result =pd.concat([da,d], axis=1)
result.head()
shuju=pd.DataFrame(result)
shuju.to_csv('/root/travel/hotel/hotel2_c2.csv')
EOF
python /root/travel/hotel/code/M2/M2-T1-S2-2.py

cat > /root/travel/hotel/code/M2/M2-T1-S2-3.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/hotel.txt',sep ='\t')
# 将评分为空的数据设置为 0
da['评分'].fillna(0,inplace=True)
# 存储处理后的数据
da.to_csv('/root/travel/hotel/hotel2_c3.csv', index=False)
EOF
python /root/travel/hotel/code/M2/M2-T1-S2-3.py

cat > /root/travel/hotel/code/M2/M2-T1-S2-4.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/hotel.txt',sep ='\t')
# 计算总平均评分
total_average_rating = round(da['评分'].mean(),1)
print(total_average_rating)
# 将评分为空的数据设置为总平均评分
da['评分'].fillna(total_average_rating, inplace=True)
print(da['评分'])
# 生成文件名
file_name = '/root/travel/hotel/hotel2_c4_'+ str(total_average_rating)+ '.csv'
# 存储处理后的数据
da.to_csv(file_name, index=False)
EOF
python /root/travel/hotel/code/M2/M2-T1-S2-4.py

cat > /root/travel/hotel/code/M2/M2-T1-S2-5.py << EOF
# coding:utf-8
import pandas as pd
df = pd.read_csv('/root/travel/hotel/hotels.txt',sep = '\t')
# 缺失数量
num = df['最热评价'].isnull().sum()
# 删除指定列的确实行
df = df.dropna(subset=['最热评价'])
file_name ='/root/travel/hotel/hotel_comment.csv'
df.to_csv(file_name, index=False, encoding='utf8')
EOF
python /root/travel/hotel/code/M2/M2-T1-S2-5.py

cat > /root/travel/hotel/code/M2/M2-T2-S1-1.py << EOF
# coding:utf-8
from snownlp import SnowNLP
import pandas as pd
data = pd.read_csv('/root/travel/hotel/hotel_comment.csv')
# 定义情感倾向标注函数
def get_sentiment_label(sentiment):
    if sentiment >= 0.7:
        return '正向'
    elif sentiment > 0.4:
        return '中性'
    else:
        return '负向'

# 标注情感倾向并存入新的 Dataframe
standard_data = pd.DataFrame(columns=['编号', '酒店名称', '最热评价', '情感倾向', '备注'])
for index, row in data.iterrows():
    comment = row['最热评价']
    sentiment = SnowNLP(comment).sentiments
    label = get_sentiment_label(sentiment)
    standard_data.loc[index] = [index+1, row['酒店名称'], comment, label, '']

# 存储标注结果
print(standard_data.head())
standard_data.to_csv('/root/travel/hotel/standard.csv', index=False, encoding='utf8')
EOF
python /root/travel/hotel/code/M2/M2-T2-S1-1.py

# 内网ip
hostnamectl set-hostname bigdata && bash
start-all.sh
hadoop dfsadmin -safemode leave
hadoop fs -mkdir /file2_1
hadoop fs -chmod 777 /file2_1
hadoop fs -get /file2_1 /root


cat > /root/travel/hotel/code/M2/M2-T3-S2-1.py << EOF
# coding:utf-8
import pandas as pd
da= pd.read_csv('/root/travel/hotel/hotel.txt', sep ='\t')
localtion = da['位置信息']
localtion = [localtion.replace(" · ",",")for localtion in localtion]
delimiter = ','
df = pd.DataFrame(localtion, columns=['Column1'])['Column1'].str.split(delimiter, expand=True)
df = df.rename(columns={0:'商圈', 1:'景点'})
sss =pd.concat([da, df],axis=1)
shu=pd.DataFrame(sss)
print(sss.head(10))
shu.to_csv('/root/travel/hotel/district.csv', index=None, encoding='UTF-8')
EOF
python /root/travel/hotel/code/M2/M2-T3-S2-1.py

cat > /root/travel/hotel/code/M2/M2-T3-S3-1.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/district.csv')
area_counts = da.groupby('商圈').size().reset_index(name='酒店数量')
# 接下来T 按照酒店数量进行降序排序，并选择排名前三的商圈
top_three_areas = area_counts.sort_values('酒店数量',ascending=False).head(3)['商圈'].tolist()
#现在我门有我们可以筛选原始数据集中属于这三个商圈的记录
filtered_data = da[da['商圈'].isin(top_three_areas)]
#最后，我们对筛选后的数据按照商圈和酒店类型进行分组统计
hotel_type_counts = filtered_data.groupby(['商圈','酒店类型']).size().reset_index(name='数量')
hotel_type_counts.to_csv('/root/travel/hotel/types.csv', index=None, encoding='UTF-8')
EOF
python /root/travel/hotel/code/M2/M2-T3-S3-1.py

#=============
mkdir -p /root/travel/hotel/code/M3
cat > /root/travel/hotel/code/M3/M3-T1-S1-1.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/district.csv')
hotel_sum = da.groupby('商圈').size().reset_index(name='酒店数量')
# 按照酒店数量进行降序排序
top5_hotel = hotel_sum.sort_values('酒店数量',ascending=False).head(5)
print(top5_hotel)
top5_hotel.to_csv('/root/travel/hotel/hotel sum.csv', index=None, encoding='UTF-8')
EOF
python /root/travel/hotel/code/M3/M3-T1-S1-1.py

cat > /root/travel/hotel/code/M3/M3-T1-S1-2.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/district.csv')
a = da['起价']
a=list(a)
a = [int(a.replace("¥","").replace("起",""))for a in a]
a = pd.Series(a)
a.head()
d = pd.DataFrame({"最低价":a})
shu = pd.concat([da,d],axis=1)
shu.head()
area_counts = shu.groupby('商圈')['最低价'].mean().reset_index(name='平均最低价')
top_five = area_counts.sort_values('平均最低价').head(5)
print(top_five)
top_five.to_csv('/root/travel/hotel/price_mean.csv', index=None, encoding='UTF-8')
EOF
python /root/travel/hotel/code/M3/M3-T1-S1-2.py

cat > /root/travel/hotel/code/M3/M3-T1-S1-3.py << EOF
# coding:utf-8
import pandas as pd
da = pd.read_csv('/root/travel/hotel/district.csv')
# 筛出5星级酒店
da_five_star = da[da['酒店类型'] =='五星级']
# 分数平均
score_mean = da_five_star['评分'].mean()
print('五星级酒店平均分为:\n{}'.format(score_mean))
EOF
python /root/travel/hotel/code/M3/M3-T1-S1-3.py

cat > /root/travel/hotel/code/M3/M3-T1-S1-4.py << EOF
# coding:utf-8
import pandas as pd
import matplotlib.pyplot as plt
plt.rcParams['font.sans-serif']=['SimHei'] # 设置中文显示
plt.rcParams['axes.unicode_minus']=False # 解决负号’-'显示为方块的问题
# 读取数据
da = pd.read_csv('/root/travel/hotel/district.csv', encoding='utf-8')
hotel_sum = da.groupby('商圈').size().reset_index(name='酒店数量')
# 按照酒店数量进行降序排序
top5_hotel = hotel_sum.sort_values('酒店数量', ascending=False).head(10)
# 创建柱状图
plt.figure(figsize=(20, 10))
plt.bar(top5_hotel['商圈'],top5_hotel['酒店数量'], color='skyblue')
plt.title('酒店数排名前十的商圈')
plt.xlabel('商圈')
plt.ylabel('酒店数量')
plt.show()
plt.savefig('/root/travel/hotel/bar.png')
EOF
python /root/travel/hotel/code/M3/M3-T1-S1-4.py

cat >> /root/travel/hotel/code/M3/M3-T1-S1-5.py << EOF
# coding:utf-8
import pandas as pd
import matplotlib.pyplot as plt
plt.rcParams['font.sans-serif']=['SimHei'] # 设置中文显示
plt.rcParams['axes.unicode_minus']= False # 解决负号’'显示为方块的问题
# 读取数据
da = pd.read_csv('/root/travel/hotel/district.csv', encoding='utf-8')
# 数据处理
average = da.groupby('酒店类型')['评分'].mean().reset_index(name='平均评分')
# 绘制折线图
plt.plot(average['酒店类型'], average['平均评分'], marker='o')

# 添加标题和标签
plt.title('各类型酒店平均评分走势')
plt.xlabel('酒店类型')
plt.ylabel('平均评分')
plt.show()
plt.savefig('/root/travel/hotel/plot.png')
EOF
python /root/travel/hotel/code/M3/M3-T1-S1-5.py
