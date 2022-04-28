#!/bin/bash
#Created by wangyongxin on 2021/02/10

#spec路径
SOURCE_SPECS='git@code.shihuo.cn:shihuoios/shihuomodulize/shmodulizespecs.git,git@code.shihuo.cn:shihuoios/shihuomodulize/shmodulizespecs_gray.git,git@code.shihuo.cn:shihuoios/shihuomodulize/shmodulizespecs_test.git,git@code.shihuo.cn:shihuoios/shihuospecs.git,https://github.com/CocoaPods/Specs.git'

cd ..

pod lib lint --sources=${SOURCE_SPECS} --allow-warnings --use-libraries --use-modular-headers --skip-import-validation --verbose
