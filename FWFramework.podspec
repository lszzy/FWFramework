Pod::Spec.new do |s|
  s.name                  = 'FWFramework'
  s.version               = '1.3.7'
  s.summary               = 'ios develop framework'
  s.homepage              = 'http://wuyong.site'
  s.license               = 'MIT'
  s.author                = { 'Wu Yong' => 'admin@wuyong.site' }
  s.source                = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => s.version }

  s.ios.deployment_target = '9.0'
  s.swift_version         = '5.0'
  s.requires_arc          = true
  s.frameworks            = 'Foundation', 'UIKit'
  s.default_subspecs      = 'FWFramework'

  s.subspec 'FWFramework' do |ss|
    ss.dependency 'FWFramework/Framework'
    ss.dependency 'FWFramework/Application'
    ss.dependency 'FWFramework/Component/Foundation'
    ss.dependency 'FWFramework/Component/UIKit'
  end

  s.subspec 'Framework' do |ss|
    ss.source_files = 'FWFramework/FWFramework.h'

    ss.subspec 'Kernel' do |sss|
      sss.source_files = 'FWFramework/Framework/Kernel/*.{h,m,swift}'
    end

    ss.subspec 'Service' do |sss|
      sss.source_files = 'FWFramework/Framework/Service/*.{h,m,swift}'
      sss.dependency 'FWFramework/Framework/Kernel'
    end

    ss.subspec 'Toolkit' do |sss|
      sss.source_files = 'FWFramework/Framework/Toolkit/*.{h,m,swift}'
      sss.dependency 'FWFramework/Framework/Kernel'
    end
  end

  s.subspec 'Application' do |ss|
    ss.dependency 'FWFramework/Framework'

    ss.subspec 'App' do |sss|
      sss.source_files = 'FWFramework/Application/App/**/*.{h,m,swift}'
    end

    ss.subspec 'Controller' do |sss|
      sss.source_files = 'FWFramework/Application/Controller/*.{h,m,swift}'
      sss.dependency 'FWFramework/Application/App'
    end

    ss.subspec 'Model' do |sss|
      sss.source_files = 'FWFramework/Application/Model/*.{h,m,swift}'
    end

    ss.subspec 'View' do |sss|
      sss.source_files = 'FWFramework/Application/View/*.{h,m,swift}'
    end

    ss.subspec 'Cache' do |sss|
      sss.library = 'sqlite3'
      sss.source_files = 'FWFramework/Application/Service/Cache/*.{h,m,swift}'
    end

    ss.subspec 'Database' do |sss|
      sss.library = 'sqlite3'
      sss.source_files = 'FWFramework/Application/Service/Database/*.{h,m,swift}'
    end

    ss.subspec 'Image' do |sss|
      sss.source_files = 'FWFramework/Application/Service/Image/*.{h,m,swift}'
      sss.dependency 'FWFramework/Application/Network'
    end

    ss.subspec 'Network' do |sss|
      sss.source_files = 'FWFramework/Application/Service/Network/*.{h,m,swift}'
    end

    ss.subspec 'Request' do |sss|
      sss.source_files = 'FWFramework/Application/Service/Request/*.{h,m,swift}'
      sss.dependency 'FWFramework/Application/Network'
    end

    ss.subspec 'Socket' do |sss|
      sss.source_files = 'FWFramework/Application/Service/Socket/*.{h,m,swift}'
    end
  end

  s.subspec 'Component' do |ss|
    ss.dependency 'FWFramework/Framework'

    ss.subspec 'Foundation' do |sss|
      sss.source_files = 'FWFramework/Component/Foundation/**/*.{h,m,swift}'
    end

    ss.subspec 'UIKit' do |sss|
      sss.source_files = 'FWFramework/Component/UIKit/**/*.{h,m,swift}'
    end

    ss.subspec 'SwiftUI' do |sss|
      sss.source_files = 'FWFramework/Component/SwiftUI/**/*.{h,m,swift}'
    end

    ss.subspec 'Contacts' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_CONTACTS_ENABLED=1' }
    end

    ss.subspec 'Microphone' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_MICROPHONE_ENABLED=1' }
    end

    ss.subspec 'Calendar' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_CALENDAR_ENABLED=1' }
    end

    ss.subspec 'AppleMusic' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_APPLEMUSIC_ENABLED=1' }
    end

    ss.subspec 'Tracking' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_TRACKING_ENABLED=1' }
    end

    ss.subspec 'SDWebImage' do |sss|
      sss.dependency 'SDWebImage'
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_SDWEBIMAGE_ENABLED=1' }
    end

    ss.subspec 'SQLCipher' do |sss|
      sss.dependency 'SQLCipher'
      sss.dependency 'FWFramework/Application/Database'
      sss.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DSQLITE_HAS_CODEC -DHAVE_USLEEP=1' }
    end
  end
end
