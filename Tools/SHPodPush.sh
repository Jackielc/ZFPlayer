#!/bin/bash
#Created by wangyongxin on 2021/02/10

# 发布流程
# 选择发布的SPECS
# 检测本地是否含有选择的发布SPECS，没有进行添加
# 获取组件名，.podSpec 文件
# 同步远端代码, 输出当前最新的版本号
# pod组件 本地校验 （校验失败 exit）
# 匹配版本号规则
# 输入提交信息
# 提交代码, 打tag
# 发布
# 进入二进制流程

function log_line() {
    echo "========"
}

#重写文件内容
function rewriteFileContentOfLine() {
    #文件名
    FILE_NAME=$1
    #匹配字符串
    MATCH_STR="$2*"
    #替换内容
    REPLACE_STR=$3

    echo $FILE_NAME
    echo $MATCH_STR
    echo $REPLACE_STR

    while read line; do
        #echo $line
        if [[ $line == $MATCH_STR ]]; then
            # 匹配单引号或者双引号
            RE="\'([^\']*)\'"
            RE_DOUBLE="\"([^\"]*)\""
            if [[ $line =~ $RE || $line =~ $RE_DOUBLE ]]; then
                oldContentStr=${BASH_REMATCH[1]}
                # echo "内容为： $oldContentStr"
                OID_TMP_STRING=$line
                echo $OID_TMP_STRING
            fi
            break
        fi
    done <$FILE_NAME

    NEW_TMP_STRING=${OID_TMP_STRING/$oldContentStr/$REPLACE_STR}
    echo "写入内容：$NEW_TMP_STRING"

    sed -i '' "s%${OID_TMP_STRING}%${NEW_TMP_STRING}%g" $FILE_NAME
}
source './Tools/sh_pod_release.sh'

# 飞书结果通知
webhook() {
    webhookMessage $1 "源码" $NEW_VERSION $Tag_Author $2
}

#分割线
function log_line() {
    echo "========================"
}

source './Tools/tool_functions.sh'

#校验外部传参，确定手动发布还是自动发布
ARG_BRANCH_TAG=$1
CI_BEGAIN_TIME=$2

#REPO发布类型
RELEASE="release"
GRAY="gray"
TEST="test"
OLD="old"

#解析后的参数，以此来判断是否采用交互式过程
USER_CHOOESD_REPO=""
USER_NAME=""
#打tag的作者
Tag_Author=""
Publish_Content=""
Last_Commmit_Msg=""
USER_VERSION_POSITION="" #要变更的版本位
#发布开关控制
POD_BIN_SYMBOL="SH_pod_bin = true"
POD_CT_SYMBOL="SH_pod_CT = true"

# CI_PIPELINE_ID=1
# 是否走CI发布
isPipeline=0
if [ $CI_PIPELINE_ID ] >0; then
    isPipeline=1
fi
AUTOMATIC_PROCESS=$isPipeline
#echo "CI开始---${CI_PIPELINE_ID}---${isPipeline}---${AUTOMATIC_PROCESS}"
prepareParams() {
    arr=($(echo $ARG_BRANCH_TAG | tr '_' ' '))
    # echo ${arr[@]}
    USER_CHOOESD_REPO=${arr[0]}
    USER_NAME=${arr[1]}
    tmpVersionString=${arr[2]}
    USER_VERSION_POSITION=($(echo $tmpVersionString | tr '.' ' '))

    #读取tag信息
    TagInfo=$(git show $ARG_BRANCH_TAG)
    Tag_Author=$USER_NAME
    #判断是否附注tag
    if [[ ${TagInfo:0:3} == "tag" ]]; then
        #正则匹配出作者位置
        Tag_Author=$(echo $TagInfo | grep -Eo "Tagger: (.*?) <")
        #使用空格分割成数组
        TagInfoArray=(${Tag_Author// / })
        #取出第2个位置的就是打tag的作者
        Tag_Author=${TagInfoArray[1]}

        #提取发布内容
        Publish_Content=$(git cat-file tag $ARG_BRANCH_TAG | tail -n+6)
    else
        Last_Commmit_Msg=$(tool_get_last_suitable_commit_message)
    fi
    echo "本次发布者：|$Tag_Author|"

    #删除触发tag
    git push origin :refs/tags/$ARG_BRANCH_TAG
    git tag -d $ARG_BRANCH_TAG
    #所属仓库:必要 release/test/old/gray
    if test ${#USER_CHOOESD_REPO} -lt 1; then
        echo "tag中目标repo不符合规范"
        return 0
    fi
    if [ "$USER_CHOOESD_REPO" != $RELEASE ] && [ "$USER_CHOOESD_REPO" != $GRAY ] && [ "$USER_CHOOESD_REPO" != $TEST ] && [ "$USER_CHOOESD_REPO" != $OLD ]; then
        echo "tag中目标repo不符合规范"
        return 0
    fi
    #提交者姓名:必要 缩写(eg:lzy)
    if test ${#USER_NAME} -lt 1; then
        echo "tag中缺少name字段"
        return 0
    fi

    TEMP_VERSION_LENGTH=${#USER_VERSION_POSITION[@]}
    if [ $TEMP_VERSION_LENGTH -gt 1 ]; then
        echo "tag中version字段不符合规范"
        return 0
    fi
    #版本号:可选
    #case1:版本号各位如果大于当前版本3则校验不通过、直接退出
    #case2:版本号位数少于3
    if [ $USER_VERSION_POSITION -gt 3 -o $USER_VERSION_POSITION -lt 0 ]; then
        USER_VERSION_POSITION=2
        echo "tag中version字段不符合规范, 超出当前版本号位数"
        return 0
    fi
    return 1
}
#回到主工程目录
# echo $(pwd)

echo "进入自动发布流程"
#校验参数
prepareParams
#校验结果
isVerification=$?
#校验失败终止，发送
if [ $isVerification == 0 ]; then
    echo_warning "自动发布版本号校验失败"
    webhook false "触发CI参数格式校验失败"
    exit 1
fi

#发布流程开始
#配置脚本替换内容
#spec路径
SOURCE_SPECS='git@code.shihuo.cn:shihuoios/shihuomodulize/shmodulizespecs-bin.git,git@code.shihuo.cn:shihuoios/shihuomodulize/shmodulizespecs.git,git@code.shihuo.cn:shihuoios/shihuomodulize/shmodulizespecs_gray.git,git@code.shihuo.cn:shihuoios/shihuomodulize/shmodulizespecs_test.git,git@code.shihuo.cn:shihuoios/shihuospecs.git,https://github.com/CocoaPods/Specs.git'
#spec本地名字
SOURCE_REPO='shihuo-shmodulizespecs_bin,shihuo-shmodulizespecs,shihuo-shmodulizespecs_gray,shihuo-shmodulizespecs_test,shihuo-shihuospecs'
#测试的repo
TEST_REPO='shihuo-shmodulizespecs_test'
#解析获取
RepoList=(${SOURCE_REPO//,/ })
RepoPathList=(${SOURCE_SPECS//,/ })
#选择的发布specs
Repo=''
BIN_REPO=''
BIN_SOURCE_REPO=''
#获取本地repo list
LOCAL_COCOPODS_PATH=~/.cocoapods/repos
REPO_FILES=$(ls $LOCAL_COCOPODS_PATH)

mapRepoName() {
    BIN_REPO=${RepoList[0]}
    if [ $USER_CHOOESD_REPO == $RELEASE ]; then
        Repo=${RepoList[1]}
    elif [ $USER_CHOOESD_REPO == $GRAY ]; then
        Repo=${RepoList[2]}
    elif [ $USER_CHOOESD_REPO == $TEST ]; then
        Repo=${RepoList[3]}
    elif [ $USER_CHOOESD_REPO == $OLD ]; then
        Repo=${RepoList[4]}
    fi
}

getRepo() {
    #自动发布-设置targetrepo
    mapRepoName
    getArrItemIdx "${RepoList[*]}" $Repo
    RepoIndex=$item_index
    getArrItemIdx "${RepoList[*]}" $BIN_REPO
    BinRepoIndex=$item_index
    echo "即将自动发布的仓库是:${Repo}, ${RepoIndex}"
}
echo "---------------- 选择发布的repo处理 -----------------------"
#[AUTO]替换目标repo
getRepo
#二进制源repo
BIN_SOURCE_REPO=${RepoPathList[$BinRepoIndex]}
#检测本地有没有对应的repo
IsContainCurrentRepo=false
IsContainBinRepo=false
for filename in $REPO_FILES; do
    if [[ $filename == *$Repo* ]]; then
        IsContainCurrentRepo=true
    fi
    if [[ $filename == *$BIN_REPO* ]]; then
        IsContainBinRepo=true
    fi
done

if [[ ${IsContainCurrentRepo} == false ]]; then
    echo "本地repo列表中没有对应的spec，增加${Repo}"
    pod repo add ${Repo} ${RepoPathList[$RepoIndex]}
fi
if [[ ${IsContainBinRepo} == false ]]; then
    echo "本地repo列表中没有对应二进制的spec，增加${BIN_REPO}"
    pod repo add ${BIN_REPO} ${RepoPathList[$BinRepoIndex]}
fi

echo "----------------- 获取.podspec文件 -----------------------"
PODSPEC_PATH=$(find . -name "*.podspec")
#CT的podSepc
PODSPEC_CT_NAME=''
#是否开启CT调用
is_open_CT=0
#组件的源码的podSpec
PODSPEC_NAME=''
PODS_NAME=''
for item in ${PODSPEC_PATH[*]}; do
    itemName=$(basename $item)
    if [[ $itemName =~ "_CT" ]]; then
        PODSPEC_CT_NAME=$itemName
    else
        PODSPEC_NAME=$itemName
        PODS_NAME=${itemName%.podspec}
        echo "组件名：${PODS_NAME}"
    fi
done

if [[ (${#PODSPEC_PATH} -lt 1) || (${#PODSPEC_NAME} -lt 1) ]]; then
    echo "当前目录下未找到podspec文件,退出发布流程"
    exit 1
fi

echo "----------------- 是否发布CT引用 ---------------"
if [[ !(${#PODSPEC_CT_NAME} -lt 1) ]]; then
    fileIsContainContent $PODSPEC_CT_NAME "${POD_CT_SYMBOL}"
    is_open_CT=$?
    echo "组件开启CT：${is_open_CT}"
else
    echo "------ 该组件没有提供CT调用方式 -------"
fi

echo '-----------------获取上一个tag------------------'
LAST_VERISON=$(git describe --tags $(git rev-list --tags --max-count=1))
#自动发布筛选历史记录中成功发布的tag
#灰度修复线上的版本匹配
source './Tools/getLatestTag.sh'
if [ $USER_CHOOESD_REPO == "gray" ]; then
    #灰度修复问题发布时获取当前分支的最新tag
    gx='^([0-9]+\.){2,3}([0-9]){1,2}$'
    getCurrentBranchNewTag ${gx}
else
    #默认的版本匹配
    rx='^([0-9]+\.){2}([0-9]){1,2}$'
    get_latest_tag ${rx}
fi
LAST_VERISON=$g_latest_tag
#删除所有tag
git tag | xargs git tag -d
#判断之前是否有可用版本号
if [ -z $LAST_VERISON ]; then
    if [ $USER_CHOOESD_REPO == "gray" ]; then
        echo_warning "修复tag获取失败！！！"
        webhook false "修复tag获取失败, check !!!"
        exit 1
    fi
    LAST_VERISON='0.0.1'
    echo "当前无可用历史版本，将自动创建0.0.1"
fi
echo "自动更新版本号：[$LAST_VERISON]"
echo_success "组件仓库最后一次提交的标签版本号是 [$LAST_VERISON]"
log_line

echo '-----------------生成发布tag------------------'
log_line
#修改发布版本号
#语义化版本号发布
#x.y.z.m 依次为 主版本 次版本 修订版本 线上修复版本号
VERSION_TIPS=("Major version number" "Minor version number" "Revision version number")
VERSION_ARR=(${LAST_VERISON//./ })
VERSION_ARR_COUNT=${#VERSION_ARR[*]}
VERSION_TIPS_COUNT=${#VERSION_TIPS[*]}

NEW_VERSION=""
getAutoVersion() {
    if [ $USER_CHOOESD_REPO == $GRAY ]; then
        #灰度，修复问题版本
        if [ $VERSION_ARR_COUNT -gt 3 ]; then
            tempVersion=${VERSION_ARR[3]}
            tempVersion=$(($tempVersion + 1))
            VERSION_ARR[3]=$tempVersion
        else
            VERSION_ARR[3]="1"
        fi
    else
        if [ $USER_CHOOESD_REPO == $TEST ]; then
            echo "向test repo push 自动添加名字缩写-dev当前时间"
            nowTime=$(date "+%Y%m%d%H%M%S")
            VERSION_ARR[3]="${USER_NAME}-dev${nowTime}"
        fi
        versionPosition=2
        if [ $USER_VERSION_POSITION -gt 3 -a $USER_VERSION_POSITION -lt 0 ]; then
            #[AUTO] 版本号规则失效 采用小版本自增
            echo "tag 校验错误，请参考规范格式，本次发布即将自增第三位"
            versionPosition=2
        else
            versionPosition=$USER_VERSION_POSITION
        fi

        shouldPlus1='0'
        #当前是发正式版本,则版本号需要自增
        if [[ $USER_CHOOESD_REPO != $TEST ]]; then
            shouldPlus1="1"
        else
            #如果当前是发测试版本，且最近一次tag为正式版本，则版本号页需要自增
            devMode='-dev'
            if [[ $LAST_VERISON != *$devMode* ]]; then
                shouldPlus1="1"
            fi
        fi

        if [ $shouldPlus1 == '1' ]; then
            tempVersion=${VERSION_ARR[versionPosition]}
            tempVersion=$(($tempVersion + 1))
            VERSION_ARR[versionPosition]=$tempVersion
            #修改位之后的数字清零
            for ((i = $versionPosition + 1; i < VERSION_ARR_COUNT; i++)); do
                if test ${i} -gt 2; then
                    if [ "$USER_CHOOESD_REPO" != "test" ]; then
                        # 位数 > 3 ->  并且不是测试发布 时重置掉3位之后的
                        unset VERSION_ARR[i]
                    fi
                else
                    VERSION_ARR[i]='0'
                fi
            done
        fi
    fi

    NEW_TEMP_VERSION=''
    for item in ${VERSION_ARR[*]}; do
        NEW_TEMP_VERSION="${NEW_TEMP_VERSION}${item}."
    done
    NEW_TEMP_VERSION=${NEW_TEMP_VERSION%.}
    NEW_VERSION=$NEW_TEMP_VERSION
    echo "自动发布-将要发布的版本号为[$NEW_VERSION]"
}
getAutoVersion
echo_success "新的版本号为：${NEW_VERSION}"

#修改podspec版本号
rewriteFileContentOfLine $PODSPEC_NAME "s.version" $NEW_VERSION
if [ $is_open_CT == 1 ]; then
    rewriteFileContentOfLine $PODSPEC_CT_NAME "s.version" $NEW_VERSION
fi

echo "----------------提交发布信息------------------"

#[AUTO] 从参数中获取最后一条commit
READ_COMMIT_INFO=$CI_COMMIT_MESSAGE
# 如果没有输入注释 那么默认注释是podspec文件版本号
if [[ ${#READ_COMMIT_INFO} == 0 ]]; then
    READ_COMMIT_INFO=${NEW_VERSION}
    echo_success ">>>> 未输入注释, 默认使用push的tag号做为注释内容 <<<<"
else
    echo_success ">>>> 输入的提交注释是: <<<<"
    echo_success "${READ_COMMIT_INFO}"
    log_line
fi

git add .
git commit -a -m "自动发布，${NEW_VERSION}"

if [[ -n $Publish_Content ]]; then
    tagMessage="${Tag_Author}：${Publish_Content}"
    git tag -a -m "${tagMessage}" "${NEW_VERSION}"
else
    tagMessage="${Tag_Author}：${Last_Commmit_Msg}"
    git tag -a -m "${tagMessage}" "${NEW_VERSION}"
fi

if [[ ! $? ]]; then
    echo "打tag失败"
    webhook false "打tag失败, please check !"
    exit 1
fi

echo "当前repo选择为:${USER_CHOOESD_REPO}"
if [ $USER_CHOOESD_REPO == $RELEASE ]; then
    PUSHRESULT=$(git push origin HEAD:master --tags --porcelain)
elif [ $USER_CHOOESD_REPO == $TEST ]; then
    PUSHRESULT=$(git push --tags --porcelain)
elif [ $USER_CHOOESD_REPO == $OLD ]; then
    PUSHRESULT=$(git push origin HEAD:master --tags --porcelain)
elif [ $USER_CHOOESD_REPO == $GRAY ]; then
    #修复问题灰度发布，推倒指定的发布分支
    readFileContent "./Tools/runnerParam.txt"
    patchBranchName=$file_content
    echo "本地灰度修复提交分支为:${patchBranchName}"
    if [ ${#patchBranchName} -gt 0 ]; then
        PUSHRESULT=$(git push origin HEAD:${patchBranchName} --tags --porcelain)
    fi
fi

if [[ $PUSHRESULT == *"Done"* && !($PUSHRESULT =~ "rejected") ]]; then
    echo_success "git push was successful !"
else
    echo_warning "git push was failed, please check !"
    #删除所有tag
    git tag | xargs git tag -d
    webhook false "git push was failed, please check !"
    exit 1
fi

#源码发布时，发布源剔除二进制源
PUSH_SOURCE_REPO=${SOURCE_SPECS}
PUSH_SOURCE_REPO=${PUSH_SOURCE_REPO/"${BIN_SOURCE_REPO},"/}
echo '-----------------开始发布本次组发布--------------'
#执行发布
podsReleasePush $Repo $PODSPEC_NAME $PUSH_SOURCE_REPO $BIN_SOURCE_REPO
RELEASE_RESULT=$?

# 推送成功和推送失败的提示不一样
if [ $RELEASE_RESULT == 1 ]; then
    echo_success "组件发布成功 !! ^_^ !!"
else
    echo_warning "${NEW_VERSION}版本组件发布失败, 请检查!! -_- !!"
    webhook false "${NEW_VERSION} pod repo push failed, check !!!"
    #修改podspec版本号
    rewriteFileContentOfLine $PODSPEC_NAME "s.version" $LAST_VERISON
    rewriteFileContentOfLine $PODSPEC_CT_NAME "s.version" $LAST_VERISON
    git push origin :refs/tags/$NEW_VERSION
    git tag -d $NEW_VERSION
    git add .
    git commit "发布失败，恢复"
    git push origin HEAD:master --porcelain
    exit 1
fi

CT_RELEASE_TIPS=""
if [ $is_open_CT == 1 ]; then
    podsReleasePush $Repo $PODSPEC_CT_NAME $PUSH_SOURCE_REPO $BIN_SOURCE_REPO
    CT_RELEASE_RESULT=$?
    if [ $CT_RELEASE_RESULT == 1 ]; then
        CT_RELEASE_TIPS="组件CT发布成功"
        echo_success $CT_RELEASE_TIPS
        #CT发布同步到二进制repo
        podsReleasePush $BIN_REPO $PODSPEC_CT_NAME $PUSH_SOURCE_REPO $BIN_SOURCE_REPO
    else
        CT_RELEASE_TIPS="${NEW_VERSION}版本组件CT发布失败"
        echo_warning $CT_RELEASE_TIPS
        rewriteFileContentOfLine $PODSPEC_CT_NAME "s.version" $LAST_VERISON
        git push origin :refs/tags/$NEW_VERSION
        git tag -d $NEW_VERSION
        git add .
        git commit "组件CT发布失败，恢复"
        git push origin HEAD:master --porcelain
    fi
fi

log_line
echo_success "----------------开始更新发布机器机repo------------------"
tool_update_shihuo_repo
webhook true $CT_RELEASE_TIPS

if [ "$USER_CHOOESD_REPO" != $RELEASE ] && [ "$USER_CHOOESD_REPO" != $GRAY ]; then
    echo_success "------------------当前环境${USER_CHOOESD_REPO}屏蔽二进制----------------"
else
    fileIsContainContent $PODSPEC_NAME "${POD_BIN_SYMBOL}"
    is_binary=$?
    if [[ $is_binary == 1 ]]; then
        echo "组件${PROJIECT_NAME}开启二进制"
        #触发二进制配置
        echo_success "----------------开始更新组件二进制------------------"
        echo $(pwd)
        cd ./Tools
        ruby sh_binary_configure_framework.rb $PODS_NAME ':swift'
        cd ..
        echo $(pwd)
        #开始二进制发布
        sh ./Tools/sh_build_binary.sh $BIN_REPO $SOURCE_SPECS $NEW_VERSION $Tag_Author $BIN_SOURCE_REPO
    else
        echo_success "------------------组件没有开启二进制----------------"
        podsReleasePush $BIN_REPO $PODSPEC_NAME $PUSH_SOURCE_REPO $BIN_SOURCE_REPO
        tool_update_shihuo_repo
    fi
fi

#------------------  lint 校验过程下线 -----------------
# # 校验记录写入的文件  判断完成后会删除
# TMP_LOG_FILE="lintTmpLog.txt"
# LINT_SUCCESS_SIGN="${PODS_NAME} passed validation"

# # #本地效验
# $(>$TMP_LOG_FILE)
# echo "当前的spec源地址：$SOURCE_SPECS"

# if [ $AUTOMATIC_PROCESS == 1 ]; then
#     pod lib lint --sources=${SOURCE_SPECS} --allow-warnings | tee ${TMP_LOG_FILE}
# else
#     pod lib lint --sources=${SOURCE_SPECS} --allow-warnings --verbose | tee ${TMP_LOG_FILE}
# fi

# # 对写入到临时文件的内容进行逐行判断, 满足3个条件表示推送成功
# LINT_SUCCESS=false

# while read TMP_LINE; do
#     echo $TMP_LINE
#     if [[ $TMP_LINE == *$LINT_SUCCESS_SIGN* ]]; then
#         LINT_SUCCESS=true
#     fi
# done <$TMP_LOG_FILE

# # 移除临时的目录
# rm $TMP_LOG_FILE

# # 推送成功和推送失败的提示不一样
# if [[ ${LINT_SUCCESS} == true ]]; then
#     echo_success "pod lib lint 通过，可以发布!!!!"

# else
#     echo_warning "pod lib lint 失败, 请检查!!!!"
#     webhook false "pod lin lint failed, check !!!"
#     exit 1
# fi

#------------------  合并代码检测过程下线 -----------------
# # 合并代码检测，自动发布不执行
# #同步远程代码
# git stash
# git pull origin $(git rev-parse --abbrev-ref HEAD) --tags
# git stash pop

# #[AUTO]:不必检查，自动发布以远程分支为准
# ConflicCount=$(git ls-files -u | wc -l)
# if [ "$ConflicCount" -gt 0 ]; then
#     echo_warning "git有冲突，请执行git status查看冲突文件"
#     exit 1
# fi
