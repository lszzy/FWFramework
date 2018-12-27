/*!
 @header     FWScrollViewController.h
 @indexgroup FWFramework
 @brief      FWScrollViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWViewController.h"

@protocol FWScrollViewController <FWViewController>

@optional

// 滚动视图，默认不显示滚动条
@property (nonatomic, readonly) UIScrollView *fwScrollView;

// 内容容器视图，自动撑开，子视图需要添加到此视图上
@property (nonatomic, readonly) UIView *fwContentView;

// 渲染滚动视图，loadView自动调用
- (UIScrollView *)fwRenderScrollView;

// 渲染滚动视图布局，默认铺满，loadView自动调用
- (void)fwRenderScrollLayout;

@end

@interface FWViewControllerIntercepter (FWScrollViewController)

- (void)setupScrollViewController:(UIViewController *)viewController;

@end
