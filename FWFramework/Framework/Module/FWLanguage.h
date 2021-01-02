/*!
 @header     FWLanguage.h
 @indexgroup FWFramework
 @brief      FWLanguage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/4/21
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 读取主bundle本地化字符串
#define FWLocalizedString( key, ... ) \
    [NSBundle fwLocalizedString:key table:fw_macro_default(nil, ##__VA_ARGS__)]

/// 本地化语言改变通知，object为本地化语言名称
extern NSString *const FWLocalizedLanguageChangedNotification;

#pragma mark - NSBundle+FWLanguage

/*!
@brief NSBundle系统语言分类，处理mainBundle语言。如果需要处理三方SDK和系统组件语言，详见FWFilter分类
@discussion 如果系统组件无法正确显示语言，需Info.plist设置CFBundleAllowMixedLocalizations为YES，从而允许应用程序获取框架库内语言。
如果key为nil，value为nil，返回空串；key为nil，value非nil，返回value；如果key不存在，value为nil或空，返回key；如果key不存在，value非空，返回value
当前使用修改bundle类方式实现，也可以使用动态替换localizedStringForKey方法来实现，但需注意此方式的性能
FWFramework所需本地化翻译如下：完成|关闭|确定|取消，配置同App本地化一致即可，如zh-Hans|en等
*/
@interface NSBundle (FWLanguage)

#pragma mark - Main

/// 读取或设置系统语言，未自定义时返回preferredLanguages(支持应用设置)。自定义后会影响preferredLanguages，可用来处理GoogleMaps不支持语言切换等问题
@property (nullable, class, nonatomic, copy) NSString *fwSystemLanguage;

/// 读取或设置自定义本地化语言，未自定义时为空。(语言值对应本地化文件存在才会立即生效，如zh-Hans|en)，为空时清空自定义，会触发通知。默认只处理mainBundle语言，如果需要处理三方SDK和系统组件语言，详见Bundle分类
@property (nullable, class, nonatomic, copy) NSString *fwLocalizedLanguage;

/// 读取本地化字符串，strings文件需位于mainBundle，支持动态切换
+ (NSString *)fwLocalizedString:(NSString *)key;

/// 读取本地化字符串，指定table，strings文件需位于mainBundle，支持动态切换
+ (NSString *)fwLocalizedString:(NSString *)key table:(nullable NSString *)table;

#pragma mark - Bundle

/// 加载指定名称bundle对象，bundle文件需位于mainBundle
+ (nullable instancetype)fwBundleWithName:(NSString *)name;

/// 加载指定类所在bundle对象，可指定子目录名称，一般用于Framework内bundle文件
+ (nullable instancetype)fwBundleWithClass:(Class)clazz name:(nullable NSString *)name;

/// 根据本地化语言加载当前bundle内语言文件，支持动态切换
- (NSBundle *)fwLocalizedBundle;

/// 加载当前bundle内指定语言文件，加载失败返回nil
- (nullable NSBundle *)fwLocalizedBundleWithLanguage:(nullable NSString *)language;

/// 读取指定bundle内strings文件本地化字符串，支持动态切换
+ (NSString *)fwLocalizedString:(NSString *)key bundle:(nullable NSBundle *)bundle;

/// 读取指定bundle内strings文件本地化字符串，指定table，支持动态切换
+ (NSString *)fwLocalizedString:(NSString *)key table:(nullable NSString *)table bundle:(nullable NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
