# Changelog

## [2.0.0] - 2021-10-01

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