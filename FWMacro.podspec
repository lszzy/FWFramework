Pod::Spec.new do |s|
  s.name                  = 'FWMacro'
  s.version               = '5.2.0'
  s.summary               = 'macros of FWFramework'
  s.homepage              = 'http://wuyong.site'
  s.license               = 'MIT'
  s.author                = { 'Wu Yong' => 'admin@wuyong.site' }
  s.source                = { :git => 'https://github.com/lszzy/FWFramework.git', :tag => s.version }

  s.ios.deployment_target = '13.0'
  s.swift_version         = '5.9'
  
  s.source_files = 'Sources/FWMacro/**/*.swift'
  s.preserve_paths = [
    'Package.swift',
    'Sources/FWMacro/**/*.swift',
    'Sources/FWMacroMacros/**/*.swift'
  ]
  
  product_folder = "${PODS_BUILD_DIR}/Products/FWMacroMacros"
  
  script = <<-SCRIPT.squish
    env -i PATH="$PATH" "$SHELL" -l -c
    "swift build -c release --target FWMacro --disable-sandbox
    --package-path \\"$PODS_TARGET_SRCROOT\\"
    --scratch-path \\"#{product_folder}\\""
  SCRIPT
  
  s.script_phase = {
    :name => 'Build FWFramework macro plugin',
    :script => script,
    :input_files => Dir.glob("{Package.swift, Sources/FWMacro/**/*, Sources/FWMacroMacros/**/*}").map {
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
  s.user_target_xcconfig = xcode_config
  s.pod_target_xcconfig = xcode_config
end
