# 更新日志

## [1.8.0] - 2021-08-01

### Added
* 新增自定义导航栏FWNavigationView组件

### Changed
* 重构FWNavigationStyle实现方案，兼容自定义导航栏
* 重构FWPopupMenuDelegate方法名称

## [1.7.4] - 2021-07-14

### Changed
* 优化系统JSON解码因为特殊字符报错3840问题
* 优化URL包含中文时query参数解析问题

## [1.7.3] - 2021-07-08

### Added
* FWEmptyPlugin新增fwEmptyInsets外间距属性设置
* FWToastPlugin新增fwToastInsets外间距属性设置

## [1.7.2] - 2021-07-02

### Fixed
* 优化FWDynamicLayout缓存机制，修复iOS15高度计算bug

## [1.7.1] - 2021-07-01

### Changed
* 重构FWTheme主题颜色处理，兼容iOS13以下主题切换

## [1.7.0] - 2021-06-29

### Added
* 新增FWIcon图标字体类，支持name方式加载

### Changed
* 重构FWTheme主题管理类，优化方法名称，避免内存泄漏

## [1.6.6] - 2021-06-25

### Changed
* 优化fwDismissBlock下拉时多次调用问题，需手工触发

## [1.6.5] - 2021-06-24

### Changed
* FWWebViewJsBridge支持APP和JS双端桥接错误回调
* FWPhotoBrowser支持dismiss到指定位置

## [1.6.4] - 2021-06-23

### Fixed
* 修复UIKit Component组件nullable声明

## [1.6.3] - 2021-06-17

### Changed
* 重命名FWImageName方法为FWImageNamed
* FWModuleBundle使用fwImageNamed图片加载方法

## [1.6.2] - 2021-06-16

### Added
* iOS13+默认支持SVG图片格式
* FWImage新增解码选项配置，兼容SDWebImage
* UITableView新增fwPerformUpdates方法

## [1.6.1] - 2021-06-09

### Added
* 新增fade渐变转场动画方法

### Fixed
* 修复FWSegmentedControl第一次跳转index不正常问题
* 修复刷新插件同时触发问题、内容较短时进度回调异常问题

## [1.6.0] - 2021-06-08

### Added
* 新增FWMulticastDelegate多代理转发类

### Changed
* 重构项目目录结构，使用pod推荐方式
* 重写FWPromise类，支持OC和Swift调用
* 重构FWLog方法名称

### Fixed
* 修复FWRefreshPlugin和FWWebImage插件偶现bug

## [1.5.6] - 2021-05-31

### Changed
* 修复FWAnimatedTransition循环引用presentationController问题
* FWPhotoBrowserDelegate新增显示和隐藏时回调方法

## [1.5.5] - 2021-05-25

### Added
	* 新增Swift常用类型fwAs安全转换方法

### Changed
	* 修改FWRouterContext属性名称和声明

### Fixed
	* 修复fwTouchEventInterval不生效问题

## [1.5.4] - 2021-05-24

### Added
* FWAutoLayout增加视图宽高比布局方法
* FWRouterContext增加mergeParameters方法
* UIApplication新增调用系统分享方法

## [1.5.3] - 2021-05-20

### Changed
* UITextField键盘管理支持UIScrollView滚动
* 优化NSDate.fwCurrentTime精确度

## [1.5.2] - 2021-05-18

### Changed
* 修改FWModuleProtocol.setup为可选方法

### Fixed
* 修复FWAppDelegate方法nullable声明

## [1.5.1] - 2021-05-06

### Changed
* 优化空界面插件动画效果、自动移除Overlay视图

## [1.5.0] - 2021-04-30

### Changed
* 重构日志插件、图片插件
* 重构弹窗插件、空界面插件、吐司插件、刷新插件

## [1.4.3] - 2021-04-27

### Changed
	* FWRouter移除isObjectURL判断方法，兼容scheme:path格式URL
	* FWEmptyPluginConfig新增customBlock配置

## [1.4.2] - 2021-04-25

### Fixed
* 修复FWRouter路由参数解析问题，代码优化

## [1.4.1] - 2021-04-23

### Changed
* UIScrollView支持fwOverlayView视图
* UIScrollView支持显示空界面，修改FWEmptyViewDelegate方法
* 新增空界面渐变动画配置，默认开启

## [1.4.0] - 2021-04-22

### Changed
* 重构FWEmptyPlugin实现，支持滚动视图和默认文本
* 重构FWToastPlugin支持默认文本
* FWViewController新增renderState状态渲染方法
* FWNavigationBarAppearance支持主题颜色和主题图片

## [1.3.7] - 2021-04-21

### Fixed
* 修复FWRouter路由参数解析问题

## [1.3.6] - 2021-04-19

### Added
* 增加获取ViewController生命周期状态方法

### Changed
* UINavigationBar和UITabBar支持快速设置主题背景图片

## [1.3.5] - 2021-04-15

### Changed
* 优化FWTabBarController，表现和UITabBarController一致

## [1.3.4] - 2021-04-13

### Changed
* 重构FWWebViewDelegate方法

## [1.3.3] - 2021-04-13

### Changed
* 重构FWWebViewController实现，提取FWWebView
* FWRouter、FWMediator支持预置方法

## [1.3.2] - 2021-04-01

### Changed
* FWTabBarController支持加载网络图片
* 优化FWDrawerView动画效果

## [1.3.1] - 2021-03-30

### Changed
* FWPagingView支持悬停时子页面下拉刷新

## [1.3.0] - 2021-03-28

### Added
* 新增FWOAuth2Manager网络授权类

### Changed
* 重构FWImagePlugin插件，重构FWWebImage，新增选项配置
* 优化FWEncode处理URL编码

## [1.2.1] - 2021-03-22

### Changed
* 重构FWRouter路由类
* 重构FWLoader自动加载类
* 重构FWPluginManager插件管理类

## [1.2.0] - 2021-03-19

### Added
* 新增FWSignatureView视图组件

### Changed
* 优化控制器fwTopBarHeight算法
* 新增FWQrcodeScanView配置参数

## [1.1.1] - 2021-03-14

### Changed
* 优化FWRouter空字符串处理
* 重构FWView设计和实现，支持Delegate和Block
* 增加FWNetworkUtils.isRequestError错误判断方法

## [1.1.0] - 2021-03-10

### Changed
* 优化框架OC属性声明，Swift调用更友好
* FWAutoloader改名为FWLoader
* 代码优化，Example项目优化

## [1.0.6] - 2021-02-05

### Added
* 增加RSA加密解密、加签验签算法

### Changed
* FWPasscodeView新增配置参数

## [1.0.5] - 2021-02-02

### Changed
* FWAlertController支持自定义textField键盘管理

## [1.0.4] - 2021-02-01

### Added
* 新增FWPasscodeView组件

## [1.0.3] - 2021-01-22

### Changed
* FWTheme和FWImage类支持bundle加载
* FWPhotoBrowser支持UIImage参数
* Example项目重构、模块化和持续集成示例

## [1.0.2] - 2021-01-15

### Added
* 增加FWAutoloader自动加载类

### Changed
* 优化FWWebViewController按钮处理

## [1.0.1] - 2021-01-11

### Changed
* 优化屏幕适配常量，详见FWAdaptive

## [1.0.0] - 2021-01-05

### Added
* 经过两年的沉淀，1.0.0版本发布

