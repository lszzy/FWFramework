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
#import "FWPlugin.h"
#import "FWRouter.h"

#pragma mark - UIView+FWToastPlugin

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

@end

@implementation UIView (FWToastPlugin)

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
    
    UIActivityIndicatorViewStyle style;
    if (@available(iOS 13.0, *)) {
        style = UIActivityIndicatorViewStyleMedium;
    } else {
        style = UIActivityIndicatorViewStyleWhite;
    }
    [self fwShowIndicatorLoadingWithStyle:style attributedTitle:attributedText];
}

- (void)fwHideLoading
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideLoading:)]) {
        [plugin fwHideLoading:self];
        return;
    }
    
    [self fwHideIndicatorLoading];
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
    
    UIActivityIndicatorViewStyle style;
    if (@available(iOS 13.0, *)) {
        style = UIActivityIndicatorViewStyleMedium;
    } else {
        style = UIActivityIndicatorViewStyleWhite;
    }
    [self fwShowIndicatorLoadingWithStyle:style attributedTitle:attributedText];
}

- (void)fwHideProgress
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideProgress:)]) {
        [plugin fwHideProgress:self];
        return;
    }
    
    [self fwHideIndicatorLoading];
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
    
    UIView *indicatorView = [self fwShowIndicatorMessageWithAttributedText:attributedText];
    indicatorView.userInteractionEnabled = completion ? YES : NO;
    [self fwHideIndicatorMessageAfterDelay:2.0 completion:completion];
}

- (void)fwHideMessage
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideMessage:)]) {
        [plugin fwHideMessage:self];
        return;
    }
    
    [self fwHideIndicatorMessage];
}

#pragma mark - Static

+ (void)fwShowLoading
{
    [UIWindow.fwMainWindow fwShowLoading];
}

+ (void)fwShowLoadingWithText:(id)text
{
    [UIWindow.fwMainWindow fwShowLoadingWithText:text];
}

+ (void)fwHideLoading
{
    [UIWindow.fwMainWindow fwHideLoading];
}

+ (void)fwShowProgressWithText:(id)text progress:(CGFloat)progress
{
    [UIWindow.fwMainWindow fwShowProgressWithText:text progress:progress];
}

+ (void)fwHideProgress
{
    [UIWindow.fwMainWindow fwHideProgress];
}

+ (void)fwShowMessageWithText:(id)text
{
    [UIWindow.fwMainWindow fwShowMessageWithText:text];
}

+ (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style
{
    [UIWindow.fwMainWindow fwShowMessageWithText:text style:style];
}

+ (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style completion:(void (^)(void))completion
{
    [UIWindow.fwMainWindow fwShowMessageWithText:text style:style completion:completion];
}

+ (void)fwHideMessage
{
    [UIWindow.fwMainWindow fwHideMessage];
}

@end
