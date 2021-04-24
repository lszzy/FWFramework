# FWFramework

[![Pod Version](https://img.shields.io/cocoapods/v/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod Platform](https://img.shields.io/cocoapods/p/FWFramework.svg?style=flat)](http://cocoadocs.org/docsets/FWFramework/)
[![Pod License](https://img.shields.io/cocoapods/l/FWFramework.svg?style=flat)](https://github.com/lszzy/FWFramework/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/lszzy/FWFramework)

# [English](README.md)

## 帮助文档
iOS开发框架，方便iOS开发，兼容OC和Swift。

本框架所有Swizzle默认不会生效，不会对现有项目产生影响，需要手工开启或调用才会生效。本库已经在正式项目使用，后续也会一直维护扩展，欢迎大家使用并提出宝贵意见，共同成长。

## 安装教程
推荐使用CocoaPods安装，自动管理依赖。如需手工导入请参考Example项目配置。

### CocoaPods
本框架支持CocoaPods，Podfile示例：

	platform :ios, '9.0'
	use_frameworks!

	target 'Example' do
	  # 引入默认子模块
	  pod 'FWFramework'
	  
	  # 引入指定子模块，子模块列表详见podspec文件
	  # pod 'FWFramework', :subspecs => ['FWFramework', 'Component/SDWebImage']
	end
	
子模块简单说明说下：

	Framework: 框架层，核心架构，和应用无关，底层依赖
	Application: 应用层，AOP方案，无需继承，组件可替换
	Component: 组件层，可选引入，常用功能，方便开发

### Carthage
本框架支持Carthage，Cartfile示例：

	github "lszzy/FWFramework"

执行`carthage update`并拷贝`FWFramework.framework`到项目即可。

## 更新日志
由于本框架一直在升级优化和扩展新功能，各版本Api可能会有些许变动，如果升级新版本时编译报错，解决方案如下：

	1. 改为指定pod版本号引入即可，推荐方式，不影响项目进度，有空才升级到新版本，示例：pod 'FWFramework', '1.0.0'
	2. 升级迁移到新版本，请留意版本更新日志。废弃Api会酌情迁移到Component/Deprecated子模块，并在后续版本删除

1.4.2版本：

	* 修复FWRouter路由参数解析问题，代码优化

1.4.1版本：

	* UIScrollView支持fwOverlayView视图
	* UIScrollView支持显示空界面，修改FWEmptyViewDelegate方法
	* 新增空界面渐变动画配置，默认开启

1.4.0版本：

	* 重构FWEmptyPlugin实现，支持滚动视图和默认文本
	* 重构FWToastPlugin支持默认文本
	* FWViewController新增renderState状态渲染方法
	* FWNavigationBarAppearance支持主题颜色和主题图片

1.3.7版本：

	* 修复FWRouter路由参数解析问题

1.3.6版本：

	* 增加获取ViewController生命周期状态方法
	* UINavigationBar和UITabBar支持快速设置主题背景图片

1.3.5版本：

	* 优化FWTabBarController，表现和UITabBarController一致

1.3.4版本：

	* 重构FWWebViewDelegate方法

1.3.3版本：

	* 重构FWWebViewController实现，提取FWWebView
	* FWRouter、FWMediator支持预置方法

1.3.2版本：

	* FWTabBarController支持加载网络图片
	* 优化FWDrawerView动画效果

1.3.1版本：

	* FWPagingView支持悬停时子页面下拉刷新

1.3.0版本：

	* 重构FWImagePlugin插件，重构FWWebImage，新增选项配置
	* 新增FWOAuth2Manager网络授权类
	* 优化FWEncode处理URL编码

1.2.1版本：

	* 重构FWRouter路由类
	* 重构FWLoader自动加载类
	* 重构FWPluginManager插件管理类

1.2.0版本：

	* 优化控制器fwTopBarHeight算法
	* 新增FWQrcodeScanView配置参数
	* 新增FWSignatureView视图组件

1.1.1版本：

	* 优化FWRouter空字符串处理
	* 重构FWView设计和实现，支持Delegate和Block
	* 增加FWNetworkUtils.isRequestError错误判断方法

1.1.0版本：

	* 优化框架OC属性声明，Swift调用更友好
	* FWAutoloader改名为FWLoader
	* 代码优化，Example项目优化

1.0.6版本：

	* 增加RSA加密解密、加签验签算法
	* FWPasscodeView新增配置参数

1.0.5版本：

	* FWAlertController支持自定义textField键盘管理

1.0.4版本：

	* 新增FWPasscodeView组件

1.0.3版本：

	* FWTheme和FWImage类支持bundle加载
	* FWPhotoBrowser支持UIImage参数
	* Example项目重构、模块化和持续集成示例

1.0.2版本：

	* 增加FWAutoloader自动加载类
	* 优化FWWebViewController按钮处理

1.0.1版本：

	* 优化屏幕适配常量，详见FWAdaptive

1.0.0版本：

	* 经过两年的沉淀，1.0.0版本发布

## 第三方库
本框架使用了很多第三方库，在此感谢所有第三方库的作者，此处不一一列举，详见源码头文件相关链接。  
 
	在引入第三方库时，为了兼容现有项目pod依赖，也为了三方库自定义改动和bug修复，并方便后续维护，本框架统一修改了FW类前缀和fw方法前缀，使用时如有不便敬请谅解。
	如果您是某三方开源库的作者，若是本库侵犯了您的权益，请告诉我，本人会立即移除该三方开源库的使用，深感歉意。

## 官方网站
[大勇的网站](http://www.wuyong.site)
