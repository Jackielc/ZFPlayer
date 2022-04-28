#!/usr/bin/ruby
#Created by wangyongxin on 2022/03/15

require 'xcodeproj'

class ModifyTarget
    def ModifyTarget.changeRunScriptInstallBuildOnly(target)
        buildPhases = target.build_phases
        buildPhases.each do |item|
            if item.isa == 'PBXShellScriptBuildPhase' && item.name == '[CP] Copy Pods Resources' 
                item.run_only_for_deployment_postprocessing = '1'
            end    
        end 
    end    

    def ModifyTarget.changeBuildPhaseOfPodInstall(project_name)
        @@project_name = project_name
        project = Xcodeproj::Project.open("#{@@project_name}.xcodeproj")
        puts '当前工程的targets: '
        puts project.targets
        project.targets.each do |target|
            if target.name == @@project_name
                ModifyTarget.changeRunScriptInstallBuildOnly(target)
            end    
        end
        project.save    
    end       
end   
ModifyTarget.changeBuildPhaseOfPodInstall(ARGV.first)
