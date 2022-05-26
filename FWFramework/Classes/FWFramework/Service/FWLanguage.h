/**
 @header     FWLanguage.h
 @indexgroup FWFramework
      FWLanguage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/4/21
 */

#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

/// 读取主bundle本地化字符串
#define FWLocalizedString( key, ... ) \
    [NSBundle.fw localizedString:key table:fw_macro_default(nil, ##__VA_ARGS__)]

/// 本地化语言改变通知，object为本地化语言名称
extern NSNotificationName const FWLanguageChangedNotification NS_SWIFT_NAME(LanguageChanged);

#pragma mark - FWBundleWrapper+FWLanguage

@interface FWBundleWrapper (FWLanguage)

/// 根据本地化语言加载当前bundle内语言文件，支持动态切换
- (NSBundle *)localizedBundle;

/// 加载当前bundle内指定语言文件，加载失败返回nil
- (nullable NSBundle *)localizedBundleWithLanguage:(nullable NSString *)language;

@end

#pragma mark - FWBundleClassWrapper+FWLanguage

/**
NSBundle系统语言分类，处理mainBundle语言。如果需要处理三方SDK和系统组件语言，详见Bundle分类
@note 如果系统组件无法正确显示语言，需Info.plist设置CFBundleAllowMixedLocalizations为YES，从而允许应用程序获取框架库内语言。
如果key为nil，value为nil，返回空串；key为nil，value非nil，返回value；如果key不存在，value为nil或空，返回key；如果key不存在，value非空，返回value
当前使用修改bundle类方式实现，也可以使用动态替换localizedStringForKey方法来实现，但需注意此方式的性能
*/
@interface FWBundleClassWrapper (FWLanguage)

#pragma mark - Main

/// 读取应用当前语言，如果localizedLanguage存在则返回，否则返回systemLanguage
@property (nullable, nonatomic, copy, readonly) NSString *currentLanguage;

/// 读取应用系统语言，返回preferredLocalizations(支持应用设置，不含区域)，示例：zh-Hans|en
@property (nullable, nonatomic, copy, readonly) NSString *systemLanguage;

/// 读取或设置自定义本地化语言，未自定义时为空。(语言值对应本地化文件存在才会立即生效，如zh-Hans|en)，为空时清空自定义，会触发通知。默认只处理mainBundle语言，如果需要处理三方SDK和系统组件语言，详见Bundle分类
@property (nullable, nonatomic, copy) NSString *localizedLanguage;

/// 读取本地化字符串，strings文件需位于mainBundle，支持动态切换
- (NSString *)localizedString:(NSString *)key;

/// 读取本地化字符串，指定table，strings文件需位于mainBundle，支持动态切换
- (NSString *)localizedString:(NSString *)key table:(nullable NSString *)table;

#pragma mark - Bundle

/// 加载指定名称bundle对象，bundle文件需位于mainBundle
- (nullable NSBundle *)bundleWithName:(NSString *)name;

/// 加载指定类所在bundle对象，可指定子目录名称，一般用于Framework内bundle文件
- (nullable NSBundle *)bundleWithClass:(Class)clazz name:(nullable NSString *)name;

/// 读取指定bundle内strings文件本地化字符串，支持动态切换
- (NSString *)localizedString:(NSString *)key bundle:(nullable NSBundle *)bundle;

/// 读取指定bundle内strings文件本地化字符串，指定table，支持动态切换
- (NSString *)localizedString:(NSString *)key table:(nullable NSString *)table bundle:(nullable NSBundle *)bundle;

@end

#pragma mark - FWStringWrapper+FWLanguage

@interface FWStringWrapper (FWLanguage)

/// 快速读取本地化语言
@property (nonatomic, copy, readonly) NSString *localized;

@end

NS_ASSUME_NONNULL_END
