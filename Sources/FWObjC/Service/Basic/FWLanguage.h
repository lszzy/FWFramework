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

#pragma mark - NSBundle+FWLanguage

/**
NSBundle系统语言分类，处理mainBundle语言。如果需要处理三方SDK和系统组件语言，详见Bundle分类
@note 如果系统组件无法正确显示语言，需Info.plist设置CFBundleAllowMixedLocalizations为YES，从而允许应用程序获取框架库内语言。
如果key为nil，value为nil，返回空串；key为nil，value非nil，返回value；如果key不存在，value为nil或空，返回key；如果key不存在，value非空，返回value
当前使用修改bundle类方式实现，也可以使用动态替换localizedStringForKey方法来实现，但需注意此方式的性能
*/
@interface NSBundle (FWLanguage)

#pragma mark - Main

/// 读取应用当前语言，如果localizedLanguage存在则返回，否则返回systemLanguage
@property (nullable, class, nonatomic, copy, readonly) NSString *fw_currentLanguage NS_REFINED_FOR_SWIFT;

/// 读取应用系统语言，返回preferredLocalizations(支持应用设置，不含区域)，示例：zh-Hans|en
@property (nullable, class, nonatomic, copy, readonly) NSString *fw_systemLanguage NS_REFINED_FOR_SWIFT;

/// 读取或设置自定义本地化语言，未自定义时为空。(语言值对应本地化文件存在才会立即生效，如zh-Hans|en)，为空时清空自定义，会触发通知。默认只处理mainBundle语言，如果需要处理三方SDK和系统组件语言，详见Bundle分类
@property (nullable, class, nonatomic, copy) NSString *fw_localizedLanguage NS_REFINED_FOR_SWIFT;

/// 读取本地化字符串，strings文件需位于mainBundle，支持动态切换
+ (NSString *)fw_localizedString:(NSString *)key NS_REFINED_FOR_SWIFT;

/// 读取本地化字符串，指定table，strings文件需位于mainBundle，支持动态切换
+ (NSString *)fw_localizedString:(NSString *)key table:(nullable NSString *)table NS_REFINED_FOR_SWIFT;

#pragma mark - Bundle

/// 加载指定名称bundle对象，bundle文件需位于mainBundle
+ (nullable NSBundle *)fw_bundleWithName:(NSString *)name NS_REFINED_FOR_SWIFT;

/// 加载指定类所在bundle对象，可指定子目录名称，一般用于Framework内bundle文件
+ (nullable NSBundle *)fw_bundleWithClass:(Class)clazz name:(nullable NSString *)name NS_REFINED_FOR_SWIFT;

/// 读取指定bundle内strings文件本地化字符串，支持动态切换
+ (NSString *)fw_localizedString:(NSString *)key bundle:(nullable NSBundle *)bundle NS_REFINED_FOR_SWIFT;

/// 读取指定bundle内strings文件本地化字符串，指定table，支持动态切换
+ (NSString *)fw_localizedString:(NSString *)key table:(nullable NSString *)table bundle:(nullable NSBundle *)bundle NS_REFINED_FOR_SWIFT;

#pragma mark - Localized

/// 根据本地化语言加载当前bundle内语言文件，支持动态切换
- (NSBundle *)fw_localizedBundle NS_SWIFT_NAME(__fw_localizedBundle()) NS_REFINED_FOR_SWIFT;

/// 加载当前bundle内指定语言文件，加载失败返回nil
- (nullable NSBundle *)fw_localizedBundleWithLanguage:(nullable NSString *)language NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSString+FWLanguage

@interface NSString (FWLanguage)

/// 快速读取本地化语言
@property (nonatomic, copy, readonly) NSString *fw_localized NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
