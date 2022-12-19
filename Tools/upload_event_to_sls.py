#!/usr/bin/python3
# encoding: utf-8
# create by SGQ 2022-12-18
# 对提交文件进行检测

from aliyun.log import LogClient, PutLogsRequest, LogItem, GetLogsRequest, IndexConfig
import sys
import os
import os.path
import io
import re
import time
import requests
import json
import datetime

endpoint = "cn-hangzhou.log.aliyuncs.com"
project_name = "shihuo-new"
logstore_name = "sentry_log"


# 读取本地记录的日志信息
def read_file_to_json(file_name):
    res = {}
    try:
        with io.open(file_name, 'r', encoding='utf-8') as data:
            for each_line in data:
               line_clean = ''.join(each_line.strip('\n').split('$$$$$$$$$$'))
               key_value = line_clean.split('=')
               if len(key_value) == 2:
                    key = key_value[0]
                    value = key_value[1]
                    res[key] = value

    except BaseException as error:
        print('读取文件出错: ', str(error))

    res['rn_twenty_content_time'] = caculate_time_interval(res)
    return res


# 单位s
def caculate_time_interval(info):
    time_interval = 0
    startTime = info.get('startTime', "0")
    endTime = info.get('endTime', "0")
    if startTime != '0' and endTime != "0":
        startTime = datetime.datetime.strptime(startTime, '%Y-%m-%d %H:%M:%S')
        endTime = datetime.datetime.strptime(endTime, '%Y-%m-%d %H:%M:%S')
        time_delta = endTime - startTime
        time_interval = time_delta.seconds
    else:
        print("startTime or endTime not found")
    return time_interval


# 创建logClient
def get_log_client():
    url = "http://sh-gateway.shihuo.cn/v4/services/sh-applicationapi/aliyunToken?platform=ios&timestamp=1671184247654&v=7.27.2&token=0ac1c9820db8abe384f22fa664d828b9&access_token=nkoJBsk6Ag63X9OE25"
    r = requests.get(url)
    response = r.json()

    accessKeyId = response["AccessKeyId"]
    accessKey = response["AccessKeySecret"]
    token = response["SecurityToken"]
    client = LogClient(endpoint, accessKeyId, accessKey, token)
    return client


# 发送日志到sls
def send_log(client, project, logstore, log):
    topic = ''
    source = '识货iOS app 打包时间统计'
    extra = {
        'event_name': 'com.shsentry.iosModularTime',
    }
    extra.update(log)
    extraString = json.dumps(extra)
    contents = [
            ('device_id', 'aldjflsajdflsdjflkdsjfdslkfj'),
            ('extra', extraString)
        ]
    logitemList = []  # LogItem list
    logItem = LogItem()
    logItem.set_time(int(time.time()))
    logItem.set_contents(contents)
    for i in range(0, 1):
        logitemList.append(logItem)

    request = PutLogsRequest(project, logstore, topic, source, logitemList, compress=False)
    response = client.put_logs(request)
    response.log_print()

    print("put logs for %s success " % logstore_name)
    time.sleep(1)


if __name__ == '__main__':
    client = get_log_client()
    log = read_file_to_json('package_record.txt')
    send_log(client, project_name, logstore_name, log)