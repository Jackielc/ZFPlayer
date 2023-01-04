#!/usr/bin/python3
# encoding: utf-8
# create by SGQ 2020-02-11
# 对提交文件进行检测

import sys
import os
import os.path
import io
import re
import json

Max_Pic_Size = 150


# 获取commit message
def get_commit_message():
    commit_temp_file = sys.argv[1]
    with io.open(commit_temp_file, 'r', encoding='utf-8') as data:
        # 读取第一行
        message = data.readline()

        # 编码问题
        if type(message) == type(u'Hello World! \u00f8'):
            message = message.encode('unicode-escape').decode('string_escape')

        # 变换
        message = message.strip('\n').strip(" ").lower()
        return message


# log for alert
def not_pass_alert():
    print('commit message 不符合规范，规范格式形似: feat(location):登录API调试')

    print('feat:新功能')
    print('fix:修复bug')
    print('doc:文档改变')
    print('style:代码格式改变')
    print('refactor:某个已有功能重构')
    print('perf:性能优化')
    print('test:增加测试')
    print('build:改变了build工具，如 grunt换成了 npm')
    print('revert:撤销上一次的 commit')
    print('cherry:遴选')
    print('conflict:冲突解决')

    print('详情请参考本项目的 commit.template')
    print('临时可以使用 --no-verify 规避检测，在sourceTree的提交选项中可以选择')


# 判断是否忽略掉本次检测
def is_ignored_commit_message(message):
    # 合并代码自动生成
    if message.startswith("merge"):
        return True

    # 回滚代码自动生成
    if message.startswith("revert"):
        return True

    # 冲突代码自动生成
    if message.startswith("conflict"):
        return True
    return False


# A. 检测变更的文件中类是否添加的必要的注释说明
def judge_files(files):
    # 定义退出code
    code = 0

    # 遍历文件 检出.h中是否带有对该类的注释说明
    for file_name in files:
        file_name = file_name.strip('\n')

        if not os.path.exists(file_name):
            continue

        if file_name.find(".h") != -1 or file_name.find(".swift") != -1:
            res = check_annotation(file_name)
            if res is False:
                last_part = os.path.basename(file_name).strip('\n')
                code = 1
                print("请确认在 %s 中第七行是否添加了足额必要的注释(最少五个字)" % (last_part))
                print('特殊情况, 可以临时使用 --no-verify 规避检测')
                break

    return code


# 辅助A. 检测一个类是否添加的必要的注释说明 没有注释返回1
def check_annotation(file_name):
    file_name = file_name.lower()
    res = True
    if file_name.find('vc.h') == -1 \
            and file_name.find('controller.h') == -1 \
            and file_name.find('vc.swift') == -1 \
            and file_name.find('controller.swift') == -1:
        return res
    try:
        with io.open(file_name, 'r', encoding='utf-8') as data:
            i = 0
            for each_line in data:
                i = i + 1
                if i == 7:
                    line_clean = ''.join(each_line.strip('\n').split(' '))
                    if len(line_clean) < 7:
                        res = False
                    break

    except BaseException as error:
        print('读取文件出错: ', str(error))
    return res


# B. 读取当前git环境下变动的图片，使用imageoptim-cli 进行压缩
def check_compress_png():
    # 定义退出code
    code = 0

    # 变更的图片
    changed_images = get_all_png_from_git_diff()

    if len(changed_images) <= 0:
        return code

    # 原有的图片
    record_images = []
    record_path = os.getcwd() + '/gitHooks/imageRecord.txt'

    if not os.path.exists(record_path):
        command = "touch " + record_path
        os.system(command)
        command = "echo [ ] > " + record_path
        os.system(command)
        print("创建imageRecord.txt 成功")

    with open(record_path, "r") as fp:
        record_images = json.loads(fp.read())

    # 新增的图片
    new_images = []
    for file_name in changed_images:
        file_name = file_name.strip('\n')

        if not os.path.exists(file_name):
            continue

        if file_name.find(".png") != -1 or file_name.find(".jpg") != -1:
            if file_name not in record_images:
                record_images.append(file_name)
                new_images.append(file_name)

    if len(new_images) <= 0:
        return 0

    # 更新
    with open(record_path, "w") as fp:
        fp.write(json.dumps(record_images, indent=4))

    # 开始压缩
    print("检测到有新增图片，开始压缩")

    for file_name in new_images:
        transform_img_use_image_optim_cli(file_name)

    print("压缩完成，请重新提交")
    return 1


# 辅助B. 获取 git diff 变更的文件中所有的 .png
def get_all_png_from_git_diff():
    image_dir_array = []
    res = os.popen("git diff --cached --name-only")
    for file in res:
        file = file.strip("\n")
        full_file_name = os.path.join(os.getcwd(), file)
        if not os.path.exists(full_file_name):
            continue

        if full_file_name[-4:] == ".png" or full_file_name[-4:] == ".jpg":
            image_dir_array.append(full_file_name)
    return list(set(image_dir_array))


'''
# 辅助B. 使用tinyPng压缩单张图片 image_path图片绝对路径
def transform_img_use_tiny_png(image_path):
    print("正在压缩 %s" % (image_path))
    original_size = os.path.getsize(image_path) / 1000.0
    source = tinify.from_file(image_path)
    source.to_file(image_path)
    size = os.path.getsize(image_path) / 1000.0
    print("%.2fkb ---> %.2fkb" % (original_size, size))
    # 超过500次后，再重新申请一个账号
    print("已使用次数：%s" % (tinify.compression_count))
'''


# 辅助B. 使用imageoptim压缩单张图片 image_path图片绝对路径
def transform_img_use_image_optim_cli(image_path):
    cmd = "/usr/local/bin/imageoptim -Q %s" % (image_path)
    res = os.system(cmd)


# C. 检测文件名中是否有空格 有空格返回True
def check_space(files):
    # 定义退出code
    code = 0
    for file_name in files:
        name = file_name.strip('\n')

        if not os.path.exists(name):
            continue

        res = name.split(' ')
        if (len(res)) > 1:
            code = 1
            print("请删除在 %s 中包含的空格" % (name))
            print('特殊情况, 可以临时使用 --no-verify 规避检测')
            break

    return code


# D. 检测文件名和文件所在目录是否大写
def check_dir_capital(files):
    pattern = re.compile(r'^([A-Z]).*?$')
    for file_name in files:
        name = file_name.strip('\n')

        if not os.path.exists(file_name):
            continue

        if name.find(".h") == -1 and name.find(".m") == -1 and name.find('.swift') == -1:
            continue
        coms = name.split("/")
        if not pattern.match(coms[-1]) or not pattern.match(coms[-2]):
            last_part = os.path.basename(file_name).strip('\n')
            print("请确认 %s 文件本身和其所处目录是否大写开头" % (last_part))
            return 1

    return 0


# E. 检测图片大小是否超过指定大小
def check_pic_size(files):
    # 定义退出code
    code = 0
    for file_name in files:
        file_name = file_name.strip('\n')

        if not os.path.exists(file_name):
            continue

        if file_name.find(".png") != -1 or file_name.find(".jpg") != -1:
            with open(file_name, 'rb') as data:
                image = data.read()
                image_b = io.BytesIO(image).read()
                size = len(image_b) / 1024
                if size > Max_Pic_Size:
                    print("%s 这张图片大小为%dkb，大于了%dkb，请压缩后重新提交" % (file_name, size, Max_Pic_Size))
                    print('特殊情况, 可以临时使用 --no-verify 规避检测')
                    return 1

    return code


def pickout_file_content(file_name):
    contents = []
    try:
        with io.open(file_name, 'r', encoding='utf-8') as data:
            for each_line in data:
                each_line = each_line.strip('\n')
                contents.append(each_line)
    except BaseException as error:
        print('读取文件出错: ', str(error))
    return contents


def get_name_version(each_line):
    # 特殊版本，无需判断
    if each_line.find(':git') != -1:
        return None
    if each_line.find(':path') != -1:
        return None
    res = re.findall(r"'(.*?)'", each_line)
    if len(res) >= 2:
        name = res[0]
        version_str = res[1].replace('.', '')
        version_result = ''
        for char in version_str:
            if char.isdigit():
                version_result += char
            else:
                break

        version = int(version_result)
        if version <= 0:
            return None

        dict = {'name': name, 'version': version}
        return dict
    else:
        return None


def check_podfile_version(contents):
    # 定义退出code
    code = 0
    pod_changed_old_versions = {}
    pod_changed_new_versions = {}
    for each_line in contents:
        if each_line.find('-  pod') != -1:
            res = get_name_version(each_line)
            if res is not None:
                name = res['name']
                version = res["version"]
                pod_changed_old_versions[name] = version
        elif each_line.find('+  pod') != -1:
            res = get_name_version(each_line)
            if res is not None:
                name = res['name']
                version = res["version"]
                pod_changed_new_versions[name] = version
    for name in pod_changed_new_versions:
        new_version = pod_changed_new_versions[name]
        if name not in pod_changed_old_versions.keys():
            continue
        old_version = pod_changed_old_versions[name]
        # 新版本号版本减短
        while len(str(new_version)) < len(str(old_version)):
            new_version = new_version * 10

        if new_version < old_version:
            print("%s 版本被降低，pod库版本只升不降，请检查！" % (name))
            code = 1
            break
    return code


# main function
def check_all_files(ignore_image_compress):
    code = 0

    # 1.检测注释
    # print('类头文件注释检测...')
    #
    # # 拿到所有变更的文件名
    # allDiffFile = os.popen('git diff --cached --name-only')
    # code = judge_files(allDiffFile)
    # if code == 0:
    #     print('类头文件注释检测通过\n')
    # else:
    #     return code

    # 2.图片压缩检测
    if not ignore_image_compress:
        print('图片压缩检测...')
        code = check_compress_png()
        if code == 0:
            print('图片压缩检测通过✅✅✅✅\n')
        else:
            return code

    # 3.图片大小检测
    print('图片大小检测...')
    all_diff_file = os.popen('git diff --cached --name-only')
    code = check_pic_size(all_diff_file)
    if code == 0:
        print('图片大小检测通过✅✅✅✅\n')
    else:
        return code

    # 4.检测文件名中的空格
    print('文件名空格检测...')
    all_diff_file = os.popen('git diff --cached --name-only')
    code = check_space(all_diff_file)
    if code == 0:
        print('文件名空格检测通过✅✅✅✅\n')
    else:
        return code

    # 5.文件目录大小写检测
    print('文件目录大小写检测...')
    all_diff_file = os.popen('git diff --cached --name-only')
    code = check_dir_capital(all_diff_file)
    if code == 0:
        print('文件目录大小写检测通过✅✅✅✅\n')
    else:
        return code

    # 6.Podfile检测
    print('Podfile检测...')
    contents = os.popen('git diff --cached Podfile')
    code = check_podfile_version(contents)
    if code == 0:
        print('Podfile检测通过✅✅✅✅\n')
    else:
        return code
    return code
