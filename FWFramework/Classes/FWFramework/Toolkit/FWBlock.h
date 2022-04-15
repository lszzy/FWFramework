/**
 @header     FWBlock.h
 @indexgroup FWFramework
      FWBlock
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import <UIKit/UIKit.h>
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWBlock

/**
 通用不带参数block
 */
typedef void (^FWBlockVoid)(void) NS_SWIFT_UNAVAILABLE("");

/**
 通用id参数block
 
 @param param id参数
 */
typedef void (^FWBlockParam)(id _Nullable param) NS_SWIFT_UNAVAILABLE("");

/**
 通用bool参数block
 
 @param isTrue bool参数
 */
typedef void (^FWBlockBool)(BOOL isTrue) NS_SWIFT_UNAVAILABLE("");

/**
 通用NSInteger参数block
 
 @param index NSInteger参数
 */
typedef void (^FWBlockInt)(NSInteger index) NS_SWIFT_UNAVAILABLE("");

/**
 通用double参数block
 
 @param value double参数
 */
typedef void (^FWBlockDouble)(double value) NS_SWIFT_UNAVAILABLE("");

/**
 通用(BOOL,id)参数block
 
 @param isTrue BOOL参数
 @param param id参数
 */
typedef void (^FWBlockBoolParam)(BOOL isTrue, id _Nullable param) NS_SWIFT_UNAVAILABLE("");

#pragma mark - FWTimerClassWrapper+FWBlock

@interface FWTimerClassWrapper (FWBlock)

/**
 创建NSTimer，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param seconds 时间
 @param target 目标
 @param selector 方法
 @param userInfo 参数
 @param repeats 是否重复
 @return 定时器
 */
- (NSTimer *)commonTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector userInfo:(nullable id)userInfo repeats:(BOOL)repeats;

/**
 创建NSTimer，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
- (NSTimer *)commonTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

/**
 创建倒计时定时器
 
 @param seconds 倒计时描述
 @param block 每秒执行block，为0时自动停止
 @return 定时器，可手工停止
 */
- (NSTimer *)commonTimerWithCountDown:(NSInteger)seconds block:(void (^)(NSInteger countDown))block;

/**
 创建NSTimer，使用block，需要调用addTimer:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
 @note 示例：[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes]
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
- (NSTimer *)timerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

/**
 创建NSTimer，使用block，默认模式安排到当前的运行循环中
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
- (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

@end

#pragma mark - FWGestureRecognizerWrapper+FWBlock

@interface FWGestureRecognizerWrapper (FWBlock)

/// 添加事件句柄，返回唯一标志
- (NSString *)addBlock:(void (^)(id sender))block;

/// 根据唯一标志移除事件句柄
- (void)removeBlock:(nullable NSString *)identifier;

/// 移除所有事件句柄
- (void)removeAllBlocks;

@end

#pragma mark - FWGestureRecognizerClassWrapper+FWBlock

@interface UIGestureRecognizer (FWBlock)

/// 从事件句柄初始化
+ (instancetype)gestureRecognizerWithBlock:(void (^)(id sender))block;

@end

@interface FWGestureRecognizerClassWrapper (FWBlock)

/// 从事件句柄初始化
- (__kindof UIGestureRecognizer *)gestureRecognizerWithBlock:(void (^)(id sender))block;

@end

#pragma mark - FWViewWrapper+FWBlock

@interface FWViewWrapper (FWBlock)

/// 添加点击手势事件，默认子视图也会响应此事件。如要屏蔽之，解决方法：1、子视图设为UIButton；2、子视图添加空手势事件
- (void)addTapGestureWithTarget:(id)target action:(SEL)action;

/// 添加点击手势句柄，同上
- (NSString *)addTapGestureWithBlock:(void (^)(id sender))block;

/// 根据唯一标志移除点击手势句柄
- (void)removeTapGesture:(nullable NSString *)identifier;

/// 移除所有点击手势
- (void)removeAllTapGestures;

@end

#pragma mark - FWControlWrapper+FWBlock

@interface FWControlWrapper (FWBlock)

/// 添加事件句柄
- (NSString *)addBlock:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents;

/// 根据唯一标志移除事件句柄
- (void)removeBlock:(nullable NSString *)identifier forControlEvents:(UIControlEvents)controlEvents;

/// 移除所有事件句柄
- (void)removeAllBlocksForControlEvents:(UIControlEvents)controlEvents;

/// 添加点击事件
- (void)addTouchTarget:(id)target action:(SEL)action;

/// 添加点击句柄
- (NSString *)addTouchBlock:(void (^)(id sender))block;

/// 根据唯一标志移除点击句柄
- (void)removeTouchBlock:(nullable NSString *)identifier;

@end

#pragma mark - FWBarButtonItemWrapper+FWBlock

/**
 iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
 */
@interface FWBarButtonItemWrapper (FWBlock)

/// 设置当前Item触发句柄，nil时清空句柄
- (void)setBlock:(nullable void (^)(id sender))block;

@end

#pragma mark - FWBarButtonItemClassWrapper+FWBlock

@interface FWBarButtonItemClassWrapper (FWBlock)

/// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber等
- (UIBarButtonItem *)itemWithObject:(nullable id)object target:(nullable id)target action:(nullable SEL)action;

/// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber等
- (UIBarButtonItem *)itemWithObject:(nullable id)object block:(nullable void (^)(id sender))block;

@end

NS_ASSUME_NONNULL_END
