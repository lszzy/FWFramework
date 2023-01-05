//
//  ToastPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ToastPluginImpl.h"

#if FWMacroSPM

@interface UIView ()

- (NSArray<NSLayoutConstraint *> *)__fw_pinEdgesToSuperview:(UIEdgeInsets)insets;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWToastPluginImpl

@implementation __FWToastPluginImpl

+ (__FWToastPluginImpl *)sharedInstance
{
    static __FWToastPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWToastPluginImpl alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fadeAnimated = YES;
        _delayTime = 2.0;
    }
    return self;
}

- (void)showLoadingWithAttributedText:(NSAttributedString *)attributedText cancelBlock:(void (^)(void))cancelBlock inView:(UIView *)view
{
    NSAttributedString *loadingText = attributedText;
    if (!loadingText && self.defaultLoadingText) {
        loadingText = self.defaultLoadingText();
    }
    
    __FWToastView *toastView = (__FWToastView *)[view __fw_subviewWithTag:2011];
    if (toastView) {
        [toastView invalidateTimer];
        [view bringSubviewToFront:toastView];
        toastView.attributedTitle = loadingText;
        toastView.cancelBlock = cancelBlock;
        
        if (self.reuseBlock) {
            self.reuseBlock(toastView);
        }
        return;
    }
    
    toastView = [[__FWToastView alloc] initWithType:__FWToastViewTypeIndicator];
    toastView.tag = 2011;
    toastView.attributedTitle = loadingText;
    toastView.cancelBlock = cancelBlock;
    [view addSubview:toastView];
    [toastView __fw_pinEdgesToSuperview:view.__fw_toastInsets];
    
    if (self.customBlock) {
        self.customBlock(toastView);
    }
    [toastView showAnimated:self.fadeAnimated];
}

- (void)hideLoading:(UIView *)view
{
    __FWToastView *toastView = (__FWToastView *)[view __fw_subviewWithTag:2011];
    if (toastView) [toastView hide];
}

- (BOOL)isShowingLoading:(UIView *)view
{
    __FWToastView *toastView = (__FWToastView *)[view __fw_subviewWithTag:2011];
    return toastView ? YES : NO;
}

- (void)showProgressWithAttributedText:(NSAttributedString *)attributedText progress:(CGFloat)progress cancelBlock:(void (^)(void))cancelBlock inView:(UIView *)view
{
    NSAttributedString *progressText = attributedText;
    if (!progressText && self.defaultProgressText) {
        progressText = self.defaultProgressText();
    }
    
    __FWToastView *toastView = (__FWToastView *)[view __fw_subviewWithTag:2012];
    if (toastView) {
        [toastView invalidateTimer];
        [view bringSubviewToFront:toastView];
        toastView.attributedTitle = progressText;
        toastView.progress = progress;
        toastView.cancelBlock = cancelBlock;
        
        if (self.reuseBlock) {
            self.reuseBlock(toastView);
        }
        return;
    }
    
    toastView = [[__FWToastView alloc] initWithType:__FWToastViewTypeProgress];
    toastView.tag = 2012;
    toastView.attributedTitle = progressText;
    toastView.progress = progress;
    toastView.cancelBlock = cancelBlock;
    [view addSubview:toastView];
    [toastView __fw_pinEdgesToSuperview:view.__fw_toastInsets];
    
    if (self.customBlock) {
        self.customBlock(toastView);
    }
    [toastView showAnimated:self.fadeAnimated];
}

- (void)hideProgress:(UIView *)view
{
    __FWToastView *toastView = (__FWToastView *)[view __fw_subviewWithTag:2012];
    if (toastView) [toastView hide];
}

- (BOOL)isShowingProgress:(UIView *)view
{
    __FWToastView *toastView = (__FWToastView *)[view __fw_subviewWithTag:2012];
    return toastView ? YES : NO;
}

- (void)showMessageWithAttributedText:(NSAttributedString *)attributedText style:(__FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(void (^)(void))completion inView:(UIView *)view
{
    NSAttributedString *messageText = attributedText;
    if (!messageText && self.defaultMessageText) {
        messageText = self.defaultMessageText(style);
    }
    if (messageText.length < 1) return;
    
    __FWToastView *toastView = (__FWToastView *)[view __fw_subviewWithTag:2013];
    BOOL fadeAnimated = self.fadeAnimated && !toastView;
    if (toastView) [toastView hide];
    
    toastView = [[__FWToastView alloc] initWithType:__FWToastViewTypeText];
    toastView.tag = 2013;
    toastView.userInteractionEnabled = !interactive;
    toastView.attributedTitle = messageText;
    [view addSubview:toastView];
    [toastView __fw_pinEdgesToSuperview:view.__fw_toastInsets];
    
    if (self.customBlock) {
        self.customBlock(toastView);
    }
    [toastView showAnimated:fadeAnimated];
    
    if (autoHide) {
        [toastView hideAfterDelay:self.delayTime completion:completion];
    }
}

- (void)hideMessage:(UIView *)view
{
    __FWToastView *toastView = (__FWToastView *)[view __fw_subviewWithTag:2013];
    if (toastView) [toastView hide];
}

- (BOOL)isShowingMessage:(UIView *)view
{
    __FWToastView *toastView = (__FWToastView *)[view __fw_subviewWithTag:2013];
    return toastView ? YES : NO;
}

@end
