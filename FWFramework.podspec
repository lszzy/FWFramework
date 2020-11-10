Pod::Spec.new do |s|
  s.name                = 'FWFramework'
  s.version             = '0.7.7'
  s.summary             = 'ios develop framework'
  s.homepage            = 'http://wuyong.site'
  s.license             = 'MIT'
  s.author              = { 'Wu Yong' => 'admin@wuyong.site' }
  s.source              = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => s.version, :submodules => true }

  s.platform            = :ios, '9.0'
  s.swift_version       = '5.0'
  s.requires_arc        = true
  s.frameworks          = 'Foundation', 'UIKit'
  s.default_subspecs    = 'Application', 'Component'

  s.subspec 'Framework' do |ss|
    ss.source_files = 'FWFramework/FWFramework.h'

    ss.subspec 'Kernel' do |sss|
      sss.source_files = 'FWFramework/Framework/Kernel/*.{h,m,swift}'
    end

    ss.subspec 'Module' do |sss|
      sss.source_files = 'FWFramework/Framework/Module/*.{h,m,swift}'
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
      sss.source_files = 'FWFramework/Application/{App,Controller,Model,View}/**/*.{h,m,swift}'
    end

    ss.subspec 'Cache' do |sss|
      sss.source_files = 'FWFramework/Application/Service/Cache/*.{h,m,swift}'
      sss.dependency 'FWFramework/Application/Database'
    end
  
    ss.subspec 'Database' do |sss|
      sss.library = 'sqlite3'
      sss.source_files = 'FWFramework/Application/Service/Database/*.{h,m,swift}'
    end
  
    ss.subspec 'Image' do |sss|
      sss.source_files = 'FWFramework/Application/Service/Image/*.{h,m,swift}'
      sss.dependency 'FWFramework/Application/Network'
    end
  
    ss.subspec 'Json' do |sss|
      sss.source_files = 'FWFramework/Application/Service/Json/*.{h,m,swift}'
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
  end

  s.subspec 'Authorize' do |ss|
    ss.dependency 'FWFramework/Framework'

    ss.subspec 'Contacts' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCONTACTS_ENABLED=1' }
    end
  
    ss.subspec 'Microphone' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWMICROPHONE_ENABLED=1' }
    end
  
    ss.subspec 'Calendar' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCALENDAR_ENABLED=1' }
    end
  
    ss.subspec 'AppleMusic' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWAPPLEMUSIC_ENABLED=1' }
    end
  
    ss.subspec 'Tracking' do |sss|
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWTRACKING_ENABLED=1' }
    end
  end

  s.subspec 'Vendor' do |ss|
    ss.dependency 'FWFramework/Framework'

    ss.subspec 'SDWebImage' do |sss|
      sss.dependency 'SDWebImage'
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWSDWEBIMAGE_ENABLED=1' }
    end
  end
end
