#!/usr/bin/ruby
#Created by wangyongxin on 2023/03/31

require '../Tools/Tool_funtions.rb'
require './sh_parseLocalRepo.rb'
require 'fileutils'

module SHPod
    class RelaseVersionCheck
        attr_reader :release_version, :prase_repo_path, :pod_name, :pod_repo_name, :is_release

        def self.perform(version, podName, repoName, isRelease)
            new(version, podName, repoName, isRelease).run
        end

        def initialize(version, podName, repoName, isRelease)
            @release_version = version
            @prase_repo_path = Dir.pwd
            @pod_repo_name = repoName
            @pod_name = podName
            @is_release = isRelease
        end

        def run 
            return checkRelaseVersionisValite
        end

        def checkRelaseVersionisValite
            result = ParseLocalRepo.perform(@prase_repo_path, @pod_repo_name)
            content = result[0]
            path = result[1]
            if content[@pod_name].nil?
               return "0:本地没有找到该组件库"
            else
                last_version = content[@pod_name]
                res = compareVersion(last_version, @release_version)
                if res === -1 || @is_release != "1"
                    dir_path = "#{path}/#{@pod_name}/#{@release_version}"
                    FileUtils.mkdir_p(dir_path)
                    return "1:获取成功,可以发布:#{dir_path}"  
                else 
                    return "2:发布版本低于已有的版本，失败"          
                end    
            end
        end    
    end    
end    

result = SHPod::RelaseVersionCheck.perform(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
puts result