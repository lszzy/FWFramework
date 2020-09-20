/*!
 @header     UIApplication+FWFramework.h
 @indexgroup FWFramework
 @brief      UIApplication+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/17
 */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIApplication+FWFramework
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

// 是否是盗版(不是从AppStore安装)
+ (BOOL)fwIsPirated;

// 是否是Testflight版本
+ (BOOL)fwIsTestflight;

#pragma mark - URL

// 打开外部浏览器，支持NSString|NSURL
+ (void)fwOpenSafari:(id)url;

// 打开应用设置
+ (void)fwOpenAppSettings;

// 打开应用内评价，10.3+生效，一年内最多3次
+ (void)fwRequestAppReview;

// 打开AppStore评论页
+ (void)fwOpenAppReview:(NSString *)appId;

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
