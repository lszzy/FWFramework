Pod::Spec.new do |s|
  s.name             = 'Test'
  s.version          = '1.0.0'
  s.summary          = 'A short description of Test.'
  s.description      = 'A description of Test.'
  s.homepage         = 'https://github.com/lingshizhuangzi@gmail.com/Test'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lingshizhuangzi@gmail.com' => 'lingshizhuangzi@gmail.com' }
  s.source           = { :git => 'https://github.com/lingshizhuangzi@gmail.com/Test.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.swift_version         = '5.0'
  s.source_files = 'Test/Classes/**/*'
  s.public_header_files = [
    'Test/Classes/Public/**/*.h',
    'Test/Classes/Private/TestViewController.h'
  ]
  s.resource_bundles = {
    'Test' => ['Test/Assets/**/*.*']
  }
  s.dependency 'Mediator'
  s.dependency 'Core'
  s.dependency 'FWFramework/FWFramework'
end
