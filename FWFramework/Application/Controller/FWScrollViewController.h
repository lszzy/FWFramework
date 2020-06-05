/*!
 @header     FWScrollViewController.h
 @indexgroup FWFramework
 @brief      FWScrollViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWViewController.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 滚动视图控制器协议，可覆写
 */
@protocol FWScrollViewController <FWViewController>

@optional

// 滚动视图，默认不显示滚动条
@property (nonatomic, readonly) UIScrollView *scrollView NS_REFINED_FOR_SWIFT;

// 内容容器视图，自动撑开，子视图需要添加到此视图上
@property (nonatomic, readonly) UIView *contentView NS_REFINED_FOR_SWIFT;

// 渲染滚动视图，renderView之前调用，默认未实现
- (void)renderScrollView;

// 渲染滚动视图布局，renderView之前调用，默认铺满
- (void)renderScrollLayout;

@end

/*!
 @brief 管理器滚动视图控制器分类
 */
@interface FWViewControllerManager (FWScrollViewController)

@end

NS_ASSUME_NONNULL_END
