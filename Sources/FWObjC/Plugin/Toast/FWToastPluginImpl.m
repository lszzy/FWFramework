//
//  FWToastPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWToastPluginImpl.h"
#import "FWUIKit.h"

#if FWMacroSPM



#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - FWToastPluginImpl

@implementation FWToastPluginImpl

+ (FWToastPluginImpl *)sharedInstance
{
    static FWToastPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWToastPluginImpl alloc] init];
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
    
    FWToastView *toastView = [view fw_subviewWithTag:2011];
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
    
    toastView = [[FWToastView alloc] initWithType:FWToastViewTypeIndicator];
    toastView.tag = 2011;
    toastView.attributedTitle = loadingText;
    toastView.cancelBlock = cancelBlock;
    [view addSubview:toastView];
    [toastView fw_pinEdgesToSuperview:view.fw_toastInsets];
    
    if (self.customBlock) {
        self.customBlock(toastView);
    }
    [toastView showAnimated:self.fadeAnimated];
}

- (void)hideLoading:(UIView *)view
{
    FWToastView *toastView = [view fw_subviewWithTag:2011];
    if (toastView) [toastView hide];
}

- (BOOL)isShowingLoading:(UIView *)view
{
    FWToastView *toastView = [view fw_subviewWithTag:2011];
    return toastView ? YES : NO;
}

- (void)showProgressWithAttributedText:(NSAttributedString *)attributedText progress:(CGFloat)progress cancelBlock:(void (^)(void))cancelBlock inView:(UIView *)view
{
    NSAttributedString *progressText = attributedText;
    if (!progressText && self.defaultProgressText) {
        progressText = self.defaultProgressText();
    }
    
    FWToastView *toastView = [view fw_subviewWithTag:2012];
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
    
    toastView = [[FWToastView alloc] initWithType:FWToastViewTypeProgress];
    toastView.tag = 2012;
    toastView.attributedTitle = progressText;
    toastView.progress = progress;
    toastView.cancelBlock = cancelBlock;
    [view addSubview:toastView];
    [toastView fw_pinEdgesToSuperview:view.fw_toastInsets];
    
    if (self.customBlock) {
        self.customBlock(toastView);
    }
    [toastView showAnimated:self.fadeAnimated];
}

- (void)hideProgress:(UIView *)view
{
    FWToastView *toastView = [view fw_subviewWithTag:2012];
    if (toastView) [toastView hide];
}

- (BOOL)isShowingProgress:(UIView *)view
{
    FWToastView *toastView = [view fw_subviewWithTag:2012];
    return toastView ? YES : NO;
}

- (void)showMessageWithAttributedText:(NSAttributedString *)attributedText style:(FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(void (^)(void))completion inView:(UIView *)view
{
    NSAttributedString *messageText = attributedText;
    if (!messageText && self.defaultMessageText) {
        messageText = self.defaultMessageText(style);
    }
    if (messageText.length < 1) return;
    
    FWToastView *toastView = [view fw_subviewWithTag:2013];
    BOOL fadeAnimated = self.fadeAnimated && !toastView;
    if (toastView) [toastView hide];
    
    toastView = [[FWToastView alloc] initWithType:FWToastViewTypeText];
    toastView.tag = 2013;
    toastView.userInteractionEnabled = !interactive;
    toastView.attributedTitle = messageText;
    [view addSubview:toastView];
    [toastView fw_pinEdgesToSuperview:view.fw_toastInsets];
    
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
    FWToastView *toastView = [view fw_subviewWithTag:2013];
    if (toastView) [toastView hide];
}

- (BOOL)isShowingMessage:(UIView *)view
{
    FWToastView *toastView = [view fw_subviewWithTag:2013];
    return toastView ? YES : NO;
}

@end
