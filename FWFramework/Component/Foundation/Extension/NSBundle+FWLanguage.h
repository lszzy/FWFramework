/*!
 @header     NSBundle+FWLanguage.h
 @indexgroup FWFramework
 @brief      NSBundle+FWLanguage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/4/21
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 本地化语言改变通知，object为本地化语言名称
extern NSString *const FWLocalizedLanguageChangedNotification;

#pragma mark - NSBundle+FWLanguage

/*!
@brief NSBundle系统语言分类，处理mainBundle语言。如果需要处理三方SDK和系统组件语言，详见Bundle分类
@discussion 如果系统组件无法正确显示语言，需Info.plist设置CFBundleAllowMixedLocalizations为YES，从而允许应用程序获取框架库内语言。
如果key为nil，value为nil，返回空串；key为nil，value非nil，返回value；如果key不存在，value为nil或空，返回key；如果key不存在，value非空，返回value
当前使用修改bundle类方式实现，也可以使用动态替换localizedStringForKey方法来实现，但需注意此方式的性能
FWFramework所需本地化翻译如下(默认zh|en等)：完成|关闭|确定|取消
*/
@interface NSBundle (FWLanguage)

// 读取系统语言
+ (nullable NSString *)fwSystemLanguage;

// 读取自定义本地化语言，未自定义时返回空
+ (nullable NSString *)fwLocalizedLanguage;

// 设置自定义本地化语言，为空时清空自定义，会触发通知。默认只处理mainBundle语言，如果需要处理三方SDK和系统组件语言，详见Bundle分类
+ (void)fwSetLocalizedLanguage:(nullable NSString *)language;

@end

#pragma mark - NSBundle+FWBundle

/*!
 @brief NSBundle自定义语言分类，处理三方SDK和系统组件语言
 */
@interface NSBundle (FWBundle)

// 设置全局bundle过滤器，返回YES代表当前bundle需要加载本地化语言。用于处理三方SDK和系统组件等
+ (void)fwSetBundleFilter:(BOOL (^)(NSBundle *bundle))filter;

// 设置全局bundle查找器，返回当前bundle实际使用语言，language为nil表示默认语言。需设置全局过滤器后才会生效
+ (void)fwSetBundleFinder:(nullable NSString * _Nullable (^)(NSBundle *bundle, NSString * _Nullable language))finder;

// 根据语言加载当前bundle指定语言文件的bundle，加载失败返回nil
- (nullable NSBundle *)fwLocalizedBundle:(nullable NSString *)language;

@end

NS_ASSUME_NONNULL_END
