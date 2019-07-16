/*!
 @header     UIApplication+FWFramework.h
 @indexgroup FWFramework
 @brief      UIApplication+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/17
 */

#import <UIKit/UIKit.h>
#import "UIApplication+FWAppearance.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

// 是否是调试模式
#ifdef DEBUG
    #define FWIsDebug YES
#else
    #define FWIsDebug NO
#endif

/*!
 @brief UIApplication+FWFramework
 @discussion 注意Info.plist文件URL SCHEME配置项只影响canOpenUrl方法，不影响openUrl。微信返回app就是获取sourceUrl，直接openUrl实现。因为跳转微信的时候，来源app肯定已打开过，可以跳转，只要不检查canOpenUrl，就可以跳转回app
 */
@interface UIApplication (FWFramework)

#pragma mark - App

// 读取应用信息字典
+ (nullable id)fwAppInfo:(NSString *)key;

// 读取应用名称
+ (NSString *)fwAppName;

// 读取应用显示名称，未配置时读取名称
+ (NSString *)fwAppDisplayName;

// 读取应用主版本号，示例：1.0.0
+ (NSString *)fwAppVersion;

// 读取应用构建版本号，示例：1.0.0.1
+ (NSString *)fwAppBuildVersion;

// 读取应用标识
+ (NSString *)fwAppIdentifier;

#pragma mark - Debug

// 是否是调试模式
+ (BOOL)fwIsDebug;

// 是否是盗版(不是从AppStore安装)
+ (BOOL)fwIsPirated;

// 是否是Testflight版本
+ (BOOL)fwIsTestflight;

#pragma mark - URL

// 能否打开URL，需配置对应URL SCHEME到Info.plist才能返回YES
+ (BOOL)fwCanOpenURL:(NSURL *)url;

// 打开URL，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
+ (void)fwOpenURL:(NSURL *)url;

// 打开URL，完成时回调，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
+ (void)fwOpenURL:(NSURL *)url completionHandler:(nullable void (^)(BOOL success))completion;

// 打开浏览器
+ (void)fwOpenSafari:(NSString *)url;

// 打开应用设置
+ (void)fwOpenAppSettings;

// 打开应用内评价，10.3+生效，一年内最多3次
+ (void)fwRequestAppReview;

// 打开AppStore下载页
+ (void)fwOpenAppStore:(NSString *)appId;

// 打开AppStore评论页
+ (void)fwOpenAppReview:(NSString *)appId;

// 判断URL是否是App Store链接
+ (BOOL)fwIsAppStoreURL:(NSURL *)url;

// 发送邮件
+ (void)fwSendEmail:(NSString *)email;

// 发送短信
+ (void)fwSendSms:(NSString *)phone;

// 打电话
+ (void)fwMakeCall:(NSString *)phone;

// 播放音频文件
+ (nullable AVAudioPlayer *)fwPlaySound:(NSString *)file;

// 播放内置声音文件
+ (SystemSoundID)fwPlayAlert:(NSString *)file;

// 停止播放内置声音文件
+ (void)fwStopAlert:(SystemSoundID)soundId;

// 中文语音朗读文字
+ (void)fwReadText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
