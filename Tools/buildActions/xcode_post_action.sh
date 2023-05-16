#!/bin/sh
echo "xcode_post_action excute"

project_dir=$(dirname "$SRCROOT")
actionScriptRoot="$project_dir/Tools/buildActions"

# 读取时间戳文件
timeFile="$actionScriptRoot/buildActionTemp.txt"

# 读取时间戳文件
if [ ! -f "$timeFile" ]; then
  echo "找不到时间戳文件"
  exit 0
fi

#记录信息
record_key_value_script_path="$actionScriptRoot/record_key_value.py"
chmod +x $record_key_value_script_path

cur_time=$(date "+%Y-%m-%d %H:%M:%S")
python $record_key_value_script_path "$timeFile" "endTime" "$cur_time"

echo "记录信息结束时间"


# 发送日志
upload_log_script_path="$actionScriptRoot/upload_event_to_sls.py"
python "$upload_log_script_path" "$timeFile"