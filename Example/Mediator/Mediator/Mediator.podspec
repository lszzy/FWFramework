Pod::Spec.new do |s|
  s.name             = 'Mediator'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Mediator.'
  s.description      = 'A description of Mediator.'
  s.homepage         = 'https://github.com/lingshizhuangzi@gmail.com/Mediator'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lingshizhuangzi@gmail.com' => 'lingshizhuangzi@gmail.com' }
  s.source           = { :git => 'https://github.com/lingshizhuangzi@gmail.com/Mediator.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.swift_version         = '5.0'
  s.source_files = 'Mediator/Classes/**/*'
  s.public_header_files = 'Mediator/Classes/Public/**/*.h'
  # s.resource_bundles = {
  #   'Mediator' => ['Mediator/Assets/*.png']
  # }
  # s.frameworks = 'UIKit', 'MapKit'
  # s.static_framework = true
  s.dependency 'FWFramework/FWFramework'
end
