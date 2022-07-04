#!/usr/bin/ruby
#Created by wangyongxin on 2022/03/01

require 'tempfile'
require 'fileutils'
require './sh_modify_podfile.rb'

def configPodBinSwitch(a)
    # 开始改写podfile
    projectName = a.first
    $PODSPEC_PATH = "../#{projectName}.podSpec"
    temp_file = Tempfile.new("#{projectName}.podSpec")
    begin   
        podfile = File.open($PODSPEC_PATH, "r")
        is_contain=false
        podfile.each do |line|
            if line.include?("SH_pod_bin")
                is_contain = true
                temp_file.puts line
            elsif line.to_s.start_with?("Pod::Spec.new") && !is_contain
                item = "#组件是否参与二进制开关 \n#SH_pod_bin = false \n#{line}"
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