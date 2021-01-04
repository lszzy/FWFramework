# FWFramework

[![Pod Version](https://img.shields.io/cocoapods/v/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod Platform](https://img.shields.io/cocoapods/p/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod License](https://img.shields.io/cocoapods/l/FWFramework.svg?style=flat)](https://github.com/lszzy/FWFramework/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/lszzy/FWFramework)

# [中文](README_CN.md)

iOS development framework, convenient for iOS development, compatible with OC and Swift.

## Installation
It is recommended to use CocoaPods to install and automatically manage dependencies. For manual import, please refer to Example project configuration.

### CocoaPods
This framework supports CocoaPods, Podfile example:

	platform :ios, '9.0'
	use_frameworks!

	target 'Example' do
	  # Import the default subspecs
	  pod 'FWFramework'
	  
	  # Import the specified subspecs, see the podspec file for the list of subspecs
	  # pod 'FWFramework', :subspecs => ['FWFramework', 'Component/SDWebImage']
	end

A brief description of the subspecs:

	Framework: framework layer, core architecture, has nothing to do with the application, the bottom layer depends on
	Application: application layer, AOP solution, no need to inherit, components can be replaced
	Component: component layer, optional import, common functions, convenient for development

### Carthage
This framework supports Carthage, Cartfile example:

	github "lszzy/FWFramework"

Execute `carthage update` and copy `FWFramework.framework` to the project.

## Tutorial
All Swizzles in this framework will not take effect by default and will not affect existing projects. They need to be manually opened or invoked to take effect. This library has been used in formal projects, and will continue to be maintained and expanded in the future. Everyone is welcome to use and provide valuable comments to grow together.

### HeaderDoc 
This framework document is located in the Document folder. [HeaderDoc Document](Document/HeaderDoc) will be automatically generated when compiling. For the list of supported tags, please see [HeaderDoc tags](https://developer.apple.com/legacy/library/documentation/DeveloperTools/Conceptual/HeaderDoc/tags/tags.html).

HeaderDoc.sh can quickly generate framework HeaderDoc documents, using the following commands:

	./HeaderDoc.sh
	
### CodeSnippets
CodeSnippets can quickly write HeaderDoc comments in Xcode, such as `hd_class`, etc. The installation command is as follows:

	./CodeSnippets.sh
	
### Templates
Templates can create new OC classes with HeaderDoc annotations in Xcode. The installation commands are as follows:

	./Templates.sh

## Standard
[Coding Standards Document](STANDARD.md)

## Changelog
As this framework is constantly upgrading, optimizing and expanding new functions, the Api of each version may be slightly changed. If a compilation error is reported when the new version is upgraded, the solution is as follows:

	1. Just change to specify the pod version number to import, the recommended way, does not affect the project progress, upgrade to the new version only when you have time, example: pod'FWFramework', '1.0.0'
	2. Upgrade to the new version, please pay attention to the version update log. Obsolete Api will be migrated to the Component/Deprecated submodule as appropriate, and will be deleted in subsequent versions

Version 1.0.0:

	* After two years of hard work, version 1.0.0 was released

## Vendor
This framework uses a lot of third-party libraries. Thanks to the authors of all third-party libraries. I will not list them all here. For details, please refer to the relevant links of the source file.
 
	In the introduction of third-party libraries, in order to be compatible with existing project pod dependencies, as well as to customize changes and bug fixes of third-party libraries, and to facilitate subsequent maintenance, this framework uniformly modified the FW class prefix and fw method prefix. If there is any inconvenience during use, Please understand.
	If you are the author of a third-party open source library, if this library violates your rights, please let me know, and I will immediately remove the use of the third-party open source library. 

## Support
[wuyong.site](http://www.wuyong.site)
