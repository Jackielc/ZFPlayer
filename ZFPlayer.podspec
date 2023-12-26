#
# Be sure to run `pod lib lint ZFPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

#组件是否参与二进制开关 
#SH_pod_bin = false 
#组件是否跳过校验 
#POD_SKIP_CHECK = false 
Pod::Spec.new do |s|
  s.name             = 'ZFPlayer'
  s.version          = '12.0.9'
  s.summary          = 'A short description of ZFPlayer.'
 s.swift_version = '5.0'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://code.shihuo.cn/shihuoios/thirdparty/zfplayer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wangyongxin0408' => 'wangyongxin0408@shihuo.cn' }
  s.source           = { :git => 'git@code.shihuo.cn:shihuoios/thirdparty/zfplayer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.ios.deployment_target = '11.0'
  s.static_framework = true
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  s.subspec 'Core' do |core|
      core.source_files = 'ZFPlayer/Classes/Core/**/*'
      core.public_header_files = 'ZFPlayer/Classes/Core/**/*.h'
      core.frameworks = 'UIKit', 'MediaPlayer', 'AVFoundation'
      core.dependency 'SHFoundation'
  end

  s.subspec 'ControlView' do |controlView|
      controlView.source_files = 'ZFPlayer/Classes/ControlView/**/*.{h,m}'
      controlView.public_header_files = 'ZFPlayer/Classes/ControlView/**/*.h'
      controlView.resource = 'ZFPlayer/Classes/ControlView/ZFPlayer.bundle'
      controlView.dependency 'ZFPlayer/Core'
  end

  s.subspec 'AVPlayer' do |avPlayer|
      avPlayer.source_files = 'ZFPlayer/Classes/AVPlayer/**/*.{h,m}'
      avPlayer.public_header_files = 'ZFPlayer/Classes/AVPlayer/**/*.h'
      avPlayer.dependency 'ZFPlayer/Core'
  end
end
