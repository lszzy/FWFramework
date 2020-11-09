Pod::Spec.new do |spec|
  spec.name                = 'FWFramework'
  spec.version             = '0.7.7'
  spec.summary             = 'ios develop framework'
  spec.homepage            = 'http://wuyong.site'
  spec.license             = 'MIT'
  spec.author              = { 'Wu Yong' => 'admin@wuyong.site' }
  spec.source              = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => spec.version, :submodules => true }

  spec.platform            = :ios, '9.0'
  spec.swift_version       = '5.0'
  spec.requires_arc        = true
  spec.frameworks          = [ 'Foundation', 'UIKit' ]
  spec.default_subspecs    = [ 'FWFramework' ]

  spec.subspec 'FWFramework' do |subspec|
    subspec.source_files = 'FWFramework/FWFramework.h'
    subspec.public_header_files = 'FWFramework/FWFramework.h'
    subspec.dependency 'FWFramework/Framework'
    subspec.dependency 'FWFramework/Application'
    subspec.dependency 'FWFramework/Component'
  end

  spec.subspec 'Framework' do |subspec|
    subspec.source_files = 'FWFramework/Framework/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Framework/**/*.h'
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

  spec.subspec 'Service' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/**/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Cache' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Cache/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Cache/*.h'
    subspec.dependency 'FWFramework/Database'
  end

  spec.subspec 'Database' do |subspec|
    subspec.library = [ 'sqlite3' ]
    subspec.source_files = 'FWFramework/Application/Service/Database/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Database/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Image' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Image/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Image/*.h'
    subspec.dependency 'FWFramework/Network'
  end

  spec.subspec 'Json' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Json/*.{h,m,swift}'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Network' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Network/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Network/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Request' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Request/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Request/*.h'
    subspec.dependency 'FWFramework/Network'
  end

  spec.subspec 'Socket' do |subspec|
    subspec.source_files = 'FWFramework/Application/Service/Socket/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/Service/Socket/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Foundation' do |subspec|
    subspec.source_files = 'FWFramework/Component/Foundation/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Component/Foundation/**/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'UIKit' do |subspec|
    subspec.source_files = 'FWFramework/Component/UIKit/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Component/UIKit/**/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'SwiftUI' do |subspec|
    subspec.source_files = 'FWFramework/Component/SwiftUI/*.{h,m,swift}'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Contacts' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCONTACTS_ENABLED=1' }
  end

  spec.subspec 'Microphone' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWMICROPHONE_ENABLED=1' }
  end

  spec.subspec 'Calendar' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWCALENDAR_ENABLED=1' }
  end

  spec.subspec 'AppleMusic' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWAPPLEMUSIC_ENABLED=1' }
  end

  spec.subspec 'Tracking' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWTRACKING_ENABLED=1' }
  end

  spec.subspec 'SDWebImage' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.dependency 'SDWebImage'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWSDWEBIMAGE_ENABLED=1' }
  end
end
