/*!
 @header     NSBundle+FWFramework.h
 @indexgroup FWFramework
 @brief      NSBundle分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import <Foundation/Foundation.h>

// 读取本地化字符串
#define FWLocalizedString( key, ... ) \
    [[NSBundle mainBundle] localizedStringForKey:key value:@"" table:fw_macro_default(nil, ##__VA_ARGS__)]

// 本地化语言改变通知，object为本地化语言名称
extern NSString *const FWLocalizedLanguageChangedNotification;

/*!
 @brief NSBundle分类，默认只处理mainBundle语言。如果需要处理三方SDK和系统组件语言，详见Custom相关方法
 @discussion 如果系统组件无法正确显示语言，需Info.plist设置CFBundleAllowMixedLocalizations为YES，从而允许应用程序获取框架库内语言。
 如果key为nil，value为nil，返回空串；key为nil，value非nil，返回value；如果key不存在，value为nil或空，返回key；如果key不存在，value非空，返回value
 当前使用修改bundle类方式实现，也可以使用动态替换localizedStringForKey方法来实现，但需注意此方式的性能
 */
@interface NSBundle (FWFramework)

// 读取系统语言
+ (NSString *)fwSystemLanguage;

// 读取自定义本地化语言，未自定义时返回空
+ (NSString *)fwLocalizedLanguage;

// 设置自定义本地化语言，为空时清空自定义，会触发通知。默认只处理mainBundle语言，如果需要处理三方SDK和系统组件语言，详见Custom相关方法
+ (void)fwSetLocalizedLanguage:(NSString *)language;

// 加载当前本地化语言，一般launch或load中调用，仅生效一次，会触发通知。如果未设置自定义语言，不处理
+ (void)fwLoadLocalizedLanguage;

// 设置自定义检测句柄，返回YES代表当前bundle需要加载本地化语言。用于处理三方SDK和系统组件等
+ (void)fwSetCustomDetectorBlock:(BOOL (^)(NSBundle *bundle))detector;

// 设置自定义查找句柄，返回当前bundle实际使用语言，language为nil表示清空自定义。用于处理三方SDK和系统组件等
+ (void)fwSetCustomFinderBlock:(NSString * (^)(NSBundle *bundle, NSString *language))finder;

@end
