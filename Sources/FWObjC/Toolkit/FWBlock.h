//
//  FWBlock.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWBlock

/**
 通用互斥锁方法
 */
void FWSynchronized(id object, __attribute__((noescape)) void (^closure)(void)) NS_REFINED_FOR_SWIFT;

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

/**
 通用(NSInteger,id)参数block
 
 @param index NSInteger参数
 @param param id参数
 */
typedef void (^FWBlockIntParam)(NSInteger index, id _Nullable param) NS_SWIFT_UNAVAILABLE("");

#pragma mark - NSTimer+FWBlock

@interface NSTimer (FWBlock)

/**
 创建NSTimer，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param seconds 时间
 @param target 目标
 @param selector 方法
 @param userInfo 参数
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fw_commonTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector userInfo:(nullable id)userInfo repeats:(BOOL)repeats NS_REFINED_FOR_SWIFT;

/**
 创建NSTimer，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fw_commonTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats NS_REFINED_FOR_SWIFT;

/**
 创建倒计时定时器
 
 @param seconds 倒计时描述
 @param block 每秒执行block，为0时自动停止
 @return 定时器，可手工停止
 */
+ (NSTimer *)fw_commonTimerWithCountDown:(NSInteger)seconds block:(void (^)(NSInteger countDown))block NS_REFINED_FOR_SWIFT;

/**
 创建NSTimer，使用block，需要调用addTimer:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
 @note 示例：[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes]
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fw_timerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats NS_REFINED_FOR_SWIFT;

/**
 创建NSTimer，使用block，默认模式安排到当前的运行循环中
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fw_scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats NS_REFINED_FOR_SWIFT;

/// 暂停NSTimer
- (void)fw_pauseTimer NS_REFINED_FOR_SWIFT;

/// 开始NSTimer
- (void)fw_resumeTimer NS_REFINED_FOR_SWIFT;

/// 延迟delay秒后开始NSTimer
- (void)fw_resumeTimerAfterDelay:(NSTimeInterval)delay NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIGestureRecognizer+FWBlock

@interface UIGestureRecognizer (FWBlock)

/// 添加事件句柄，返回唯一标志
- (NSString *)fw_addBlock:(void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 根据唯一标志移除事件句柄
- (void)fw_removeBlock:(nullable NSString *)identifier NS_REFINED_FOR_SWIFT;

/// 移除所有事件句柄
- (void)fw_removeAllBlocks NS_REFINED_FOR_SWIFT;

/// 从事件句柄初始化
+ (instancetype)fw_gestureRecognizerWithBlock:(void (^)(id sender))block NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIView+FWBlock

@interface UIView (FWBlock)

/// 获取当前视图添加的第一个点击手势，默认nil
@property (nonatomic, readonly, nullable) UITapGestureRecognizer *fw_tapGesture NS_REFINED_FOR_SWIFT;

/// 添加点击手势事件，默认子视图也会响应此事件。如要屏蔽之，解决方法：1、子视图设为UIButton；2、子视图添加空手势事件
- (void)fw_addTapGestureWithTarget:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/// 添加点击手势句柄，同上
- (NSString *)fw_addTapGestureWithBlock:(void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 根据唯一标志移除点击手势句柄
- (void)fw_removeTapGesture:(nullable NSString *)identifier NS_REFINED_FOR_SWIFT;

/// 移除所有点击手势
- (void)fw_removeAllTapGestures NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIControl+FWBlock

@interface UIControl (FWBlock)

/// 添加事件句柄
- (NSString *)fw_addBlock:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents NS_REFINED_FOR_SWIFT;

/// 根据唯一标志移除事件句柄
- (void)fw_removeBlock:(nullable NSString *)identifier forControlEvents:(UIControlEvents)controlEvents NS_REFINED_FOR_SWIFT;

/// 移除所有事件句柄
- (void)fw_removeAllBlocksForControlEvents:(UIControlEvents)controlEvents NS_REFINED_FOR_SWIFT;

/// 添加点击事件
- (void)fw_addTouchTarget:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/// 添加点击句柄
- (NSString *)fw_addTouchBlock:(void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 根据唯一标志移除点击句柄
- (void)fw_removeTouchBlock:(nullable NSString *)identifier NS_REFINED_FOR_SWIFT;

/// 移除所有点击句柄
- (void)fw_removeAllTouchBlocks NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIBarButtonItem+FWBlock

/**
 iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
 */
@interface UIBarButtonItem (FWBlock)

/// 自定义标题样式属性，兼容appearance，默认nil同系统
@property (nonatomic, copy, nullable) NSDictionary<NSAttributedStringKey, id> *fw_titleAttributes NS_REFINED_FOR_SWIFT;

/// 设置当前Item触发句柄，nil时清空句柄
- (void)fw_setBlock:(nullable void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
+ (instancetype)fw_itemWithObject:(nullable id)object target:(nullable id)target action:(nullable SEL)action NS_REFINED_FOR_SWIFT;

/// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
+ (instancetype)fw_itemWithObject:(nullable id)object block:(nullable void (^)(id sender))block NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIViewController+FWBlock

/// iOS13+支持针对VC.navigationItem单独设置导航栏样式，如最低兼容iOS13时可使用
@interface UIViewController (FWBlock)

/// 快捷设置导航栏标题
@property (nonatomic, copy, nullable) NSString *fw_title NS_REFINED_FOR_SWIFT;

/// 设置导航栏返回按钮，支持UIBarButtonItem|NSString|UIImage等，nil时显示系统箭头，下个页面生效
@property (nonatomic, strong, nullable) id fw_backBarItem NS_REFINED_FOR_SWIFT;

/// 设置导航栏左侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
@property (nonatomic, strong, nullable) id fw_leftBarItem NS_REFINED_FOR_SWIFT;

/// 设置导航栏右侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
@property (nonatomic, strong, nullable) id fw_rightBarItem NS_REFINED_FOR_SWIFT;

/// 快捷设置导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
- (void)fw_setLeftBarItem:(nullable id)object target:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/// 快捷设置导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
- (void)fw_setLeftBarItem:(nullable id)object block:(void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 快捷设置导航栏右侧按钮
- (void)fw_setRightBarItem:(nullable id)object target:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/// 快捷设置导航栏右侧按钮，block事件
- (void)fw_setRightBarItem:(nullable id)object block:(void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 快捷添加导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
- (void)fw_addLeftBarItem:(nullable id)object target:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/// 快捷添加导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
- (void)fw_addLeftBarItem:(nullable id)object block:(void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 快捷添加导航栏右侧按钮
- (void)fw_addRightBarItem:(nullable id)object target:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/// 快捷添加导航栏右侧按钮，block事件
- (void)fw_addRightBarItem:(nullable id)object block:(void (^)(id sender))block NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
