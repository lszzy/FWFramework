Pod::Spec.new do |spec|
  spec.name                = "FWFramework"
  spec.version             = "1.0.0"
  spec.summary             = "ios develop framework"
  spec.homepage            = "http://wuyong.site"
  spec.license             = "MIT"
  spec.author              = { "Wu Yong" => "admin@wuyong.site" }
  spec.source              = { :git => "https://github.com/lszzy/FWFramework.git", :tag => "#{spec.version}" }

  spec.platform            = :ios, "8.0"
  spec.requires_arc        = true
  spec.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
  spec.frameworks          = [ "Foundation", "UIKit" ]
  spec.library             = [ "sqlite3" ]
  spec.default_subspecs    = 'FWFramework', "FWApplication"

  spec.subspec 'FWFramework' do |subspec|
    subspec.source_files = 'FWFramework/FWFramework/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/FWFramework/**/*.h'
  end

  spec.subspec 'FWApplication' do |subspec|
    subspec.source_files = 'FWFramework/FWApplication/**/*.{h,m,swift}'
    subspec.public_header_files = 'FWFramework/FWApplication/**/*.h'

    subspec.dependency 'FWFramework/FWFramework'
  end
end
