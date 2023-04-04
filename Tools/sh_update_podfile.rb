#!/usr/bin/ruby
#Created by wangyongxin on 2022/03/01

require 'tempfile'
require 'fileutils'
require './sh_modify_podfile.rb'
require './sh_config_Vari.rb'

def configPodBinSwitch(a)
    # 开始改写podfile
    projectName = a.first
    $PODSPEC_PATH = "../#{projectName}.podSpec"
    temp_file = Tempfile.new("#{projectName}.podSpec")
    begin   
        podfile = File.open($PODSPEC_PATH, "r")
        is_contain_bin=false
        is_contain_skip=false
        podfile.each do |line|
            if line.include?("SH_pod_bin")
                is_contain_bin = true
                temp_file.puts line
            elsif line.include?("POD_SKIP_CHECK")
                is_contain_skip = true
                temp_file.puts line
            elsif line.to_s.start_with?("Pod::Spec.new")
                item = ''
                if !is_contain_bin
                    item = item + "#组件是否参与二进制开关 \n#SH_pod_bin = false \n"    
                elsif !is_contain_skip
                    item = item + "#组件是否跳过校验 \n#POD_SKIP_CHECK = false \n"    
                end    
                item = item + "#{line}"
                temp_file.puts item
            elsif line.to_s.include?(".ios.deployment_target") || line.to_s.include?(".deployment_target")
                item = "  s.ios.deployment_target = '#{$POD_DEVELOPMENT_TARGET}'"
                temp_file.puts item
            else
                temp_file.puts line
            end    
        end
        FileUtils.mv(temp_file.path, $PODSPEC_PATH)
    ensure
        temp_file.close
        temp_file.unlink
    end
end
configPodBinSwitch(ARGV)
params = ARGV.drop(1)
SHModifyPodile.modifyWorkSpacePodfile(params)