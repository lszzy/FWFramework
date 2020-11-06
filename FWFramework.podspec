Pod::Spec.new do |spec|
  spec.name                = 'FWFramework'
  spec.version             = '0.7.6'
  spec.summary             = 'ios develop framework'
  spec.homepage            = 'http://wuyong.site'
  spec.license             = 'MIT'
  spec.author              = { 'Wu Yong' => 'admin@wuyong.site' }
  spec.source              = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => spec.version, :submodules => true }

  spec.platform            = :ios, '9.0'
  spec.swift_version       = '5.0'
  spec.requires_arc        = true
  spec.frameworks          = [ 'Foundation', 'UIKit' ]
  spec.default_subspecs    = [ 'Framework', 'Application', 'Component' ]

  spec.subspec 'Framework' do |subspec|
    subspec.source_files = [ 'FWFramework/FWFramework.h', 'FWFramework/Framework/**/*.{h,m,swift}' ]
    subspec.public_header_files = [ 'FWFramework/FWFramework.h', 'FWFramework/Framework/**/*.h' ]
  end

  spec.subspec 'Application' do |subspec|
    subspec.library = [ 'sqlite3' ]
    subspec.source_files = 'FWFramework/Application/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/**/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Component' do |subspec|
    subspec.source_files = 'FWFramework/Component/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Component/**/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Component_Cache' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Cache/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Cache/*.h'
    subspec.dependency 'FWFramework/Component_Database'
  end

  spec.subspec 'Component_Database' do |subspec|
    subspec.library = [ 'sqlite3' ]
    subspec.source_files = 'FWFramework/Application/Service/Database/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Database/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Component_Image' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Image/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Image/*.h'
    subspec.dependency 'FWFramework/Component_Network'
  end

  spec.subspec 'Component_Json' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Json/*.{h,m,swift}'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Component_Network' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Network/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Network/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Component_Request' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Request/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Request/*.h'
    subspec.dependency 'FWFramework/Component_Network'
  end

  spec.subspec 'Component_Socket' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Socket/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Socket/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Component_Contacts' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_CONTACTS_ENABLED=1' }
  end

  spec.subspec 'Component_Microphone' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_MICROPHONE_ENABLED=1' }
  end

  spec.subspec 'Component_Calendar' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_CALENDAR_ENABLED=1' }
  end

  spec.subspec 'Component_AppleMusic' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_APPLEMUSIC_ENABLED=1' }
  end

  spec.subspec 'Component_Tracking' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_TRACKING_ENABLED=1' }
  end

  spec.subspec 'Component_SDWebImage' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.dependency 'SDWebImage'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCOMPONENT_SDWEBIMAGE_ENABLED=1' }
  end
end
