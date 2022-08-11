#!/usr/bin/ruby
#Created by wangyongxin on 2022/08/10

require 'tempfile'
require 'fileutils'
require '../SHPod_local_confi.rb'
# 1、更新发布repo SHPodPush.sh  SHPodLint.sh  podfile

class SHUpdatePodRepo

    def SHUpdatePodRepo.perform()
        SHUpdatePodRepo.updatePodPushSource()
        SHUpdatePodRepo.updatePodLintSource()
        SHUpdatePodRepo.updatePodfileSource()  
    end    

    def SHUpdatePodRepo.updatePodPushSource()
        source_symbol = 'SOURCE_SPECS='
        podPush_path = './SHPodPush.sh'
        temp_file = Tempfile.new('SHPodPush.sh')
        begin
            podPush = File.open(podPush_path, "r")
            podPush.each do |line|
                if line.start_with?(source_symbol)
                    content = line.gsub(/#{source_symbol}/, '').tr("\'\'", "").strip
                    repos = content.split(",")
                    res_repos = SHUpdatePodRepo.splicingSpecifyRepo(repos)
                    sourceLine = "#{source_symbol}'#{res_repos.join(",")}'"
                    puts sourceLine
                    temp_file.puts sourceLine    
                elsif
                    temp_file.puts line    
                end    
            end
            temp_file.close
            FileUtils.mv(temp_file.path, podPush_path)
        ensure
            temp_file.close
            temp_file.unlink
        end
    end    

    def SHUpdatePodRepo.updatePodLintSource() 
        source_symbol = 'SOURCE_SPECS='
        podLint_path = './SHPodLint.sh'
        temp_file = Tempfile.new('SHPodLint.sh')
        begin
            podLint = File.open(podLint_path, "r")
            podLint.each do |line|
                if line.start_with?(source_symbol)
                    content = line.gsub(/#{source_symbol}/, '').tr("\'\'", "").strip
                    repos = content.split(",")
                    res_repos = SHUpdatePodRepo.splicingSpecifyRepo(repos)
                    sourceLine = "#{source_symbol}'#{res_repos.join(",")}'"
                    puts sourceLine
                    temp_file.puts sourceLine    
                elsif
                    temp_file.puts line    
                end    
            end
            temp_file.close
            FileUtils.mv(temp_file.path, podLint_path)
        ensure
            temp_file.close
            temp_file.unlink
        end
    end  

    def SHUpdatePodRepo.splicingSpecifyRepo(lists)
        $pod_abandoned_repos.each do |item|
            if lists.include?(item) 
                lists.delete(item)
            end    
        end
        $pod_specify_repos.each do |item|
            if !lists.include?(item) 
                lists.push(item)
            end    
        end
        puts "结果字符串: #{lists}"
        return lists    
    end    

    def SHUpdatePodRepo.updatePodfileSource() 
        source_symbol = 'source'
        podfile_path = '../Example/Podfile'
        repos = Array.new
        File.open(podfile_path, "r") do |file|
            file.each_line do |line|
                if line.start_with?(source_symbol)
                    content = line.gsub(/#{source_symbol}/, '').tr("\'\'", "").strip
                    repos.push(content)
                end 
            end    
        end 
        repos = SHUpdatePodRepo.splicingSpecifyRepo(repos)
        temp_file = Tempfile.new('Podfile')
        begin
            repos.each do |item|
                line = "source '#{item}'"
                temp_file.puts line
            end 
            podfile = File.open(podfile_path, "r")
            podfile.each do |line|
                if !line.to_s.start_with?("source")
                    temp_file.puts line
                end
            end
            temp_file.close
            FileUtils.mv(temp_file.path, podfile_path)
        ensure
            temp_file.close
            temp_file.unlink
        end
    end  
end    

SHUpdatePodRepo.perform()