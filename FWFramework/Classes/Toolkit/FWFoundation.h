/**
 @header     FWFoundation.h
 @indexgroup FWFramework
      FWFoundation
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSArray+FWFoundation

/**
 NSArray+FWFoundation
 */
@interface NSArray<__covariant ObjectType> (FWFoundation)

/// 过滤数组元素，返回YES的obj重新组装成一个数组
- (instancetype)fwFilterWithBlock:(BOOL (^)(ObjectType obj))block;

/// 映射数组元素，返回的obj重新组装成一个数组
- (NSArray *)fwMapWithBlock:(id _Nullable (^)(ObjectType obj))block;

/// 匹配数组第一个元素，返回满足条件的第一个obj
- (nullable ObjectType)fwMatchWithBlock:(BOOL (^)(ObjectType obj))block;

/// 从数组中随机取出对象，如@[@"a", @"b", @"c"]随机取出@"b"
@property (nullable, nonatomic, readonly) ObjectType fwRandomObject;

@end

#pragma mark - NSAttributedString+FWFoundation

/**
 NSAttributedString+FWFoundation
 */
@interface NSAttributedString (FWFoundation)

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
+ (nullable instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString;

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)fwHtmlString;

/// 计算所占尺寸，需设置Font等
@property (nonatomic, assign, readonly) CGSize fwSize;

/// 计算在指定绘制区域内所占尺寸，需设置Font等
- (CGSize)fwSizeWithDrawSize:(CGSize)drawSize;

@end

#pragma mark - NSData+FWFoundation

/**
 NSData+FWFoundation
 */
@interface NSData (FWFoundation)

/// 使用NSKeyedArchiver压缩对象
+ (nullable NSData *)fwArchiveObject:(id)object;

/// 使用NSKeyedUnarchiver解压数据
- (nullable id)fwUnarchiveObject;

/// 保存对象归档
+ (void)fwArchiveObject:(id)object toFile:(NSString *)path;

/// 读取对象归档
+ (nullable id)fwUnarchiveObjectWithFile:(NSString *)path;

@end

#pragma mark - NSDate+FWFoundation

/**
 NSDate+FWFoundation
 */
@interface NSDate (FWFoundation)

/// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (class, nonatomic, assign) NSTimeInterval fwCurrentTime;

/// 从字符串初始化日期，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
+ (nullable NSDate *)fwDateWithString:(NSString *)string;

/// 从字符串初始化日期，默认当前时区，自定义格式
+ (nullable NSDate *)fwDateWithString:(NSString *)string format:(nullable NSString *)format;

/// 从字符串初始化日期，指定时区，自定义格式和时区
+ (nullable NSDate *)fwDateWithString:(NSString *)string format:(nullable NSString *)format timeZone:(nullable NSTimeZone *)timeZone;

/// 转化为字符串，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
@property (nonatomic, copy, readonly) NSString *fwStringValue;

/// 转化为字符串，默认当前时区，自定义格式
- (NSString *)fwStringWithFormat:(nullable NSString *)format;

/// 转化为字符串，指定时区，自定义格式和时区
- (NSString *)fwStringWithFormat:(nullable NSString *)format timeZone:(nullable NSTimeZone *)timeZone;

/// 格式化时长，格式"00:00"或"00:00:00"
+ (NSString *)fwFormatDuration:(NSTimeInterval)duration hasHour:(BOOL)hasHour;

@end

#pragma mark - NSDictionary+FWFoundation

/**
 NSDictionary+FWFoundation
 */
@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (FWFoundation)

/// 过滤字典元素，如果block返回NO，则去掉该元素
- (instancetype)fwFilterWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block;

/// 映射字典元素，返回的obj重新组装成一个字典
- (NSDictionary *)fwMapWithBlock:(id _Nullable (^)(KeyType key, ObjectType obj))block;

/// 匹配字典第一个元素，返回满足条件的第一个obj
- (nullable ObjectType)fwMatchWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block;

@end

#pragma mark - NSObject+FWFoundation

/**
 NSObject+FWFoundation
 */
@interface NSObject (FWFoundation)

/// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
- (void)fwLock;

/// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
- (void)fwUnlock;

@end

#pragma mark - NSString+FWFoundation

/**
 NSString+FWFoundation
 */
@interface NSString (FWFoundation)

/// 计算单行字符串指定字体所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font;

/// 计算多行字符串指定字体在指定绘制区域内所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize;

/// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;

/// 格式化文件大小为".0K/.1M/.1G"
+ (NSString *)fwSizeString:(NSUInteger)fileSize;

/// 是否匹配正则表达式，示例：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
- (BOOL)fwMatchesRegex:(NSString *)regex;

@end

#pragma mark - NSTimer+FWFoundation

/**
 NSTimer+FWFoundation
 */
@interface NSTimer (FWFoundation)

/// 暂停NSTimer
- (void)fwPauseTimer;

/// 开始NSTimer
- (void)fwResumeTimer;

/// 延迟delay秒后开始NSTimer
- (void)fwResumeTimerAfterDelay:(NSTimeInterval)delay;

@end

#pragma mark - NSUserDefaults+FWFoundation

/**
 NSUserDefaults+FWFoundation
 */
@interface NSUserDefaults (FWFoundation)

/// 从standard读取对象，支持unarchive对象
+ (nullable id)fwObjectForKey:(NSString *)key;

/// 保存对象到standard，支持archive对象
+ (void)fwSetObject:(nullable id)object forKey:(NSString *)key;

/// 读取对象，支持unarchive对象
- (nullable id)fwObjectForKey:(NSString *)key;

/// 保存对象，支持archive对象
- (void)fwSetObject:(nullable id)object forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
