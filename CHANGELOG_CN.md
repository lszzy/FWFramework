# 更新日志

## [6.1.0] - 2025-03-08

### Added
* 引入SmartCodable组件，新增SmartModel模型兼容AnyModel|AnyArchive协议，建议逐步迁移
* 新增MMKV缓存插件，MMAPValue属性包装器组件
* Cache组件修改为泛型方式，需迁移适配
* Archiver组件修改为泛型方式，registerType不再必须，需迁移适配
* 新增解析DNS、检查VPN是否连接等工具方法
* Decimal和CGFloat兼容BasicType协议

### Migrate
1. JSONModel读写内存方式不稳定，请使用KeyMappable方式或迁移至SmartModel，下个版本将移除memoryMode方式
2. Archiver组件改为泛型方式后，无需registerType注册，如需兼容旧版本Any类型数据，使用方式和之前保持一致
3. Cache组件改为泛型方式后，如遇代码报错，可将as? T转换为as T?即可
4. 下个大版本将拆分UIKit子模块，重构子模块按需加载方式，并移除废弃代码，敬请期待

## [6.0.5] - 2025-02-12

### Fixed
* 修复ViewTransition组件dimmingColor切换横屏时未占满问题
* Router新增appendURL方法拼接query参数

## [6.0.4] - 2024-11-15

### Changed
* ViewStyle支持根据视图类型扩展自定义样式，移除自带default样式

## [6.0.3] - 2024-10-30

### Changed
* 兼容Xcode 16.1
* 拆分不常用View和Service到FWPlugin/Module子模块，可按需引入
* 移除网络请求插件mockEnabled，请使用NetworkMocker.register(for:)方法

## [6.0.2] - 2024-10-18

### Added
* 新增GuideView引导视图组件
* PopupMenu支持自定义视图customView
* 优化快速创建tableView和collectionView方法
* 新增UISearchController测试用例

## [6.0.1] - 2024-10-17

### Changed
* 兼容Alamofire 5.10.0最新版
* 新增UIImage长边缩放工具方法
* 移动VersionManager到Service子模块
* 开放WebViewJSBridge.WeakProxy用于扩展

## [6.0.0] - 2024-10-09

### Added
* 兼容Swift 6，代码标记MainActor、Sendable、nonisolated等，轻松编写更安全的代码
* 兼容iOS 18，ViewIntrospect新增iOS 18相关变量
* 重构等比例缩放实现方案，相关方法支持非主线程调用
* 新增SendableValue对象，用于解决任意对象Sendable传参问题
* 新增safe开头Message相关observe方法，用于主线程调用监听句柄
* 新增ProtectedValue、LockingProtocol等处理线程安全工具类
* 新增MainActor.runDeinit方法统一处理deinit调用主线程代码问题
* Router、JSBridge组件相关方法标记MainActor主线程调用，需迁移适配
* 移除5.x版本标记为废弃的方法，请使用新API替换实现，需迁移适配
* 重构全局状态栏、导航栏、标签栏等高度获取方法，优先动态获取并缓存

### Migrate
1. 适配Swift 6，需修复标记MainActor、Sendable、nonisolated后相关代码编译错误，需迁移适配
2. 适配iOS 18，如使用ViewIntrospect组件需适配v18相关变量，需迁移适配
3. 适配Plugin，自定义Plugin实现时需同步标记MainActor、Sendable等，需迁移适配
4. 如需主线程调用Message相关observe监听句柄，请迁移使用safe开头对应方法
5. 如需处理deinit调用主线程代码问题，请迁移使用MainActor.runDeinit方法
6. 主项目如开启Swift 6编译，HTTPRequest请求子类等需同步标记为`@unchecked Sendable`
7. 5.x版本废弃方法已移除，请使用新Api替换实现(如chain=>layoutChain等)，需迁移适配
8. 修复编译错误后，需同步测试相关功能是否正常(如状态栏、导航栏等高度、MainActor相关功能等)
9. 更多使用示例，请参考Example项目

## [5.12.2] - 2024-09-27

### Changed
* 兼容Swift 5.8，兼容SwiftPackageIndex

## [5.12.1] - 2024-09-27

### Fixed
* 标记WeakObject为废弃，请迁移至WeakValue
* 新增isIpod和pointHalf工具方法
* 修复performBlock方法未使用queue参数问题
* 修复iOS13系统isMac的判断方法

## [5.12.0] - 2024-09-23

### Added
* Adaptive全局静态栏高度兼容iPhone15、iPhone16等系列机型
* DispatchQueue新增runSyncIf相关方法
* AssetManager预览图方法新增size参数，默认nil获取屏幕大小
* 标记UIDevice.isLandscape为废弃，请迁移至UIScreen.isInterfaceLandscape
* Runtime新增安全获取value和setValue方法
* Mediator和Plugin支持默认查找当前模块去掉Protocol实现类
* WebView新增injectWindowClose属性拦截window.close事件

## [5.11.2] - 2024-09-12

### Changed
* BarStyle隐藏判断兼容视图isHidden
* 优化hidesBottomBarWhenPushed开启且控制器转场时tabBarHeight的计算方式
* 视图转场方法新增inAncestorView参数

## [5.11.1] - 2024-09-11

### Fixed
* 修复设置statusBarHidden未生效问题

## [5.11.0] - 2024-09-09

### Changed
* 重构Test异步测试，支持自定义testSuite并手动调用，需迁移升级
* PluginView参数优化为AttributedStringParameter
* tempObject和allBoundObject线程安全处理

## [5.10.6] - 2024-09-04

### Added
* DrawerView新增draggingAreaBlock配置和springAnimation配置

## [5.10.5] - 2024-09-02

### Changed
* 优化ScrollView滚动时实现折叠指定视图效果的方法

## [5.10.4] - 2024-09-02

### Added
* 新增ScrollView滚动时实现折叠指定视图效果的方法

## [5.10.3] - 2024-08-30

### Changed
* ViewModel重命名为ObservableViewModel，标记弃用，需迁移升级
* ViewProtocol标记弃用，新增SetupViewProtocol协议且相关方法会自动调用，需迁移升级
* 新增EventViewProtocol通用事件视图协议，可选使用

## [5.10.2] - 2024-08-21

### Fixed
* 优化autoMatchDimension生成约束为required，防止与imageView自动约束冲突不生效
* autoMatchDimension支持动态切换开启或关闭

## [5.10.1] - 2024-08-21

### Added
* UIView新增autoMatchDimension处理图片高度固定，宽度自适应尺寸布局等问题

## [5.10.0] - 2024-08-19

### Added
* 新增AnyChainable协议支持链式调用，NSObject默认实现chainValue、chainBlock链式方法
* 新增ArrayResultBuilder，用于实现类似SwiftUI布局代码等功能
* SwiftUI新增AttributedText富文本组件，兼容NSAttributedString显示
* SwiftUI.Text支持多文本拼接，兼容ArrayResultBuilder
* SwiftUI部分工具方法参数名称builder修改为content
* NSAttributedString支持多文本拼接，兼容ArrayResultBuilder
* UIView新增arrangeSubviews、arrangeLayout方法，兼容ArrayResultBuilder
* UILabel点击attributedText时兼容font和textAlignment设置
* UITextView支持获取点击位置的文本样式属性，类似UILabel

## [5.9.8] - 2024-08-14

### Changed
* 新增Shortcut工具方法，原方法标记deprecated下个版本删除，建议逐步迁移

## [5.9.7] - 2024-08-14

### Fixed
* 兼容SwiftPackageIndex

## [5.9.6] - 2024-08-13

### Changed
* 兼容Swift5.8编译

## [5.9.5] - 2024-08-06

### Changed
* UIButton新增contentCollapse属性快速处理按钮收缩问题

## [5.9.4] - 2024-08-01

### Fixed
* 兼容SwiftPackageIndex

## [5.9.3] - 2024-08-01

### Changed
* 新增UITableView和UICollectionView计算高度和frame相关方法
* 修复WebView配置reuseConfigurationBlock未生效问题

## [5.9.2] - 2024-07-19

### Changed
* 兼容Xcode16，修复Cocoapods子模块编译报错
* 修改版本号获取和比较工具方法，支持小版本
* 修改Autoloader默认加载以load开头静态方法和类方法

## [5.9.1] - 2024-07-12

### Changed
* 兼容Xcode16，修复编译报错
* SwiftUI组件ViewIntrospect在Xcode16条件编译时新增v18，兼容iOS18，可迁移适配
* Xcode16条件编译时兼容iOS18新增setTabBarHidden方法
* 优化Optional.isNil和deepUnwrap方法，去掉_OptionalProtocol
* Cocoapods子模块FWPlugin/Macros兼容Xcode16

## [5.9.0] - 2024-07-09

### Changed
* 重构Language多语言实现方案，优化性能
* 重构ToastPlugin，支持detail属性，更多定制属性
* 重构ToastView，支持position、attributedMessage等定制属性
* 优化TabbarController测试用例动画效果
* 兼容Swift Package Index

## [5.8.3] - 2024-07-03

### Fixed
* 修复SDWebImage插件渲染SDAnimatedImageView问题

## [5.8.2] - 2024-07-03

### Changed
* 新增String检测链接的工具方法
* 优化递归查找子视图方法名称
* layoutKey兼容accessibilityIdentifier
* 统一优化测试用例导航栏按钮样式

## [5.8.1] - 2024-06-18

### Changed
* SwiftUI组件ViewIntrospect新增Later|Earlier相关适配方法，无需再写死每个版本号
* ToolbarView开放updateHeight和updateLayout方法允许子类重写
* setContentModeAspectFill方法重命名为scaleAspectFill

## [5.8.0] - 2024-06-12

### Changed
* 兼容Xcode16，修复编译报错
* AutoLayout布局扩展方法新增autoScale参数
* 框架所有组件布局代码禁用autoScale自动等比例缩放
* 新增PopupViewControllerProtocol弹窗控制器协议，支持底部、中心弹窗等
* 新增RectCornerView处理不规则圆角问题
* 重构ViewTransition组件，新增edge参数支持四个方向等
* 转场动画interactEnabled与interactScreenEdge交互手势可共存

## [5.7.0] - 2024-06-05

### Added
* 新增ViewProtocol视图规范协议，可选使用
* 新增SingletonProtocol用于插件查找单例
* AppResponder新增setupBusiness业务初始化钩子
* 设置导航栏按钮方法新增可忽略返回值
* 优化非必要时框架类不再继承NSObject

## [5.6.6] - 2024-06-03

### Fixed
* 修复开启BUILD_LIBRARY_FOR_DISTRIBUTION时编译报错问题
* 修复部分OC项目可能与框架自动生成的Swift.h桥接头文件冲突的问题

## [5.6.5] - 2024-06-03

### Fixed
* 修复ImageCropController自定义toolbar按钮后点击无效问题
* 新增导航栏childProxyEnabled开关控制child状态栏样式

## [5.6.4] - 2024-05-31

### Changed
* 优化ImagePreview组件状态栏样式处理

## [5.6.3] - 2024-05-30

### Changed
* 优化ImagePicker、ImagePreview组件状态栏样式处理
* 优化导航控制器child状态栏样式处理

## [5.6.2] - 2024-05-29

### Added
* 新增ViewStyle以及定义和使用通用视图样式方法

## [5.6.1] - 2024-05-27

### Changed
* setBorderView禁用自动布局等比例缩放
* emptyInsets|toastInsets禁用自动布局等比例缩放
* PasscodeView|WebView禁用自动布局等比例缩放

## [5.6.0] - 2024-05-24

### Changed
* 新增RequestViewControllerProtocol快速处理控制器网络请求
* BatchRequest、ChainRequest实现HTTPRequestProtocol协议
* ViewModel移动到Module子模块，兼容UIKit和SwiftUI
* UITableView快捷初始化方法新增tableViewConfiguration配置句柄
* 优化reloadData(completion:)方法实现

## [5.5.1] - 2024-05-23

### Changed
* JSBridge支持查找默认DefaultBridge:开发
* CacheKeychain支持自定义Service名称
* CacheUserDefaults兼容AnyArchivable协议
* 移除ArchivedValue属性注解，StoredValue属性注解兼容AnyArchivable协议

## [5.5.0] - 2024-05-20

### Added
* 新增AnyArchivable协议，可快速归档模型，兼容Codable、CodableModel、JSONModel
* Archiver、UserDefault、Cache、Database、Keychain等组件兼容AnyArchivable协议对象
* 新增ArchivedValue属性注解，快速将AnyArchivable对象归档并保存到UserDefaults
* Authorize、Toolkit相关组件支持async|await协程调用
* 重构AuthorizeLocation组件，支持async|await协程调用

## [5.4.1] - 2024-05-17

### Changed
* 重构Authorize组件，开放实现类并新增Error参数，需迁移适配
* 新增生物识别授权插件AuthorizeBiometry，需引入FWPlugin/Biometry子模块
* 修复GET请求requestArgument嵌套Optional参数时编码为nil的问题

## [5.4.0] - 2024-05-14

### Changed
* 拆分二级子模块，CocoaPods可按需引入所需子模块
* 重构FWExtension子模块为FWPlugin，兼容CocoaPods和SPM使用，需迁移适配
* 拆分不常用View和Service到FWPlugin/Module子模块，可按需引入
* 代码重构，去掉所有fw_开头分类扩展方法，仅支持Wrapper(fw.)方式调用
* 重构MulticastBlock，支持优先级和异步调用
* 控制器生命周期去掉didLayoutSubviews状态
* ImagePlugin新增queryMemoryData选项

## [5.3.2] - 2024-04-29

### Changed
* 重构FWExtension子模块，兼容CocoaPods和SPM使用，需迁移FWMacro相关子模块到FWExtension
* 集成PrivicyInfo.xcprivacy文件
* 修复addColor混合颜色未生效问题

## [5.3.1] - 2024-04-23

### Changed
* HTTPRequest方法句柄参数支持Self，无需类型转换
* HTTPRequest开放contextAccessory属性，可自定义
* BatchRequest某个请求失败导致停止时只取消其他请求，新增addRequest方法

## [5.3.0] - 2024-04-22

### Changed
* 纯Swift完整功能实现，移除FWObjC子模块
* Autoloader的autoload方法改为Swift调用机制
* 重构属性KVO监听，新增swift原生observe方式
* 重构错误捕获ErrorManager，纯Swift实现
* Mediator新增Delegate模式，AppResponder可选使用
* 重构UIViewController生命周期监听，新增ViewControllerLifecycleObservable协议
* 新增常用UIKit工具方法

### Migrate
1. Autoloader.autoload不再自动调用，可启动时手工调用或继承AppResponder，需迁移升级
2. UIViewController默认lifecyleState修改为nil，需实现LifecycleObservable或开启监听后才有值，需迁移升级
3. 由于Swift实现机制，UIViewController生命周期didDeinit时不可再访问关联属性，需迁移升级
4. ExceptionManager错误捕获相关API变更为ErrorManager，需迁移升级

## [5.2.1] - 2024-04-08

### Changed
* 修复Xcode编译警告，替换并移除废弃的方法
* 移除废弃的获取运营商方法，修改获取网络类型方法
* 新增Optional快捷方法，优化CGFloat等不再实现BasicType

## [5.2.0] - 2024-03-29

### Changed
* 新增MappedValueMacro等宏，快速编写接口数据模型，需引入FWMacro/Macros子模块
* CodableModel和JSONModel移除KeyMapping模式相关方法，因为使用复杂且不支持继承
* MappedValue支持ignored忽略配置
* JSONModel注解MappedValue兼容ValidatedValue

## [5.1.0] - 2024-03-21

### Changed
* 新增KeyMappable协议，兼容CodableModel和JSONModel
* 新增MappedValue属性注解，兼容CodableModel和JSONModel
* 修改JSONModel，当实现KeyMappable协议之后不再直接读写内存，建议逐步迁移
* 同步修改Router.Parameter，继承时新增属性需标记MappedValue
* Codable支持解析Any、Any字典和Any数组类型数据
* 重构BadgeView，统一并简化badgeOffset使用
* 修改mirrorDictionary方法不再过滤下划线开头属性

## [5.0.3] - 2024-03-11

### Changed
* JSONModel兼容Xcode15.3
* 图片插件新增delayPlaceholder选项
* TabBarController新增imageInsets属性
* 新增全局快速ceil扩展方法
* 新增控制器使用safeArea布局时兼容TabBar适配方法
* 新增控制器快捷定制Toast|Empty插件方法
* 路由openURL方法参数url修改为Optional

## [5.0.2] - 2024-02-26

### Changed
* 控制器navigationBarHeight兼容自定义navigationBarHidden设置
* 修复图片预览插件customBlock位置变动引起未更新countLabel的问题

## [5.0.1] - 2024-02-26

### Changed
* 新增RoundedCornerView无需frame处理半圆圆角问题
* 修改NavigationStyle未设置时获取当前状态
* PopupMenu支持指定容器视图，修改showsMaskView为隐藏maskView，需迁移测试
* 优化Database性能，增加ModelFields解析缓存

## [5.0.0] - 2024-02-22

### Added
* 经过两年的重构，Swift版本发布，兼容iOS13+，不再兼容OC
* 支持Swift协程async、await，属性注解propertyWrapper等高级特性
* 完全可替换的UI插件管理，轻松实现项目定制
* 可替换的图片库、网络请求层，自带扩展兼容SDWebImage、Alamofire等
* 几年的线上项目积累，两年心血的Swift版本重构，你想要的，这里全都有
* 感谢ChatGPT、感谢Codeium、感谢使用到的所有开源库的作者
* 最后，感谢自己，无数个日日夜夜，能坚持下来，真的不容易

### Migrate
1. Autoloader默认仅加载static类方法，需迁移升级
2. Router路由绑定方法API变更，需迁移升级
3. JSBridge绑定方法API变更，需迁移升级
4. HTTPRequest网络请求API变更，需迁移升级
5. 其他编译报错需使用新API修复，并测试相关功能是否正常
6. 使用示例代码可参考Example项目

## [4.18.3] - 2024-03-12

### Fixed
* 兼容Xcode15.3，修复Archive失败问题

## [4.18.2] - 2023-10-27

### Added
* UISwitch支持自定义offTintColor

## [4.18.1] - 2023-10-13

### Added
* 修复UILabel自定义contentInset时偶现文本显示不全问题
* BannerView支持NSAttributedString，新增间距设置等属性

## [4.18.0] - 2023-09-19

### Added
* 兼容Xcode15、iOS17
* 同步SwiftUI组件Introspect到最新版本
* 优化SwiftUI刷新、追加插件使用方式

## [4.17.5] - 2023-09-18

### Fixed
* 修复扫描二维码组件使用时可能连续回调多次的问题

## [4.17.4] - 2023-09-10

### Changed
* Image插件新增读取本地缓存和清理所有缓存的方法
* 修复ZoomImageView图片缓存存在时偶现转场动画异常问题

## [4.17.3] - 2023-09-08

### Fixed
* 修复系统图片选择器回调顺序不对以及触发多次回调的问题
* 优化图片压缩递减率默认值为0.3

## [4.17.2] - 2023-09-07

### Changed
* 新增UICollectionView拖动排序方法
* Lottie视图新增修改进度时始终执行动画选项

## [4.17.1] - 2023-09-06

### Changed
* 键盘管理新增keyboardDistanceBlock自定义句柄
* 新增后台批量压缩图片处理方法
* 系统图片选择器选择单张图片时支持自定义裁剪
* 优化系统图片选择器处理图片完成后才关闭界面并回调
* 新增快捷创建NSParagraphStyle方法
* UITextView新增快捷设置lineHeight方法
* 修改cursorRect的origin含义为偏移量

## [4.17.0] - 2023-09-01

### Added
* Router路由支持*id格式参数
* PopupMenu新增自定义样式属性
* NSAttributedString快捷初始化方法新增attributes参数
* UICollectionView新增layoutFrame计算方法
* RefreshPlugin新增customBlock参数，需适配
* RefreshView支持自定义height，去掉原UIScrollView插件高度设置，需适配
* 图片选择器新增开启导航栏属性开关
* 修改MulticastDelegate的filter方法行为，需适配

## [4.16.2] - 2023-08-25

### Changed
* 修改autoScale仅针对当前视图生效，不再查找父视图(不稳定)
* 兼容loadingFinished在reloadData之前设置也能生效

### Fixed
* 修复finished未改变，但isDataEmpty改变时finishedView未刷新问题
* 修复开启自动布局等比例缩放时offset和collapse方法未自动缩放和取反的问题

### Migrate
1. 如果开启了等比例缩放，检查是否有单独设置autoScale的视图并适配
2. 如果开启了等比率缩放，检查LayoutChain中带参数的collapse、offset方法，改为自动缩放
3. 如果开启了等比例缩放，布局约束需要固定值时，使用LayoutChain的constant方法即可

## [4.16.1] - 2023-08-24

### Changed
* 扫码默认仅开启二维码，可指定条形码等
* 扫码新增缩放手势句柄
* 上拉追加插件如果数据为空时不显示finishedView
* 上拉追加插件padding支持负数

## [4.16.0] - 2023-08-22

### Added
* 新增Swift版本CachedValue注解
* 新增Swift版本表格和集合Cell简单曝光方案
* 新增Swift版本解析服务器响应时间方法
* 新增开始后台任务快捷方法
* 重构和同步二维码扫描组件ScanView
* PopupMenu新增maskViewColor属性
* SegmentedControl新增自定义layer句柄
* 新增判断网络请求错误类型工具方法
* 自定义Sheet组件支持隐藏取消按钮

## [4.15.0] - 2023-07-28

### Added
* 新增数据库迁移协议方法
* PageControl新增currentDotSize设置
* MulticastBlock新增主线程调用属性
* SwiftUI新增Button包装方法
* 重构NumberFormatter构造方法

## [4.14.1] - 2023-06-30

### Changed
* 播放系统声音文件方法支持完成回调
* 优化SwiftUI显示ToastPlugin相关方法
* 修复SwiftUI偶现ToastPlugin返回界面时重新显示问题

## [4.14.0] - 2023-06-28

### Added
* 新增AutoLayout批量布局方法、布局冲突调试优化
* EmptyPlugin新增获取正在显示的视图方法
* ToastPlugin新增获取正在显示的视图方法
* 小红点BadgeView支持自定义大小和偏移
* WebView默认支持window.close关闭界面
* 优化SwiftUI控制是否能继续追加处理
* 修复空界面自定义customBlock后偶现样式不生效问题

## [4.13.0] - 2023-06-26

### Added
* EmptyPlugin支持NSAttributedString参数
* 新增快捷创建NSAttributedString方法
* 新增计算字体高度、计算baselineOffset方法

## [4.12.1] - 2023-06-21

### Changed
* 移除barTransitionNeedsUpdate方法，框架自动处理
* 移除全局autoFlat开关，迁移到UIFont和UIView配置
* 修复部分情况下SegmentedControl文字未居中问题

## [4.12.0] - 2023-06-16

### Added
* SwiftUI新增常用相对布局方法
* AutoLayout支持切换禁用多个布局约束
* JSONModel支持下划线驼峰风格互转
* 新增全局等比例缩放像素取整开关配置
* 修复iOS15以上JSONModel大数字转字符串精度丢失问题

## [4.11.0] - 2023-05-31

### Added
* SegmentedControl组件新增背景色等配置
* 上拉追加视图新增finishedBlock属性
* 新增全局flat快捷方法、移除pointHalf常量
* LayoutChain支持同时collapse多个约束
* 修复iOS14偶现DynamicLayout崩溃问题
* 修复打开mailto、sms跳转链接问题

## [4.10.1] - 2023-04-23

### Fixed
* 修复轮询请求stop时未完全取消问题
* 网络请求新增isCancelled句柄处理请求取消的场景

## [4.10.0] - 2023-04-21

### Added
* 新增SwiftUI快捷绑定List、ScrollView刷新追加、空界面组件
* 新增刷新组件showsFinishedView配置是否显示完成视图
* 修改全局静态颜色配置方式为句柄配置
* 修改SwiftUI输入框自动聚焦方法参数
* 统一ViewControllerState和ViewState为ViewState枚举
* 同步Introspect组件最新代码，兼容iOS16
* 修复SwiftUI处理List、ScrollView兼容组件bug

## [4.9.0] - 2023-04-20

### Added
* 新增SwiftUI处理List、ScrollView兼容组件
* 新增SwiftUI处理Divider兼容组件
* 新增SwiftUI输入框配置句柄组件
* 新增SwiftUI按钮高亮和禁用样式组件
* 修改SwiftUI的ViewModel组件为协议
* 修复SwiftUI刷新组件、边框圆角方法bug

## [4.8.5] - 2023-04-17

### Added
* 新增快捷处理自动布局收缩方法
* 新增视图批量自动布局方法

## [4.8.4] - 2023-04-15

### Changed
* 路由支持严格模式，完全匹配时才响应，默认关闭
* 优化请求重试方法，支持-1不限次数
* 优化SwiftUI字体方法，同UIKit方式
* 修复键盘管理touchResign需点击两次才能触发按钮事件问题

## [4.8.3] - 2023-04-08

### Added
* 新增barTransitionNeedsUpdate方法处理导航栏转场样式改变的场景

## [4.8.2] - 2023-04-08

### Changed
* PagingView支持重用，修复reloadData未重置contentOffset问题
* 控制器新增allowsBarAppearance控制是否修改导航栏样式
* ImagePreview插件新增dismissingScaleEnabled配置，修复偶现闪烁问题
* 重构全局fontBlock，自动根据配置取相对尺寸
* ToolbarView支持不规则形状按钮

## [4.8.1] - 2023-03-31

### Added
* StateView兼容Xcode14.3
* 兼容iPhone14系列手机
* ToolbarTitleView支持配置左侧最小距离

## [4.8.0] - 2023-03-30

### Added
* ToolbarView支持配置左对齐和间距
* ToolbarTitleView支持配置左对齐和间距

## [4.7.4] - 2023-03-18

### Added
* 新增动态计算AutoLayout布局视图宽高方法
* DynamicLayout方法新增NS_NOESCAPE标记
* DrawerView新增scrollViewInsets内边距配置
* AttributedLabel兼容iOS15+系统自带删除线

## [4.7.3] - 2023-03-13

### Changed
* 重构获取和选中TabBar指定控制器方法名称
* 优化DrawerView位于非scrollViewPositions时不自动回到顶部

## [4.7.2] - 2023-03-11

### Added
* 重构DrawerView，支持多种模式
* 新增safeJSON快捷转换JSON方法
* 新增获取TabBar根控制器方法

## [4.7.1] - 2023-03-09

### Added
* JSONModel新增merge方法
* ParameterModel.toDictionary方法自动过滤下划线开头属性
* UIButton和点击手势支持自定义高亮状态、禁用状态句柄
* 修复DrawerView特殊场景时调用setPosition不生效问题

## [4.7.0] - 2023-03-07

### Added
* 新增Swift版本ParameterModel组件
* DrawerView新增scrollViewFilter配置
* NotificationManager新增delegate配置

## [4.6.0] - 2023-02-20

### Added
* 新增Analyzer分析组件
* 新增Validator Swift验证组件
* 新增MulticastBlock多句柄代理组件
* 新增Optional常用扩展方法
* 重构Swift Annotation组件
* 重构Request组件同步请求
* 移除NetworkMocker组件

## [4.5.0] - 2023-02-09

### Added
* Request组件支持同步请求
* ModuleBundle支持加载模块颜色
* AttributedLabel支持删除线样式

## [4.4.3] - 2023-02-07

### Fixed
* 修复手机系统为12小时制时DateFormatter格式化不正确的问题

## [4.4.2] - 2023-01-18

### Fixed
* 修复启用导航栏拦截后快速侧滑顶部导航栏会触发底部导航栏的侧滑返回问题

## [4.4.1] - 2023-01-06

### Changed
* 优化下拉刷新插件indicatorPadding的实现方式
* 修复Swift Package Manager最低兼容lottie-ios 4.0版本

## [4.4.0] - 2022-12-07

### Changed
* 升级Lottie组件兼容lottie-ios 4.0版本
* 重命名LottieView为LottiePluginView

## [4.3.3] - 2022-12-05

### Changed
* AlertController支持修改animationType
* AlertController支持点击Action不关闭界面

## [4.3.2] - 2022-11-25

### Changed
* SegmentedControl新增box样式和内边距属性
* 优化DynamicLayout支持Swift泛型

## [4.3.1] - 2022-10-27

### Added
* 瀑布流布局支持Header悬停效果

## [4.3.0] - 2022-10-19

### Changed
* 新增Swift版本模型解析组件JSONModel
* 修改Swift版本API方法默认值
* 优化骨架屏视图，无需手工添加动画视图
* 重写所有测试用例为Swift实现

## [4.2.1] - 2022-10-10

### Added
* 图片插件下载图片时新增data回调参数
* 支持自定义全局mainWindow属性
* 新增UIView排序子视图层级关系方法
* 视图控制器新增toastInAncestor属性

## [4.2.0] - 2022-10-08

### Changed
* 全局兼容iPad
* 重构Swift版本Swizzle相关API方法
* 新增等比例缩放屏幕适配常用方法
* 修改autoScale属性为当前视图及其子视图生效

## [4.1.2] - 2022-09-22

### Fixed
* 优化控制器获取底部栏高度算法
* 优化转场手势Failed状态处理

## [4.1.1] - 2022-09-20

### Fixed
* 修复方法名称from单词拼写错误
* 新增解析启动URL方法
* 优化上拉追加浮点数精度问题

## [4.1.0] - 2022-09-13

### Changed
* 重构AutoLayout支持priority参数
* 新增WebView允许打开SchemeURL配置
* 新增List查找UICollectionView方法
* 兼容Xcode14，兼容iOS16

## [4.0.2] - 2022-09-07

### Added
* 点击手势支持监听highlighted状态
* 优化BannerView索引改变回调方法

## [4.0.1] - 2022-09-06

### Added
* 新增pop到指定工作流方法
* 新增颜色混合方法
* 新增播放触控反馈方法

## [4.0.0] - 2022-08-28

### Changed
* 合并FWApplication到本框架，全新版本
* 重构部分API方法，去掉不常用功能
* 重构目录结构，统一Pod子模块

## [3.8.1] - 2022-08-10

### Changed
* NSAttributedString支持点击高亮URL
* 修改输入框自动完成默认等待时间为0.5秒

## [3.8.0] - 2022-08-02

### Added
* 新增iOS13+启用新导航栏样式全局开关
* 新增根据tag查找subviews子视图方法
* 新增数组safe下标安全读取方法
* 新增移除所有点击block事件方法
* 删除colorWithString从颜色名称初始化方法

## [3.7.0] - 2022-07-27

### Changed
* 修改Swift版本State为StateObject

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

