/*!
 @header     FWWebViewController.h
 @indexgroup FWFramework
 @brief      FWWebViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/28
 */

#import <WebKit/WebKit.h>
#import "FWViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class FWWebViewJsBridge;

/*!
 @brief 网页视图控制器协议，可覆写
 @discussion 默认实现并允许JS调用alert|confirm|prompt方法，如不需要可覆盖之。
 默认自定义User-Agent为请求通用格式，如不需要可覆盖之。
 */
@protocol FWWebViewController <FWViewController, WKNavigationDelegate, WKUIDelegate>

@optional

// 网页视图，默认显示滚动条，启用前进后退手势
@property (nonatomic, readonly) WKWebView *webView;

// 进度视图，默认trackTintColor为clear
@property (nonatomic, readonly) UIProgressView *progressView;

// 左侧按钮组，依次为返回|关闭，支持UIBarButtonItem|UIImage|NSString|NSNumber等。可覆写，默认nil
@property (nullable, nonatomic, readonly) NSArray *webItems;

// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
@property (nullable, nonatomic, strong) id webRequest;

// 渲染网页视图，renderView之前调用，默认未实现
- (void)renderWebView;

// 渲染网页视图布局，renderView之前调用，默认铺满
- (void)renderWebLayout;

// 渲染网页桥接，renderView之前调用，默认未实现
- (void)renderWebBridge:(FWWebViewJsBridge *)bridge;

// 是否开始加载，可用来拦截URL SCHEME、通用链接、系统链接(如tel默认未开放)等，默认未实现
- (BOOL)shouldStartLoad:(WKNavigationAction *)navigationAction;

// 已经加载完成，可用来获取title、设置按钮等，默认未实现
- (void)didFinishLoad:(WKNavigation *)navigation;

@end

/*!
 @brief 管理器网页视图控制器分类
 */
@interface FWViewControllerManager (FWWebViewController)

@end

NS_ASSUME_NONNULL_END
