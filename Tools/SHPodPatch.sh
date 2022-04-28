#!/bin/bash
#Created by wangyongxin on 2021/11/12

# 组件修复发布脚本
#

source './tool_functions.sh'

function checkTag() {
    tagName=$1
    rx='^([0-9]+\.){2,3}([0-9]){1,2}$'
    if [[ $tagName =~ $rx ]]; then
        return 1
    else
        echo "${tagName} not match rules"
        return 0
    fi
}
cd ..
#开始配置
read -p "输入需要需要修复的版本号: " version
#开始配置
read -p "输入创建人名字缩写: " name

checkTag $version

isVerification=$?

if [ $isVerification == 0 ]; then
    echo_warning "修复版本号格式校验失败"
    exit 1
fi

if [ ${#name} -lt 1 ]; then
    echo_warning "未输入发布人"
    exit 1
fi

branchName="${name}/patch_release_${version}"

CREATERESULT=$(git branch ${branchName} ${version} 2>&1)

echo "${CREATERESULT}"

if [[ ($CREATERESULT =~ "fatal") ]]; then
    echo_warning "指定tag${branchName}分支创建失败"
    exit 1
fi

RESULT=$(git checkout ${branchName} 2>&1)

echo "${RESULT}"

if [[ ($RESULT =~ "fatal") || ($RESULT =~ "error") ]]; then
    echo_warning "切换分支${branchName}失败"
    exit 1
fi

echo "新建分支："
echo ${branchName} >./Tools/runnerParam.txt

echo_success "对应修复分支创建完成，show time !"
