//
//  UIView+FWBlock.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIGestureRecognizer+FWBlock

@interface UIGestureRecognizer (FWBlock)

// 获取手势直接作用的view，不同于view，此处是view的subview
@property (nullable, nonatomic, weak, readonly) UIView *fwTargetView;

// 从事件句柄初始化
+ (instancetype)fwGestureRecognizerWithBlock:(void (^)(id sender))block;

// 添加事件句柄
- (void)fwAddBlock:(void (^)(id sender))block;

// 移除所有事件句柄
- (void)fwRemoveAllBlocks;

@end

#pragma mark - UIView+FWBlock

@interface UIView (FWBlock)

// 添加点击手势事件，默认子视图也会响应此事件。如要屏蔽之，解决方法：1、子视图设为UIButton；2、子视图添加空手势事件
- (void)fwAddTapGestureWithTarget:(id)target action:(SEL)action;

// 添加点击手势句柄，同上
- (void)fwAddTapGestureWithBlock:(void (^)(id sender))block;

// 移除所有点击手势
- (void)fwRemoveAllTapGestures;

@end

#pragma mark - UIControl+FWBlock

@interface UIControl (FWBlock)

// 添加事件句柄
- (void)fwAddBlock:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents;

// 移除所有事件句柄
- (void)fwRemoveAllBlocksForControlEvents:(UIControlEvents)controlEvents;

// 添加点击事件
- (void)fwAddTouchTarget:(id)target action:(SEL)action;

// 添加点击句柄
- (void)fwAddTouchBlock:(void (^)(id sender))block;

@end

#pragma mark - UIBarButtonItem+FWBlock

/*!
 @brief iOS11之后，customView必须具有intrinsicContentSize值才能点击，可使用frame布局或者实现intrinsicContentSize即可
 */
@interface UIBarButtonItem (FWBlock)

// 使用指定对象和事件创建Item
+ (instancetype)fwBarItemWithObject:(nullable id)object target:(id)target action:(SEL)action;

// 使用指定对象和句柄创建Item
+ (instancetype)fwBarItemWithObject:(nullable id)object block:(void (^)(id sender))block;

@end

NS_ASSUME_NONNULL_END
