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
  s.source_files = 'Core/Classes/**/*.{h,m,swift}'
  s.resource_bundles = {
    'Core' => ['Core/Assets/**/*.{xcassets,lproj,png}']
  }
  # s.resources = [
  #   'Core/Static/CoreModule.bundle'
  # ]
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.static_framework = true
  s.dependency 'FWFramework/Framework'
end
