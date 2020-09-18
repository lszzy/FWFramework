/*!
 @header     FWToolkitManager.h
 @indexgroup FWFramework
 @brief      FWToolkitManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/18
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSDate+FWToolkit

/// 标记时间调试开始
#define FWBenchmarkBegin( x ) \
    [NSDate fwBenchmarkBegin:@(#x)];

/// 标记时间调试结束并打印消耗时间
#define FWBenchmarkEnd( x ) \
    [NSDate fwBenchmarkEnd:@(#x)];

@interface NSDate (FWToolkit)

/// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (class, nonatomic, assign) NSTimeInterval fwCurrentTime;

#pragma mark - Benchmark

/// 标记时间调试开始
+ (void)fwBenchmarkBegin:(NSString *)name;

/// 标记时间调试结束并打印消耗时间
+ (NSTimeInterval)fwBenchmarkEnd:(NSString *)name;

@end

#pragma mark - NSNull+FWToolkit

/*!
 @brief NSNull分类，解决值为NSNull时调用不存在方法崩溃问题，如JSON中包含null
 @discussion 默认调试环境不处理崩溃，正式环境才处理崩溃，尽量开发阶段避免此问题

 @see https://github.com/nicklockwood/NullSafe
*/
@interface NSNull (FWToolkit)

@end

#pragma mark - NSObject+FWToolkit

@interface NSObject (FWToolkit)

/*! @brief 临时对象 */
@property (nullable, nonatomic, strong) id fwTempObject;

#pragma mark - Lock

/// 创建信号量锁(支持任意对象)，初始值1，可选调用
- (void)fwLockCreate;

/// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
- (void)fwLock;

/// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
- (void)fwUnlock;

@end

#pragma mark - NSString+FWToolkit

@interface NSString (FWToolkit)

/// 去掉空白字符
- (NSString *)fwTrimString;

#pragma mark - Size

// 计算单行字符串指定字体所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font;

// 计算多行字符串指定字体在指定绘制区域内所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize;

// 计算多行字符串指定字体、指定段落样式(如lineBreakMode等)在指定绘制区域内所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize paragraphStyle:(nullable NSParagraphStyle *)paragraphStyle;

@end

NS_ASSUME_NONNULL_END
