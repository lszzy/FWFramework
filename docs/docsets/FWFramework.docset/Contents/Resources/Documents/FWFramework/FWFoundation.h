/**
 @header     FWFoundation.h
 @indexgroup FWFramework
      FWFoundation
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSArray+FWFoundation

@interface NSArray<__covariant ObjectType> (FWFoundation)

/// 过滤数组元素，返回YES的obj重新组装成一个数组
- (NSArray<ObjectType> *)fw_filterWithBlock:(BOOL (^)(ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 映射数组元素，返回的obj重新组装成一个数组
- (NSArray *)fw_mapWithBlock:(id _Nullable (^)(ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 匹配数组第一个元素，返回满足条件的第一个obj
- (nullable ObjectType)fw_matchWithBlock:(BOOL (^)(ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 从数组中随机取出对象，如@[@"a", @"b", @"c"]随机取出@"b"
@property (nullable, nonatomic, readonly) ObjectType fw_randomObject NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSAttributedString+FWFoundation

/**
 如果需要实现行内图片可点击效果，可使用UITextView添加附件或Link并实现delegate.shouldInteractWith方法即可
 */
@interface NSAttributedString (FWFoundation)

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)fw_htmlString NS_REFINED_FOR_SWIFT;

/// 计算所占尺寸，需设置Font等
@property (nonatomic, assign, readonly) CGSize fw_textSize NS_REFINED_FOR_SWIFT;

/// 计算在指定绘制区域内所占尺寸，需设置Font等
- (CGSize)fw_textSizeWithDrawSize:(CGSize)drawSize NS_REFINED_FOR_SWIFT;

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
+ (nullable instancetype)fw_attributedStringWithHtmlString:(NSString *)htmlString NS_REFINED_FOR_SWIFT;

/// 图片转换为NSAttributedString对象，可实现行内图片样式。其中bounds.x会设置为间距，y常用算法：(font.capHeight - image.size.height) / 2.0
+ (NSAttributedString *)fw_attributedStringWithImage:(nullable UIImage *)image bounds:(CGRect)bounds NS_REFINED_FOR_SWIFT;

/// 快速创建NSAttributedString并指定高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
+ (NSAttributedString *)fw_attributedStringWithString:(NSString *)string attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes highlight:(NSString *)highlight highlightAttributes:(nullable NSDictionary<NSAttributedStringKey, id> *)highlightAttributes NS_REFINED_FOR_SWIFT;

/// 快速创建NSAttributedString，自定义字体
+ (instancetype)fw_attributedString:(NSString *)string withFont:(nullable UIFont *)font NS_REFINED_FOR_SWIFT;

/// 快速创建NSAttributedString，自定义字体和颜色
+ (instancetype)fw_attributedString:(NSString *)string withFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSData+FWFoundation

@interface NSData (FWFoundation)

/// 使用NSKeyedUnarchiver解压数据
- (nullable id)fw_unarchiveObject:(Class)clazz NS_REFINED_FOR_SWIFT;

/// 使用NSKeyedArchiver压缩对象
+ (nullable NSData *)fw_archiveObject:(id)object NS_REFINED_FOR_SWIFT;

/// 保存对象归档
+ (BOOL)fw_archiveObject:(id)object toFile:(NSString *)path NS_REFINED_FOR_SWIFT;

/// 读取对象归档
+ (nullable id)fw_unarchiveObject:(Class)clazz withFile:(NSString *)path NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSDate+FWFoundation

@interface NSDate (FWFoundation)

/// 转化为字符串，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
@property (nonatomic, copy, readonly) NSString *fw_stringValue NS_REFINED_FOR_SWIFT;

/// 转化为字符串，默认当前时区，自定义格式
- (NSString *)fw_stringWithFormat:(NSString *)format NS_REFINED_FOR_SWIFT;

/// 转化为字符串，自定义格式和时区
- (NSString *)fw_stringWithFormat:(NSString *)format timeZone:(nullable NSTimeZone *)timeZone NS_REFINED_FOR_SWIFT;

/// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (class, nonatomic, assign) NSTimeInterval fw_currentTime NS_REFINED_FOR_SWIFT;

/// 从字符串初始化日期，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
+ (nullable NSDate *)fw_dateWithString:(NSString *)string NS_REFINED_FOR_SWIFT;

/// 从字符串初始化日期，默认当前时区，自定义格式
+ (nullable NSDate *)fw_dateWithString:(NSString *)string format:(NSString *)format NS_REFINED_FOR_SWIFT;

/// 从字符串初始化日期，自定义格式和时区
+ (nullable NSDate *)fw_dateWithString:(NSString *)string format:(NSString *)format timeZone:(nullable NSTimeZone *)timeZone NS_REFINED_FOR_SWIFT;

/// 格式化时长，格式"00:00"或"00:00:00"
+ (NSString *)fw_formatDuration:(NSTimeInterval)duration hasHour:(BOOL)hasHour NS_REFINED_FOR_SWIFT;

/// 格式化16位、13位时间戳为10位(秒)
+ (NSTimeInterval)fw_formatTimestamp:(NSTimeInterval)timestamp NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSDictionary+FWFoundation

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (FWFoundation)

/// 过滤字典元素，如果block返回NO，则去掉该元素
- (NSDictionary<KeyType, ObjectType> *)fw_filterWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 映射字典元素，返回的obj重新组装成一个字典
- (NSDictionary *)fw_mapWithBlock:(id _Nullable (^)(KeyType key, ObjectType obj))block NS_REFINED_FOR_SWIFT;

/// 匹配字典第一个元素，返回满足条件的第一个obj
- (nullable ObjectType)fw_matchWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSObject+FWFoundation

@interface NSObject (FWFoundation)

/// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
- (void)fw_lock NS_REFINED_FOR_SWIFT;

/// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
- (void)fw_unlock NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSString+FWFoundation

@interface NSString (FWFoundation)

/// 计算单行字符串指定字体所占尺寸
- (CGSize)fw_sizeWithFont:(UIFont *)font NS_REFINED_FOR_SWIFT;

/// 计算多行字符串指定字体在指定绘制区域内所占尺寸
- (CGSize)fw_sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize NS_REFINED_FOR_SWIFT;

/// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
- (CGSize)fw_sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes NS_REFINED_FOR_SWIFT;

/// 是否匹配正则表达式，示例：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
- (BOOL)fw_matchesRegex:(NSString *)regex NS_REFINED_FOR_SWIFT;

/// 格式化文件大小为".0K/.1M/.1G"
+ (NSString *)fw_sizeString:(NSUInteger)fileSize NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSUserDefaults+FWFoundation

@interface NSUserDefaults (FWFoundation)

/// 读取对象，支持unarchive对象
- (nullable id)fw_objectForKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/// 保存对象，支持archive对象
- (void)fw_setObject:(nullable id)object forKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/// 从standard读取对象，支持unarchive对象
+ (nullable id)fw_objectForKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/// 保存对象到standard，支持archive对象
+ (void)fw_setObject:(nullable id)object forKey:(NSString *)key NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
