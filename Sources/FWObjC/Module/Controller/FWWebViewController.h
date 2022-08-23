//
//  FWWebViewController.h
//  
//
//  Created by wuyong on 2022/8/23.
//

#import "FWWebView.h"
#import "FWViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 网页视图控制器协议，可覆写
 */
NS_SWIFT_NAME(WebViewControllerProtocol)
@protocol FWWebViewController <FWViewController, FWWebViewDelegate>

@optional

/// 网页视图，默认显示滚动条，启用前进后退手势
@property (nonatomic, readonly) FWWebView *webView NS_SWIFT_UNAVAILABLE("");

/// 左侧按钮组，依次为返回|关闭，支持UIBarButtonItem|UIImage|NSString|NSNumber等。可覆写，默认nil
@property (nullable, nonatomic, copy) NSArray *webItems NS_SWIFT_UNAVAILABLE("");

/// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
@property (nullable, nonatomic, strong) id webRequest NS_SWIFT_UNAVAILABLE("");

/// 渲染网页配置，setupWebView之前调用，默认未实现
- (WKWebViewConfiguration *)setupWebConfiguration;

/// 渲染网页视图，setupSubviews之前调用，默认未实现
- (void)setupWebView;

/// 渲染网页视图布局，setupSubviews之前调用，默认铺满
- (void)setupWebLayout;

/// 渲染网页桥接，setupSubviews之前调用，默认未实现
- (void)setupWebBridge:(FWWebViewJsBridge *)bridge;

@end

/**
 管理器网页视图控制器分类
 */
@interface FWViewControllerManager (FWWebViewController)

@end

NS_ASSUME_NONNULL_END
