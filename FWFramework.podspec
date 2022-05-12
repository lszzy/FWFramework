Pod::Spec.new do |s|
  s.name                  = 'FWFramework'
  s.version               = '3.1.0'
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
    ss.source_files = 'FWFramework/Classes/FWFramework/**/*.{h,m}'
  end

  s.subspec 'Compatible' do |ss|
    ss.source_files = 'FWFramework/Classes/Compatible/**/*.swift'
    ss.dependency 'FWFramework/FWFramework'
  end
  
  s.subspec 'Contacts' do |ss|
    ss.dependency 'FWFramework/Compatible'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroContacts'
    }
  end

  s.subspec 'Microphone' do |ss|
    ss.dependency 'FWFramework/Compatible'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroMicrophone'
    }
  end

  s.subspec 'Calendar' do |ss|
    ss.dependency 'FWFramework/Compatible'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroCalendar'
    }
  end

  s.subspec 'AppleMusic' do |ss|
    ss.dependency 'FWFramework/Compatible'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroAppleMusic'
    }
  end

  s.subspec 'Tracking' do |ss|
    ss.dependency 'FWFramework/Compatible'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroTracking',
      'GCC_PREPROCESSOR_DEFINITIONS' => 'FWMacroTracking=1'
    }
  end
end
