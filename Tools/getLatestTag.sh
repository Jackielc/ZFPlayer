#!/bin/bash
#Created by shigaoqiang on 2021/05/17
#source该脚本后，$LatestTag为最新tag

function showAllTags() {
    tags=$(git tag --sort=committerdate --format '%(refname:short)|%(committerdate:short)')
    for each in ${tags[@]}; do
        suffix5=${each:0-1}
        tagName=${each%|*}
        if [ $suffix5 == "|" ]; then
            echo "${tagName} is 附注tag"
        else
            echo "${tagName} is 轻量级tag"
        fi
    done
}

# 取出最新的轻量级tag，可能为空，为空表示当前没有符合规则的轻量级tag
# 第一个参数传版本号匹配规则的rx
g_latest_light_tag=''
function tool_get_latest_light_tag() {
    # tag按照-committerdate排序，则轻量级tag会被排列在上面
    # 因为轻量级tag是依附在具体的commit上，故排序时间也就依据commit的时间
    # 对同一个commit打了多个轻量级tag，因为这些tag时间相同，则依据tag本身的字符进行排序
    tags=$(git tag --sort=-committerdate --format '%(refname:short)|%(committerdate:short)')
    rx=$1

    declare -i count=0
    for each in ${tags[@]}; do
        echo "遍历轻量级tag ${each}"
        suffix5=${each:0-1}
        tagName=${each%|*}
        #出现|表示已经遍历到附注tag了
        if [ $suffix5 == "|" ]; then
            echo "tool_get_latest_light_tag 中断"
            break
        else
            if [[ $tagName =~ $rx ]]; then
                g_latest_light_tag=$tagName
                break
            else
                echo "${tagName} not match ${rx}"
            fi
            count=$(expr $count + 1)
        fi
        if [[ $count == 10 ]]; then
            break
        fi

    done
    echo "😊最新轻量级tag is ${g_latest_light_tag}"
}

# 取出最新的附注tag和tag的时间
# 最后echo的是个数组 index 0 是tag， index 1是时间
# 第一个参数传版本号匹配规则的rx
g_latest_annotation_tag=''
g_latest_annotation_time=''
function tool_get_latest_annotation_tag_info() {
    # tag按照-taggerdate排序，则附注tag会被排列在上面
    # 附注tag本身有时间信息，他们的排序是完全按照打tag的时间进行排序的
    tags=$(git tag --sort=-taggerdate --format '%(refname:short)|%(taggerdate:unix)')
    rx=$1

    declare -i count=0
    for each in ${tags[@]}; do
        suffix5=${each:0-1}
        tagName=${each%|*}

        echo "遍历附注tag ${each}"

        if [ $suffix5 == "|" ]; then
            break
        else
            if [[ $tagName =~ $rx ]]; then
                tagTime=${each#*|}
                g_latest_annotation_tag=$tagName
                g_latest_annotation_time=$tagTime
                break
            else
                echo "${tagName} not match ${rx}"
            fi
            count=$(expr $count + 1)
        fi
        if [[ $count == 10 ]]; then
            break
        fi

    done
    echo "😊最新附注tag is ${g_latest_annotation_tag} time: ${g_latest_annotation_time}"
}

# 第一参数给轻量级tag，第二个参数给附注tag 第三个参数给附注tag的时间😄
function compare_tag_time() {
    #echo "轻量级tag $1 and 附注tag $2 进入pk场"
    lightTagDate=$(git log -1 --format='%ct' $1)
    annotationTagDate=$3

    resultTag=$1
    if [[ $lightTagDate < $annotationTagDate ]]; then
        resultTag=$2
    fi

    echo "$resultTag"
}

# 获取最新的一次tag，第一个参数传版本号匹配规则的rx
g_latest_tag=''
function get_latest_tag() {
    rx=$1

    # 获取最新轻量级tag
    tool_get_latest_light_tag ${rx}

    # 获取最新附注tag
    tool_get_latest_annotation_tag_info ${rx}

    # 进行比较
    targetTag=''
    if [[ -z $g_latest_light_tag && -n $g_latest_annotation_tag ]]; then
        targetTag=$g_latest_annotation_tag
    elif [[ -z $g_latest_annotation_tag && -n $g_latest_light_tag ]]; then
        targetTag=$g_latest_light_tag
    else
        targetTag=$(compare_tag_time $g_latest_light_tag $g_latest_annotation_tag $g_latest_annotation_time)
    fi

    echo "😊查找出来最新的tag is $targetTag"
    g_latest_tag=$targetTag
}

function getCurrentBranchNewTag() {
    gx=$1
    branch_latest_tag=$(git describe --abbrev=0 --tags)
    echo "😊当前分支最新tag is $branch_latest_tag"
    if [[ $branch_latest_tag =~ $gx ]]; then
        g_latest_tag=$branch_latest_tag
    fi
    echo "😊当前分支最新的有效tag is $g_latest_tag"
}
