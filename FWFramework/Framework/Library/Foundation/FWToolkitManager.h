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

/// 系统运行时间
+ (long long)fwSystemUptime;

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

#pragma mark - NSTimer+FWToolkit

/*!
 @brief CADisplayLink分类
 */
@interface CADisplayLink (FWToolkit)

/*!
 @brief 创建CADisplayLink，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param target 目标
 @param selector 方法
 @return CADisplayLink
 */
+ (CADisplayLink *)fwCommonDisplayLinkWithTarget:(id)target selector:(SEL)selector;

/*!
 @brief 创建CADisplayLink，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param block 代码块
 @return CADisplayLink
 */
+ (CADisplayLink *)fwCommonDisplayLinkWithBlock:(void (^)(CADisplayLink *displayLink))block;

/*!
 @brief 创建CADisplayLink，使用block，需要调用addToRunLoop:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
 @discussion 示例：[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes]
 
 @param block 代码块
 @return CADisplayLink
 */
+ (CADisplayLink *)fwDisplayLinkWithBlock:(void (^)(CADisplayLink *displayLink))block;

@end

/*!
 @brief NSTimer分类
 */
@interface NSTimer (FWToolkit)

/*!
 @brief 创建NSTimer，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param seconds 时间
 @param target 目标
 @param selector 方法
 @param userInfo 参数
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fwCommonTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector userInfo:(nullable id)userInfo repeats:(BOOL)repeats;

/*!
 @brief 创建NSTimer，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fwCommonTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

/*!
 @brief 创建倒计时定时器
 
 @param seconds 倒计时描述
 @param block 每秒执行block，为0时自动停止
 @return 定时器，可手工停止
 */
+ (NSTimer *)fwCommonTimerWithCountDown:(NSInteger)seconds block:(void (^)(NSInteger countDown))block;

/*!
 @brief 创建NSTimer，使用block，需要调用addTimer:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
 @discussion 示例：[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes]
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fwTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

/*!
 @brief 创建NSTimer，使用block，默认模式安排到当前的运行循环中
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fwScheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

@end

#pragma mark - NSAttributedString+FWToolkit

@interface NSAttributedString (FWToolkit)

#pragma mark - Html

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
+ (nullable instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString;

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)fwHtmlString;

#pragma mark - Size

/// 计算所占尺寸，需设置Font等
- (CGSize)fwSize;

/// 计算在指定绘制区域内所占尺寸，需设置Font等
- (CGSize)fwSizeWithDrawSize:(CGSize)drawSize;

@end

NS_ASSUME_NONNULL_END
