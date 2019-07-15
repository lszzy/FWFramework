/*!
 @header     UIWebView+FWFramework.h
 @indexgroup FWFramework
 @brief      UIWebView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/4
 */

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIWebView

extern const float FWInitialProgressValue;
extern const float FWInteractiveProgressValue;
extern const float FWFinalProgressValue;

typedef void (^FWWebViewProgressBlock)(float progress);

@protocol FWWebViewProgressDelegate;

@interface FWWebViewProgress : NSObject<UIWebViewDelegate>

@property (nullable, nonatomic, weak) id<FWWebViewProgressDelegate> progressDelegate;
@property (nullable, nonatomic, weak) id<UIWebViewDelegate> webViewProxyDelegate;
@property (nullable, nonatomic, copy) FWWebViewProgressBlock progressBlock;
// 0.0..1.0
@property (nonatomic, readonly) float progress;

- (void)reset;

@end

@protocol FWWebViewProgressDelegate <NSObject>

- (void)webViewProgress:(FWWebViewProgress *)webViewProgress updateProgress:(float)progress;

@end

@interface FWWebViewProgressView : UIView

@property (nonatomic) float progress;

@property (nonatomic) UIView *progressBarView;
// default 0.1
@property (nonatomic) NSTimeInterval barAnimationDuration;
// default 0.27
@property (nonatomic) NSTimeInterval fadeAnimationDuration;
// default 0.1
@property (nonatomic) NSTimeInterval fadeOutDelay;

- (void)setProgress:(float)progress animated:(BOOL)animated;

@end

#pragma mark - WKWebView

@protocol FWWebViewNavigationDelegate <WKNavigationDelegate>

- (void)webView:(WKWebView *)webView updateProgress:(CGFloat)progress;

@end

@interface WKWebView (FWFramework)

@property (nullable, nonatomic, weak) id <FWWebViewNavigationDelegate> fwNavigationDelegate;

@end

@interface UIProgressView (FWFramework)

// 更新进度，0和1自动切换隐藏状态。可设置trackTintColor为clear，隐藏背景色
- (void)fwSetProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
