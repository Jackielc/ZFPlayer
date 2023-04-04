#!/usr/bin/ruby
#Created by wangyongxin on 2022/02/22

require 'tempfile'
require 'fileutils'
require './sh_config_Vari.rb'

class SHModifyPodile

    @@PODFILE_PATH = "../Example/podfile"
    @@DEVELOPMENT_TARGET = "platform :ios, '#{$POD_DEVELOPMENT_TARGET}'\n"
    POD_INSTALL_WAY = "#use_frameworks! \nuse_modular_headers!"
    #关闭bitcode ，并且屏蔽模拟器arm64 架构
    POD_CONFIG = 
"post_install do |installer| 
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        end
    end
    dev_team = ''
    project = installer.aggregate_targets[0].user_project
    project.targets.each do |target|
        target.build_configurations.each do |config|
            if dev_team.empty? and !config.build_settings['DEVELOPMENT_TEAM'].nil?
                dev_team = config.build_settings['DEVELOPMENT_TEAM']
            end
        end
    end

    # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
    installer.pods_project.targets.each do |target|
        if target.respond_to?(:product_type) and target.product_type == 'com.apple.product-type.bundle'
            target.build_configurations.each do |config|
                config.build_settings['DEVELOPMENT_TEAM'] = dev_team
            end
        end
    end
end "

    # 抓取podspec 中所有的依赖库
    def SHModifyPodile.obtainPodspecDependencys(path)
        podSpec = File.open(path, "r") 
        keyStr = "dependency"
        dependencys = Array.new
        podSpec.each do |line|
            if line.include?(keyStr)
                keyIndex = line.index(keyStr)
                keyIndex += keyStr.length
                subStr = line[keyIndex, line.length]
                puts "截取的字符串---:#{subStr}"
                dependencys.push(subStr)            
            end    
        end
        return dependencys     
    end

    def SHModifyPodile.BinModifyWorkSpacePodfile(projectName, isIncludeTests)
        @@project_name = projectName
        if @@project_name.nil? || @@project_name.empty? 
            puts "工程名字参数为空--#{@@project_name}"
            return
        end 
        @@PODSPEC_PATH = "../#{@@project_name}.podspec"
        # podfile 文件改造 常量
        @@WORKSPACE = "\nworkspace '#{@@project_name}.xcworkspace' \n"
        @@PROJECT_XCODEPROJ = "xcodeproj '#{@@project_name}.xcodeproj'\n"
        @@SOURCE_TESTS_TARGET_POD = "target '#{@@project_name}_Tests' do\n    inherit! :search_paths\n    end\n"
        @@SOURCE_TARGET_POD = "target '#{@@project_name}_Example' do\n    pod '#{@@project_name}', :path => '../'\n    #{@@PROJECT_XCODEPROJ}\n    end \n"
        if isIncludeTests == true 
            @@SOURCE_TARGET_POD = "target '#{@@project_name}_Example' do\n    pod '#{@@project_name}', :path => '../'\n    #{@@PROJECT_XCODEPROJ}\n  #{@@SOURCE_TESTS_TARGET_POD}  end \n" 
        end    
        # 开始改写podfile
        puts "针对#{@@project_name}二进制开始改写podfile"
        temp_file = Tempfile.new('podfile')
        begin
            dependencys = SHModifyPodile.obtainPodspecDependencys(@@PODSPEC_PATH)
            podfile = File.open(@@PODFILE_PATH, "r")
            podfile.each do |line|
                if line.to_s.start_with?("source")
                    
                    temp_file.puts line
                end    
            end

            temp_file.puts @@WORKSPACE
            temp_file.puts @@PROJECT_XCODEPROJ
            temp_file.puts @@DEVELOPMENT_TARGET
            temp_file.puts POD_INSTALL_WAY
            temp_file.puts "\n"
            temp_file.puts @@SOURCE_TARGET_POD
            temp_file.puts "\n"
            #写入framework 依赖
            temp_file.puts "target '#{@@project_name}' do"
            temp_file.puts "  #{@@PROJECT_XCODEPROJ}"
            dependencys.each do |item|
                temp_file.puts "   pod #{item}"
            end
            temp_file.puts "end"
            temp_file.puts "\n"
            temp_file.puts POD_CONFIG
            temp_file.close
            FileUtils.mv(temp_file.path, @@PODFILE_PATH)
        ensure
            temp_file.close
            temp_file.unlink
        end
    end
    
    # 初始配置podfile
    def SHModifyPodile.modifyWorkSpacePodfile(params)
        # 开始改写podfile
        temp_file = Tempfile.new('podfile')
        puts '开始改写podfile'
        puts params
        puts temp_file
        begin
            params.each do |item|
                line = "source '#{item}'"
                temp_file.puts line
            end 
            podfile = File.open(@@PODFILE_PATH, "r")
            podfile.each do |line|
                break if line.to_s.start_with?("post_install")
                next if line.to_s.start_with?("source")
                if line.to_s.start_with?("platform :ios,")
                    temp_file.puts @@DEVELOPMENT_TARGET
                else 
                    temp_file.puts line
                end    
            end
            temp_file.puts POD_CONFIG
            temp_file.close
            FileUtils.mv(temp_file.path, @@PODFILE_PATH)
        ensure
            temp_file.close
            temp_file.unlink
        end
    end
end
