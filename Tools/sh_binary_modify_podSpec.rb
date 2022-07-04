#!/usr/bin/ruby
#Created by wangyongxin on 2022/02/28

require 'tempfile'
require 'fileutils'

class SHBinModifyPodSpec
    #工程名
    @@project_name = ""
    #二进制包链接
    @@binary_source = ""
    #判断是否包含subSpec
    @@is_include_subspec = false
    #xxconfig配置内容
    @@exist_pod_target_xcconfig = ""
    @@exist_user_target_xcconfig = ""
    POD_TARGET_XCCONFIG_SYMBOL = "s.pod_target_xcconfig"
    USER_TARGET_XCCONFIG_SYMBOL = "s.user_target_xcconfig"
    $dependencys = Array.new
    #subSepc 识别标识
    SUBSPEC_SYMBOL = ".subspec" 
    #依赖
    DEPENDENCY_SYMBOL = "dependency" 
    #判断是否包含bundle
    def SHBinModifyPodSpec.judgeBundle(project_name)
        @@bundle_path = "../Build/#{project_name}/#{project_name}.bundle"
        if File.exist?(@@bundle_path) 
            return true
        end 
        return false   
    end
    #判断源Spec文件包含的一些内容
    def SHBinModifyPodSpec.judgeContent(paths)
        podspec = File.open(paths, "r")
        podspec.each do |line|
            if line.include?(SUBSPEC_SYMBOL)
                @@is_include_subspec = true
            elsif line.include?(POD_TARGET_XCCONFIG_SYMBOL) 
                @@exist_pod_target_xcconfig = line.match('[^{\}]+(?=})')     
            elsif line.include?(USER_TARGET_XCCONFIG_SYMBOL) 
                @@exist_user_target_xcconfig = line.match('[^{\}]+(?=})')  
            elsif line.include?(DEPENDENCY_SYMBOL)
                keyIndex = line.index(DEPENDENCY_SYMBOL)
                keyIndex += DEPENDENCY_SYMBOL.length
                subStr = line[keyIndex, line.length]
                puts "当前的依赖库---:#{subStr}"
                $dependencys.push(subStr)          
            end    
        end
    end   

    def SHBinModifyPodSpec.modifyAction(params)
        puts "开始修改 podspec #{params}"
        @@project_name = params.first
        @@binary_source = params[1]
        @@is_xcframework = params[2]
        #文件路径
        @@PODSPEC_PATH = "../#{@@project_name}.podspec"
        SHBinModifyPodSpec.judgeContent(@@PODSPEC_PATH)
        #  ss.source           = { :http => 'https://sh-mobile-archive.oss-cn-hangzhou.aliyuncs.com/ios/SHFoundation/0.0.6.1/SHFoundation.framework.zip' }
        pod_source = "  s.source           = { :http => '#{@@binary_source}' }"
        # framework引用
        pod_vendored_frameworks = ".ios.vendored_frameworks = '#{@@project_name}/#{@@project_name}.framework'"
        spec_another_name = "s"
        # 新建二进制subSpec
        bin_subSpec_name = "binSpec"
        subSpec_another_name = "ss"
        default_Spec_symbol = "  s.default_subspec = '#{bin_subSpec_name}'"
        bin_subSpec_Head_symbol = "  #{spec_another_name}.subspec '#{bin_subSpec_name}' do |ss|"
        subSpec_end_symbol = " end"
        bin_subSpec_dependency = "    #{subSpec_another_name}.dependency '#{@@project_name}/#{bin_subSpec_name}'"
        # resources引用
        pod_resources_bundle = ".resources = '#{@@project_name}/#{@@project_name}.bundle'"
        pod_source_prefix_symbol = "s.source"
        pod_source_path_symbol = ":git =>"
        pod_source_file_symbol = "source_files"
        pod_source_bundles_prefix_symbol = "resource_bundle"
        pod_source_bundles_path_symbol = "Assets/"
        pod_source_bundles_end_symbol = "}"
        #fat framework 屏蔽掉 模拟器的 arm64 架构
        pod_excluded_archs = "'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'"
        pod_target_xcconfig = "#{POD_TARGET_XCCONFIG_SYMBOL} = { #{pod_excluded_archs} }"
        user_target_xcconfig = "#{USER_TARGET_XCCONFIG_SYMBOL} = { #{pod_excluded_archs} }"
        if @@project_name.nil? || @@project_name.empty?
            puts "工程名字参数为空"
            return
        end    
        # 开始改写podSepc
        temp_file = Tempfile.new(@@project_name + '.podspec')
        begin
            is_bundles = false
            is_subSepc_begin = false
            podspec = File.open(@@PODSPEC_PATH, "r")
            podspec.each do |line|
                if line.include?(pod_source_prefix_symbol) && line.include?(pod_source_path_symbol)
                    #添加二进制地址依赖
                    is_bundles = false
                    temp_file.puts pod_source 
                    # xxconfig配置写入
                    if @@exist_pod_target_xcconfig.length > 0 
                        pod_target_xcconfig = "  #{POD_TARGET_XCCONFIG_SYMBOL} = { #{pod_excluded_archs}, #{@@exist_pod_target_xcconfig} }"
                        temp_file.puts pod_target_xcconfig + "\n"
                    else    
                        temp_file.puts "  #{POD_TARGET_XCCONFIG_SYMBOL} = { #{pod_excluded_archs} }" + "\n"
                    end

                    if @@exist_user_target_xcconfig.length > 0 
                        user_target_xcconfig = "  #{USER_TARGET_XCCONFIG_SYMBOL} = { #{pod_excluded_archs}, #{@@exist_user_target_xcconfig} }"
                        temp_file.puts user_target_xcconfig + "\n" 
                    else 
                        temp_file.puts "  #{USER_TARGET_XCCONFIG_SYMBOL} = { #{pod_excluded_archs} }" + "\n"     
                    end 
                    #二进制依赖包写入，区分是否含有subSpec
                    if @@is_include_subspec == false 
                        temp_file.puts "  #{spec_another_name}#{pod_vendored_frameworks}" + "\n"
                        if SHBinModifyPodSpec.judgeBundle(@@project_name)
                            temp_file.puts "  #{spec_another_name}#{pod_resources_bundle}" + "\n"
                        end
                    else
                        temp_file.puts default_Spec_symbol + "\n"
                        temp_file.puts bin_subSpec_Head_symbol + "\n"
                        temp_file.puts "    #{subSpec_another_name}#{pod_vendored_frameworks}" + "\n"
                        if SHBinModifyPodSpec.judgeBundle(@@project_name)
                            temp_file.puts "    #{subSpec_another_name}#{pod_resources_bundle}" + "\n"
                        end
                        #添加该组件库中所有的依赖
                        $dependencys.each do |item|
                            temp_file.puts "   #{subSpec_another_name}.dependency #{item}"
                        end
                        temp_file.puts subSpec_end_symbol + "\n"
                    end 
                elsif line.include?(pod_source_file_symbol) 
                    #注释掉源码依赖, 切换二进制依赖
                    is_bundles = false
                    temp_file.puts '#' + line + "\n"
                elsif line.include?(pod_source_bundles_prefix_symbol) || line.include?(pod_source_bundles_path_symbol)
                    temp_file.puts '#' + line 
                    is_bundles = true
                elsif line.include?(pod_source_bundles_end_symbol) && is_bundles
                    #注释掉源码资源依赖
                    is_bundles = false
                    temp_file.puts '#' + line 
                elsif line.include?(POD_TARGET_XCCONFIG_SYMBOL) || line.include?(USER_TARGET_XCCONFIG_SYMBOL)
                    is_bundles = false
                elsif line.include?(SUBSPEC_SYMBOL)
                    is_subSepc_begin = true
                    temp_file.puts line + "\n"
                    temp_file.puts bin_subSpec_dependency 
                elsif line.include?(subSpec_end_symbol)    
                    is_subSepc_begin = false
                    temp_file.puts line 
                else
                    is_bundles = false
                    if is_subSepc_begin == true 
                        #puts "subSpec中的内容#{line}"
                        temp_file.puts '#' + line
                    else
                        temp_file.puts line 
                    end
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
