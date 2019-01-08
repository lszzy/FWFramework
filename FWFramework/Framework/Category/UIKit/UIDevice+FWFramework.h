/*!
 @header     UIDevice+FWFramework.h
 @indexgroup FWFramework
 @brief      UIDevice+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <UIKit/UIKit.h>

#pragma mark - Macro

// 是否是模拟器
#if TARGET_OS_SIMULATOR
    #define FW_SIMULATOR 1
#else
    #define FW_SIMULATOR 0
#endif

// 是否是iPhone设备
#define FWIsIphone \
    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? YES : NO)

// 是否是iPad设备
#define FWIsIpad \
    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO)

// iOS系统版本
#define FWIosVersion \
    [[[UIDevice currentDevice] systemVersion] floatValue]

// 是否是指定iOS主版本
#define FWIsIos( version ) \
    (FWIosVersion >= version && FWIosVersion < (version + 1) ? YES : NO)

// 是否是大于等于指定iOS主版本
#define FWIsIosLater( version ) \
    (FWIosVersion >= version ? YES : NO)

// 界面是否横屏
#define FWIsInterfaceLandscape \
    UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])

// 设备是否横屏，无论支不支持横屏
#define FWIsDeviceLandscape \
    UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])

/*!
 @brief UIDevice+FWFramework
 */
@interface UIDevice (FWFramework)

#pragma mark - Judge

// 是否是iPhone
+ (BOOL)fwIsIphone;

// 是否是iPad
+ (BOOL)fwIsIpad;

// 是否是模拟器
+ (BOOL)fwIsSimulator;

// 是否越狱
+ (BOOL)fwIsJailbroken;

#pragma mark - Landscape

// 界面是否横屏
+ (BOOL)fwIsInterfaceLandscape;

// 设备是否横屏，无论支不支持横屏
+ (BOOL)fwIsDeviceLandscape;

#pragma mark - Version

// iOS系统版本
+ (float)fwIosVersion;

// 是否是指定iOS主版本
+ (BOOL)fwIsIos:(NSInteger)version;

// 是否是大于等于指定iOS主版本
+ (BOOL)fwIsIosLater:(NSInteger)version;

#pragma mark - Model

// 设备模型，格式："iPhone6,1"
+ (NSString *)fwDeviceModel;

// 设备UUID，应用删除后会改变，可通过keychain持久化
+ (NSString *)fwDeviceUUID;

#pragma mark - Token

// 设置设备token，格式化并保存
+ (void)fwSetDeviceToken:(NSData *)tokenData;

// 获取设备Token格式化后的字符串
+ (NSString *)fwDeviceToken;

#pragma mark - Network

// 本地IP地址
+ (NSString *)fwIpAddress;

// 本地主机名称
+ (NSString *)fwHostName;

@end
