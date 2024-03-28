Pod::Spec.new do |s|
  s.name                  = 'FWFramework'
  s.version               = '5.2.0'
  s.summary               = 'ios develop framework'
  s.homepage              = 'http://wuyong.site'
  s.license               = 'MIT'
  s.author                = { 'Wu Yong' => 'admin@wuyong.site' }
  s.source                = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => s.version }

  s.ios.deployment_target = '13.0'
  s.swift_version         = '5.9'
  s.requires_arc          = true
  s.frameworks            = 'Foundation', 'UIKit'
  s.default_subspecs      = ['FWFramework']
  
  s.subspec 'FWObjC' do |ss|
    ss.source_files = 'Sources/FWObjC/**/*.{h,m}'
  end
  
  s.subspec 'FWFramework' do |ss|
    ss.source_files = 'Sources/FWFramework/**/*.swift'
    ss.dependency 'FWFramework/FWObjC'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited)'
    }
  end
  
  s.subspec 'FWSwiftUI' do |ss|
    ss.weak_frameworks = 'SwiftUI', 'Combine'
    ss.source_files = 'Sources/FWSwiftUI/**/*.swift'
    ss.dependency 'FWFramework/FWFramework'
  end
  
  s.subspec 'FWMacro' do |ss|
    ss.subspec 'Contacts' do |sss|
      sss.dependency 'FWFramework/FWFramework'
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroContacts'
      }
    end

    ss.subspec 'Microphone' do |sss|
      sss.dependency 'FWFramework/FWFramework'
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroMicrophone'
      }
    end

    ss.subspec 'Calendar' do |sss|
      sss.dependency 'FWFramework/FWFramework'
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroCalendar'
      }
    end

    ss.subspec 'Tracking' do |sss|
      sss.dependency 'FWFramework/FWFramework'
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWMacroTracking'
      }
    end
    
    ss.subspec 'Macros' do |sss|
      sss.source_files = 'Sources/FWMacro/**/*.swift'
      sss.preserve_paths = [
        'Package.FWMacro.swift',
        'Sources/FWMacroMacros/**/*.swift'
      ]
      
      product_folder = "${PODS_BUILD_DIR}/Products/FWMacroMacros"
      
      script = <<-SCRIPT.squish
        env -i PATH="$PATH" "$SHELL" -l -c
        "swift build -c release --target FWMacro --disable-sandbox
        --package-path \\"$PODS_TARGET_SRCROOT\\"
        --scratch-path \\"#{product_folder}\\""
      SCRIPT
      
      sss.script_phase = {
        :name => 'Build FWFramework macro plugin',
        :script => script,
        :input_files => Dir.glob("{Package.swift, Sources/FWMacroMacros/**/*}").map {
          |path| "$(PODS_TARGET_SRCROOT)/#{path}"
        },
        :output_files => ["#{product_folder}/release/FWMacroMacros"],
        :execution_position => :before_compile
      }
      
      xcode_config = {
        'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
        'OTHER_SWIFT_FLAGS' => <<-FLAGS.squish
        -Xfrontend -load-plugin-executable
        -Xfrontend #{product_folder}/release/FWMacroMacros#FWMacroMacros
        FLAGS
      }
      sss.user_target_xcconfig = xcode_config
      sss.pod_target_xcconfig = xcode_config
    end
  end
  
  s.subspec 'FWVendor' do |ss|
    ss.subspec 'SDWebImage' do |sss|
      sss.source_files = 'Sources/FWVendor/SDWebImage/**/*.swift'
      sss.dependency 'SDWebImage'
      sss.dependency 'FWFramework/FWFramework'
    end
    
    ss.subspec 'Alamofire' do |sss|
      sss.source_files = 'Sources/FWVendor/Alamofire/**/*.swift'
      sss.dependency 'Alamofire'
      sss.dependency 'FWFramework/FWFramework'
    end
      
    ss.subspec 'Lottie' do |sss|
      sss.source_files = 'Sources/FWVendor/Lottie/**/*.swift'
      sss.dependency 'lottie-ios'
      sss.dependency 'FWFramework/FWFramework'
    end
  end
end
