#!/bin/bash
#Created by shigaoqiang on 2021/05/17
# 跳转gitlab

#拿到git仓库地址
function get_home_page() {
    result=$(git remote -v)
    homePage=""
    for each in $result; do
        # 类型一：git@code.shihuo.cn:shihuoios/shihuomodulize/bussinessgroup/shabtest.git
        if [[ $each =~ ^git.* ]]; then
            homePage=$each
            break
        # 类型二：https://code.shihuo.cn/shihuoios/shihuoioscert
        elif [[ $each =~ ^http.* ]];then
            homePage=$each
            break
        fi
    done
    
    # git@开头的需要字符串替换
    if [[ $homePage =~ ^git@code.shihuo.cn:.* ]]; then
        current="git@code.shihuo.cn:"
        domain="https://code.shihuo.cn/"
        homePage=${homePage/${current}/${domain}}
        homePage=${homePage%.git}
    fi
   
    echo $homePage
}

GO_TO_TAG=''
GO_TO_MR=''
Git_ENV_PATH=''
while [[ $# -gt 0 ]]; do
    case "$1" in
    -tag)
        GO_TO_TAG="$1"
        shift
        ;;
    -mr)
        GO_TO_MR="$1"
        shift
        ;;
    -path)
        Git_ENV_PATH="$2"
        shift
        shift
        ;;
    *)
        echo "Unknown option: $1"
        shift
    esac
done

cd ${Git_ENV_PATH}

home_page=`get_home_page`

if [[ -n $GO_TO_TAG ]]; then
    path="${home_page}/-/tags"
elif [[ -n $GO_TO_MR ]]; then
    path="${home_page}/merge_requests"
else
    path="${home_page}"
fi
open -a "/Applications/Google Chrome.app" $path

