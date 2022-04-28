#!/bin/bash
#Created by shigaoqiang on 2021/05/17
# 本地触发gitlab runner 打包

paramsCount=${#}
if [[ $paramsCount != 3 ]];then
    echo "参数有误，第一个参数为git路径，第二个参数为tagName，第三个参数为tag的附注信息"
    exit -1
fi

GitEnvPath=$1
TagName=$2
TagDesc=$3

cd $GitEnvPath

IsTagNameFits="0"
if [[ ${TagName} =~ ^release_.* ]]; then
    IsTagNameFits="1"
    cureent_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $cureent_branch != "master" ]];then
        echo "release包必须在master分支打包"
        exit -1
    else
        git fetch origin
        gstResult=$(git status)
        for each in ${gstResult}; do
            if [[ $each == "您的分支落后" ]];then
                echo "发现远程分支有更新，请更新后再重新执行"
                exit -1
            fi
        done
    fi
elif [[ ${TagName} =~ ^test_.* ]]; then
    IsTagNameFits="1"
     cureent_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $cureent_branch == "master" ]];then
        echo "test包不可以在master上打"
        exit -1
    fi
fi

if [[ $IsTagNameFits != "1" ]];then
    echo "tagName不符合规则，请参数示例：realse_sgq_2 或者 teste_sgq_2"
    exit -1
fi

 git tag | xargs git tag -d
 git tag -a -m "${TagDesc}" "${TagName}"
 git push origin $TagName
 git tag | xargs git tag -d
