#!/usr/bin/ruby
#Created by wangyongxin on 2022/02/28

require 'tempfile'
require 'fileutils'

class SHBinModifyPodSpec

    @@project_name=""
    #二进制包链接
    @@binary_source=""
    #判断是否包含bundle
    def SHBinModifyPodSpec.judgeBundle(project_name)
        @@bundle_path = "../Build/#{project_name}/#{project_name}.bundle"
        if File.exist?(@@bundle_path) 
            return true
        end 
        return false   
    end    

    def SHBinModifyPodSpec.modifyAction(params)
        puts "开始修改 podspec #{params}"
        @@project_name = params.first
        @@binary_source = params[1]
        @@is_xcframework = params[2]
        #文件路径
        @@PODSPEC_PATH = "../#{@@project_name}.podspec"
        #  ss.source           = { :http => 'https://sh-mobile-archive.oss-cn-hangzhou.aliyuncs.com/ios/SHFoundation/0.0.6.1/SHFoundation.framework.zip' }
        pod_source = "s.source           = { :http => '#{@@binary_source}' }"
        # framework引用
        pod_vendored_frameworks = "  s.ios.vendored_frameworks = '#{@@project_name}/#{@@project_name}.framework'"
        # resources引用
        pod_resources_bundle = "  s.resources = '#{@@project_name}/#{@@project_name}.bundle'"
        pod_source_key1 = "s.source"
        pod_source_key2 = ":git =>"
        pod_source_file = "source_files"
        pod_source_bundles_key1 = "resource_bundle"
        pod_source_bundles_key2 = "Assets/"
        pod_source_bundles_key3 = "}"
        #fat framework 屏蔽掉 模拟器的 arm64 架构
        pod_excluded_archs = "'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'"
        pod_target_xcconfig_symbol = "s.pod_target_xcconfig"
        user_target_xcconfig_symbol = "s.user_target_xcconfig"
        pod_target_xcconfig = "#{pod_target_xcconfig_symbol} = { #{pod_excluded_archs} }"
        user_target_xcconfig = "#{user_target_xcconfig_symbol} = { #{pod_excluded_archs} }"
        exist_pod_target_xcconfig = ""
        exist_user_target_xcconfig = ""
        # 识别依赖开始，在之前写入 pod_target_xcconfig
        dependency_symbol = "dependency" 
        if @@project_name.nil? || @@project_name.empty?
            puts "工程名字参数为空"
            return
        end    
        # 开始改写podSepc
        temp_file = Tempfile.new(@@project_name + '.podspec')
        begin
            is_bundles = false
            is_first_dependency = true
            podspec = File.open(@@PODSPEC_PATH, "r")
            podspec.each do |line|
                if line.include?(pod_source_key1) && line.include?(pod_source_key2)
                    #添加二进制地址依赖
                    is_bundles = false
                    temp_file.puts pod_source       
                elsif line.include?(pod_source_file) 
                    #注释掉源码依赖, 切换二进制依赖
                    is_bundles = false
                    if SHBinModifyPodSpec.judgeBundle(@@project_name)
                        temp_file.puts '#' + line + "\n" + pod_vendored_frameworks + "\n" + pod_resources_bundle + "\n"
                    elsif
                        temp_file.puts '#' + line + "\n" + pod_vendored_frameworks + "\n"
                    end    
                elsif line.include?(pod_source_bundles_key1) || line.include?(pod_source_bundles_key2)
                    temp_file.puts '#' + line 
                    is_bundles = true
                elsif line.include?(pod_source_bundles_key3) && is_bundles
                    #注释掉源码资源依赖
                    is_bundles = false
                    temp_file.puts '#' + line 
                elsif line.include?(pod_target_xcconfig_symbol) 
                    is_bundles = false
                    exist_pod_target_xcconfig = line.match('[^{\}]+(?=})')
                elsif line.include?(user_target_xcconfig_symbol) 
                    is_bundles = false
                    exist_user_target_xcconfig = line.match('[^{\}]+(?=})')
                elsif line.include?(dependency_symbol) && is_first_dependency
                    is_bundles = false
                    if exist_pod_target_xcconfig.length > 0 
                        pod_target_xcconfig = "  #{pod_target_xcconfig_symbol} = { #{pod_excluded_archs}, #{exist_pod_target_xcconfig} }"
                    end    
                    if exist_user_target_xcconfig.length > 0 
                        user_target_xcconfig = "  #{user_target_xcconfig_symbol} = { #{pod_excluded_archs}, #{exist_user_target_xcconfig} }"
                    end 
                    temp_file.puts pod_target_xcconfig + "\n" + user_target_xcconfig + "\n" + line 
                    is_first_dependency = false
                else
                    is_bundles = false
                    temp_file.puts line 
                end    
            end
            temp_file.close
            FileUtils.mv(temp_file.path, @@PODSPEC_PATH)
        ensure
            temp_file.close
            temp_file.unlink
        end
    end    
end    

SHBinModifyPodSpec.modifyAction(ARGV)
