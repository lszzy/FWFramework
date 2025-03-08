# FWFramework

[![Pod Version](https://img.shields.io/cocoapods/v/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flszzy%2FFWFramework%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/lszzy/FWFramework)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flszzy%2FFWFramework%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/lszzy/FWFramework)
[![Pod License](https://img.shields.io/cocoapods/l/FWFramework.svg?style=flat)](https://github.com/lszzy/FWFramework/blob/master/LICENSE)

# [中文](https://github.com/lszzy/FWFramework/blob/master/README_CN.md)

## Tutorial
iOS development framework, mainly solves the routine and pain points in native development, and builds a modular project structure to facilitate iOS development. 

	* Modular architecture design, with built-in Mediator middleware, Router routing and other components
	* Supports advanced features such as Swift coroutine async, await, property annotation propertyWrapper, macro, etc.
	* Easily customizable UI plug-ins, including pop-up windows, toast, empty interface, pull-down refresh, image selection and other plug-ins
	* Completely replaceable network images and network request layer, compatible with SDWebImage, Alamofire, etc. by default
	* Automatically updated AutoLayout chain layout, commonly used UI view components are all available
	* Extensible Model, View, and Controller architecture encapsulation for quick writing of business codes
	* Compatible with SwiftUI, easily implement UIKit and SwiftUI hybrid interface development
    * Compatible with Swift 6, quickly write more robust, less crash-prone, and thread-safe code   
	* Any replaceable fw. code prefix, commonly used Toolkit methods, Theme, multi-language processing
	* Everything you want is available here

All Swizzles in this framework will not take effect by default and will not affect existing projects. They need to be manually opened or invoked to take effect. This library has been used in formal projects, and will continue to be maintained and expanded in the future. Everyone is welcome to use and provide valuable comments to grow together.

## Installation
It is recommended to use CocoaPods or Swift Package Manager to install and automatically manage dependencies.

### CocoaPods
This framework supports CocoaPods, Podfile example:

	platform :ios, '13.0'
	use_frameworks!

	target 'Example' do
	  # Import the default subspecs
	  pod 'FWFramework'
	  
      # Import the macro subspecs
      # pod 'FWFramework', :subspecs => ['FWFramework', 'FWPlugin/Macros']   
	  # Import the specified subspecs, see the podspec file for the list of subspecs
	  # pod 'FWFramework', :subspecs => ['FWFramework', 'FWSwiftUI']
	end

### Swift Package Manager
This framework supports Swift Package Manager, just add and check the required modules, Package example:

	https://github.com/lszzy/FWFramework.git
	
	# Check and import the default submodule
	import FWFramework
	
    # Check and import the macro submodule
    import FWPluginMacros
	# Check and import the specified sub-modules, see the Package.swift file for the list of sub-modules
	import FWSwiftUI

## [Api](https://fwframework.wuyong.site)
The document is located in the docs folder, just open index.html in the browser, or run docs.sh to automatically generate the Api document.

Custom code prefix is app example:

	public typealias APP = WrapperGlobal
	
	extension WrapperCompatible {
		public static var app: Wrapper<Self>.Type { get { wrapperExtension } set {} }
		public var app: Wrapper<Self> { get { wrapperExtension } set {} }
	}
    
Example of importing default fw code prefix:

	@_spi(FW) import FWFramework

## [Changelog](https://github.com/lszzy/FWFramework/blob/master/CHANGELOG.md)
As this framework is constantly upgrading, optimizing and expanding new functions, the Api of each version may be slightly changed. If a compilation error is reported when the new version is upgraded, the solution is as follows:

	1. Just change to specify the pod version number to import, the recommended way, does not affect the project progress, upgrade to the new version only when you have time, example: pod 'FWFramework', '6.1.0'
	2. Upgrade to the new version, please pay attention to the version update log

### Swift
Starting from version 6.0, it is compatible with Swift 6 and iOS 13+. Version 5.x is only compatible with Swift 5. When migrating, in addition to using the new API to fix compilation errors, you also need to test whether the relevant functions are normal. We apologize for the inconvenience caused to you.

### Objective-C
For OC compatibility, please use version 4.x, compatible with iOS 11+. Subsequent versions of version 4.x will only fix bugs and no new features will be added.

## Vendor
This framework uses a lot of third-party libraries. Thanks to the authors of all third-party libraries. I will not list them all here. For details, please refer to the relevant links of the source file.
 
	In the introduction of third-party libraries, in order to be compatible with existing project pod dependencies, as well as to customize changes and bug fixes of third-party libraries, and to facilitate subsequent maintenance, this framework uniformly modified the class prefix and method prefix. If there is any inconvenience during use, Please understand.
	If you are the author of a third-party open source library, if this library violates your rights, please let me know, and I will immediately remove the use of the third-party open source library. 

## Support
[wuyong.site](http://www.wuyong.site)
