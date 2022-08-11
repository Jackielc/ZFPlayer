#!/bin/bash
#Created by wangyongxin on 2021/12/03

source './Tools/tool_functions.sh'

FEATURE_LISTS=("组件校验工具" "更新组件依赖repo source" "组件修复版本工具" "前往组件仓库")
FEATURE_FILE_ISTS=("SHPodLint.sh" "sh_update_pod_repo_source.rb" "SHPodPatch.sh" "gotoGitlab.sh")

length=${#FEATURE_LISTS[@]}

for ((index = 0; index < length; index++)); do
    echo " (${index}) ${FEATURE_LISTS[$index]}"
done
read -p "请选择组件工具 (输入标号) :" FeatureIndex

if test $FeatureIndex -lt $length; then
    FEATURE_FLIE=${FEATURE_FILE_ISTS[$FeatureIndex]}
else
    echo_warning "\n\n 标号必须小于 ${length}\n"
    exit 1
fi

cd Tools

if [ "${FEATURE_FLIE##*.}" == "rb" ]; then
    ruby $FEATURE_FLIE
elif [ "${FEATURE_FLIE##*.}" == "sh" ]; then
    sh $FEATURE_FLIE
fi
