#!/bin/sh
echo "xcode_pre_action excute"

project_dir=$(dirname "$SRCROOT")
actionScriptRoot="$project_dir/Tools/buildActions"

# 读取时间戳文件
timeFile="$actionScriptRoot/buildActionTemp.txt"

echo "timeFile path:$timeFile" 

# clear file
"" > $timeFile

#记录信息脚本路径
record_key_value_script_path="$actionScriptRoot/record_key_value.py"
python $record_key_value_script_path $timeFile "event_name" "com.shsentry.xcodeBuildTime"
cur_time=$(date "+%Y-%m-%d %H:%M:%S")
python $record_key_value_script_path $timeFile "startTime" "$cur_time"

# 记录编译的项目名
python $record_key_value_script_path $timeFile "page" "$PRODUCT_NAME"

echo "记录起始时间成功"