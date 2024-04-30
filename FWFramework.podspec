Pod::Spec.new do |s|
  s.name                  = 'FWFramework'
  s.version               = '5.4.0'
  s.summary               = 'ios develop framework'
  s.homepage              = 'http://wuyong.site'
  s.license               = 'MIT'
  s.author                = { 'Wu Yong' => 'admin@wuyong.site' }
  s.source                = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => s.version }

  s.ios.deployment_target = '13.0'
  s.swift_version         = '5.9'
  s.frameworks            = 'Foundation', 'UIKit'
  s.default_subspecs      = ['FWFramework']
  
  s.subspec 'FWFramework' do |ss|
    ss.subspec 'Kernel' do |sss|
      sss.source_files = 'Sources/FWFramework/Kernel/**/*.swift'
      sss.resource_bundles = {'FWFramework' => ['Sources/PrivacyInfo.xcprivacy']}
      sss.pod_target_xcconfig = {
          'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited)'
        }
    end
    
    ss.subspec 'Toolkit' do |sss|
      sss.source_files = 'Sources/FWFramework/Toolkit/**/*.swift'
      sss.dependency 'FWFramework/FWFramework/Kernel'
    end
    
    ss.subspec 'Service' do |sss|
      sss.source_files = 'Sources/FWFramework/Service/**/*.swift'
      sss.dependency 'FWFramework/FWFramework/Kernel'
    end
    
    ss.subspec 'Plugin' do |sss|
      sss.source_files = 'Sources/FWFramework/Plugin/**/*.swift'
      sss.dependency 'FWFramework/FWFramework/Kernel'
    end
    
    ss.subspec 'Module' do |sss|
      sss.source_files = 'Sources/FWFramework/Module/**/*.swift'
      sss.dependency 'FWFramework/FWFramework/Kernel'
    end
  end
  
  s.subspec 'FWSwiftUI' do |ss|
    ss.subspec 'Toolkit' do |sss|
      sss.weak_frameworks = 'SwiftUI', 'Combine'
      sss.source_files = 'Sources/FWSwiftUI/Toolkit/**/*.swift'
      sss.dependency 'FWFramework/FWFramework'
    end
    
    ss.subspec 'Plugin' do |sss|
      sss.weak_frameworks = 'SwiftUI', 'Combine'
      sss.source_files = 'Sources/FWSwiftUI/Plugin/**/*.swift'
      sss.dependency 'FWFramework/FWFramework'
    end
    
    ss.subspec 'Module' do |sss|
      sss.weak_frameworks = 'SwiftUI', 'Combine'
      sss.source_files = 'Sources/FWSwiftUI/Module/**/*.swift'
      sss.dependency 'FWFramework/FWFramework'
    end
  end
  
  s.subspec 'FWComponent' do |ss|
    ss.subspec 'Contacts' do |sss|
      sss.source_files = 'Sources/FWComponent/Contacts/**/*.swift'
      sss.dependency 'FWFramework/FWFramework'
    end

    ss.subspec 'Microphone' do |sss|
      sss.source_files = 'Sources/FWComponent/Microphone/**/*.swift'
      sss.dependency 'FWFramework/FWFramework'
    end

    ss.subspec 'Calendar' do |sss|
      sss.source_files = 'Sources/FWComponent/Calendar/**/*.swift'
      sss.dependency 'FWFramework/FWFramework'
    end

    ss.subspec 'Tracking' do |sss|
      sss.source_files = 'Sources/FWComponent/Tracking/**/*.swift'
      sss.dependency 'FWFramework/FWFramework'
    end
    
    ss.subspec 'Macros' do |sss|
      sss.source_files = 'Sources/FWComponent/Macros/FWComponentMacros/**/*.swift'
      sss.dependency 'FWFramework/FWFramework'
      sss.preserve_paths = [
        'Sources/FWComponent/Macros/Package.swift',
        'Sources/FWComponent/Macros/FWMacroMacros/**/*.swift'
      ]
      
      product_folder = "${PODS_BUILD_DIR}/Products/FWMacroMacros"
      build_script = <<-SCRIPT.squish
        env -i PATH="$PATH" "$SHELL" -l -c
        "swift build -c release --disable-sandbox
        --package-path \\"$PODS_TARGET_SRCROOT/Sources/FWComponent/Macros\\"
        --scratch-path \\"#{product_folder}\\""
      SCRIPT
      swift_flags = <<-FLAGS.squish
        -Xfrontend -load-plugin-executable
        -Xfrontend #{product_folder}/release/FWMacroMacros#FWMacroMacros
      FLAGS
      
      sss.script_phase = {
        :name => 'Build FWMacroMacros',
        :script => build_script,
        :input_files => Dir.glob("{Sources/FWComponent/Macros/Package.swift, Sources/FWComponent/Macros/FWMacroMacros/**/*.swift}").map {
          |path| "$(PODS_TARGET_SRCROOT)/#{path}"
        },
        :output_files => ["#{product_folder}/release/FWMacroMacros"],
        :execution_position => :before_compile
      }
      sss.user_target_xcconfig = {
        'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
        'OTHER_SWIFT_FLAGS' => swift_flags
      }
      sss.pod_target_xcconfig = {
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'FWComponentMacros',
        'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
        'OTHER_SWIFT_FLAGS' => swift_flags
      }
    end
    
    ss.subspec 'SDWebImage' do |sss|
      sss.source_files = 'Sources/FWComponent/SDWebImage/**/*.swift'
      sss.dependency 'SDWebImage'
      sss.dependency 'FWFramework/FWFramework'
    end
    
    ss.subspec 'Alamofire' do |sss|
      sss.source_files = 'Sources/FWComponent/Alamofire/**/*.swift'
      sss.dependency 'Alamofire'
      sss.dependency 'FWFramework/FWFramework'
    end
      
    ss.subspec 'Lottie' do |sss|
      sss.source_files = 'Sources/FWComponent/Lottie/**/*.swift'
      sss.dependency 'lottie-ios'
      sss.dependency 'FWFramework/FWFramework'
    end
  end
end
