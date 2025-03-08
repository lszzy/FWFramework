# Changelog

## [6.1.0] - 2025-03-08

### Added
* SmartCodable component introduced, new SmartModel model compatible with AnyModel|AnyArchive protocol, gradual migration is recommended
* MMKV cache plug-in, MMAPValue property wrapper component added
* Cache component changed to generic mode, migration and adaptation required
* Archiver component changed to generic mode, registerType is no longer required, migration and adaptation required
* Added tools and methods such as DNS resolution and VPN connection check
* Decimal and CGFloat are compatible with BasicType protocol

### Migrate
1. JSONModel memory reading and writing method is unstable, please use KeyMappable method or migrate to SmartModel, memoryMode method will be removed in the next version
2. After the Archiver component is changed to a generic method, registerType is no longer required. If you need to be compatible with the old version of Any type data, the usage method remains the same as before
3. After Cache component is changed to generic mode, if you encounter code errors, you can convert as? T to as T?
4. The next major version will split the UIKit submodules, refactor the on-demand loading method of submodules, and remove obsolete code. Stay tuned.

## [6.0.5] - 2025-02-12

### Fixed
* Fixed the issue that the dimmingColor of the ViewTransition component does not occupy the full space when switching to horizontal screen
* Added the appendURL method in Router to splice query parameters

## [6.0.4] - 2024-11-15

### Changed
* ViewStyle supports extending custom styles based on view types and removes the default style

## [6.0.3] - 2024-10-30

### Changed
* Compatible with Xcode 16.1
* Split uncommonly used Views and Services into FWPlugin/Module submodules, which can be imported as needed
* Remove the network request plugin mockEnabled, please use the NetworkMocker.register(for:) method

## [6.0.2] - 2024-10-18

### Added
* Added GuideView guide view component
* PopupMenu supports custom view customView
* Optimize the method of quickly creating tableView and collectionView
* Added UISearchController test case

## [6.0.1] - 2024-10-17

### Changed
* Compatible with the latest version of Alamofire 5.10.0
* Added UIImage long edge scaling tool method
* Moved VersionManager to Service submodule
* Opened WebViewJSBridge.WeakProxy for extension

## [6.0.0] - 2024-10-09

### Added
* Compatible with Swift 6, code marks MainActor, Sendable, nonisolated, etc., easy to write safer code
* Compatible with iOS 18, ViewIntrospect adds iOS 18 related variables
* Refactor the proportional scaling implementation scheme, and related methods support non-main thread calls
* Add SendableValue object to solve the problem of passing parameters of any object Sendable
* Add observe method related to Message starting with safe, used for main thread calling listener handle
* Add ProtectedValue, LockingProtocol and other thread safety tool classes
* Add MainActor.runDeinit method to uniformly handle deinit calling main thread code problems
* Router, JSBridge component related methods mark MainActor main thread calls, need to migrate and adapt
* Remove the methods marked as deprecated in version 5.x, please use the new API to replace the implementation, need to migrate and adapt
* Refactor the height acquisition methods of the global status bar, navigation bar, tab bar, etc., and give priority to dynamic acquisition and caching

### Migrate
1. To adapt to Swift 6, you need to fix the compilation errors of related codes after marking MainActor, Sendable, and nonisolated, and you need to migrate and adapt
2. To adapt to iOS 18, if you use the ViewIntrospect component, you need to adapt to v18 related variables, and you need to migrate and adapt
3. To adapt to Plugin, you need to synchronously mark MainActor, Sendable, etc. when implementing custom Plugins, and you need to migrate and adapt
4. If the main thread needs to call the Message-related observe listener handle, please migrate to the corresponding method starting with safe
5. If you need to handle the problem of deinit calling the main thread code, please migrate to use the MainActor.runDeinit method
6. If the main project opens Swift 6 compilation, HTTPRequest request subclasses, etc. need to be synchronously marked as `@unchecked Sendable`
7. The obsolete methods of version 5.x have been removed. Please use the new Api to replace the implementation (such as chain=>layoutChain, etc.), and you need to migrate and adapt
8. After fixing the compilation error, you need to test whether the related functions are normal (such as the height of the status bar, navigation bar, MainActor related functions, etc.)
9. For more usage examples, please refer to the Example project

## [5.12.2] - 2024-09-27

### Changed
* Compatible with Swift 5.8 and SwiftPackageIndex

## [5.12.1] - 2024-09-27

### Fixed
* Mark WeakObject as deprecated, please migrate to WeakValue
* Added isIpod and pointHalf tool methods
* Fixed the issue that performBlock method does not use queue parameter
* Fixed the judgment method of isMac in iOS13 system

## [5.12.0] - 2024-09-23

### Added
* Adaptive global static bar is highly compatible with iPhone15, iPhone16 and other series models
* DispatchQueue adds runSyncIf related methods
* AssetManager preview method adds size parameter, default nil to get screen size
* Mark UIDevice.isLandscape as obsolete, please migrate to UIScreen.isInterfaceLandscape
* Runtime adds safe access value and setValue methods
* Mediator and Plugin support default search for current module to remove Protocol implementation class
* WebView adds injectWindowClose property to intercept window.close event

## [5.11.2] - 2024-09-12

### Changed
* BarStyle hidden judgment compatible view isHidden
* Optimize the calculation method of tabBarHeight when hidesBottomBarWhenPushed is turned on and the controller transitions
* Add inAncestorView parameter to the view transition method

## [5.11.1] - 2024-09-11

### Fixed
* Fixed the issue that setting statusBarHidden did not take effect

## [5.11.0] - 2024-09-09

### Changed
* Refactor Test asynchronous test, support custom testSuite and manual call, migration and upgrade required
* PluginView parameter optimized to AttributedStringParameter
* Thread-safe processing of tempObject and allBoundObject

## [5.10.6] - 2024-09-04

### Added
* DrawerView adds draggingAreaBlock configuration and springAnimation configuration

## [5.10.5] - 2024-09-02

### Changed
* Optimize the method of folding the specified view effect when scrolling ScrollView

## [5.10.4] - 2024-09-02

### Added
* Added a method to achieve the effect of folding a specified view when scrolling ScrollView

## [5.10.3] - 2024-08-30

### Changed
* ViewModel renamed to ObservableViewModel, marked as deprecated, migration and upgrade required
* ViewProtocol marked as deprecated, SetupViewProtocol protocol added and related methods automatically called, migration and upgrade required
* EventViewProtocol general event view protocol added, optional use

## [5.10.2] - 2024-08-21

### Fixed
* Optimize autoMatchDimension to generate constraints as required to prevent conflicts with imageView automatic constraints
* autoMatchDimension supports dynamic switching on or off

## [5.10.1] - 2024-08-21

### Added
* UIView adds autoMatchDimension to handle issues such as fixed image height and adaptive width size layout

## [5.10.0] - 2024-08-19

### Added
* Added AnyChainable protocol to support chain calls, NSObject implements chainValue and chainBlock chain methods by default
* Added ArrayResultBuilder to implement functions similar to SwiftUI layout code
* SwiftUI added AttributedText rich text component, compatible with NSAttributedString display
* SwiftUI.Text supports multiple text splicing, compatible with ArrayResultBuilder
* Modified the parameter name of some SwiftUI tool methods from builder to content
* NSAttributedString supports multiple text splicing, compatible with ArrayResultBuilder
* UIView added arrangeSubviews and arrangeLayout methods, compatible with ArrayResultBuilder
* UILabel is compatible with font and textAlignment settings when clicking attributedText
* UITextView supports getting text style attributes of the click position, similar to UILabel

## [5.9.8] - 2024-08-14

### Changed
* Added Shortcut tool method, the original method is marked as deprecated and will be deleted in the next version, it is recommended to migrate gradually

## [5.9.7] - 2024-08-14

### Fixed
* Compatible with SwiftPackageIndex

## [5.9.6] - 2024-08-13

### Changed
* Compatible with Swift5.8 compilation

## [5.9.5] - 2024-08-06

### Changed
* UIButton adds contentCollapse property to quickly handle button shrinkage issues

## [5.9.4] - 2024-08-01

### Fixed
* Compatible with SwiftPackageIndex

## [5.9.3] - 2024-08-01

### Changed
* Added UITableView and UICollectionView methods for calculating height and frame
* Fixed the issue that WebView configuration reuseConfigurationBlock did not take effect

## [5.9.2] - 2024-07-19

### Changed
* Compatible with Xcode16, fix Cocoapods submodule compilation error
* Modify version number acquisition and comparison tool methods to support minor versions
* Modify Autoloader to load static methods and class methods starting with load by default

## [5.9.1] - 2024-07-12

### Changed
* Compatible with Xcode16, fix compilation errors
* SwiftUI component ViewIntrospect adds v18 when conditionally compiled in Xcode16, compatible with iOS18, and can be migrated and adapted
* Xcode16 conditionally compiled compatible with iOS18, adds setTabBarHidden method
* Optimize Optional.isNil and deepUnwrap methods, remove _OptionalProtocol
* Cocoapods submodule FWPlugin/Macros compatible with Xcode16

## [5.9.0] - 2024-07-09

### Changed
* Refactor the Language multi-language implementation to optimize performance
* Refactor ToastPlugin to support detail attributes and more custom attributes
* Refactor ToastView to support custom attributes such as position and attributedMessage
* Optimize the animation effect of TabbarController test cases
* Compatible with Swift Package Index

## [5.8.3] - 2024-07-03

### Fixed
* Fixed the issue of SDWebImage plugin rendering SDAnimatedImageView

## [5.8.2] - 2024-07-03

### Changed
* Added a new String detection link tool method
* Optimized the recursive search for subview method names
* layoutKey is compatible with accessibilityIdentifier
* Unified and optimized the test case navigation bar button style

## [5.8.1] - 2024-06-18

### Changed
* Added Later|Earlier related adaptation methods to the SwiftUI component ViewIntrospect, no need to hard-code each version number
* ToolbarView opens updateHeight and updateLayout methods to allow subclasses to override
* The setContentModeAspectFill method is renamed to scaleAspectFill

## [5.8.0] - 2024-06-12

### Changed
* Compatible with Xcode16, fix compilation errors
* Added autoScale parameter to AutoLayout layout extension method
* Disable autoScale automatic proportional scaling in all component layout codes of the framework
* Added PopupViewControllerProtocol popup controller protocol, supporting bottom and center popups, etc.
* Added RectCornerView to handle irregular rounded corners
* Refactored ViewTransition component, added edge parameter to support four directions, etc.
* Transition animation interactEnabled and interactScreenEdge interactive gestures can coexist

## [5.7.0] - 2024-06-05

### Added
* Added ViewProtocol view specification protocol, optional use
* Added SingletonProtocol for plug-in to find singleton
* Added setupBusiness business initialization hook to AppResponder
* Added ignorable return value to the method of setting navigation bar button
* Optimized framework class to no longer inherit NSObject when not necessary

## [5.6.6] - 2024-06-03

### Fixed
* Fixed compilation error when BUILD_LIBRARY_FOR_DISTRIBUTION is enabled
* Fixed the issue that some OC projects may conflict with the Swift.h bridging header file automatically generated by the framework

## [5.6.5] - 2024-06-03

### Fixed
* Fixed the issue that the ImageCropController custom toolbar button is invalid after clicking
* Added navigation bar childProxyEnabled switch to control the child status bar style

## [5.6.4] - 2024-05-31

### Changed
* Optimize the status bar style processing of ImagePreview components

## [5.6.3] - 2024-05-30

### Changed
* Optimize the status bar style processing of ImagePicker and ImagePreview components
* Optimize the status bar style processing of navigation controller child

## [5.6.2] - 2024-05-29

### Added
* Added ViewStyle and methods for defining and using common view styles

## [5.6.1] - 2024-05-27

### Changed
* setBorderView disables automatic layout scaling
* emptyInsets|toastInsets disables automatic layout scaling
* PasscodeView|WebView disables automatic layout scaling

## [5.6.0] - 2024-05-24

### Changed
* Added RequestViewControllerProtocol to quickly handle controller network requests
* BatchRequest, ChainRequest implement HTTPRequestProtocol protocol
* ViewModel moved to Module submodule, compatible with UIKit and SwiftUI
* UITableView shortcut initialization method adds tableViewConfiguration configuration handle
* Optimize the implementation of reloadData(completion:) method

## [5.5.1] - 2024-05-23

### Changed
* JSBridge supports finding the default DefaultBridge: development
* CacheKeychain supports custom Service names
* CacheUserDefaults is compatible with AnyArchivable protocol
* Remove the ArchivedValue attribute annotation, and the StoredValue attribute annotation is compatible with the AnyArchivable protocol

## [5.5.0] - 2024-05-20

### Added
* Added AnyArchivable protocol, which can quickly archive models and is compatible with Codable, CodableModel and JSONModel
* Archiver, UserDefault, Cache, Database, Keychain and other components are compatible with AnyArchivable protocol objects
* Added ArchivedValue attribute annotation to quickly archive and save AnyArchivable objects to UserDefaults
* Authorize and Toolkit related components support async|await coroutine calls
* Reconstruct the AuthorizeLocation component to support async|await coroutine calls

## [5.4.1] - 2024-05-17

### Changed
* Reconstruct the Authorize component, open the implementation class and add the Error parameter, which requires migration and adaptation.
* Added new biometric authorization plug-in AuthorizeBiometry, which needs to introduce the FWPlugin/Biometry submodule
* Fixed the problem of encoding nil when requestArgument nested Optional parameters in GET request

## [5.4.0] - 2024-05-14

### Changed
* Split the second-level sub-modules, CocoaPods can introduce the required sub-modules on demand
* Reconstruct the FWExtension submodule into FWPlugin, which is compatible with CocoaPods and SPM and needs to be migrated and adapted.
* Split rarely used Views and Services into FWPlugin/Module sub-modules, which can be introduced as needed
* Code reconstruction, remove all classification extension methods starting with fw_, only support Wrapper(fw.) method calling
* Reconstruct MulticastBlock to support priority and asynchronous calls
* Remove the didLayoutSubviews state from the controller life cycle
* ImagePlugin adds queryMemoryData option

## [5.3.2] - 2024-04-29

### Changed
* Reconstruct the FWExtension submodule to be compatible with CocoaPods and SPM. It is necessary to migrate the FWMacro related submodules to FWExtension.
* Integrate PrivacyInfo.xcprivacy file
* Fixed the issue that addColor mixed color does not take effect

## [5.3.1] - 2024-04-23

### Changed
* HTTPRequest method handle parameter supports Self, no type conversion is required
* HTTPRequest opens the contextAccessory attribute and can be customized
* When a BatchRequest request fails and stops, only other requests are canceled. Add the addRequest method.

## [5.3.0] - 2024-04-22

### Changed
* Complete implementation in pure Swift, removing FWObjC submodule
* Autoloader's autoload method is changed to Swift calling mechanism
* Reconstruct attribute KVO monitoring and add swift native observation method
* Reconstruct error capture ErrorManager, pure Swift implementation
* Mediator adds Delegate mode, AppResponder can be used optionally
* Reconstruct UIViewController life cycle monitoring and add ViewControllerLifecycleObservable protocol
* Added commonly used UIKit tool methods

### Migrate
1. Autoloader.autoload is no longer automatically called. It can be manually called at startup or inherited from AppResponder. Migration and upgrade are required.
2. The default lifecyleState of UIViewController is changed to nil. It needs to implement LifecycleObservable or enable monitoring to have a value. It needs to be migrated and upgraded.
3. Due to the Swift implementation mechanism, the associated properties can no longer be accessed during didDeinit of the UIViewController life cycle and need to be migrated and upgraded.
4. The API related to ExceptionManager error capture has been changed to ErrorManager, which needs to be migrated and upgraded.

## [5.2.1] - 2024-04-08

### Changed
* Fix Xcode compilation warnings, replace and remove deprecated methods
* Remove the obsolete method of obtaining the operator and modify the method of obtaining the network type
* Added Optional shortcut method, optimized CGFloat, etc. and no longer implement BasicType

## [5.2.0] - 2024-03-29

### Changed
* Added new macros such as MappedValueMacro to quickly write interface data models. FWMacro/Macros submodules need to be included.
* Remove KeyMapping mode related methods from CodableModel and JSONModel because they are complex to use and do not support inheritance
* MappedValue supports ignored configuration
* JSONModel annotation MappedValue is compatible with ValidatedValue

## [5.1.0] - 2024-03-21

### Changed
* Added KeyMappable protocol, compatible with CodableModel and JSONModel
* Added MappedValue attribute annotation, compatible with CodableModel and JSONModel
* Modify JSONModel. After implementing the KeyMappable protocol, it will no longer directly read and write memory. It is recommended to migrate gradually.
* Modify Router.Parameter synchronously. When inheriting, new properties must be marked with MappedValue.
* Codable supports parsing Any, Any dictionary and Any array type data
* Reconstruct BadgeView to unify and simplify the use of badgeOffset
* Modify the mirrorDictionary method to no longer filter attributes starting with underscores

## [5.0.3] - 2024-03-11

### Changed
* JSONModel is compatible with Xcode15.3
* Added delayPlaceholder option to the picture plug-in
* TabBarController adds imageInsets attribute
* Added global fast ceil extension method
* Added controller compatible with TabBar adaptation method when using safeArea layout
* Added new controller quick customization Toast|Empty plug-in method
* The routing openURL method parameter url is changed to Optional

## [5.0.2] - 2024-02-26

### Changed
* Controller navigationBarHeight is compatible with custom navigationBarHidden settings
* Fixed the problem of countLabel not being updated due to position change of customBlock in image preview plug-in

## [5.0.1] - 2024-02-26

### Changed
* Added RoundedCornerView to handle semi-circle corner problem without frame
* Modify NavigationStyle to get the current status when it is not set
* PopupMenu supports specifying container views. Modify showsMaskView to hide maskView. Migration testing is required.
* Optimize Database performance and increase ModelFields parsing cache

## [5.0.0] - 2024-02-22

### Added
* After two years of reconstruction, the Swift version is released, compatible with iOS13+ and no longer compatible with OC
* Supports advanced features such as Swift coroutine async, await, property annotation propertyWrapper, etc.
* Completely replaceable UI plug-in management for easy project customization
* Replaceable picture library and network request layer, with built-in extensions compatible with SDWebImage, Alamofire, etc.
* Several years of accumulation of online projects, two years of painstaking effort in refactoring the Swift version, everything you want is available here
* Thanks to ChatGPT, thanks to Codeium, and thanks to the authors of all open source libraries used
* Finally, thank myself. It’s really not easy to persevere through countless days and nights.

### Migrate
1. Autoloader only loads static class methods by default and needs to be migrated and upgraded.
2. The Router routing binding method API has changed and needs to be migrated and upgraded.
3. JSBridge binding method API has changed and needs to be migrated and upgraded.
4. HTTPRequest network request API has changed and needs to be migrated and upgraded.
5. Other compilation errors need to be fixed using the new API and tested to see if the relevant functions are normal.
6. To use the sample code, please refer to the Example project

## [4.18.3] - 2024-03-12

### Fixed
* Compatible with Xcode15.3, fix Archive failure problem

## [4.18.2] - 2023-10-27

### Added
* UISwitch supports custom offTintColor

## [4.18.1] - 2023-10-13

### Added
* Fixed the issue of incomplete text display when UILabel customizes contentInset.
* BannerView supports NSAttributedString, adding new spacing settings and other attributes

## [4.18.0] - 2023-09-19

### Added
* Compatible with Xcode15, iOS17
* Synchronize SwiftUI component Introspect to the latest version
* Optimize SwiftUI refresh and add plug-in usage

## [4.17.5] - 2023-09-18

### Fixed
* Fixed the problem that the QR code scanning component may be called back multiple times in succession when using it.

## [4.17.4] - 2023-09-10

### Changed
* Image plug-in adds new methods to read local cache and clear all caches
* Fixed the issue of occasional transition animation exception when the ZoomImageView image cache exists

## [4.17.3] - 2023-09-08

### Fixed
* Fix the problem that the callback order of the system image selector is incorrect and multiple callbacks are triggered
* Optimized image compression decrement rate default value is 0.3

## [4.17.2] - 2023-09-07

### Changed
* Add UICollectionView drag sorting method
* Added an option to always perform animation when modifying progress in Lottie view

## [4.17.1] - 2023-09-06

### Changed
* Keyboard management adds keyboardDistanceBlock custom handle
* Added batch compression image processing method in the background
* The system image selector supports custom cropping when selecting a single image
* Optimize the system image selector to close the interface and call back after processing the image
* Added shortcut to create NSParagraphStyle method
* UITextView added quick setting lineHeight method
* Modify the origin meaning of cursorRect to offset

## [4.17.0] - 2023-09-01

### Added
* Router routing supports *id format parameters
* PopupMenu adds custom style attributes
* NSAttributedString shortcut initialization method adds attributes parameter
* Added layoutFrame calculation method for UICollectionView
* RefreshPlugin adds a customBlock parameter, which needs to be adapted
* RefreshView supports custom height, remove the original UIScrollView plug-in height setting, need to adapt
* The picture selector adds a switch to enable the navigation bar property
* Modify the filter method behavior of MulticastDelegate, need to adapt

## [4.16.2] - 2023-08-25

### Changed
* Modifying autoScale is only effective for the current view, no longer looking for the parent view (unstable)
* Compatible with loadingFinished and setting before reloadData can also take effect

### Fixed
* Fixed the problem that finishedView was not refreshed when isDataEmpty changed but finished did not change
* Fix the problem that the offset and collapse methods are not automatically scaled and reversed when the automatic layout is scaled

### Migrate
1. If auto scaling layout is enabled, check whether there is a view with autoScale set separately and adapt it
2. If auto scaling layout is enabled, check the collapse and offset methods with parameters in LayoutChain, and change to automatic scaling
3. If auto scaling layout is enabled and the layout constraint requires a fixed value, use the constant method of LayoutChain

## [4.16.1] - 2023-08-24

### Changed
* By default, only the QR code is enabled for scanning the code, and you can specify the bar code, etc.
* Scan code to add zoom gesture handle
* The pull-up add-on does not display finishedView if the data is empty
* The pull-up append plugin padding supports negative numbers

## [4.16.0] - 2023-08-22

### Added
* Added Swift version CachedValue annotation
* Added Swift version table and collection Cell simple exposure scheme
* Added Swift version parsing server response time method
* Added shortcut method to start background task
* Refactor and synchronize QR code scanning component ScanView
* Added maskViewColor property to PopupMenu
* SegmentedControl adds a custom layer handle
* Added a tool method for judging network request error types
* The custom Sheet component supports hiding the cancel button

## [4.15.0] - 2023-07-28

### Added
* Added database migration protocol method
* Added currentDotSize setting to PageControl
* MulticastBlock adds the main thread call attribute
* Added Button packaging method in SwiftUI
* Refactor the NumberFormatter constructor

## [4.14.1] - 2023-06-30

### Changed
* The method of playing system sound files supports completion callback
* Optimize SwiftUI display ToastPlugin related methods
* Fix SwiftUI occasional ToastPlugin re-display problem when returning to the interface

## [4.14.0] - 2023-06-28

### Added
* Added AutoLayout batch layout method, layout conflict debugging and optimization
* EmptyPlugin adds a method to get the view being displayed
* ToastPlugin adds a method to get the view being displayed
* Little red dot BadgeView supports custom size and offset
* WebView supports window.close to close the interface by default
* Optimize whether the SwiftUI control can continue to append
* Fix the problem that the occasional style does not take effect after customizing the customBlock on the empty interface

## [4.13.0] - 2023-06-26

### Added
* EmptyPlugin supports NSAttributedString parameters
* Added shortcut to create NSAttributedString method
* Added methods for calculating font height and calculating baselineOffset

## [4.12.1] - 2023-06-21

### Changed
* Remove the barTransitionNeedsUpdate method, the framework handles it automatically
* Remove global autoFlat switch, migrate to UIFont and UIView configuration
* Fix the problem that the SegmentedControl text is not centered in some cases

## [4.12.0] - 2023-06-16

### Added
* SwiftUI adds commonly used relative layout methods
* AutoLayout supports switching to disable multiple layout constraints
* JSONModel supports underscore and camel case conversion
* Newly added global proportional scaling pixel rounding switch configuration
* Fix the loss of precision of JSONModel large number conversion to string on iOS15 and above

## [4.11.0] - 2023-05-31

### Added
* Add background color and other configurations for the SegmentedControl component
* Added finishedBlock property in the pull-up view
* Add global flat shortcut method, remove pointHalf constant
* LayoutChain supports to collapse multiple constraints at the same time
* Fixed the occasional DynamicLayout crash in iOS14
* Fix open mailto, sms jump link problem

## [4.10.1] - 2023-04-23

### Fixed
* Fixed the problem that the polling request was not completely canceled when it was stopped
* A new isCancelled handle is added to the network request to handle the scene where the request is cancelled.

## [4.10.0] - 2023-04-21

### Added
* Added SwiftUI shortcut binding List, ScrollView refresh and append, empty interface components
* New refresh component showsFinishedView configures whether to display the finished view
* Modify the global static color configuration method to handle configuration
* Modify the parameters of the SwiftUI input box auto-focus method
* Unify ViewControllerState and ViewState as ViewState enumeration
* Synchronize the latest code of the Introspect component, compatible with iOS16
* Fix SwiftUI processing List, ScrollView compatible components bug

## [4.9.0] - 2023-04-20

### Added
* Added SwiftUI to handle List and ScrollView compatible components
* Added SwiftUI to handle Divider compatible components
* Added SwiftUI input box configuration handle component
* Added SwiftUI button highlighting and disabling style components
* Modify SwiftUI's ViewModel component as a protocol
* Fix SwiftUI refresh component, border rounded method bug

## [4.8.5] - 2023-04-17

### Added
* Added shortcut processing automatic layout contraction method
* Added view batch automatic layout method

## [4.8.4] - 2023-04-15

### Changed
* Routing supports strict mode, it responds only when it matches exactly, and it is disabled by default
* Optimize the request retry method, support -1 unlimited times
* Optimize SwiftUI font method, same as UIKit method
* Fixed keyboard management touchResign need to click twice to trigger the button event problem

## [4.8.3] - 2023-04-08

### Added
* Added the barTransitionNeedsUpdate method to handle the scene where the transition style of the navigation bar changes

## [4.8.2] - 2023-04-08

### Changed
* PagingView supports reuse, fix the problem that reloadData does not reset contentOffset
* The controller adds allowsBarAppearance to control whether to modify the navigation bar style
* Added dismissingScaleEnabled configuration to the ImagePreview plug-in to fix the occasional flickering problem
* Refactor the global fontBlock, automatically take the relative size according to the configuration
* ToolbarView supports irregular shape buttons

## [4.8.1] - 2023-03-31

### Added
* StateView is compatible with Xcode14.3
* Compatible with iPhone14 series mobile phones
* ToolbarTitleView supports configuring the minimum distance on the left

## [4.8.0] - 2023-03-30

### Added
* ToolbarView now supports configuring left alignment and spacing.
* ToolbarTitleView now supports configuring left alignment and spacing.

## [4.7.4] - 2023-03-18

### Added
* Added a method to dynamically calculate the width and height of the AutoLayout layout view
* DynamicLayout method adds NS_NOESCAPE flag
* Added scrollViewInsets padding configuration for DrawerView
* AttributedLabel compatible with iOS15+ system comes with strikethrough

## [4.7.3] - 2023-03-13

### Changed
* Refactor the method name of obtaining and selecting the TabBar specified controller
* Optimize DrawerView not automatically return to the top when it is in non-scrollViewPositions

## [4.7.2] - 2023-03-11

### Added
* Refactor DrawerView to support multiple modes
* Added safeJSON fast conversion JSON method
* Added method to get TabBar root controller

## [4.7.1] - 2023-03-09

### Added
* Added merge method to JSONModel
* The ParameterModel.toDictionary method automatically filters attributes starting with an underscore
* UIButton and click gesture support custom highlight state, disabled state handle
* Fixed the problem that calling setPosition does not take effect when the DrawerView is in a special scene

## [4.7.0] - 2023-03-07

### Added
* Added Swift version ParameterModel component
* Added scrollViewFilter configuration for DrawerView
* NotificationManager adds delegate configuration

## [4.6.0] - 2023-02-20

### Added
* Added Analyzer analysis component
* Added Validator Swift verification component
* Added MulticastBlock multi-handle proxy component
* Added Optional commonly used extension methods
* Refactor the Swift Annotation component
* Refactoring Request component synchronous request
* Remove the NetworkMocker component

## [4.5.0] - 2023-02-09

### Added
* The Request component supports synchronous requests
* ModuleBundle supports loading module colors
* AttributedLabel supports strikethrough style

## [4.4.3] - 2023-02-07

### Fixed
* Fix the problem that the DateFormatter format is incorrect when the mobile phone system is in 12-hour format

## [4.4.2] - 2023-01-18

### Fixed
* Fixed the problem that sliding the top navigation bar quickly will trigger the bottom navigation bar to slide back after the navigation bar interception is enabled

## [4.4.1] - 2023-01-06

### Changed
* Optimize the implementation of the pull-down refresh plugin indicatorPadding
* Fix Swift Package Manager minimum compatible with lottie-ios 4.0

## [4.4.0] - 2022-12-07

### Changed
* Upgrade the Lottie component to be compatible with lottie-ios 4.0
* Rename LottieView to LottiePluginView

## [4.3.3] - 2022-12-05

### Changed
* AlertController supports modifying animationType
* AlertController supports clicking Action without closing the interface

## [4.3.2] - 2022-11-25

### Changed
* Added box style and padding properties to SegmentedControl
* Optimize DynamicLayout to support Swift generics

## [4.3.1] - 2022-10-27

### Added
* Waterfall layout supports Header hover effect

## [4.3.0] - 2022-10-19

### Changed
* Added Swift version model parsing component JSONModel
* Modify the default value of the Swift version API method
* Optimize the skeleton screen view, no need to manually add animation views
* Rewrite all test cases for Swift implementation

## [4.2.1] - 2022-10-10

### Added
* Added data callback parameter when the picture plugin downloads pictures
* Support custom global mainWindow properties
* Added UIView sorting subview hierarchy method
* View controller added toastInAncestor property

## [4.2.0] - 2022-10-08

### Changed
* Globally compatible with iPad
* Refactor Swift version Swizzle related API methods
* Added a common method of proportional scaling screen adaptation
* Modify the autoScale property to take effect for the current view and its subviews

## [4.1.2] - 2022-09-22

### Fixed
* Optimize the controller to get the bottom bar height algorithm
* Optimized the Failed state processing of transition gestures

## [4.1.1] - 2022-09-20

### Fixed
* Fix method name from spelling error
* Added the method of parsing the startup URL
* Optimize the precision problem of pull-up and appending floating-point numbers

## [4.1.0] - 2022-09-13

### Changed
* Refactor AutoLayout to support priority parameter
* Added WebView to allow opening SchemeURL configuration
* Added List lookup UICollectionView method
* Compatible with Xcode14, compatible with iOS16

## [4.0.2] - 2022-09-07

### Added
* Click gesture support to monitor highlighted state
* Optimized BannerView index change callback method

## [4.0.1] - 2022-09-06

### Added
* Added pop to specified workflow method
* Added color mixing method
* Added playback touch feedback method

## [4.0.0] - 2022-08-28

### Changed
* Merge FWApplication into this framework, new version
* Refactored some API methods and remove uncommon functions
* Refactor the directory structure and unify Pod submodules

## [3.8.1] - 2022-08-10

### Changed
* NSAttributedString supports click to highlight URL
* The default waiting time for the automatic completion of the modified input box is 0.5 seconds

## [3.8.0] - 2022-08-02

### Added
* Added iOS13+ to enable new navigation bar style global switch
* Added method to find subviews subviews according to tag
* Added the safe reading method of array safe subscript
* Added method to remove all click block events
* Removed colorWithString from color name init method

## [3.7.0] - 2022-07-27

### Changed
* Modify the Swift version State to StateObject

## [3.6.1] - 2022-07-22

### Fixed
* Fixed the problem of opening failure when route parsing URL with port
* Support saving custom deviceToken strings

## [3.6.0] - 2022-07-11

### Changed
* Refactoring the NavigationOptions routing solution
* Controller close method supports options parameter
* Refactor the Navigation navigation tool method

## [3.5.1] - 2022-07-06

### Added
* Added completion callback for quick open URL method
* Route userInfo supports custom routerHandler

## [3.5.0] - 2022-07-04

### Added
* Open controller, workflow and other methods support completion callback
* Added FW.synchronized to add mutex lock method
* Migrate some common tools and methods to FWFramework

## [3.4.0] - 2022-06-26

### Changed
* Refactored OC version classification API, changed to fw_ prefix, removed Wrapper
* Optimize the keyboard management jump input box scheme
* Optimized to get safeAreaInsets even when keyWindow does not exist

## [3.3.1] - 2022-06-15

### Changed
* Route support lookup DefaultRouter: format method
* Keyboard management support to hide default previous and next buttons
* Fix the calculation problem when the countdown method is running in the background
* Fix the abnormal problems of the theme colorForStyle and other methods

## [3.3.0] - 2022-06-11

### Added
* New configuration management and configuration template protocol

## [3.2.1] - 2022-06-08

### Added
* Refactor Router routing component method name
* Added UIKit input component tool method

## [3.2.0] - 2022-05-27

### Added
* Refactor AutoLayout layout syntax to be more beautiful
* Added UITableView and UICollectionView custom cache methods

## [3.1.0] - 2022-05-26

### Added
* Refactor Swift version Api method
* Added FW global method, you can customize the call name
* Refactored some components and added several functions
* This version is not compatible with the previous version, the code must be migrated

## [3.0.0] - 2022-04-29

### Added
* Brand new version, using .fw. calling method
* Customizable .fw. for any call name
* Refactored some components and added several functions
* This version is not compatible with the previous version, the code must be migrated

## [2.4.0] - 2022-02-12

### Added
* Added proportional adaptation to FWRelative related methods
* FWLayoutChain opens the view attribute for easy expansion

## [2.3.1] - 2022-02-07

### Added
* FWTest supports asynchronous testing

### Changed
* Modify the FWRouterProtocol method to remove the fw prefix
* Modify FWLog, support group and userInfo

## [2.3.0] - 2022-01-20

### Added
* Added FWABTest class for AB testing
* UILabel supports quick setting of line height and attribute style

## [2.2.1] - 2022-01-13

### Fixed
* Migrate UIDevice.fwDeviceIDFA to Tracking submodule and fix the problem that the value is nil

## [2.2.0] - 2022-01-12

### Added
* Added FWEncode compatible Swift extension method
* Added FWFoundation compatible Swift extension method

### Changed
* Modify the debug information method to debugDescription

## [2.1.0] - 2021-12-31

### Added
* Refactored Pod sub-module, split OC and Swift code
* Support Swift Package Manager
* Added String multi-language extension method

## [2.0.0] - 2021-12-09

### Changed
* Split out FWApplication to maintain a separate warehouse
* Refactor the implementation of FWFramework

## [1.9.4] - 2021-11-22

### Fixed
* Fix the compatibility problem of navigation bar style when compiling with Xcode13

## [1.9.3] - 2021-08-28

### Added
* FWAttributedLabel supports custom view when the tail is truncated
* UIButton supports quick setting of alpha when clicked and highlighted

## [1.9.2] - 2021-08-20

### Changed
* UITextView supports vertical center layout and placeholder custom margins
* Optimize UISearchBar center position algorithm

## [1.9.0] - 2021-08-16

### Added
* Added FWAssetManager image management component
* Added FWAudioPlayer audio player component
* Added FWVideoPlayer video playback component
* The input box supports custom cursor color and cursor size
* The navigation bar style is compatible with iOS15, Xcode13 takes effect

### Changed
* Refactored FWPhotoBrowser to support asynchronous loading of pictures

## [1.8.2] - 2021-08-11

### Added
* Added a method to determine whether the view skeleton screen is displaying
* Toast plug-in supports setting the vertical offset, the default is -30

## [1.8.1] - 2021-08-07

### Fixed
* Fixed the bug that the navigation bar cannot be hidden when Appearance is set and then hidden

## [1.8.0] - 2021-08-06

### Added
* Added custom navigation bar FWNavigationView component
* New controller popover controller shortcut method

### Changed
* Modify the minimum compatible iOS version to iOS10
* Refactored the implementation of FWNavigationStyle, compatible with custom navigation bars
* Refactored FWPopupMenuDelegate method name
* Refactored UIViewController navigation bar height acquisition method
* Modify the web container JS bridge call to support callback when there is an error

## [1.7.4] - 2021-07-14

### Changed
* Optimize system JSON decoding because of special characters error 3840 problem
* Optimize the query parameter parsing problem when the URL contains Chinese

## [1.7.3] - 2021-07-08

### Added
* FWEmptyPlugin added fwEmptyInsets outer spacing property setting
* FWToastPlugin added fwToastInsets outer spacing property setting

## [1.7.2] - 2021-07-02

### Fixed
* Optimize FWDynamicLayout caching mechanism, fix iOS15 height calculation bug

## [1.7.1] - 2021-07-01

### Changed
* Refactored FWTheme theme color processing, compatible with theme switching below iOS13

## [1.7.0] - 2021-06-29

### Added
* Added FWIcon icon font class, supporting loading by name

### Changed
* Refactored FWTheme theme management class, optimized method names, and avoided memory leaks

## [1.6.6] - 2021-06-25

### Changed
* Optimize the problem of multiple calls when fwDismissBlock is pulled down, which needs to be triggered manually

## [1.6.5] - 2021-06-24

### Changed
* FWWebViewJsBridge supports APP and JS double-ended bridge error callback
* FWPhotoBrowser supports dismiss to the specified location

## [1.6.4] - 2021-06-23

### Fixed
* Fix the nullable declaration of UIKit Component

## [1.6.3] - 2021-06-17

### Changed
* Rename the FWImageName method to FWImageNamed
* FWModuleBundle uses the fwImageNamed image loading method

## [1.6.2] - 2021-06-16

### Added
* iOS13+ supports SVG image format by default
* FWImage newly added decoding option configuration, compatible with SDWebImage
* UITableView added fwPerformUpdates method

## [1.6.1] - 2021-06-09

### Added
* Added fade transition animation method

### Fixed
* Fix the problem that the index of FWSegmentedControl is not normal when it jumps to it for the first time
* Fix the problem of triggering the refresh plug-in at the same time, and the abnormal progress callback when the content is short

## [1.6.0] - 2021-06-08

### Added
* Added FWMulticastDelegate multi-agent forwarding class

### Changed
* Refactor the project directory structure and use the recommended method of pod
* Rewrite the FWPromise class to support OC and Swift calls
* Refactor FWLog method name

### Fixed
* Fixed occasional bugs in FWRefreshPlugin and FWWebImage plugins

## [1.5.6] - 2021-05-31

### Changed
* Fixed the issue of FWAnimatedTransition referencing presentationController circularly
* FWPhotoBrowserDelegate added callback methods when displaying and hiding

## [1.5.5] - 2021-05-25

### Added
* Added safe conversion method for fwAs commonly used types in Swift

### Changed
* Modify the FWRouterContext attribute name and declaration

### Fixed
* Fix the problem that fwTouchEventInterval does not take effect

## [1.5.4] - 2021-05-24

### Added
* FWAutoLayout increases the layout method of view aspect ratio
* FWRouterContext adds mergeParameters method
* UIApplication adds a new calling system sharing method

## [1.5.3] - 2021-05-20

### Changed
* UITextField keyboard management supports UIScrollView scrolling
* Optimize the accuracy of NSDate.fwCurrentTime

## [1.5.2] - 2021-05-18

### Changed
* Modify FWModuleProtocol.setup as an optional method

### Fixed
* Fix the nullable declaration of FWAppDelegate method

## [1.5.1] - 2021-05-06

### Changed
* Optimize the animation effect of the empty interface plug-in, and automatically remove the Overlay view

## [1.5.0] - 2021-04-30

### Changed
* Refactored log plug-in and image plug-in
* Refactored pop-up plug-in, empty interface plug-in, toast plug-in, refresh plug-in

## [1.4.3] - 2021-04-27

### Changed
* FWRouter removes the isObjectURL judgment method, compatible with scheme:path format URL
* FWEmptyPluginConfig adds customBlock configuration

## [1.4.2] - 2021-04-25

### Fixed
* Fix FWRouter routing parameter parsing problem, code optimization

## [1.4.1] - 2021-04-23

### Changed
* UIScrollView supports fwOverlayView view
* UIScrollView supports displaying an empty interface, modify the FWEmptyViewDelegate method
* Added new empty interface gradient animation configuration, which is enabled by default

## [1.4.0] - 2021-04-22

### Changed
* Refactor the implementation of FWEmptyPlugin to support scroll view and default text
* Refactored FWToastPlugin to support default text
* FWViewController added renderState state rendering method
* FWNavigationBarAppearance supports theme colors and theme pictures

## [1.3.7] - 2021-04-21

### Fixed
* Fix the problem of FWRouter routing parameter parsing

## [1.3.6] - 2021-04-19

### Added
* Add a method to get the life cycle status of ViewController

### Changed
* UINavigationBar and UITabBar support quick setting of theme background images

## [1.3.5] - 2021-04-15

### Changed
* Optimize FWTabBarController, the performance is consistent with UITabBarController

## [1.3.4] - 2021-04-13

### Changed
* Refactor FWWebViewDelegate method

## [1.3.3] - 2021-04-13

### Changed
* Refactor the implementation of FWWebViewController and extract FWWebView
* FWRouter, FWMediator support preset methods

## [1.3.2] - 2021-04-01

### Changed
* FWTabBarController supports loading network pictures
* Optimize the animation effect of FWDrawerView

## [1.3.1] - 2021-03-30

### Changed
* FWPagingView supports pull-down refresh of sub-pages when hovering

## [1.3.0] - 2021-03-28

### Added
* Added FWOAuth2Manager network authorization class

### Changed
* Refactored FWImagePlugin plug-in, refactored FWWebImage, and added option configuration
* Optimize FWEncode to handle URL encoding

## [1.2.1] - 2021-03-22

### Changed
* Refactor the FWRouter routing class
* Refactor FWLoader to automatically load classes
* Refactored FWPluginManager plugin management class

## [1.2.0] - 2021-03-19

### Added
* Added FWSignatureView view component

### Changed
* Optimize the controller fwTopBarHeight algorithm
* Added FWQrcodeScanView configuration parameters

## [1.1.1] - 2021-03-14

### Changed
* Optimize FWRouter empty string handling
* Refactor the design and implementation of FWView, support Delegate and Block
* Add FWNetworkUtils.isRequestError error judgment method

## [1.1.0] - 2021-03-10

### Changed
* Optimize framework OC attribute declaration, Swift call is more friendly
* FWAutoloader was renamed to FWLoader
* Code optimization, Example project optimization

## [1.0.6] - 2021-02-05

### Added
* Add RSA encryption and decryption, signature verification algorithm

### Changed
* FWPasscodeView added configuration parameters

## [1.0.5] - 2021-02-02

### Changed
* FWAlertController supports custom textField keyboard management

## [1.0.4] - 2021-02-01

### Added
* Added FWPasscodeView component

## [1.0.3] - 2021-01-22

### Changed
* FWTheme and FWImage classes support bundle loading
* FWPhotoBrowser supports UIImage parameters
* Example project refactoring, modularization and continuous integration example

## [1.0.2] - 2021-01-15

### Added
* Add FWAutoloader automatic loading class

### Changed
* Optimize FWWebViewController button handling

## [1.0.1] - 2021-01-11

### Changed
* Optimize screen adaptation constants, see FWAdaptive for details

## [1.0.0] - 2021-01-05

### Added
* After two years of precipitation, version 1.0.0 was released
