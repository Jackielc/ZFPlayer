#!/usr/bin/ruby
require 'xcodeproj'

projectPath = ARGV[0]
puts projectPath

shell_script_content = %q[echo "copy scripts to ./git/hooks"
# gitHook同步
source_dir="${SRCROOT}/Tools/gitHooks"
if [ ! -d "$source_dir" ]; then 
    source_dir="$(dirname ${SRCROOT})/Tools/gitHooks"
    
    if [ ! -d "$source_dir" ]; then 
       source_dir=""
    fi
fi
echo "source_dir: ${source_dir}"

target_dir="${SRCROOT}/.git/hooks"
if [ ! -d "$target_dir" ]; then 
    target_dir="$(dirname ${SRCROOT})/.git/hooks"
    
    if [ ! -d "$target_dir" ]; then 
        target_dir=""
    fi
fi
echo "target_dir: ${target_dir}"

if [ -n "$source_dir" ]  && [ -n "${target_dir}" ]; then 
    cp "${source_dir}/commit-msg" "${target_dir}/commit-msg"
    cp "${source_dir}/shTools.py" "${target_dir}/shTools.py"  
else
    echo "未能定位目录"
fi 
]  

project = Xcodeproj::Project.open(projectPath)
puts project.targets
mainTarget = project.targets.first
buildPhases = mainTarget.build_phases
puts buildPhases
isHave = false
buildPhases.each do |item|
    if item.isa == 'PBXShellScriptBuildPhase' && item.name == 'gitHooksShell' 
        puts item.shell_script
        item.shell_script = shell_script_content
        isHave = true
    end    
end    

if !isHave 
    gitShell = mainTarget.new_shell_script_build_phase('gitHooksShell')
    gitShell.shell_script = shell_script_content
end  
puts isHave  
project.save