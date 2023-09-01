# FWFramework

[![Pod Version](https://img.shields.io/cocoapods/v/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod Platform](https://img.shields.io/cocoapods/p/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod License](https://img.shields.io/cocoapods/l/FWFramework.svg?style=flat)](https://github.com/lszzy/FWFramework/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/lszzy/FWFramework)

# [English](https://github.com/lszzy/FWFramework/blob/master/README.md)

## 帮助文档
iOS开发框架，方便iOS开发，兼容OC和Swift。

本框架所有Swizzle默认不会生效，不会对现有项目产生影响，需要手工开启或调用才会生效。本库已经在正式项目使用，后续也会一直维护扩展，欢迎大家使用并提出宝贵意见，共同成长。

## 安装教程
推荐使用CocoaPods或Swift Package Manager安装，自动管理依赖。如需手工导入请参考Example项目配置。

### CocoaPods
本框架支持CocoaPods，Podfile示例：

	platform :ios, '11.0'
	use_frameworks!

	target 'Example' do
	  # 引入默认子模块，小于5.0版本
	  pod 'FWFramework', '~> 4.0'
	  
	  # 引入指定子模块，小于5.0版本，子模块列表详见podspec文件
	  # pod 'FWFramework', '~> 4.0', :subspecs => ['FWFramework', 'FWSwiftUI']
	end

### Swift Package Manager
本框架支持Swift Package Manager，添加并勾选所需模块即可，Package示例：

	https://github.com/lszzy/FWFramework.git
	
	# 勾选并引入默认子模块
	import FWFramework
	
	# 勾选并引入指定子模块，子模块列表详见Package.swift文件
	import FWSwiftUI

## [Api文档](https://fwframework.wuyong.site)
文档位于docs文件夹，浏览器打开index.html即可，也可运行docs.sh自动生成Api文档。

## [更新日志](https://github.com/lszzy/FWFramework/blob/master/CHANGELOG_CN.md)
由于本框架一直在升级优化和扩展新功能，各版本Api可能会有些许变动，如果升级新版本时编译报错，解决方案如下：

	1. 改为指定pod版本号引入即可，推荐方式，不影响项目进度，有空才升级到新版本，示例：pod 'FWFramework', '4.17.0'
	2. 升级迁移到新版本，请留意版本更新日志。废弃Api会酌情迁移到Deprecated子模块，并在后续版本删除

## 第三方库
本框架使用了很多第三方库，在此感谢所有第三方库的作者，此处不一一列举，详见源码头文件相关链接。  
 
	在引入第三方库时，为了兼容现有项目pod依赖，也为了三方库自定义改动和bug修复，并方便后续维护，本框架统一修改了FW类前缀和fw方法前缀，使用时如有不便敬请谅解。
	如果您是某三方开源库的作者，若是本库侵犯了您的权益，请告诉我，本人会立即移除该三方开源库的使用，深感歉意。

## 官方网站
[大勇的网站](http://www.wuyong.site)
