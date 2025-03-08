# FWFramework

[![Pod Version](https://img.shields.io/cocoapods/v/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flszzy%2FFWFramework%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/lszzy/FWFramework)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flszzy%2FFWFramework%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/lszzy/FWFramework)
[![Pod License](https://img.shields.io/cocoapods/l/FWFramework.svg?style=flat)](https://github.com/lszzy/FWFramework/blob/master/LICENSE)

# [English](https://github.com/lszzy/FWFramework/blob/master/README.md)

## 帮助文档
iOS开发框架，主要解决原生开发中的常规和痛点问题，搭建模块化项目架构，方便iOS开发。

	* 模块化架构设计，自带Mediator中间件、Router路由等组件
	* 支持Swift协程async、await，属性注解propertyWrapper、宏等高级特性
	* 轻松可定制的UI插件，自带弹窗、吐司、空界面、下拉刷新、图片选择等插件
	* 完全可替换的网络图片、网络请求层，默认兼容SDWebImage、Alamofire等
	* 自动更新的AutoLayout链式布局，常用的UI视图组件一应俱全
	* 可扩展的Model、View、Controller架构封装，快速编写业务代码
	* 兼容SwiftUI，轻松实现UIKit、SwiftUI混合界面开发
    * 兼容Swift 6，快捷编写更健壮不易崩溃、线程安全的代码   
	* 任意可替换的fw.代码前缀，常用的Toolkit方法、Theme、多语言处理
	* 你想要的，这里全都有

本框架所有Swizzle默认不会生效，不会对现有项目产生影响，需要手工开启或调用才会生效。本库已经在正式项目使用，后续也会一直维护扩展，欢迎大家使用并提出宝贵意见，共同成长。

## 安装教程
推荐使用CocoaPods或Swift Package Manager安装，自动管理依赖。

### CocoaPods
本框架支持CocoaPods，Podfile示例：

	platform :ios, '13.0'
	use_frameworks!

	target 'Example' do
	  # 引入默认子模块
	  pod 'FWFramework'
   
      # 引入宏子模块
      # pod 'FWFramework', :subspecs => ['FWFramework', 'FWPlugin/Macros']   
	  # 引入指定子模块，子模块列表详见podspec文件
	  # pod 'FWFramework', :subspecs => ['FWFramework', 'FWSwiftUI']
	end

### Swift Package Manager
本框架支持Swift Package Manager，添加并勾选所需模块即可，Package示例：

	https://github.com/lszzy/FWFramework.git
	
	# 勾选并引入默认子模块
	import FWFramework
 
    # 勾选并引入宏子模块
    import FWPluginMacros 
	# 勾选并引入指定子模块，子模块列表详见Package.swift文件
	import FWSwiftUI

## [Api文档](https://fwframework.wuyong.site)
文档位于docs文件夹，浏览器打开index.html即可，也可运行docs.sh自动生成Api文档。

自定义代码前缀为app示例：

	public typealias APP = WrapperGlobal
	
	extension WrapperCompatible {
	    public static var app: Wrapper<Self>.Type { get { wrapperExtension } set {} }
	    public var app: Wrapper<Self> { get { wrapperExtension } set {} }
	}
	
导入默认fw代码前缀示例：

	@_spi(FW) import FWFramework

## [更新日志](https://github.com/lszzy/FWFramework/blob/master/CHANGELOG_CN.md)
由于本框架一直在升级优化和扩展新功能，各版本Api可能会有些许变动，如果升级新版本时编译报错，解决方案如下：

	1. 改为指定pod版本号引入即可，推荐方式，不影响项目进度，有空才升级到新版本，示例：pod 'FWFramework', '6.1.0'
	2. 升级迁移到新版本，请留意版本更新日志

### Swift
从6.0版本起，兼容Swift 6，兼容iOS 13+。5.x版本仅兼容Swift 5，迁移时除了使用新API修复编译错误外，还需测试相关功能是否正常，给您带来的不便敬请谅解。

### Objective-C
如需兼容OC，请使用4.x版本，兼容iOS 11+。4.x版本后续只修复bug，不再添加新功能。

## 第三方库
本框架使用了很多第三方库，在此感谢所有第三方库的作者，此处不一一列举，详见源码头文件相关链接。  
 
	在引入第三方库时，为了兼容现有项目pod依赖，也为了三方库自定义改动和bug修复，并方便后续维护，本框架统一修改了类前缀、方法前缀，使用时如有不便敬请谅解。
	如果您是某三方开源库的作者，若是本库侵犯了您的权益，请告诉我，本人会立即移除该三方开源库的使用，深感歉意。

## 官方网站
[大勇的网站](http://www.wuyong.site)
