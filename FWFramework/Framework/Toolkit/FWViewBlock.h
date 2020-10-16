/*!
 @header     FWViewBlock.h
 @indexgroup FWFramework
 @brief      FWViewBlock
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
+ (instancetype)fwBarItemWithObject:(nullable id)object target:(id)target action:(SEL)action;

// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber等
+ (instancetype)fwBarItemWithObject:(nullable id)object block:(void (^)(id sender))block;

@end

NS_ASSUME_NONNULL_END
