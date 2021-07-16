# FWFramework

[![Pod Version](https://img.shields.io/cocoapods/v/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod Platform](https://img.shields.io/cocoapods/p/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod License](https://img.shields.io/cocoapods/l/FWFramework.svg?style=flat)](https://github.com/lszzy/FWFramework/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/lszzy/FWFramework)

# [中文](README_CN.md)

## Tutorial
iOS development framework, convenient for iOS development, compatible with OC and Swift.

All Swizzles in this framework will not take effect by default and will not affect existing projects. They need to be manually opened or invoked to take effect. This library has been used in formal projects, and will continue to be maintained and expanded in the future. Everyone is welcome to use and provide valuable comments to grow together.

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

## Changelog
As this framework is constantly upgrading, optimizing and expanding new functions, the Api of each version may be slightly changed. If a compilation error is reported when the new version is upgraded, the solution is as follows:

	1. Just change to specify the pod version number to import, the recommended way, does not affect the project progress, upgrade to the new version only when you have time, example: pod'FWFramework', '1.0.0'
	2. Upgrade to the new version, please pay attention to the version update log. Obsolete Api will be migrated to the Component/Deprecated submodule as appropriate, and will be deleted in subsequent versions

Version 1.7.4:

	* Optimize system JSON decoding because of special characters error 3840 problem
	* Optimize the query parameter parsing problem when the URL contains Chinese

Version 1.7.3:

	* FWEmptyPlugin added fwEmptyInsets outer spacing property setting
	* FWToastPlugin added fwToastInsets outer spacing property setting

Version 1.7.2:

	* Optimize FWDynamicLayout caching mechanism, fix iOS15 height calculation bug

Version 1.7.1:

	* Refactored FWTheme theme color processing, compatible with theme switching below iOS13

Version 1.7.0:

	* Refactored FWTheme theme management class, optimized method names, and avoided memory leaks
	* Added FWIcon icon font class, supporting loading by name

Version 1.6.6:

	* Optimize the problem of multiple calls when fwDismissBlock is pulled down, which needs to be triggered manually

Version 1.6.5:

	* FWWebViewJsBridge supports APP and JS double-ended bridge error callback
	* FWPhotoBrowser supports dismiss to the specified location

Version 1.6.4:

	* Fix the nullable declaration of UIKit Component

Version 1.6.3:

	* Rename the FWImageName method to FWImageNamed
	* FWModuleBundle uses the fwImageNamed image loading method

Version 1.6.2:

	* iOS13+ supports SVG image format by default
	* FWImage newly added decoding option configuration, compatible with SDWebImage
	* UITableView added fwPerformUpdates method

Version 1.6.1:

	* Added fade transition animation method
	* Fix the problem that the index of FWSegmentedControl is not normal when it first jumps to it
	* Fix the problem of triggering the refresh plug-in at the same time, and the abnormal progress callback when the content is short

Version 1.6.0:

	* Refactor the project directory structure and use the recommended method of pod
	* Rewrite the FWPromise class to support OC and Swift calls
	* Added FWMulticastDelegate multi-agent forwarding class
	* Refactor FWLog method name
	* Fixed occasional bugs in FWRefreshPlugin and FWWebImage plugins

Version 1.5.6:

	* Fixed the issue of FWAnimatedTransition referencing presentationController circularly
	* FWPhotoBrowserDelegate added callback methods when displaying and hiding

Version 1.5.5:

	* Modify the FWRouterContext attribute name and declaration
	* Added safe conversion method for fwAs commonly used types in Swift
	* Fix the problem that fwTouchEventInterval does not take effect

Version 1.5.4:

	* FWAutoLayout increases the layout method of view aspect ratio
	* FWRouterContext adds mergeParameters method
	* UIApplication adds a new calling system sharing method

Version 1.5.3:

	* UITextField keyboard management supports UIScrollView scrolling
	* Optimize the accuracy of NSDate.fwCurrentTime

Version 1.5.2:

	* Modify FWModuleProtocol.setup as an optional method
	* Fix the nullable declaration of FWAppDelegate method

Version 1.5.1:

	* Optimize the animation effect of the empty interface plug-in, automatically remove the Overlay view

Version 1.5.0:

	* Refactored log plug-in and image plug-in
	* Refactored pop-up plug-in, empty interface plug-in, toast plug-in, refresh plug-in

Version 1.4.3:

	* FWRouter removes the isObjectURL judgment method, compatible with scheme:path format URL
	* FWEmptyPluginConfig adds customBlock configuration

Version 1.4.2:

	* Fix FWRouter routing parameter parsing problem, code optimization

Version 1.4.1:

	* UIScrollView supports fwOverlayView view
	* UIScrollView supports displaying an empty interface and modifying the FWEmptyViewDelegate method
	* Added new empty interface gradient animation configuration, which is enabled by default

Version 1.4.0:

	* Refactor the implementation of FWEmptyPlugin to support scroll view and default text
	* Refactored FWToastPlugin to support default text
	* FWViewController added renderState state rendering method
	* FWNavigationBarAppearance supports theme colors and theme pictures

Version 1.3.7:

	* Fix the problem of FWRouter routing parameter parsing

Version 1.3.6:

	* Add a method to get the life cycle status of ViewController
	* UINavigationBar and UITabBar support quick setting of theme background images

Version 1.3.5:

	* Optimize FWTabBarController, the performance is consistent with UITabBarController

Version 1.3.4:

	* Refactor FWWebViewDelegate method

Version 1.3.3:

	* Refactor the implementation of FWWebViewController and extract FWWebView
	* FWRouter, FWMediator support preset methods

Version 1.3.2:

	* FWTabBarController supports loading network pictures
	* Optimize the animation effect of FWDrawerView

Version 1.3.1:

	* FWPagingView supports pull-down refresh of sub-pages when hovering

Version 1.3.0:

	* Refactored FWImagePlugin plug-in, refactored FWWebImage, and added option configuration
	* Added FWOAuth2Manager network authorization class
	* Optimize FWEncode to handle URL encoding

Version 1.2.1:

	* Refactor the FWRouter routing class
	* Refactor FWLoader to automatically load classes
	* Refactored FWPluginManager plugin management class

Version 1.2.0:

	* Optimize the controller fwTopBarHeight algorithm
	* Added FWQrcodeScanView configuration parameters
	* Added FWSignatureView view component

Version 1.1.1:

	* Optimize FWRouter empty string handling
	* Refactor the design and implementation of FWView, support Delegate and Block
	* Added FWNetworkUtils.isRequestError error judgment method

Version 1.1.0:

	* Optimize framework OC attribute declaration, Swift call is more friendly
	* FWAutoloader was renamed to FWLoader
	* Code optimization, Example project optimization

Version 1.0.6:

	* Add RSA encryption and decryption, signature verification algorithm
	* FWPasscodeView added configuration parameters

Version 1.0.5:

	* FWAlertController supports custom textField keyboard management

Version 1.0.4:

	* Added FWPasscodeView component

Version 1.0.3:

	* FWTheme and FWImage classes support bundle loading
	* FWPhotoBrowser supports UIImage parameters
	* Example project reconstruction, modularization and continuous integration example

Version 1.0.2:

	* Add FWAutoloader automatic loading class
	* Optimize FWWebViewController button handling

Version 1.0.1:

	* Optimize screen adaptation constants, see FWAdaptive for details

Version 1.0.0:

	* After two years of hard work, version 1.0.0 was released

## Vendor
This framework uses a lot of third-party libraries. Thanks to the authors of all third-party libraries. I will not list them all here. For details, please refer to the relevant links of the source file.
 
	In the introduction of third-party libraries, in order to be compatible with existing project pod dependencies, as well as to customize changes and bug fixes of third-party libraries, and to facilitate subsequent maintenance, this framework uniformly modified the FW class prefix and fw method prefix. If there is any inconvenience during use, Please understand.
	If you are the author of a third-party open source library, if this library violates your rights, please let me know, and I will immediately remove the use of the third-party open source library. 

## Support
[wuyong.site](http://www.wuyong.site)
