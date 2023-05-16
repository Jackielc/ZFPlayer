#!/usr/bin/python3
# encoding: utf-8
# create by SGQ 2022-12-18
# 对提交文件进行检测

import sys
import os
import os.path
import io
import re
import time
import requests
import json
import datetime

if __name__ == '__main__':
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
        key=sys.argv[2]
        value=sys.argv[3]
        print(file_path, key, value)

        with open(file_path, 'a') as f:
            f.write(key + '=' + str(value) + '\n')
        
        print('写入完成')
    else:
        print('执行参数不足，参数1：文件路径，参数2：key，参数三：value')
