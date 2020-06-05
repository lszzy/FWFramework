Pod::Spec.new do |spec|
  spec.name                = 'FWFramework'
  spec.version             = '0.5.8'
  spec.summary             = 'ios develop framework'
  spec.homepage            = 'http://wuyong.site'
  spec.license             = 'MIT'
  spec.author              = { 'Wu Yong' => 'admin@wuyong.site' }
  spec.source              = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => spec.version, :submodules => true }

  spec.platform            = :ios, '9.0'
  spec.swift_version       = '5.0'
  spec_mrr_files           = [
    'FWFramework/Framework/Kernel/FWCoroutine.m',
    'FWFramework/Framework/Kernel/FWTuple.m',
  ]
  spec_arc_files           = Pathname.glob("FWFramework/**/*.{h,m,swift}")
  spec_arc_files           = spec_arc_files.map {|file| file.to_path}
  spec_arc_files           = spec_arc_files.reject {|file| spec_mrr_files.include?(file)}
  spec.requires_arc        = spec_arc_files
  spec.frameworks          = [ 'Foundation', 'UIKit' ]
  spec.library             = [ 'sqlite3' ]
  spec.default_subspecs    = [ 'Framework', 'Application' ]

  spec.subspec 'Framework' do |subspec|
    subspec.source_files = 'FWFramework/FWFramework.h', 'FWFramework/Framework/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/FWFramework.h', 'FWFramework/Framework/**/*.h'
  end

  spec.subspec 'Application' do |subspec|
    subspec.source_files = 'FWFramework/Application/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/Application/**/*.h'
    subspec.dependency 'FWFramework/Framework'
  end

  spec.subspec 'Image-Webp' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.dependency 'libwebp'
    subspec.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/libwebp/src' }
  end

  spec.subspec 'Authorize-Contacts' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWAuthorizeContactsEnabled=1' }
  end

  spec.subspec 'Authorize-Microphone' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWAuthorizeMicrophoneEnabled=1' }
  end

  spec.subspec 'Authorize-Calendar' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWAuthorizeCalendarEnabled=1' }
  end

  spec.subspec 'Authorize-AppleMusic' do |subspec|
    subspec.dependency 'FWFramework/Framework'
    subspec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'FWAuthorizeAppleMusicEnabled=1' }
  end
end
