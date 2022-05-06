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
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWArrayWrapper+FWFoundation

@interface FWArrayWrapper<__covariant ObjectType> (FWFoundation)

/// 过滤数组元素，返回YES的obj重新组装成一个数组
- (NSArray<ObjectType> *)filterWithBlock:(BOOL (^)(ObjectType obj))block;

/// 映射数组元素，返回的obj重新组装成一个数组
- (NSArray *)mapWithBlock:(id _Nullable (^)(ObjectType obj))block;

/// 匹配数组第一个元素，返回满足条件的第一个obj
- (nullable ObjectType)matchWithBlock:(BOOL (^)(ObjectType obj))block;

/// 从数组中随机取出对象，如@[@"a", @"b", @"c"]随机取出@"b"
@property (nullable, nonatomic, readonly) ObjectType randomObject;

@end

#pragma mark - FWAttributedStringWrapper+FWFoundation

@interface FWAttributedStringWrapper (FWFoundation)

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)htmlString;

/// 计算所占尺寸，需设置Font等
@property (nonatomic, assign, readonly) CGSize textSize;

/// 计算在指定绘制区域内所占尺寸，需设置Font等
- (CGSize)textSizeWithDrawSize:(CGSize)drawSize;

@end

#pragma mark - FWAttributedStringClassWrapper+FWFoundation

/**
 如果需要实现行内图片可点击效果，可使用UITextView添加附件或Link并实现delegate.shouldInteractWith方法即可
 */
@interface FWAttributedStringClassWrapper (FWFoundation)

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
- (nullable NSAttributedString *)attributedStringWithHtmlString:(NSString *)htmlString;

/// 图片转换为NSAttributedString对象，可实现行内图片样式。其中bounds.x会设置为间距，y常用算法：round(font.capHeight - image.size.height) / 2.0
- (NSAttributedString *)attributedStringWithImage:(nullable UIImage *)image bounds:(CGRect)bounds;

@end

#pragma mark - FWDataWrapper+FWFoundation

@interface FWDataWrapper (FWFoundation)

/// 使用NSKeyedUnarchiver解压数据
- (nullable id)unarchiveObject:(Class)clazz;

@end

#pragma mark - FWDataClassWrapper+FWFoundation

@interface FWDataClassWrapper (FWFoundation)

/// 使用NSKeyedArchiver压缩对象
- (nullable NSData *)archiveObject:(id)object;

/// 保存对象归档
- (BOOL)archiveObject:(id)object toFile:(NSString *)path;

/// 读取对象归档
- (nullable id)unarchiveObject:(Class)clazz withFile:(NSString *)path;

@end

#pragma mark - FWDateWrapper+FWFoundation

@interface FWDateWrapper (FWFoundation)

/// 转化为字符串，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
@property (nonatomic, copy, readonly) NSString *stringValue;

/// 转化为字符串，默认当前时区，自定义格式
- (NSString *)stringWithFormat:(NSString *)format;

/// 转化为字符串，自定义格式和时区
- (NSString *)stringWithFormat:(NSString *)format timeZone:(nullable NSTimeZone *)timeZone;

@end

#pragma mark - FWDateClassWrapper+FWFoundation

@interface FWDateClassWrapper (FWFoundation)

/// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (nonatomic, assign) NSTimeInterval currentTime;

/// 从字符串初始化日期，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
- (nullable NSDate *)dateWithString:(NSString *)string;

/// 从字符串初始化日期，默认当前时区，自定义格式
- (nullable NSDate *)dateWithString:(NSString *)string format:(NSString *)format;

/// 从字符串初始化日期，自定义格式和时区
- (nullable NSDate *)dateWithString:(NSString *)string format:(NSString *)format timeZone:(nullable NSTimeZone *)timeZone;

/// 格式化时长，格式"00:00"或"00:00:00"
- (NSString *)formatDuration:(NSTimeInterval)duration hasHour:(BOOL)hasHour;

/// 格式化16位、13位时间戳为10位(秒)
- (NSTimeInterval)formatTimestamp:(NSTimeInterval)timestamp;

@end

#pragma mark - FWDictionaryWrapper+FWFoundation

@interface FWDictionaryWrapper<__covariant KeyType, __covariant ObjectType> (FWFoundation)

/// 过滤字典元素，如果block返回NO，则去掉该元素
- (NSDictionary<KeyType, ObjectType> *)filterWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block;

/// 映射字典元素，返回的obj重新组装成一个字典
- (NSDictionary *)mapWithBlock:(id _Nullable (^)(KeyType key, ObjectType obj))block;

/// 匹配字典第一个元素，返回满足条件的第一个obj
- (nullable ObjectType)matchWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block;

@end

#pragma mark - FWObjectWrapper+FWFoundation

@interface FWObjectWrapper (FWFoundation)

/// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
- (void)lock;

/// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
- (void)unlock;

@end

#pragma mark - FWStringWrapper+FWFoundation

@interface FWStringWrapper (FWFoundation)

/// 计算单行字符串指定字体所占尺寸
- (CGSize)sizeWithFont:(UIFont *)font;

/// 计算多行字符串指定字体在指定绘制区域内所占尺寸
- (CGSize)sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize;

/// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
- (CGSize)sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;

/// 是否匹配正则表达式，示例：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
- (BOOL)matchesRegex:(NSString *)regex;

@end

#pragma mark - FWStringClassWrapper+FWFoundation

@interface FWStringClassWrapper (FWFoundation)

/// 格式化文件大小为".0K/.1M/.1G"
- (NSString *)sizeString:(NSUInteger)fileSize;

@end

#pragma mark - FWTimerWrapper+FWFoundation

@interface FWTimerWrapper (FWFoundation)

/// 暂停NSTimer
- (void)pauseTimer;

/// 开始NSTimer
- (void)resumeTimer;

/// 延迟delay秒后开始NSTimer
- (void)resumeTimerAfterDelay:(NSTimeInterval)delay;

@end

#pragma mark - FWUserDefaultsWrapper+FWFoundation

@interface FWUserDefaultsWrapper (FWFoundation)

/// 读取对象，支持unarchive对象
- (nullable id)objectForKey:(NSString *)key;

/// 保存对象，支持archive对象
- (void)setObject:(nullable id)object forKey:(NSString *)key;

@end

#pragma mark - FWUserDefaultsClassWrapper+FWFoundation

@interface FWUserDefaultsClassWrapper (FWFoundation)

/// 从standard读取对象，支持unarchive对象
- (nullable id)objectForKey:(NSString *)key;

/// 保存对象到standard，支持archive对象
- (void)setObject:(nullable id)object forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
