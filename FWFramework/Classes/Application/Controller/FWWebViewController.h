/*!
 @header     FWWebViewController.h
 @indexgroup FWFramework
 @brief      FWWebViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/28
 */

#import <WebKit/WebKit.h>
#import "FWWebViewBridge.h"
#import "FWViewController.h"
#import "FWCollectionViewController.h"
#import "FWScrollViewController.h"
#import "FWTableViewController.h"
#import "FWNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 网页视图控制器协议，可覆写
 */
@protocol FWWebViewController <FWViewController, FWWebViewDelegate>

@optional

/// 网页视图，默认显示滚动条，启用前进后退手势
@property (nonatomic, readonly) FWWebView *webView NS_SWIFT_UNAVAILABLE("");

/// 左侧按钮组，依次为返回|关闭，支持UIBarButtonItem|UIImage|NSString|NSNumber等。可覆写，默认nil
@property (nullable, nonatomic, readonly) NSArray *webItems NS_SWIFT_UNAVAILABLE("");

/// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
@property (nullable, nonatomic, strong) id webRequest NS_SWIFT_UNAVAILABLE("");

/// 渲染网页配置，renderWebView之前调用，默认未实现
- (WKWebViewConfiguration *)renderWebConfiguration;

/// 渲染网页视图，renderView之前调用，默认未实现
- (void)renderWebView;

/// 渲染网页视图布局，renderView之前调用，默认铺满
- (void)renderWebLayout;

/// 渲染网页桥接，renderView之前调用，默认未实现
- (void)renderWebBridge:(FWWebViewJsBridge *)bridge;

/// 点击关闭按钮(不含手势返回)，可用来拦截关闭时二次确认等，默认直接关闭
- (void)onWebClose;

@end

/*!
 @brief 管理器网页视图控制器分类
 */
@interface FWViewControllerManager (FWWebViewController)

@end

NS_ASSUME_NONNULL_END
