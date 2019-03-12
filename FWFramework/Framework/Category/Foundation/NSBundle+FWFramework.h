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

/*!
 @brief NSBundle分类
 @discussion 如果系统组件无法正确显示语言，需Info.plist设置CFBundleAllowMixedLocalizations为YES，从而允许应用程序获取框架库内语言。
 如果key为nil，value为nil，返回空串；key为nil，value非nil，返回value；如果key不存在，value为nil或空，返回key；如果key不存在，value非空，返回value
 */
@interface NSBundle (FWFramework)

// 读取系统语言
+ (NSString *)fwSystemLanguage;

// 读取自定义本地化语言，未自定义时返回空
+ (NSString *)fwLocalizedLanguage;

// 设置自定义本地化语言，为空时清空自定义。系统组件下次启动生效
+ (void)fwSetLocalizedLanguage:(NSString *)language;

@end
