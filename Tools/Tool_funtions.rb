#!/usr/bin/ruby
#Created by wangyongxin on 2022/07/21


# 比较版本号大小 -1 小于 ， 0 等于 ， 1大于
def compareVersion(item1, item2)
    arr1 = item1.split(".")
    arr2 = item2.split(".")
    index = arr1.length < arr2.length ? arr1.length : arr2.length
    for i in 0..index
        num1 = arr1[i].to_i
        num2 = arr2[i].to_i
        if num1 > num2 
            return 1
        elsif num1 < num2
            return -1                    
        end     
    end
    return 0    
end 

#ruby删除文件夹
def deleteDirectory(dirPath)
    if File.directory?(dirPath)
      Dir.foreach(dirPath) do |subFile|
        if subFile != '.' and subFile != '..' 
          deleteDirectory(File.join(dirPath, subFile));
        end
      end
      Dir.rmdir(dirPath);
    else
      File.delete(dirPath);
    end
end
