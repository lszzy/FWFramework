# Changelog

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
