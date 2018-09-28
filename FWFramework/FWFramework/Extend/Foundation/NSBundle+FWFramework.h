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
 */
@interface NSBundle (FWFramework)

// 读取系统语言
+ (NSString *)fwSystemLanguage;

// 读取自定义本地化语言，未自定义时返回空
+ (NSString *)fwLocalizedLanguage;

// 设置自定义本地化语言，为空时清空自定义。系统组件下次启动生效
+ (void)fwSetLocalizedLanguage:(NSString *)language;

// 读取本地化字符串(默认Localizable.strings)
+ (NSString *)fwLocalizedString:(NSString *)key;

// 读取指定本地化字符串(默认Localizable.strings)
+ (NSString *)fwLocalizedString:(NSString *)key table:(NSString *)table;

@end
