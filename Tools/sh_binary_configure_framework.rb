#!/usr/bin/ruby
#Created by wangyongxin on 2022/02/10

require 'xcodeproj'
require 'tempfile'
require 'fileutils'

# projectName = ARGV[0]
# lan = ARGV[1]
# extension = ARGV[2]
puts "接受的参数 #{ARGV}"
#组件工程名
$projectName = ARGV[0]
# $projectName = 'SHGoodsDetailModules'
#创建target的语言 :swift or :objc
$language = ARGV[1]
# $language = ':swift'
#创建framwork的target 名字
$targetName = $projectName
#devlopment_target
DEVELOPMENT_TARGET = '9.0'
#工程路径
project_file = $projectName + '.xcodeproj'
project_file_path = "../Example/#{project_file}"
#源文件路径
$sources_path = "../#{$projectName}/Assets"
$files_path = "../#{$projectName}/Classes"
#framework头文件路径
framework_header_path = "../#{$targetName}/Classes/#{$targetName}.h"
#二进制需要公开的.h文件
$framework_headers = Array.new
#兼容有些组件本身就已经存在公共的工程头文件
$is_contain_framework_header_path = ""

#创建或者改写framework的头文件
#return：是否需要添加文件到target
def createFrameworkHeaderFile(path, targetName)
    @@line1 = "#import <Foundation/Foundation.h>\n"
    @@line2 = "//! Project version number for #{targetName}.\n  FOUNDATION_EXPORT double #{targetName}VersionNumber;\n\n"
    @@line3 = "//! Project version string for #{targetName}.\n  FOUNDATION_EXPORT const unsigned char #{targetName}VersionString[];\n\n"
    @@line4 = "// In this header, you should import all the public headers of your framework using statements like #import <#{targetName}/PublicHeader.h>"
    if File.exist?($is_contain_framework_header_path) 
        temp_file = Tempfile.new($is_contain_framework_header_path)
        begin
            temp_file.puts @@line1
            temp_file.puts @@line2
            temp_file.puts @@line3
            temp_file.puts @@line4
            $framework_headers.each do |fileName|
                puts "写入的头文件#{fileName}"
                temp_file.puts("#import \"#{fileName}\"")
            end   
            temp_file.close
            FileUtils.mv(temp_file.path, $is_contain_framework_header_path)
        ensure
            temp_file.close
            temp_file.unlink
        end
        return false
    elsif !File.exist?(path)
         #"./Example/#{targetName}/#{targetName}.h"
        framework_headerFile = File.new(path,"w+")
        framework_headerFile.puts(@@line1)
        framework_headerFile.puts(@@line2)
        framework_headerFile.puts(@@line3)
        framework_headerFile.puts(@@line4)
        framework_headerFile.puts("\n")
        # 公开头文件
        $framework_headers.each do |fileName|
            puts "写入的头文件#{fileName}"
            framework_headerFile.puts("#import \"#{fileName}\"")
        end    
        framework_headerFile.close
        return true
    end    
end 

#是否为资源文件格式限制名单
def is_resource_group(filePath) 
    extname = filePath[/\.[^\.]+$/]
    if extname == '.bundle' || extname == '.xcassets' || extname == '.xib' || extname == '.svga' || extname == '.ttf' || extname == '.json' || extname == '.rb' then
        return true
    end
    return false       
end 
#创建bundle产物

def copyFile(sourcePath, destPath)
    resource_files = Dir.glob(sourcePath + "/*")
    if resource_files.length > 0
        resource_files.each do |item|
            if File.directory?(item)
                copyFile(item, destPath)
            else 
                puts "复制的资源文件: #{item}"
                FileUtils.cp item, destPath
            end    
        end    
    end 
end 

def createBundle(sourcePath)
    puts "bundle文件路径#{sourcePath}"
    resource_files = Dir.glob(sourcePath + "/*")
    puts resource_files
    if resource_files.length > 0
        new_file="../#{$projectName}.bundle"
        if File.exist?(new_file) 
            FileUtils.rm_rf(new_file)
        end    
        puts "开始创建bundle"
        dest = "../#{$projectName}Bundle"
        FileUtils.makedirs(dest)
        copyFile(sourcePath, dest)   
        File.rename(dest, new_file)
    end    
end    
#增加单个文件的引用
def addSingleFileReference(path, target, group) 
    itemName = File.basename(path)
    file = group.new_reference(path)
    buildFiles = target.add_file_references([file])
    # 头文件修改为 public
    if itemName.include? ".h" 
        $framework_headers.push(itemName)
        buildFile = buildFiles.first
        buildFile.settings = { 'ATTRIBUTES' => ['Public'] }
        if itemName == "#{$targetName}.h" 
            $is_contain_framework_header_path = path
        end
    end
end    

#为指定的taget的group 创建文件引用，
def addFileReference(target, relative_path, group, isResource)
    path = File.expand_path(relative_path)
    puts group
    puts "绝对路径#{path}"
    if path.to_s.end_with?(".h", ".m", ".swift", ".mm")
        addSingleFileReference(path, target, group)   
    else
        Dir.glob(path + "/*") do |item|
            # puts "路径下的--#{item}"
            # is_resource_group(item)
            if isResource == true 
                puts "资源路径下的--#{item}"
                file = group.new_reference(item)
                target.add_resources([file])
            elsif File.directory?(item)
                # parent = File.basename(File.dirname(item))
                itemName = File.basename(item)
                # puts "路径--#{item}---#{File.basename(item)}"
                subGroup = group.find_subpath(File.join(itemName), true)
                # puts "子group#{item}---路径的--#{subGroup}"
                #递归查询
                addFileReference(target, item, subGroup, false)
            else
                addSingleFileReference(item, target, group)   
            end
        end
    end        
end

#修改工程现有target的 中 build_setting的配置
def modifyTargetBuildSetting(project)
    project.targets.each do |target|
        target.build_configurations.each do |config|
            build_settings = config.build_settings
            build_settings["SWIFT_VERSION"] = "5.0"
            build_settings.each do |key, value|
                # puts "#{key} == #{value}"
            end    
        end
    end    
end

#修改framework 中 build_setting的配置
def modifyFrameworkTargetBuildSetting(target)
    target.build_configurations.each do |config|
        puts "config names:  --- #{config.name}"
        build_settings = config.build_settings
        build_settings["SWIFT_VERSION"] = "5.0"
        build_settings["MACH_O_TYPE"] = "staticlib"
        build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.shihuo.#{target.name}"
        build_settings["DEVELOPMENT_TEAM"] = "SWTU7N2NXP"
        build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
        build_settings["OTHER_SWIFT_FLAGS"] = "$(inherited) -Xcc -Wno-error=non-modular-include-in-framework-module"
        build_settings.each do |key, value|
            # puts "#{key} == #{value}"
        end    
    end    
end

#添加target对应的scheme
def addSchemeWithTarget(target, project_path) 
    scheme = Xcodeproj::XCScheme.new
    scheme.add_build_target(target)
    scheme_name = "lib#{target.name}"
    scheme.save_as(project_path, scheme_name)
end    

#创建framework的target
def createFrameworkTarget(project) 
    project.targets.each do |target|
        if target.name == $targetName
            project.main_group.children.each do |group| 
                if group.name == $targetName
                    puts "已存在target--#{target}--group--#{group}" 
                    return target, group
                end    
            end    
        end    
    end
    path = "../Example/#{$projectName}"
    mainGroup = project.main_group
    frameworkGroup = mainGroup.new_group($targetName, File.basename(path), :group)
    product_group = project.products_group
    puts "创建的target的group--#{frameworkGroup.name}"
    framework_target = Xcodeproj::Project::ProjectHelper.new_target(project, :framework, $targetName, :ios, DEVELOPMENT_TARGET, product_group, $language, $targetName)
    return  framework_target, frameworkGroup
end    

def judgeTargetsIncludeTests(project) 
    test_target = "#{$targetName}_Tests"
    include_Tests = false
    project.targets.each do |target|
        if target.name == test_target
            include_Tests = true
        end    
    end
    return include_Tests
end

# 开始主流程
# Open the existing Xcode projec
project = Xcodeproj::Project.open(project_file_path)
modifyTargetBuildSetting(project)
puts project.targets
puts project.main_group.children
#Add the target to the project.
#Add the target group
framework_results = createFrameworkTarget(project)
#framework target
framework_target = framework_results[0]
#framework group
framework_group = framework_results[1]
puts "创建的target--#{framework_results}"
puts framework_target.product_install_path
puts framework_target.product_reference
#添加源文件group，并添加引用
addFileReference(framework_target, $files_path, framework_group, false)
#创建framework的.h 文件，并添加引用
needAddFrameworkHeader = createFrameworkHeaderFile(framework_header_path, $targetName)
if needAddFrameworkHeader == true
    addFileReference(framework_target, framework_header_path, framework_group, false)
end   
#添加资源路径
addFileReference(framework_target, $sources_path, framework_group, true)
createBundle($sources_path)
#修改build_settings的配置
modifyFrameworkTargetBuildSetting(framework_target)
#添加scheme
addSchemeWithTarget(framework_target, project_file_path)
include_TestTarget = judgeTargetsIncludeTests(project)
project.save
puts "------------工程二进制配置完成---------"
#修改工程podfile配置
require './sh_modify_podfile' 
SHModifyPodile.BinModifyWorkSpacePodfile($projectName, include_TestTarget)