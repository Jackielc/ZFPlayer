#!/bin/bash
#Created by wangyongxin on 2022/02/28

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

#组件发布通知
# param 1 : success
# param 2 : 标题描述
# param 3 : 发布版本
# param 4 : 版本发布者
# param 5 : 错误描述
function webhookMessage() {
    message=""
    name="${CI_PROJECT_NAME}"
    tag="${CI_COMMIT_TAG}"
    url="$CI_PROJECT_URL"
    pipeline="$CI_PIPELINE_ID"
    #发布是否成功
    PUSH_SUCCESS=$1
    #标题
    titleDesc=$2
    #发布版本
    pushTag="$3"
    #Tag_Author
    userName="$4"
    errorDesc=$5
    hookUrl="https://open.feishu.cn/open-apis/bot/v2/hook/71a8a82a-ee40-442e-aff6-8d626d2feb08"
    if $PUSH_SUCCESS; then
        cost_time=$(tool_get_time_interval ${CI_BEGAIN_TIME} $(date +%s))
        #成功的通知
        content_publish_tag="{\"tag\":\"text\",\"text\":\"发布tag：$pushTag\n\"}"
        content_publish_author="{\"tag\":\"text\",\"text\":\"发布者：$userName\n\"}"
        content_publish_content="{\"tag\":\"text\",\"text\":\"发布内容：${Publish_Content}\n\"}"
        content_publish_cost_time="{\"tag\":\"text\",\"text\":\"耗时：${cost_time}\n\"}"
        if [[ -z ${Publish_Content} ]]; then
            content_publish_content="{\"tag\":\"text\",\"text\":\"最后提交：${Last_Commmit_Msg}\n\"}"
        fi
        content_repo_link="{\"tag\":\"a\",\"text\":\"仓库地址\",\"href\":\"$url\"}"
        message="{\"msg_type\":\"post\",\"content\":{\"post\":{\"zh_cn\":{\"title\":\"$name--${titleDesc}--发布成功\",\"content\":[[${content_publish_tag},${content_publish_author},${content_publish_content},${content_publish_cost_time},${content_repo_link}]]}}}}"
        if [[ !(${#errorDesc} -lt 1) ]]; then
            content_publish_tips="{\"tag\":\"text\",\"text\":\"提示：${errorDesc}\n\"}"
            message="{\"msg_type\":\"post\",\"content\":{\"post\":{\"zh_cn\":{\"title\":\"$name--${titleDesc}--发布成功\",\"content\":[[${content_publish_tag},${content_publish_author},${content_publish_content},${content_publish_tips},${content_publish_cost_time},${content_repo_link}]]}}}}"
        fi
        hookUrl="https://open.feishu.cn/open-apis/bot/v2/hook/71a8a82a-ee40-442e-aff6-8d626d2feb08"
        res=$(curl -X POST -H "Content-Type: application/json" -d "$message" https://open.feishu.cn/open-apis/bot/v2/hook/71a8a82a-ee40-442e-aff6-8d626d2feb08)
    else
        #失败的通知
        message2="{\"msg_type\":\"post\",\"content\":{\"post\":{\"zh_cn\":{\"title\":\"$name--${titleDesc}--发布失败\",\"content\":[[{\"tag\":\"text\",\"text\":\"触发tag：$tag\npipeline信息：$pipeline\nError：$errorDesc\n\"},{\"tag\":\"a\",\"text\":\"仓库地址\",\"href\":\"$url\"}]]}}}}"
        hookUrl="https://open.feishu.cn/open-apis/bot/v2/hook/5e235e56-9abe-4c8c-9dba-867d40238652"
        res=$(curl -X POST -H "Content-Type: application/json" -d "$message2" https://open.feishu.cn/open-apis/bot/v2/hook/5e235e56-9abe-4c8c-9dba-867d40238652)
    fi
}

#组件发布
function podsReleasePush() {
    Repo=$1
    PODSPEC_FILE=$2
    PODS_SOURCE_SPECS=$3
    BIN_SOURCE_SPECS=$4

    SOURCE_SPECS_LIST=(${PODS_SOURCE_SPECS//,/ })
    echo "当前的发布为：$1, $2, $3, $4"
    # 校验记录写入的文件  判断完成后会删除
    PUSH_TMP_LOG_FILE="repoPushTmpLog.txt"
    PUSH_SUCCESS_SIGN_ONE="Updating the \`${Repo}\' repo"
    PUSH_SUCCESS_SIGN_TWO="Adding the spec to the \`${Repo}\' repo"
    PUSH_SUCCESS_SIGN_THREE="Pushing the \`${Repo}\' repo"
    # #远程校验
    $(>$PUSH_TMP_LOG_FILE)
    #执行发布
    #发布源中如果包含二进制源，走定制参数发布，否则常规发布
    if [[ "${SOURCE_SPECS_LIST[@]}" =~ "${BIN_SOURCE_SPECS}" ]]; then
        pod repo push ${Repo} ${PODSPEC_FILE} --sources=${PODS_SOURCE_SPECS} --allow-warnings --use-libraries --use-modular-headers --skip-import-validation | tee ${PUSH_TMP_LOG_FILE}
    else
        pod repo push ${Repo} ${PODSPEC_FILE} --sources=${PODS_SOURCE_SPECS} --allow-warnings --use-libraries --use-modular-headers --skip-import-validation | tee ${PUSH_TMP_LOG_FILE}
    fi
    # 对写入到临时文件的内容进行逐行判断, 满足3个条件表示推送成功
    CHECK_MATCH_NUM=0
    while read TMP_LINE; do
        if [[ $TMP_LINE == *$PUSH_SUCCESS_SIGN_ONE* ]]; then
            CHECK_MATCH_NUM=$(($CHECK_MATCH_NUM + 1))
        fi
        if [[ $TMP_LINE == *$PUSH_SUCCESS_SIGN_TWO* ]]; then
            CHECK_MATCH_NUM=$(($CHECK_MATCH_NUM + 1))
        fi
        if [[ $TMP_LINE == *$PUSH_SUCCESS_SIGN_THREE* ]]; then
            CHECK_MATCH_NUM=$(($CHECK_MATCH_NUM + 1))
        fi
    done <$PUSH_TMP_LOG_FILE
    # 移除临时的目录
    rm $PUSH_TMP_LOG_FILE
    # 推送成功和推送失败的提示不一样
    if [[ ${CHECK_MATCH_NUM} -gt 2 ]]; then
        return 1
    else
        return 0
    fi
}

#直接发布的
function skipCheckRelease() {
    path_param=$1
    version_param=$2
    podSpec_name=$3
    current_path=$(pwd)
    cp "${current_path}/${podSpec_name}" $path_param
    cd "${path_param}/.."
    git status
    git add .
    git commit -a -m "${version_param} 版本发布"
    PUSHRESULT=$(git push origin master --porcelain)
    cd $current_path
    if [[ $PUSHRESULT == *"Done"* && !($PUSHRESULT =~ "rejected") ]]; then
        return 1
    else
        return 0
    fi
}
