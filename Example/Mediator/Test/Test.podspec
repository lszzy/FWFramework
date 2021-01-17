Pod::Spec.new do |s|
  s.name             = 'Test'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Test.'
  s.description      = 'A description of Test.'
  s.homepage         = 'https://github.com/lingshizhuangzi@gmail.com/Test'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lingshizhuangzi@gmail.com' => 'lingshizhuangzi@gmail.com' }
  s.source           = { :git => 'https://github.com/lingshizhuangzi@gmail.com/Test.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.swift_version         = '5.0'
  s.source_files = 'Test/Classes/**/*'
  s.public_header_files = 'Test/Classes/Public/**/*.h'
  s.resources = [
    'Test/Static/TestModule.bundle'
  ]
  s.dependency 'Mediator'
  s.dependency 'Core'
  s.dependency 'FWFramework/FWFramework'
end
