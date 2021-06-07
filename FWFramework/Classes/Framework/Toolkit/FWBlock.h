/*!
 @header     FWBlock.h
 @indexgroup FWFramework
 @brief      FWBlock
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - CADisplayLink+FWBlock

/*!
 @brief CADisplayLink分类
 */
@interface CADisplayLink (FWBlock)

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

#pragma mark - NSTimer+FWBlock

/*!
 @brief NSTimer分类
 */
@interface NSTimer (FWBlock)

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

#pragma mark - UIGestureRecognizer+FWBlock

@interface UIGestureRecognizer (FWBlock)

// 从事件句柄初始化
+ (instancetype)fwGestureRecognizerWithBlock:(void (^)(id sender))block;

// 添加事件句柄，返回唯一标志
- (NSString *)fwAddBlock:(void (^)(id sender))block;

// 根据唯一标志移除事件句柄
- (void)fwRemoveBlock:(nullable NSString *)identifier;

// 移除所有事件句柄
- (void)fwRemoveAllBlocks;

@end

#pragma mark - UIView+FWBlock

@interface UIView (FWBlock)

// 添加点击手势事件，默认子视图也会响应此事件。如要屏蔽之，解决方法：1、子视图设为UIButton；2、子视图添加空手势事件
- (void)fwAddTapGestureWithTarget:(id)target action:(SEL)action;

// 添加点击手势句柄，同上
- (NSString *)fwAddTapGestureWithBlock:(void (^)(id sender))block;

// 根据唯一标志移除点击手势句柄
- (void)fwRemoveTapGesture:(nullable NSString *)identifier;

// 移除所有点击手势
- (void)fwRemoveAllTapGestures;

@end

#pragma mark - UIControl+FWBlock

@interface UIControl (FWBlock)

// 添加事件句柄
- (NSString *)fwAddBlock:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents;

// 根据唯一标志移除事件句柄
- (void)fwRemoveBlock:(nullable NSString *)identifier forControlEvents:(UIControlEvents)controlEvents;

// 移除所有事件句柄
- (void)fwRemoveAllBlocksForControlEvents:(UIControlEvents)controlEvents;

// 添加点击事件
- (void)fwAddTouchTarget:(id)target action:(SEL)action;

// 添加点击句柄
- (NSString *)fwAddTouchBlock:(void (^)(id sender))block;

// 根据唯一标志移除点击句柄
- (void)fwRemoveTouchBlock:(nullable NSString *)identifier;

@end

#pragma mark - UIBarButtonItem+FWBlock

/*!
 @brief iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
 */
@interface UIBarButtonItem (FWBlock)

// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber等
+ (instancetype)fwBarItemWithObject:(nullable id)object target:(nullable id)target action:(nullable SEL)action;

// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber等
+ (instancetype)fwBarItemWithObject:(nullable id)object block:(nullable void (^)(id sender))block;

@end

NS_ASSUME_NONNULL_END
