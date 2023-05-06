#!/bin/bash
#Created by shigaoqiang on 2021/05/17
# 一些shell函数

export JENKISN="jenkins"
export RUNNER="runner"

# 获取最后一条commit信息（非Merge 非自动发布开头）
function tool_get_last_suitable_commit_message() {
    commitContents=$(git log --pretty=format:"%H" -20)
    result_content=''
    for each in ${commitContents[@]}; do
        content=$(git log --format=%B -n 1 ${each})
        if [[ "$content" =~ ^Merge.* ]]; then
            continue
        elif [[ "$content" =~ ^自动发布.* ]]; then
            continue
        else
            result_content=$content
            break
        fi
    done
    echo $result_content
}

# 更新识货私有repo
function tool_update_shihuo_repo() {
    #拿到所有repo
    repoList=$(pod repo list)
    echo "$repoList" | while read -r line; do
        if [[ $line =~ ^shihuo.* ]]; then
            echo "😊正在更新$line"
            #target= echo "$a" | awk '{print $(NF)}'
            pod repo update $line
        fi
    done
}

# 计算时间间隔 $2 - $1，并以01:01的格式进行打印
function tool_get_time_interval() {
    begin=$1
    end=$2
    ci_cost_time=$(($end - $begin))

    min=$(($ci_cost_time / 60))
    min=$(printf "%0.2d" ${min})

    second=$(($ci_cost_time % 60))
    second=$(printf "%0.2d" ${second})

    echo "${min}:${second}"
}

function echo_warning() {
    if [[ ${#1} > 0 ]]; then
        echo "\033[31mwarning: ${1}\033[0m"
    fi
}

# 打印绿色的文本内容 正常流程会使用这个打印
function echo_success() {
    if [[ ${#1} > 0 ]]; then
        echo "\033[32m${1}\033[0m"
    fi
}

function log_line() {
    echo "========"
}

file_content=''
function readFileContent() {
    TMP_FILE=$1
    content=''
    while read TMP_LINE; do
        # echo $TMP_LINE
        content=$content$TMP_LINE
    done <$TMP_FILE
    file_content=$content
}

function fileIsContainContent() {
    FILE_PATH=$1
    key_content=$2
    while read TMP_LINE; do
        # echo $TMP_LINE
        if [[ $TMP_LINE == *$key_content* ]]; then
            # 匹配单引号或者双引号
            return 1
            break
        fi
    done <$FILE_PATH
    return 0
}

item_index=0
function getArrItemIdx() {
    arr=$1
    item=$2
    index=0
    for i in ${arr[*]}; do
        if [[ $item == $i ]]; then
            item_index=$index
            return
        fi
        index=$(($index + 1))
    done
}

function getTargetXcodeproject() {
    path=$1
    project_name=$(basename $path) # SHFoundation_OC
    project_example_xcodeproj=''
    # echo "项目名称<$project_name>"
    example_path="$path/Example"
    if [ ! -d "$example_path" ]; then
        # echo "Example不存在"
        project_example_xcodeproj="$path/${project_name}.xcodeproj"
    else
        # echo 'Example存在'
        project_example_xcodeproj="$example_path/${project_name}.xcodeproj"

        # if [ ! -d "$project_example_xcodeproj" ]; then
        #     echo "${project_example_xcodeproj} 不存在额"
        # else
        #     echo "${project_example_xcodeproj} 存在额"
        # fi
    fi

    if [ ! -d "$project_example_xcodeproj" ]; then
        echo ""
    else
        echo "${project_example_xcodeproj}"
    fi
}
