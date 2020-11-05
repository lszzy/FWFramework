Pod::Spec.new do |spec|
  spec.name                = 'FWFramework'
  spec.version             = '0.7.4'
  spec.summary             = 'ios develop framework'
  spec.homepage            = 'http://wuyong.site'
  spec.license             = 'MIT'
  spec.author              = { 'Wu Yong' => 'admin@wuyong.site' }
  spec.source              = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => spec.version, :submodules => true }

  spec.platform            = :ios, '9.0'
  spec.swift_version       = '5.0'
  spec.requires_arc        = true
  spec.frameworks          = [ 'Foundation', 'UIKit' ]
  spec.library             = [ 'sqlite3' ]
  spec.default_subspecs    = [ 'Framework', 'Application', 'Component' ]

  spec.subspec 'Framework' do |subspec|
    subspec.source_files = 'FWFramework/FWFramework.h', 'FWFramework/Framework/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/FWFramework.h', 'FWFramework/Framework/**/*.h'
  end

  spec.subspec 'Application' do |subspec|
    subspec.source_files = 'FWFramework/Application/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/**/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Component' do |subspec|
    subspec.source_files = 'FWFramework/Component/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Component/**/*.h'
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
