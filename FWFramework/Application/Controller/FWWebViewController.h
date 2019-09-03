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

// 网页视图，默认显示滚动条，启用前进后退手势
@property (nonatomic, readonly) WKWebView *webView;

// 进度视图，默认trackTintColor为clear
@property (nonatomic, readonly) UIProgressView *progressView;

// 返回按钮，默认箭头图标，可覆写。如果为nil，不处理
@property (nullable, nonatomic, readonly) UIBarButtonItem *webBackItem;

// 关闭按钮，默认关闭图标，可覆写。如果为nil，不处理
@property (nullable, nonatomic, readonly) UIBarButtonItem *webCloseItem;

// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest
@property (nullable, nonatomic, strong) id webRequest;

// 渲染网页视图和布局等，默认铺满
- (void)renderWebView;

@end

/*!
 @brief 管理器网页视图控制器分类
 */
@interface FWViewControllerManager (FWWebViewController)

@end

NS_ASSUME_NONNULL_END
