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

/*!
 @brief UIApplication+FWFramework
 */
@interface UIApplication (FWFramework)

#pragma mark - App

// 读取应用信息字典
+ (id)fwAppInfo:(NSString *)key;

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

#pragma mark - URL

// 打开URL
+ (void)fwOpenURL:(NSURL *)url;

// 打开URL，完成时回调
+ (void)fwOpenURL:(NSURL *)url completionHandler:(void (^)(BOOL success))completion;

// 打开应用设置
+ (void)fwOpenSettings;

// 打开AppStore下载页
+ (void)fwOpenStore:(NSString *)appId;

// 打开AppStore评论页
+ (void)fwOpenReview:(NSString *)appId;

// 打开浏览器
+ (void)fwOpenSafari:(NSString *)url;

// 发送邮件
+ (void)fwSendEmail:(NSString *)email;

// 发送短信
+ (void)fwSendSms:(NSString *)phone;

// 打电话
+ (void)fwMakeCall:(NSString *)phone;

// 播放音频文件
+ (AVAudioPlayer *)fwPlaySound:(NSString *)file;

// 播放内置声音文件
+ (SystemSoundID)fwPlayAlert:(NSString *)file;

// 停止播放内置声音文件
+ (void)fwStopAlert:(SystemSoundID)soundId;

// 中文语音朗读文字
+ (void)fwReadText:(NSString *)text;

@end
