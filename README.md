# FWFramework

[![Pod Version](http://img.shields.io/cocoapods/v/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod Platform](http://img.shields.io/cocoapods/p/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod License](http://img.shields.io/cocoapods/l/FWFramework.svg?style=flat)](https://github.com/lszzy/FWFramework/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/lszzy/FWFramework)

iOS开发框架，方便iOS开发。

## 安装教程
推荐使用CocoaPods安装，自动管理依赖。如需手工导入请参考Example项目配置。

### CocoaPods
本框架支持CocoaPods，Podfile示例：

	platform :ios, '8.0'
	use_frameworks!

	target 'Example' do
	  pod 'FWFramework'
	end

### Carthage
本框架支持Carthage，Cartfile示例：

	github "lszzy/FWFramework"

执行`carthage update`并拷贝`FWFramework.framework`到项目即可。

## 帮助文档
本框架文档位于Document文件夹，编译时会自动生成[HeaderDoc文档](Document/HeaderDoc)，支持标签列表详见[HeaderDoc tags](https://developer.apple.com/legacy/library/documentation/DeveloperTools/Conceptual/HeaderDoc/tags/tags.html)。
### HeaderDoc
HeaderDoc.sh可以快速生成框架HeaderDoc文档，使用命令如下：

	./HeaderDoc.sh
	
### CodeSnippets
CodeSnippets可以在Xcode快速编写HeaderDoc注释，如`hd_class`等，安装命令如下：

	./CodeSnippets.sh
	
### Templates
Templates可以在Xcode新建使用HeaderDoc注释的OC类，安装命令如下：

	./Templates.sh

## 更新日志
1.0.0版本：

	* 框架1.0.0版本发布

## 编码规范
### 命名
* 约定优先原则，如果命名约定存在应优先遵循约定命名，示例：

		FWClassName.sharedInstance

* 框架自定义OC类必须以FW开头，驼峰式命名，示例：

		FWClassName

* 框架枚举必须以FW开头，枚举项必须以枚举类型开头；应用枚举项可以以k+枚举类型开头，驼峰式命名，示例：

		# 框架
		FWLogType
		FWLogTypeVerbose
		# 应用
		AppEnumType
		kAppEnumTypeValue
	
* 框架自定义协议、代理必须以FW开头，以Protocol/Delegate/DataSource结尾，驼峰式命名，示例：

		FWTestProtocol
		FWViewDelegate
		FWTableViewDataSource
		
* 框架自定义OC方法、分类方法、属性必须以fw开头，驼峰式命名，以区别于系统方法，示例：

		fwCGRectAdd
		fwMethodName
		fwPropertyName

* 框架OC分类的类初始化方法必须以fw开头，示例：

		 fwColorWithString
		 fwImageWithView

* 框架C方法必须以fw_开头，内部c方法必须以fw_inner_开头，内部c全局静态变量必须以fw_static_开头，下划线分隔，示例：

		fw_method_name
		fw_inner_method
		fw_static_variable
		
* 框架自定义协议方法、自定义类的方法、属性不需要以fw开头，示例：

		FWTestProtocol.methodName
		FWClassName.methodName
		FWClassName.initWithString

* 框架内部OC类必须以FWInner开头，内部OC方法必须以fwInner开头，内部OC全局静态变量必须以fwStatic开头，驼峰式命名，示例：

		FWInnerClassName
		fwInnerDebug
		fwStaticVariable

* 框架类内部全局属性统一使用_作为后缀，以区别于外部属性，示例：

		propertyName_

* 框架类内部扩展头文件必须按照类名+Private.h格式命名(使用扩展声明，主文件实现)，框架内部类分类使用Private分类命名，示例：

		FWClassName+Private.h
		FWClassName(Private)

### 宏定义
* 约定优先原则，如果命名约定存在应优先遵循约定命名，且必须加上ifndef判断，示例：

		// 使用
		@weakify
		
		// 定义
		#ifndef weakify
		#define weakify( x ) \
			...
		#endif

* 框架编译宏定义常量必须以FW_开头，全部大写，下划线分隔，示例：
	
		FW_TEST

* 框架OC宏定义或宏定义方法必须以FW开头，实现宏定义必须以FWDef开头，驼峰式命名，示例：
	
		FWScreenSize
		FWPropertyStrong
		FWDefPropertyStrong
		
* 框架C宏定义必须以fw_开头，下划线分隔，示例：

		fw_macro_make
	
* 内部宏定义统一使用_作为后缀，以区别于公开宏定义，示例：

		fw_macro_first_
		FWIsScreenInch_

### 注释
* xcode注释，类文件应该按照功能模块进行pragma分段，未完成的功能应该用TODO等标记，常用注释如下：

		// OC版本注释
		#pragma mark - Lifecycle
		#pragma mark - Accessor
		#pragma mark - Public
		#pragma mark - Private
		#pragma mark - UITableViewDataSource
		#pragma mark - UITextViewDelegate
		// TODO: feature
		// FIXME: hotfix
		
		// Swift版本注释
		// MARK: - Lifecycle
		// MARK: - Accessor
		// MARK: - Public
		// MARK: - Private
		// MARK: - UITableViewDataSource
		// MARK: - UITextViewDelegate
		// TODO: feature
		// FIXME: hotfix
		
* 代码注释，使用HeaderDoc标准，[可用标签列表](https://developer.apple.com/legacy/library/documentation/DeveloperTools/Conceptual/HeaderDoc/tags/tags.html)，常用注释如下：

		// 注释格式
		/*!
 		 @brief 标签描述
		 @discussion 详细描述
		 @... ...
 		 */
 		
 		// 通用标签
		@brief 简单描述
		@abstract 简单描述，类似brief
		@discussion 详细描述
		@internal 标记内部文档，开启--document-internal生效
		@see 链接标签
		@link 链接标签，类似see，@/link结束
		@updated 更新日期

		// 文件标签
		@header 文件名，Top-level(可不提供，自动生成)
		@file 文件名，Top-level，同header
		@indexgroup 文档分组
		@author 作者
		@copyright 版权
		@ignore 忽略指定关键字文档
		@version 版本号

		// 类、接口、协议标签
		@class 类名，Top-level
		@interface 类名，同class，Top-level
		@protocol 协议，Top-level
		@category 分类名，Top-level
		@classdesign 类设计描述，支持多行
		@deprecated 废弃描述
		@superclass 父类

		// 方法标签
		@function C方法名，Top-level
		@method OC方法名，Top-level
		@param 参数名 描述
		@return 返回描述
		@throws 抛出异常

		// 变量标签
		@var 实例变量 描述，用于全局变量，属性等，Top-level
		@const 常量名，Top-level。代表枚举时非Top-level
		@constant 常量名，同const，Top-level。代表枚举时非Top-level
		@property OC属性，Top-level
		@enum 枚举，Top-level
		@struct 结构体，Top-level
		@typedef 定义，Top-level
		@field 名称 描述
		
		// C预处理宏标签
		@define 宏名称，#define，Top-level
		@defined 宏名称，Top-level
		@defineblock 连续宏定义，@/defineblock结束，Top-level
		@definedblock 连续宏定义，@/definedblock结束，Top-level
		@define 名称 描述，用于连续宏定义时表示单个定义
		@param 参数名 描述
		@parseOnly 标记文档中隐藏

		// CodeSnippets占位符
		<#abstract#>: 占位符
 		
 		// xctempleate系统宏
 		___FILENAME___: 文件名
 		___PROJECTNAME___: 项目名
 		___FULLUSERNAME___: 用户名
 		___COPYRIGHT___: 版权声明
 		___DATE___: 日期

## 官方网站
[大勇的网站](http://www.wuyong.site)
