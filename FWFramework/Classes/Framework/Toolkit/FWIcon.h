/*!
 @header     FWIcon.h
 @indexgroup FWFramework
 @brief      FWIcon
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FWIcon;

/// 指定名称和大小初始化FWIcon，需先设置图标路由句柄
FOUNDATION_EXPORT FWIcon * _Nullable FWIconNamed(NSString *name, CGFloat size);

/*!
 @brief 字体图标抽象基类，子类需继承
 @discussion Foundation icons: https://zurb.com/playground/foundation-icon-fonts-3#allicons
 FontAwesome: https://fontawesome.com/
 ionicons: https://ionic.io/ionicons/
 Octicons: https://primer.style/octicons/
 Material: https://google.github.io/material-design-icons/#icons-for-ios
 
 @see https://github.com/PrideChung/FontAwesomeKit
 */
@interface FWIcon : NSObject

#pragma mark - Static

/// 自定义图标路由句柄
@property (class, nonatomic, copy, nullable) FWIcon * _Nullable (^iconRouter)(NSString *name, CGFloat size);

/// 指定名称和大小初始化FWIcon，需先设置路由句柄
+ (nullable FWIcon *)iconNamed:(NSString *)name size:(CGFloat)size;

#pragma mark - Lifecycle

/// 注册图标字体，返回注册结果
+ (BOOL)registerIconFont:(NSURL *)url;

/// 根据字符编码和大小创建图标对象
+ (instancetype)iconWithCode:(NSString *)code size:(CGFloat)size;

/// 根据图标名称和大小创建图标对象
+ (nullable instancetype)iconWithName:(NSString *)name size:(CGFloat)size;

/// 图标自定义偏移
@property (nonatomic, assign) UIOffset positionAdjustment;

/// 图标自定义字体大小
@property (nonatomic, assign) CGFloat fontSize;

/// 图标自定义背景色
@property (nonatomic, strong, nullable) UIColor *backgroundColor;

/// 图标自定义前景色
@property (nonatomic, strong, nullable) UIColor *foregroundColor;

/// 获取图标字符编码
@property (nonatomic, copy, readonly) NSString *characterCode;

/// 获取图标名称
@property (nonatomic, copy, readonly) NSString *iconName;

/// 返回图标字体
@property (nonatomic, strong, readonly) UIFont *iconFont;

/// 返回字体相同大小的图标Image
@property (nonatomic, strong, readonly) UIImage *image;

/// 快速生成指定大小图标Image
- (UIImage *)imageWithSize:(CGSize)imageSize;

#pragma mark - Attribute

/// 生成属性字符串
@property (nonatomic, copy, readonly) NSAttributedString *attributedString;

/// 设置图标属性，注意不要设置NSFontAttributeName为其他字体
- (void)setAttributes:(NSDictionary *)attrs;

/// 添加某个图标属性
- (void)addAttribute:(NSString *)name value:(id)value;

/// 批量添加属性
- (void)addAttributes:(NSDictionary *)attrs;

/// 移除指定名称属性
- (void)removeAttribute:(NSString *)name;

/// 返回图标所有属性
- (NSDictionary *)attributes;

/// 返回图标指定属性
- (nullable id)attribute:(NSString *)name;

#pragma mark - Protected

/// 所有图标名称=>编码映射字典，子类必须重写
+ (NSDictionary<NSString *, NSString *> *)allIcons;

/// 返回指定大小的图标字体，子类必须重写
+ (UIFont *)iconFontWithSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
