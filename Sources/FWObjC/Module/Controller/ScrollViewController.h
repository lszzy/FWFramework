//
//  ScrollViewController.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 滚动视图控制器协议，可覆写
 */
NS_SWIFT_NAME(ScrollViewControllerProtocol)
@protocol __FWScrollViewController <__FWViewController>

@optional

/// 滚动视图，默认不显示滚动条
@property (nonatomic, readonly) UIScrollView *scrollView NS_SWIFT_UNAVAILABLE("");

/// 内容容器视图，自动撑开，子视图需要添加到此视图上
@property (nonatomic, readonly) UIView *contentView NS_SWIFT_UNAVAILABLE("");

/// 渲染滚动视图，setupSubviews之前调用，默认未实现
- (void)setupScrollView;

/// 渲染滚动视图布局，setupSubviews之前调用，默认铺满
- (void)setupScrollLayout;

@end

/**
 管理器滚动视图控制器分类
 */
@interface __FWViewControllerManager (__FWScrollViewController)

@end

NS_ASSUME_NONNULL_END
