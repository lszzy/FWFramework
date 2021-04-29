/*!
 @header     FWToastPlugin.m
 @indexgroup FWFramework
 @brief      FWToastPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWToastPlugin.h"
#import "FWToastPluginImpl.h"
#import "FWAutoLayout.h"
#import "FWPlugin.h"

#pragma mark - FWToastPlugin

@implementation FWToastPluginConfig

+ (FWToastPluginConfig *)sharedInstance
{
    static FWToastPluginConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWToastPluginConfig alloc] init];
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

@end

#pragma mark - FWToastPluginView

@implementation UIView (FWToastPluginView)

- (void)fwShowLoading
{
    [self fwShowLoadingWithText:nil];
}

- (void)fwShowLoadingWithText:(id)text
{
    id loadingText = text;
    if (!loadingText && FWToastPluginConfig.sharedInstance.defaultLoadingText) {
        loadingText = FWToastPluginConfig.sharedInstance.defaultLoadingText();
    }
    
    NSAttributedString *attributedText = [loadingText isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:loadingText] : loadingText;
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwShowLoadingWithAttributedText:inView:)]) {
        [plugin fwShowLoadingWithAttributedText:attributedText inView:self];
        return;
    }
    
    FWToastView *toastView = [self viewWithTag:2011];
    if (toastView) {
        [toastView invalidateTimer];
        [self bringSubviewToFront:toastView];
        toastView.attributedTitle = attributedText;
        return;
    }
    
    toastView = [[FWToastView alloc] initWithType:FWToastViewTypeIndicator];
    toastView.tag = 2011;
    toastView.attributedTitle = attributedText;
    [self addSubview:toastView];
    [toastView fwPinEdgesToSuperview];
    
    if (FWToastPluginConfig.sharedInstance.customBlock) {
        FWToastPluginConfig.sharedInstance.customBlock(self);
    }
    [toastView showAnimated:FWToastPluginConfig.sharedInstance.fadeAnimated];
}

- (void)fwHideLoading
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideLoading:)]) {
        [plugin fwHideLoading:self];
        return;
    }
    
    FWToastView *toastView = [self viewWithTag:2011];
    if (toastView) [toastView hide];
}

- (void)fwShowProgressWithText:(id)text progress:(CGFloat)progress
{
    id progressText = text;
    if (!progressText && FWToastPluginConfig.sharedInstance.defaultProgressText) {
        progressText = FWToastPluginConfig.sharedInstance.defaultProgressText();
    }
    
    NSAttributedString *attributedText = [progressText isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:progressText] : progressText;
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwShowProgressWithAttributedText:progress:inView:)]) {
        [plugin fwShowProgressWithAttributedText:attributedText progress:progress inView:self];
        return;
    }
    
    FWToastView *toastView = [self viewWithTag:2012];
    if (toastView) {
        [toastView invalidateTimer];
        [self bringSubviewToFront:toastView];
        toastView.attributedTitle = attributedText;
        toastView.progress = progress;
        return;
    }
    
    toastView = [[FWToastView alloc] initWithType:FWToastViewTypeProgress];
    toastView.tag = 2012;
    toastView.attributedTitle = attributedText;
    toastView.progress = progress;
    [self addSubview:toastView];
    [toastView fwPinEdgesToSuperview];
    
    if (FWToastPluginConfig.sharedInstance.customBlock) {
        FWToastPluginConfig.sharedInstance.customBlock(self);
    }
    [toastView showAnimated:FWToastPluginConfig.sharedInstance.fadeAnimated];
}

- (void)fwHideProgress
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideProgress:)]) {
        [plugin fwHideProgress:self];
        return;
    }
    
    FWToastView *toastView = [self viewWithTag:2012];
    if (toastView) [toastView hide];
}

- (void)fwShowMessageWithText:(id)text
{
    [self fwShowMessageWithText:text style:FWToastStyleDefault];
}

- (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style
{
    [self fwShowMessageWithText:text style:style completion:nil];
}

- (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style completion:(void (^)(void))completion
{
    id messageText = text;
    if (!messageText && FWToastPluginConfig.sharedInstance.defaultMessageText) {
        messageText = FWToastPluginConfig.sharedInstance.defaultMessageText(style);
    }
    
    NSAttributedString *attributedText = [messageText isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:messageText] : messageText;
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwShowMessageWithAttributedText:style:completion:inView:)]) {
        [plugin fwShowMessageWithAttributedText:attributedText style:style completion:completion inView:self];
        return;
    }
    
    FWToastView *toastView = [self viewWithTag:2013];
    BOOL fadeAnimated = FWToastPluginConfig.sharedInstance.fadeAnimated && !toastView;
    if (toastView) [toastView hide];
    
    toastView = [[FWToastView alloc] initWithType:FWToastViewTypeText];
    toastView.tag = 2013;
    toastView.userInteractionEnabled = completion ? YES : NO;
    toastView.attributedTitle = attributedText;
    [self addSubview:toastView];
    [toastView fwPinEdgesToSuperview];
    
    if (FWToastPluginConfig.sharedInstance.customBlock) {
        FWToastPluginConfig.sharedInstance.customBlock(self);
    }
    [toastView showAnimated:fadeAnimated];
    [toastView hideAfterDelay:FWToastPluginConfig.sharedInstance.delayTime completion:completion];
}

- (void)fwHideMessage
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideMessage:)]) {
        [plugin fwHideMessage:self];
        return;
    }
    
    FWToastView *toastView = [self viewWithTag:2013];
    if (toastView) [toastView hide];
}

@end

@implementation UIViewController (FWToastPluginView)

- (void)fwShowLoading
{
    [self.view fwShowLoading];
}

- (void)fwShowLoadingWithText:(id)text
{
    [self.view fwShowLoadingWithText:text];
}

- (void)fwHideLoading
{
    [self.view fwHideLoading];
}

- (void)fwShowProgressWithText:(id)text progress:(CGFloat)progress
{
    [self.view fwShowProgressWithText:text progress:progress];
}

- (void)fwHideProgress
{
    [self.view fwHideProgress];
}

- (void)fwShowMessageWithText:(id)text
{
    [self.view fwShowMessageWithText:text];
}

- (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style
{
    [self.view fwShowMessageWithText:text style:style];
}

- (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style completion:(void (^)(void))completion
{
    [self.view fwShowMessageWithText:text style:style completion:completion];
}

- (void)fwHideMessage
{
    [self.view fwHideMessage];
}

@end
