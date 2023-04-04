#!/usr/bin/ruby
#Created by wangyongxin on 2022/06/13

require 'find'
require '../Tools/Tool_funtions.rb'

module SHPod
    class ParseLocalRepo
        attr_reader :repo_files, :product_path, :repo_name, :repo_path_key, :repo_type_key, :product_cache_file

        def self.perform(product_path, repo_name)
            new(product_path, repo_name).perform
        end

        def initialize(product_path, repo_name)
            @product_path = product_path
            # "shihuo-shmodulizespecs"
            @repo_name = repo_name
            @repo_path_key = "- Path: "
            @repo_URL_key = "- URL: "
            @product_cache_file = "repo_list_files.txt"
            @repo_files = "#{@product_path}/#{@product_cache_file}"
        end

        def perform 
            savePodRepoSpec
            return parse
        end

        def savePodRepoSpec
            po = %x(pod repo list)
            aFile = File.new("#{@repo_files}", "w+")
            aFile.puts po
            aFile.close
        end 

        def parse
            local_path = File.expand_path(obtainBinRepoLocalPath)
            path_content = generateBinRepoPodVerison(local_path)
            return [path_content, local_path]
        end
        #获取bin repo本地路径
        def obtainBinRepoLocalPath
            File.open("#{@repo_files}", "r") do |file|
                file.each_line do |line|
                    isSHRepo = line.include?(@repo_name) 
                    if isSHRepo == true
                        if line.start_with?(@repo_path_key)
                            local_path = line.delete_prefix(@repo_path_key)
                            return local_path.strip
                        end    
                    end    
                end
            end            
        end
    
        def generateBinRepoPodVerison(path)
            binPods = Hash.new
            Dir.glob(path + "/*") do |item|
                pod_name = File.basename(item)
                if File.directory?(item)
                    version_lists = Array.new
                    Dir.glob(item + "/*") do |file|
                        version = File.basename(file)
                        version_lists.push(version)
                    end
                    version_sort_list = sortPodVersions(version_lists)
                    # puts "组件库：#{pod_name}"
                    # puts "repo源最新版本号：#{version_sort_list.first}"
                    binPods[pod_name] = version_sort_list.first
                end    
            end
            return binPods         
        end 

        # 版本号数组排序 大 -> 小
        def sortPodVersions(list)
            len = list.length
            for i in 0...len-1
              for j in 0...len-i-1
                res = compareVersion(list[j], list[j+1])
                if res === -1        
                  temp = list[j]
                  list[j] = list[j+1]
                  list[j+1] = temp
                end
              end
            end
            return list            
        end

        # 生成非识货的repo集合
        def generateRepoMap()
            File.open("#{@repo_files}", "r") do |file|
                repo_url = ''
                file.each_line do |line|
                    if line.start_with?(@repo_URL_key) 
                        repo_url = line.delete_prefix(@repo_URL_key)
                        repo_url = repo_url.strip
                    end    
                    if line.start_with?(@repo_path_key)
                        local_path = line.delete_prefix(@repo_path_key)
                        local_path = local_path.strip
                    end      
                end
            end
        end 
    end
end    