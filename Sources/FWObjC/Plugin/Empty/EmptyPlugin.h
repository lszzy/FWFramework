//
//  EmptyPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWEmptyPlugin

/// 空界面插件协议，应用可自定义空界面插件实现
NS_SWIFT_NAME(EmptyPlugin)
@protocol __FWEmptyPlugin <NSObject>

@optional

/// 显示空界面，指定文本、详细文本、图片、加载视图和最多两个动作按钮
- (void)showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image loading:(BOOL)loading actions:(nullable NSArray *)actions block:(nullable void (^)(NSInteger index, id sender))block inView:(UIView *)view;

/// 隐藏空界面
- (void)hideEmptyView:(UIView *)view;

/// 是否显示空界面
- (BOOL)hasEmptyView:(UIView *)view;

@end

#pragma mark - __FWEmptyViewDelegate

/// 空界面代理协议
NS_SWIFT_NAME(EmptyViewDelegate)
@protocol __FWEmptyViewDelegate <NSObject>
@optional

/// 显示空界面，默认调用UIScrollView.fwShowEmptyView
- (void)showEmptyView:(UIScrollView *)scrollView;

/// 隐藏空界面，默认调用UIScrollView.fwHideEmptyView
- (void)hideEmptyView:(UIScrollView *)scrollView;

/// 显示空界面时是否允许滚动，默认NO
- (BOOL)emptyViewShouldScroll:(UIScrollView *)scrollView;

/// 无数据时是否显示空界面，默认YES
- (BOOL)emptyViewShouldDisplay:(UIScrollView *)scrollView;

/// 有数据时是否强制显示空界面，默认NO
- (BOOL)emptyViewForceDisplay:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
