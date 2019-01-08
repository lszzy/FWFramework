/*!
 @header     FWScrollViewController.h
 @indexgroup FWFramework
 @brief      FWScrollViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWViewController.h"

/*!
 @brief 滚动视图控制器协议，可覆写
 */
@protocol FWScrollViewController <FWViewController>

@optional

// 滚动视图，默认不显示滚动条
@property (nonatomic, readonly) UIScrollView *fwScrollView;

// 内容容器视图，自动撑开，子视图需要添加到此视图上
@property (nonatomic, readonly) UIView *fwContentView;

// 渲染滚动视图和布局等，默认铺满
- (void)fwRenderScrollView;

@end

/*!
 @brief 管理器滚动视图控制器分类
 */
@interface FWViewControllerManager (FWScrollViewController)

@end
