# 更新日志

## [3.6.1] - 2022-07-22

### Fixed
* 修复路由解析带端口URL时打开失败问题
* 支持保存自定义deviceToken字符串

## [3.6.0] - 2022-07-11

### Changed
* 重构NavigationOptions路由处理方案
* 控制器close方法支持options参数
* 重构Navigation导航工具方法

## [3.5.1] - 2022-07-06

### Added
* 快捷打开URL方法新增完成回调
* 路由userInfo支持自定义routerHandler

## [3.5.0] - 2022-07-04

### Added
* 打开控制器、工作流等方法支持完成回调
* 新增FW.synchronized添加互斥锁方法
* 迁移部分常用工具方法到FWFramework

## [3.4.0] - 2022-06-26

### Changed
* 重构OC版本分类API，改为fw_前缀，去掉Wrapper
* 优化键盘管理跳转输入框方案
* 优化keyWindow不存在时也能获取safeAreaInsets

## [3.3.1] - 2022-06-15

### Changed
* 路由支持查找DefaultRouter:格式方法
* 键盘管理支持隐藏默认前一个和后一个按钮
* 修复倒计时方法后台运行时计算问题
* 修复主题colorForStyle等方法异常问题

## [3.3.0] - 2022-06-11

### Added
* 新增配置管理类和配置模板协议

## [3.2.1] - 2022-06-08

### Added
* 重构Router路由组件方法名称
* 新增UIKit输入组件工具方法

## [3.2.0] - 2022-05-27

### Added
* 重构AutoLayout布局语法，更加美观
* 新增UITableView和UICollectionView自定义缓存方法

## [3.1.0] - 2022-05-26

### Added
* 重构Swift版本Api方法
* 新增FW全局方法，可自定义调用名称
* 重构部分组件，增加若干功能
* 此版本与之前的版本不兼容，须迁移代码

## [3.0.0] - 2022-04-29

### Added
* 全新的版本，使用.fw.调用方式
* 可自定义.fw.为任意调用名称
* 重构部分组件，增加若干功能
* 此版本与之前的版本不兼容，须迁移代码

## [2.4.0] - 2022-02-12

### Added
* 新增等比例适配FWRelative相关方法
* FWLayoutChain开放view属性，方便扩展

## [2.3.1] - 2022-02-07

### Added
* FWTest支持异步测试

### Changed
* 修改FWRouterProtocol方法，去掉fw前缀
* 修改FWLog，支持group和userInfo

## [2.3.0] - 2022-01-20

### Added
* 新增FWABTest类可用于AB测试
* UILabel支持快速设置行高和属性样式

## [2.2.1] - 2022-01-13

### Fixed
* 迁移UIDevice.fwDeviceIDFA到Tracking子模块并修复值为nil问题

## [2.2.0] - 2022-01-12

### Added
* 新增FWEncode兼容Swift扩展方法
* 新增FWFoundation兼容Swift扩展方法

### Changed
* 修改调试信息方法为debugDescription

## [2.1.0] - 2021-12-31

### Added
* 重构Pod子模块，拆分OC和Swift代码
* 支持Swift Package Manager
* 新增String多语言扩展方法

## [2.0.0] - 2021-12-09

### Changed
* 拆分出FWApplication为单独的仓库维护
* 重构FWFramework实现

## [1.9.4] - 2021-11-22

### Fixed
* 修复Xcode13编译时导航栏样式兼容问题

## [1.9.3] - 2021-08-28

### Added
* FWAttributedLabel支持尾部截断时自定义视图
* UIButton支持快捷设置点击和高亮时的alpha

## [1.9.2] - 2021-08-20

### Changed
* UITextView支持垂直居中布局和placeholder自定义边距
* 优化UISearchBar居中位置算法

## [1.9.1] - 2021-08-19

### Added
* UITextView支持自动高度和设置最大高度
* 新增swift扩展String.fwTrimString方法
* 重构UISearchBar扩展，支持取消按钮间距定制和textField间距定制

## [1.9.0] - 2021-08-16

### Added
* 新增FWAssetManager图片管理组件
* 新增FWAudioPlayer音频播放组件
* 新增FWVideoPlayer视频播放组件
* 输入框支持自定义光标颜色和光标大小
* 导航栏样式兼容iOS15，Xcode13生效

### Changed
* 重构FWPhotoBrowser，支持异步加载图片

## [1.8.2] - 2021-08-11

### Added
* 新增视图骨架屏是否正在显示判断方法
* 吐司插件支持设置纵向偏移，默认-30

## [1.8.1] - 2021-08-07

### Fixed
* 修复导航栏已设置Appearance再hidden时无法隐藏的bug

## [1.8.0] - 2021-08-06

### Added
* 新增自定义导航栏FWNavigationView组件
* 新增控制器快捷弹出popover控制器方法

### Changed
* 修改最低兼容iOS版本为iOS10
* 重构FWNavigationStyle实现方案，兼容自定义导航栏
* 重构FWPopupMenuDelegate方法名称
* 重构UIViewController导航栏高度获取方法
* 修改Web容器JS桥接调用出错时支持回调

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

