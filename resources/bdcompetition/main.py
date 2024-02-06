import pymysql
import json

import uvicorn
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

class Req(BaseModel):
    title: str

origins = [
    "http://127.0.0.1",
    "http://localhost",
    "http://localhost:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/data")
async def root(req: Req):
    jsondata = TableToJson(req.title)
    if len(jsondata) != 0:
        result = {'code': 200,
              'data': jsondata}
    else:
        result = {'code': 000,
              'msg': 'no data'}

    return result


def TableToJson(title):
    try:
        # 本地数据库
        # 服务器名,账户,密码，数据库名称
        connect = pymysql.connect(host='localhost',
                                user='root',
                                password='XXX',
                                db='XXX',
                                charset='utf8')
        cur = connect.cursor()

        create_sqli = "select * from bd_practice where title like '%{}%';".format(title)
        print("搜索：%{}%".format(title))
        cur.execute(create_sqli)
        data = cur.fetchall()
        # 关闭游标
        cur.close()
        # 关闭数据库连接
        connect.close()
        jsonData = []
        # 循环读取元组数据
        # 将元组数据转换为列表类型，每个条数据元素为字典类型:[{'字段1':'字段1的值','字段2':'字段2的值',...,'字段N:字段N的值'},{第二条数据},...,{第N条数据}]
        for row in data:
            result = {}
            result['type'] = row[2]
            result['answer'] = row[11]
            result['title'] = row[1]
            result['A'] = row[3]
            result['B'] = row[4]
            result['C'] = row[5]
            result['D'] = row[6]
            jsonData.append(result)
            jsondatar = json.dumps(jsonData, ensure_ascii=False)
        return jsonData
    except Exception as e:
        print("连接失败:", e)
        return None
if __name__ == '__main__':
    uvicorn.run("main:app", host="127.0.0.1", port=8000, log_level="info", reload=False)
