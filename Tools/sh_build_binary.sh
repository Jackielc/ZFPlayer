#!/bin/bash
#Created by wangyongxin on 2022/02/22

#脚本所需参数
#当前的repo
CURRENT_REPO=$1
#使用的私有源集合
SOURCE_SPECS=$2
#发布版本
POD_VERSION=$3
#发布者
TAG_AUTHER=$4
#二进制源
BIN_SOURCE_REPO=$5
#是否开启制作xcframework
IS_OPEN_XCFRAMEWORK=NO
#工程名
PROJECT_NAME=''
#通过podSpec 获取工程名
PODSPEC_PATH=$(find . -name "*.podspec")
PODSPEC_NAME=''
for item in ${PODSPEC_PATH[*]}; do
    itemName=$(basename $item)
    if [[ !($itemName =~ "_CT") ]]; then
        PODSPEC_NAME=$itemName
        PROJECT_NAME=${itemName%.podspec}
    fi
done

if [[ (${#PODSPEC_PATH} -lt 1) || (${#PODSPEC_NAME} -lt 1) ]]; then
    echo "当前目录下未找到podspec文件,退出二进制发布流程"
    exit 1
fi

BUILD_BASE_PATH='../Build'
FRAMEWORK_PATH="/Build/Products/Release-iphoneos/${PROJECT_NAME}.framework"
FRAMEWORK_DEVICE_PATH="/Build/Products/Release-iphoneos/${PROJECT_NAME}.framework"
FRAMEWORK_SIMULA_PATH="/Build/Products/Release-iphonesimulator/${PROJECT_NAME}.framework"
FRAMEWORK_MODULE_PATH="/Modules/${PROJECT_NAME}.swiftmodule"

cd ./Example
pod deintegrate
rm Podfile.lock
pod install
#制作framework前修改工程配置
ruby ../Tools/sh_binary_modify_target.rb $PROJECT_NAME

#真机架构
xcodebuild \
    -workspace $PROJECT_NAME.xcworkspace \
    -scheme "lib${PROJECT_NAME}" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -derivedDataPath "${BUILD_BASE_PATH}" \
    VALID_ARCHS="arm64 arm64e armv7s armv7" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=$IS_OPEN_XCFRAMEWORK | xcpretty

#模拟器架构
xcodebuild \
    -workspace $PROJECT_NAME.xcworkspace \
    -scheme "lib${PROJECT_NAME}" \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "${BUILD_BASE_PATH}" \
    VALID_ARCHS="x86_64 i386" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=$IS_OPEN_XCFRAMEWORK | xcpretty

DEVICE_PATH=$BUILD_BASE_PATH$FRAMEWORK_DEVICE_PATH
SIMULAR_PATH=$BUILD_BASE_PATH$FRAMEWORK_SIMULA_PATH
BUNDLE_PRODUCT_PATH="../${PROJECT_NAME}.bundle"
#产物路径文件，并创建
BUILD_PRODUCT_DIRECTORY=$BUILD_BASE_PATH/${PROJECT_NAME}
if [ ! -d $BUILD_PRODUCT_DIRECTORY ]; then
    mkdir $BUILD_PRODUCT_DIRECTORY
else
    echo dir exist
fi
BUILD_PRODUCT_PATH=""
# 合并二进制库
# IS_OPEN_XCFRAMEWORK 打开时制作 xcframework 否则制作 fat framework
if [ $IS_OPEN_XCFRAMEWORK == YES ]; then
    # TODO: xcframework 流程待完善
    BUILD_PRODUCT_PATH=$BUILD_BASE_PATH/$PROJECT_NAME.xcframework
    xcodebuild -create-xcframework \ 
    -framework $DEVICE_PATH \
        -framework $SIMULAR_PATH \
        -output $BUILD_PRODUCT_PATH
else
    BUILD_PRODUCT_PATH=$BUILD_PRODUCT_DIRECTORY/${PROJECT_NAME}.framework
    #复制framework产物
    cp -r $DEVICE_PATH $BUILD_PRODUCT_DIRECTORY
    #复制bundle产物: xxx.xib  assets.car
    if [ -d $BUNDLE_PRODUCT_PATH ]; then
        cp -r $BUNDLE_PRODUCT_PATH $BUILD_PRODUCT_DIRECTORY
        # 向bundle产物中添加编译后的资源
        PRODUCT_FILES=$(ls $BUILD_PRODUCT_PATH)
        for file in $PRODUCT_FILES; do
            if [ "${file##*.}" = "nib" ]; then
                echo "复制指定文件：${file}"
                cp -r "${BUILD_PRODUCT_PATH}/${file}" "${BUILD_PRODUCT_DIRECTORY}/${PROJECT_NAME}.bundle"
            fi
            if [ "${file##*.}" = "car" ]; then
                echo "复制指定文件：${file}"
                cp -r "${BUILD_PRODUCT_PATH}/${file}" "${BUILD_PRODUCT_DIRECTORY}/${PROJECT_NAME}.bundle"
                find "${BUILD_PRODUCT_DIRECTORY}/${PROJECT_NAME}.bundle" -maxdepth 1 -name '*.xcassets' | xargs rm -rf
            fi
            if [ "${file##*.}" = "plist" ]; then
                echo "复制指定文件：${file}"
                cp -r "${BUILD_PRODUCT_PATH}/${file}" "${BUILD_PRODUCT_DIRECTORY}/${PROJECT_NAME}.bundle"
            fi
        done
    fi
    #复制模拟器framework中swift架构
    cp -r $SIMULAR_PATH$FRAMEWORK_MODULE_PATH/. $BUILD_PRODUCT_PATH$FRAMEWORK_MODULE_PATH
    #创建最终产物
    lipo -create \
        $DEVICE_PATH/$PROJECT_NAME \
        $SIMULAR_PATH/$PROJECT_NAME \
        -output $BUILD_PRODUCT_PATH/$PROJECT_NAME
    #修改-swift.h文件, 兼容模拟器
    subFileSwift="Headers/${PROJECT_NAME}-Swift.h"
    fileSwift=$BUILD_PRODUCT_PATH/$subFileSwift
    echo "${PROJECT_NAME}-Swift.h文件路径： ${fileSwift}"
    fileSwiftMatchStr1="#if 0"
    fileSwiftMatchStr2="#elif defined(__arm64__) && __arm64__"
    fileSwiftMatchStr3="#if defined(__arm64__) && __arm64__ || (__x86_64__) && __x86_64__ || (__i386__) && __i386__"
    if [ -f $fileSwift ]; then
        sed -i '' "s/${fileSwiftMatchStr1}//" $fileSwift
        sed -i '' "s/${fileSwiftMatchStr2}//" $fileSwift
        sed -i '' "1 a\\
        ${fileSwiftMatchStr3}" $fileSwift
    fi
    #删除framework中无关的资源文件
    find ${BUILD_PRODUCT_DIRECTORY}/${PROJECT_NAME}.framework -maxdepth 1 -name '*.bundle' -not -name "${PROJECT_NAME}*.bundle" | xargs rm -rf
    find ${BUILD_PRODUCT_DIRECTORY}/${PROJECT_NAME}.framework -maxdepth 1 -name '*.car' -not -name "Assets*.car" | xargs rm -rf
    #删除bundle中无关资源
    find ${BUILD_PRODUCT_DIRECTORY}/${PROJECT_NAME}.bundle -maxdepth 1 -name '*.xib' | xargs rm -rf
fi

#此时bundle内不应该存在xxx.xcassets原始资源文件，检测bundle中如果还存在 .xcassets 文件，遍历取出全部的资源
function copyAssetsSource() {
    source_file_path=$1
    dest_path=$2
    files=$(ls $source_file_path)
    for file in $BUNDLE_FILES; do
        file_path="${source_file_path}/${file}"
        if [ -d $file ]; then
            copyAssetsSource $file_path $dest_path
        elif [ -f $file ]; then
            cp -r $file_path $dest_path
        fi
    done
}
BUNDLE_PATH="${BUILD_PRODUCT_DIRECTORY}/${PROJECT_NAME}.bundle"
BUNDLE_FILES=$(ls $BUNDLE_PATH)
for file in $BUNDLE_FILES; do
    if [ "${file##*.}" = "xcassets" ]; then
        echo "注意：存在图片资源，担未找到找到对饮的压缩文件.car，开始讲源文件解析"
        copyAssetsSource "${BUNDLE_PATH}/${file}" $BUNDLE_PATH
    fi
done

#服务器产物路径
PRODUCT_URL_PATH=""
function uploadFileOSS() {
    file_path=$1
    file_name=$(basename $file_path)
    subPath=${PROJECT_NAME}/${POD_VERSION}/${file_name}
    #oss://sh-mobile-archive/ios/SHFoundation/0.0.6.1/SHFoundation.framework.zip
    oss_path="oss://sh-mobile-archive/ios/${subPath}"
    echo $file_path
    echo $oss_path
    #上传
    ${HOME}/ossutilmac64 cp -r \
        $file_path \
        $oss_path
    #产物路径https://sh-mobile-archive.oss-cn-hangzhou.aliyuncs.com/ios/
    PRODUCT_URL_PATH="https://sh-mobile-archive.oss-cn-hangzhou.aliyuncs.com/ios/${subPath}"
}

source '../Tools/tool_functions.sh'
source '../Tools/sh_pod_release.sh'

PRODUCT_NAME="${PROJECT_NAME}"
PRODUCT_ZIP="${PRODUCT_NAME}.zip"
#判断产物是否存在
if [ -d $BUILD_PRODUCT_PATH ]; then
    cd $BUILD_BASE_PATH
    zip -r $PRODUCT_ZIP $PRODUCT_NAME
    cd ../Example
    #上传二进制zip到oss服务器
    uploadFileOSS $BUILD_BASE_PATH/$PRODUCT_ZIP
    #获取zip下载地址
    echo_success "产物路径：${PRODUCT_URL_PATH}"
    #修改podspec, 源地址(source) 指向二进制，二进制版本号
    if [ $IS_OPEN_XCFRAMEWORK == YES ]; then
        ruby ../Tools/sh_binary_modify_podSpec.rb $PROJECT_NAME $PRODUCT_URL_PATH true
    else
        ruby ../Tools/sh_binary_modify_podSpec.rb $PROJECT_NAME $PRODUCT_URL_PATH false
    fi
else
    echo_warning "！！！！！没有找到指定的二进制产物！！！！！"
    echo "------------将上传源码依赖-------------"
fi
#修改后的二进制podSpec 发布到二进制源
cd ..
BIN_PUSH_SOURCE_REPO=${SOURCE_SPECS}
BIN_PUSH_SOURCE_REPO=${BIN_PUSH_SOURCE_REPO/"${BIN_SOURCE_REPO},"/}
podsReleasePush $CURRENT_REPO $PODSPEC_NAME $BIN_PUSH_SOURCE_REPO $BIN_SOURCE_REPO
RELEASE_RESULT=$?
# 二进制组件发布结果
HTTP_GX='(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]'
if [ $RELEASE_RESULT == 1 ]; then
    if [[ $PRODUCT_URL_PATH =~ $HTTP_GX ]]; then
        echo_success "组件二进制发布成功 !! ^_^ !!"
        tool_update_shihuo_repo
        webhookMessage true "二进制" $POD_VERSION $TAG_AUTHER
    else
        echo_success "组件源码发布成功 !! ^_^ !!"
        tool_update_shihuo_repo
        echo_warning "${POD_VERSION}版本二进制发布失败, 请检查!! -_- !!"
        webhookMessage false "二进制" $POD_VERSION $TAG_AUTHER "${POD_VERSION} pod repo push failed, Replace source repo push，check !!!"
    fi
else
    echo_warning "${POD_VERSION}版本二进制发布失败, 请检查!! -_- !!"
    webhookMessage false "二进制" $POD_VERSION $TAG_AUTHER "${POD_VERSION} pod repo push failed, check !!!"
    exit 1
fi
echo_success "----------------开始更新发布机器机repo------------------"
