require "rexml/document" 

project_path=ARGV[0]
#project_path = '/Users/shigaoqiangm1/Downloads/SVGAPlayer-iOS-2.5.7/SVGAPlayer.xcodeproj'
if !File.exist?(project_path)
    puts "传入的第一个参数应该为xx.xcodeproj"
    return
end

target_name = File.basename(project_path, ".*")
file_path = "#{project_path}/xcshareddata/xcschemes/#{target_name}.xcscheme"
if !File.exist?(file_path)
    file_path = "#{project_path}/xcshareddata/xcschemes/#{target_name}-Example.xcscheme"

    if !File.exist?(file_path)
        puts "未能找到xcodeproj目录下的xcscheme文件"
        return
    end
end


pre_action_content_path=ARGV[1]
#pre_action_content_path = '/Users/shigaoqiangm1/Downloads/SVGAPlayer-iOS-2.5.7/Scripts/pre_action_content.txt'
if !File.exist?(pre_action_content_path)
    puts "传入的第二个参数为pre_action脚本内容文本地址"
    return
end

post_action_content_path=ARGV[2]
#post_action_content_path = '/Users/shigaoqiangm1/Downloads/SVGAPlayer-iOS-2.5.7/Scripts/post_action_content.txt'
if !File.exist?(post_action_content_path)
    puts "传入的第三个参数为post_action脚本内容文本地址"
    return
end

puts "project_path: #{project_path}"

def add_node_to_xml(file_path, node_name, script_content_path)
    if !File.exist?(file_path)
        puts "xcscheme地址#{file_path}没有发现，无法添加"
        return
     end

     if !File.exist?(script_content_path)
        puts "action脚本内容文件不存在，无法添加"
        return
     end

    # Open the XML file and create an XML document object
    xml_file = File.new(file_path)
    doc = REXML::Document.new(xml_file)
  
    # Check if the node already exists before adding it
    build_action_node = doc.elements.to_a( "//BuildAction" ).first
    if build_action_node == nil 
        puts "未发现BuildAction节点，无法添加"
        return 
    end

    origin_actions = build_action_node.elements.to_a( "//#{node_name}" )
    if origin_actions != nil
        origin_actions.each do |elem|
            elem.parent.delete_element(elem)
            puts "发现旧的节点，先删除"
        end
    end

    origin_buildable_reference_node = doc.elements.to_a("//BuildableReference").first
    if origin_buildable_reference_node == nil
        puts "未找到环境节点，无法添加"
        return 
    end

    puts "开始添加"
  
    # Create the new node
    pre_action_node = REXML::Element.new(node_name)

    execution_action_node = REXML::Element.new('ExecutionAction')
    execution_action_node.add_attribute('ActionType', 'Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction')
    pre_action_node.add_element(execution_action_node)

    action_content_node = REXML::Element.new('ActionContent')
    action_content_node.add_attribute('title', "Run Script")

    script_content = File.read(script_content_path)
    action_content_node.add_attribute('scriptText', script_content)
    execution_action_node.add_element(action_content_node)

    environment_buildable_mode = REXML::Element.new('EnvironmentBuildable')
    action_content_node.add_element(environment_buildable_mode)

    buildable_reference_node = origin_buildable_reference_node.dup
    environment_buildable_mode.add_element(buildable_reference_node)

    build_action_node.add_element(pre_action_node)

    # Save the updated XML file
    File.open(file_path, 'w') do |file|
      file.write(doc.to_s)
    end
    puts "添加#{node_name}节点完成"
end

def bt_xml(file_path)
    if !File.exist?(file_path)
        puts "xcscheme地址没有发现，无法添加"
        return
     end

    # 将XML文件读取为XML对象
    xml_file = File.read(file_path)
    doc = REXML::Document.new(xml_file)

    formatter = REXML::Formatters::Pretty.new(3)
    formatter.compact = true
    File.open(file_path, 'w') do |file|
      formatter.write(doc, file)
    end
end


add_node_to_xml(file_path, "PreActions", pre_action_content_path)
add_node_to_xml(file_path, "PostActions", post_action_content_path)
bt_xml(file_path)

#ruby updateBuildActions.ruby '/Users/shigaoqiangm1/Downloads/SVGAPlayer-iOS-2.5.7/SVGAPlayer.xcodeproj' '/Users/shigaoqiangm1/Downloads/SVGAPlayer-iOS-2.5.7/Scripts/pre_action_content.txt' '/Users/shigaoqiangm1/Downloads/SVGAPlayer-iOS-2.5.7/Scripts/post_action_content.txt'