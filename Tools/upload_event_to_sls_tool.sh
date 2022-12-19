#!/bin/bash
#Created by shigaoqiang on 2021/12/03

function initRecordTxt() {
  local key='startTime'

  startTime=$(date "+%Y-%m-%d %H:%M:%S")
  local value="${startTime}"

  echo "${key}=${value}" > package_record.txt
}

function recordEndTime() {
  local key='endTime'

  startTime=$(date "+%Y-%m-%d %H:%M:%S")
  local value="${startTime}"

  echo "${key}=${value}" >> package_record.txt
  echo "event_name=com.shsentry.iosModularTime" >> package_record.txt

  python ./Tools/upload_event_to_sls.py
}

function recordKeyValue() {
  local key=$1
  local value=$2
  echo "${key}=${value}" >> package_record.txt
  if [[ $key == "page" ]]; then
    echo "event_name=com.shsentry.iosModularStart" >> package_record.txt
    python ./Tools/upload_event_to_sls.py
  fi
}

# initRecordTxt
# sleep 3
# recordKeyValue "page" "SHConsts"
# recordEndTime
