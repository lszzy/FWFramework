Pod::Spec.new do |s|
  s.name             = 'Core'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Core.'
  s.description      = 'A description of Core.'
  s.homepage         = 'https://github.com/lingshizhuangzi@gmail.com/Core'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lingshizhuangzi@gmail.com' => 'lingshizhuangzi@gmail.com' }
  s.source           = { :git => 'https://github.com/lingshizhuangzi@gmail.com/Core.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.swift_version         = '5.0'
  s.source_files = 'Core/Classes/**/*.{h,m,swift}'
  s.public_header_files = 'Core/Classes/Public/**/*.h'
  s.resource_bundles = {
    'Core' => ['Core/Assets/**/*.*']
  }
  s.dependency 'FWFramework/FWFramework'
end
