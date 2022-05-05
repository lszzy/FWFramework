Pod::Spec.new do |s|
  s.name                  = 'FWFramework'
  s.version               = '3.0.0'
  s.summary               = 'ios develop framework'
  s.homepage              = 'http://wuyong.site'
  s.license               = 'MIT'
  s.author                = { 'Wu Yong' => 'admin@wuyong.site' }
  s.source                = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => s.version }

  s.ios.deployment_target = '11.0'
  s.swift_version         = '5.0'
  s.requires_arc          = true
  s.frameworks            = 'Foundation', 'UIKit'
  s.default_subspecs      = ['FWFramework', 'Compatible']
  
  s.subspec 'FWFramework' do |ss|
    ss.source_files = 'FWFramework/Classes/FWFramework/**/*.{h,m,swift}'
  end

  s.subspec 'Compatible' do |ss|
    ss.source_files = 'FWFramework/Classes/Module/Compatible/**/*.{h,m,swift}'
    ss.dependency 'FWFramework/FWFramework'
  end
  
  s.subspec 'Contacts' do |ss|
    ss.source_files = 'FWFramework/Classes/Module/Contacts/**/*.{h,m,swift}'
    ss.dependency 'FWFramework/FWFramework'
  end

  s.subspec 'Microphone' do |ss|
    ss.source_files = 'FWFramework/Classes/Module/Microphone/**/*.{h,m,swift}'
    ss.dependency 'FWFramework/FWFramework'
  end

  s.subspec 'Calendar' do |ss|
    ss.source_files = 'FWFramework/Classes/Module/Calendar/**/*.{h,m,swift}'
    ss.dependency 'FWFramework/FWFramework'
  end

  s.subspec 'AppleMusic' do |ss|
    ss.source_files = 'FWFramework/Classes/Module/AppleMusic/**/*.{h,m,swift}'
    ss.dependency 'FWFramework/FWFramework'
  end

  s.subspec 'Tracking' do |ss|
    ss.source_files = 'FWFramework/Classes/Module/Tracking/**/*.{h,m,swift}'
    ss.dependency 'FWFramework/FWFramework'
  end
end
