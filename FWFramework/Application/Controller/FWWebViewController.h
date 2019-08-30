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

/*!
 @brief 网页视图控制器协议，可覆写
 */
@protocol FWWebViewController <FWViewController, WKNavigationDelegate>

@optional

// 网页视图，默认不显示滚动条
@property (nonatomic, readonly) WKWebView *webView;

// 渲染网页视图配置，默认系统配置
- (WKWebViewConfiguration *)renderWebConfiguration;

// 渲染网页视图和布局等，默认铺满
- (void)renderWebView;

@end

/*!
 @brief 管理器网页视图控制器分类
 */
@interface FWViewControllerManager (FWWebViewController)

@end

NS_ASSUME_NONNULL_END
