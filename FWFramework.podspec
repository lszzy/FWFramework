Pod::Spec.new do |s|
  s.name                  = 'FWFramework'
  s.version               = '2.0.0'
  s.summary               = 'ios develop framework'
  s.homepage              = 'http://wuyong.site'
  s.license               = 'MIT'
  s.author                = { 'Wu Yong' => 'admin@wuyong.site' }
  s.source                = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => s.version }

  s.ios.deployment_target = '11.0'
  s.swift_version         = '5.0'
  s.requires_arc          = true
  s.frameworks            = 'Foundation', 'UIKit'
  s.default_subspecs      = 'FWFramework'

  s.subspec 'FWFramework' do |ss|
    ss.source_files = 'FWFramework/Classes/FWFramework.h'
    ss.dependency 'FWFramework/Kernel'
    ss.dependency 'FWFramework/Service'
    ss.dependency 'FWFramework/Toolkit'
  end
  
  s.subspec 'Kernel' do |ss|
    ss.source_files = 'FWFramework/Classes/Kernel/**/*.{h,m,swift}'
  end

  s.subspec 'Service' do |ss|
    ss.source_files = 'FWFramework/Classes/Service/**/*.{h,m,swift}'
    ss.dependency 'FWFramework/Kernel'
  end
  
  s.subspec 'Toolkit' do |ss|
    ss.source_files = 'FWFramework/Classes/Toolkit/**/*.{h,m,swift}'
    ss.dependency 'FWFramework/Kernel'
  end
  
  s.subspec 'Contacts' do |ss|
    ss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_CONTACTS_ENABLED=1' }
    ss.dependency 'FWFramework/Service'
  end

  s.subspec 'Microphone' do |ss|
    ss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_MICROPHONE_ENABLED=1' }
    ss.dependency 'FWFramework/Service'
  end

  s.subspec 'Calendar' do |ss|
    ss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_CALENDAR_ENABLED=1' }
    ss.dependency 'FWFramework/Service'
  end

  s.subspec 'AppleMusic' do |ss|
    ss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_APPLEMUSIC_ENABLED=1' }
    ss.dependency 'FWFramework/Service'
  end

  s.subspec 'Tracking' do |ss|
    ss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_TRACKING_ENABLED=1' }
    ss.dependency 'FWFramework/Service'
  end
end
