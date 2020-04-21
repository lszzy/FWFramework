/*!
 @header     NSBundle+FWFramework.h
 @indexgroup FWFramework
 @brief      NSBundle分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import <Foundation/Foundation.h>
#import "NSBundle+FWLanguage.h"

NS_ASSUME_NONNULL_BEGIN

// 读取主bundle本地化字符串
#define FWLocalizedString( key, ... ) \
    [[NSBundle mainBundle] localizedStringForKey:key value:@"" table:fw_macro_default(nil, ##__VA_ARGS__)]

/*!
@brief NSBundle+FWFramework
*/
@interface NSBundle (FWFramework)

// 读取主bundle本地化字符串
+ (NSString *)fwLocalizedString:(NSString *)key;

// 读取主bundle本地化字符串，指定table
+ (NSString *)fwLocalizedString:(NSString *)key table:(nullable NSString *)table;

@end

NS_ASSUME_NONNULL_END
