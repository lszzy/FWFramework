# FWFramework

[![Pod Version](https://img.shields.io/cocoapods/v/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod Platform](https://img.shields.io/cocoapods/p/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod License](https://img.shields.io/cocoapods/l/FWFramework.svg?style=flat)](https://github.com/lszzy/FWFramework/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/lszzy/FWFramework)

# [中文](https://github.com/lszzy/FWFramework/blob/master/README_CN.md)

## Tutorial
iOS development framework, convenient for iOS development, compatible with OC and Swift.

All Swizzles in this framework will not take effect by default and will not affect existing projects. They need to be manually opened or invoked to take effect. This library has been used in formal projects, and will continue to be maintained and expanded in the future. Everyone is welcome to use and provide valuable comments to grow together.

## Installation
It is recommended to use CocoaPods or Swift Package Manager to install and automatically manage dependencies. For manual import, please refer to Example project configuration.

### CocoaPods
This framework supports CocoaPods, Podfile example:

	platform :ios, '11.0'
	use_frameworks!

	target 'Example' do
	  # Import the default subspecs, less than version 5.0
	  pod 'FWFramework', '~> 4.0'
	  
	  # Import the specified subspecs, less than version 5.0, see the podspec file for the list of subspecs
	  # pod 'FWFramework', '~> 4.0', :subspecs => ['FWFramework', 'FWSwiftUI']
	end

### Swift Package Manager
This framework supports Swift Package Manager, just add and check the required modules, Package example:

	https://github.com/lszzy/FWFramework.git
	
	# Check and import the default submodule
	import FWFramework
	
	# Check and import the specified sub-modules, see the Package.swift file for the list of sub-modules
	import FWSwiftUI

## [Api](https://fwframework.wuyong.site)
The document is located in the docs folder, just open index.html in the browser, or run docs.sh to automatically generate the Api document.

## [Changelog](https://github.com/lszzy/FWFramework/blob/master/CHANGELOG.md)
As this framework is constantly upgrading, optimizing and expanding new functions, the Api of each version may be slightly changed. If a compilation error is reported when the new version is upgraded, the solution is as follows:

	1. Just change to specify the pod version number to import, the recommended way, does not affect the project progress, upgrade to the new version only when you have time, example: pod 'FWFramework', '4.17.2'
	2. Upgrade to the new version, please pay attention to the version update log. Obsolete Api will be migrated to the Deprecated submodule as appropriate, and will be deleted in subsequent versions

## Vendor
This framework uses a lot of third-party libraries. Thanks to the authors of all third-party libraries. I will not list them all here. For details, please refer to the relevant links of the source file.
 
	In the introduction of third-party libraries, in order to be compatible with existing project pod dependencies, as well as to customize changes and bug fixes of third-party libraries, and to facilitate subsequent maintenance, this framework uniformly modified the FW class prefix and fw method prefix. If there is any inconvenience during use, Please understand.
	If you are the author of a third-party open source library, if this library violates your rights, please let me know, and I will immediately remove the use of the third-party open source library. 

## Support
[wuyong.site](http://www.wuyong.site)
