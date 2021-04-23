/*!
 @header     FWEmptyPlugin.h
 @indexgroup FWFramework
 @brief      FWEmptyPlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWEmptyPlugin

/// 空界面插件协议，应用可自定义空界面插件实现
@protocol FWEmptyPlugin <NSObject>

@optional

/// 显示空界面，指定文本、图片和动作按钮
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image action:(nullable NSString *)action block:(nullable void (^)(id sender))block inView:(UIView *)view;

/// 隐藏空界面
- (void)fwHideEmptyView:(UIView *)view;

/// 是否显示空界面
- (BOOL)fwHasEmptyView:(UIView *)view;

@end

/// 空界面插件配置类
@interface FWEmptyPluginConfig : NSObject

/// 配置单例
@property (class, nonatomic, readonly) FWEmptyPluginConfig *sharedInstance;

/// 显示空界面时是否执行淡入动画，默认YES
@property (nonatomic, assign) BOOL fadeAnimated;

/// 默认空界面文本句柄
@property (nonatomic, copy, nullable) NSString * _Nullable (^defaultText)(void);
/// 默认空界面详细文本句柄
@property (nonatomic, copy, nullable) NSString * _Nullable (^defaultDetail)(void);
/// 默认空界面图片句柄
@property (nonatomic, copy, nullable) UIImage * _Nullable (^defaultImage)(void);
/// 默认空界面动作按钮句柄
@property (nonatomic, copy, nullable) NSString * _Nullable (^defaultAction)(void);

@end

#pragma mark - FWEmptyPluginView

/// 空界面插件视图协议，使用空界面插件
@protocol FWEmptyPluginView <NSObject>
@required

/// 显示空界面
- (void)fwShowEmptyView;

/// 显示空界面，指定文本
- (void)fwShowEmptyViewWithText:(nullable NSString *)text;

/// 显示空界面，指定文本和详细文本
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail;

/// 显示空界面，指定文本、详细文本和图片
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image;

/// 显示空界面，指定文本、详细文本、图片和动作按钮
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image action:(nullable NSString *)action block:(nullable void (^)(id sender))block;

/// 隐藏空界面
- (void)fwHideEmptyView;

/// 是否显示空界面
- (BOOL)fwHasEmptyView;

@end

/// UIView使用空界面插件
@interface UIView (FWEmptyPluginView) <FWEmptyPluginView>

@end

/// UIViewController使用空界面插件，内部使用UIViewController.view
@interface UIViewController (FWEmptyPluginView) <FWEmptyPluginView>

@end

#pragma mark - UIScrollView+FWEmptyPlugin

/// 空界面代理协议
@protocol FWEmptyViewDelegate <NSObject>
@optional

/// 显示空界面，默认调用UIScrollView.fwShowEmptyView
- (void)fwShowEmptyView:(UIScrollView *)scrollView;

/// 隐藏空界面，默认调用UIScrollView.fwHideEmptyView
- (void)fwHideEmptyView:(UIScrollView *)scrollView;

/// 显示空界面时是否允许滚动，默认NO
- (BOOL)fwEmptyViewShouldScroll:(UIScrollView *)scrollView;

/// 无数据时是否显示空界面，默认YES
- (BOOL)fwEmptyViewShouldDisplay:(UIScrollView *)scrollView;

/// 有数据时是否强制显示空界面，默认NO
- (BOOL)fwEmptyViewForceDisplay:(UIScrollView *)scrollView;

@end

/**
 @brief 滚动视图空界面分类
 
 @see https://github.com/dzenbot/DZNEmptyDataSet
 */
@interface UIScrollView (FWEmptyPlugin)

/// 空界面代理，默认nil
@property (nonatomic, weak, nullable) IBOutlet id<FWEmptyViewDelegate> fwEmptyViewDelegate;

/// 刷新空界面
- (void)fwReloadEmptyView;

@end

NS_ASSUME_NONNULL_END
