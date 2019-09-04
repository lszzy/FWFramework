Pod::Spec.new do |spec|
  spec.name                = 'FWFramework'
  spec.version             = '0.3.5'
  spec.summary             = 'ios develop framework'
  spec.homepage            = 'http://wuyong.site'
  spec.license             = 'MIT'
  spec.author              = { 'Wu Yong' => 'admin@wuyong.site' }
  spec.source              = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => spec.version, :submodules => true }

  spec.platform            = :ios, '8.0'
  spec.swift_version       = '5.0'
  spec.requires_arc        = true
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
end
