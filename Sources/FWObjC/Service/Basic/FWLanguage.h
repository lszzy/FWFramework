//
//  FWLanguage.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 读取主bundle本地化字符串
#define FWLocalizedString( key, ... ) \
    [NSBundle fw_localizedString:key table:fw_macro_default(nil, ##__VA_ARGS__)]

/// 本地化语言改变通知，object为本地化语言名称
extern NSNotificationName const FWLanguageChangedNotification NS_SWIFT_NAME(LanguageChanged);

#pragma mark - NSString+FWLanguage

@interface NSString (FWLanguage)

/// 快速读取本地化语言
@property (nonatomic, copy, readonly) NSString *fw_localized NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
