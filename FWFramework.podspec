Pod::Spec.new do |s|
  s.name                  = 'FWFramework'
  s.version               = '4.0.0'
  s.summary               = 'ios develop framework'
  s.homepage              = 'http://wuyong.site'
  s.license               = 'MIT'
  s.author                = { 'Wu Yong' => 'admin@wuyong.site' }
  s.source                = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => s.version }

  s.ios.deployment_target = '11.0'
  s.swift_version         = '5.0'
  s.requires_arc          = true
  s.frameworks            = 'Foundation', 'UIKit'
  s.default_subspecs      = ['FWObjC', 'FWFramework', 'FWSwiftUI']
  
  s.subspec 'FWObjC' do |ss|
    ss.source_files = 'Sources/FWObjC/**/*.{h,m}'
  end
  
  s.subspec 'FWFramework' do |ss|
    ss.source_files = 'Sources/FWFramework/**/*.swift'
    ss.dependency 'FWFramework/FWObjC'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited)'
    }
  end
  
  s.subspec 'FWSwiftUI' do |ss|
    ss.weak_frameworks = 'SwiftUI', 'Combine'
    ss.source_files = 'Sources/FWSwiftUI/**/*.swift'
    ss.dependency 'FWFramework/FWFramework'
  end
  
  s.subspec 'FWVendor' do |ss|
    ss.subspec 'Contacts' do |sss|
      sss.dependency 'FWFramework/FWFramework'
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroContacts'
      }
    end

    ss.subspec 'Microphone' do |sss|
      sss.dependency 'FWFramework/FWFramework'
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroMicrophone'
      }
    end

    ss.subspec 'Calendar' do |sss|
      sss.dependency 'FWFramework/FWFramework'
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroCalendar'
      }
    end

    ss.subspec 'AppleMusic' do |sss|
      sss.dependency 'FWFramework/FWFramework'
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroAppleMusic'
      }
    end

    ss.subspec 'Tracking' do |sss|
      sss.dependency 'FWFramework/FWFramework'
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroTracking',
        'GCC_PREPROCESSOR_DEFINITIONS' => 'FWMacroTracking=1'
      }
    end
  end
end
