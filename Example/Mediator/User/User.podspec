Pod::Spec.new do |s|
  s.name             = 'User'
  s.version          = '0.1.0'
  s.summary          = 'A short description of User.'
  s.description      = 'A description of User.'
  s.homepage         = 'https://github.com/lingshizhuangzi@gmail.com/User'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lingshizhuangzi@gmail.com' => 'lingshizhuangzi@gmail.com' }
  s.source           = { :git => 'https://github.com/lingshizhuangzi@gmail.com/User.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.swift_version         = '5.0'
  s.source_files = 'User/Classes/**/*.{h,m,swift}'
  s.public_header_files = 'User/Classes/Public/**/*.h'
  s.resources = [
    'User/Static/UserModule.bundle'
  ]
  s.dependency 'Mediator'
  s.dependency 'Core'
  s.dependency 'FWFramework/FWFramework'
end
