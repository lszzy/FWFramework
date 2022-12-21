//
//  FWIcon.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FWIcon;
@class __FWLoader<InputType, OutputType>;

/// 指定名称和大小初始化图标对象
FOUNDATION_EXPORT FWIcon * _Nullable FWIconNamed(NSString *name, CGFloat size) NS_SWIFT_UNAVAILABLE("");

/// 指定名称和大小初始化图标图像
FOUNDATION_EXPORT UIImage * _Nullable FWIconImage(NSString *name, CGFloat size) NS_SWIFT_UNAVAILABLE("");

/**
 字体图标抽象基类，子类需继承
 @note Foundation icons: https://zurb.com/playground/foundation-icon-fonts-3#allicons
 FontAwesome: https://fontawesome.com/
 ionicons: https://ionic.io/ionicons/
 Octicons: https://primer.style/octicons/
 Material: https://google.github.io/material-design-icons/#icons-for-ios
 
 @see https://github.com/PrideChung/FontAwesomeKit
 */
NS_SWIFT_NAME(Icon)
@interface FWIcon : NSObject

#pragma mark - Static

/// 图标加载器，访问未注册图标时会尝试调用并注册，block返回值为register方法class参数
@property (class, nonatomic, readonly) __FWLoader<NSString *, Class> *sharedLoader;

/// 注册图标实现类，必须继承FWIcon，用于name快速查找，注意name不要重复
+ (BOOL)registerClass:(Class)iconClass;

/// 指定名称和大小初始化图标对象
+ (nullable FWIcon *)iconNamed:(NSString *)name size:(CGFloat)size;

/// 指定名称和大小初始化图标图像
+ (nullable UIImage *)iconImage:(NSString *)name size:(CGFloat)size;

/// 安装图标字体文件，返回安装结果
+ (BOOL)installIconFont:(NSURL *)fileURL;

#pragma mark - Lifecycle

/// 根据字符编码和大小创建图标对象
- (instancetype)initWithCode:(NSString *)code size:(CGFloat)size;

/// 根据图标名称和大小创建图标对象
- (nullable instancetype)initWithName:(NSString *)name size:(CGFloat)size;

/// 自定义字体大小
@property (nonatomic, assign) CGFloat fontSize;

/// 自定义背景色
@property (nonatomic, strong, nullable) UIColor *backgroundColor;

/// 自定义前景色
@property (nonatomic, strong, nullable) UIColor *foregroundColor;

/// 获取图标字符编码
@property (nonatomic, copy, readonly) NSString *characterCode;

/// 获取图标名称
@property (nonatomic, copy, readonly) NSString *iconName;

/// 返回图标字体
@property (nonatomic, strong, readonly) UIFont *iconFont;

/// 自定义图片偏移位置，仅创建Image时生效
@property (nonatomic, assign) UIOffset imageOffset;

/// 返回字体相同大小的图标Image
@property (nonatomic, strong, readonly) UIImage *image;

/// 快速生成指定大小图标Image
- (UIImage *)imageWithSize:(CGSize)imageSize;

#pragma mark - Attribute

/// 生成属性字符串
@property (nonatomic, copy, readonly) NSAttributedString *attributedString;

/// 设置图标属性，注意不要设置NSFontAttributeName为其他字体
- (void)setAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs;

/// 添加某个图标属性
- (void)addAttribute:(NSAttributedStringKey)name value:(id)value;

/// 批量添加属性
- (void)addAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs;

/// 移除指定名称属性
- (void)removeAttribute:(NSAttributedStringKey)name;

/// 返回图标所有属性
- (NSDictionary<NSAttributedStringKey, id> *)attributes;

/// 返回图标指定属性
- (nullable id)attribute:(NSAttributedStringKey)name;

#pragma mark - Protected

/// 所有图标名称=>编码映射字典，子类必须重写
+ (NSDictionary<NSString *, NSString *> *)iconMapper;

/// 返回指定大小的图标字体，子类必须重写
+ (UIFont *)iconFontWithSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
