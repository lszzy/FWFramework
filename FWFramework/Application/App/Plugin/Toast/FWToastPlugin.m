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
    
    [FWAppToastPlugin.sharedInstance fwShowLoadingWithAttributedText:attributedText inView:self];
}

- (void)fwHideLoading
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideLoading:)]) {
        [plugin fwHideLoading:self];
        return;
    }
    
    [FWAppToastPlugin.sharedInstance fwHideLoading:self];
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
    
    [FWAppToastPlugin.sharedInstance fwShowProgressWithAttributedText:attributedText progress:progress inView:self];
}

- (void)fwHideProgress
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideProgress:)]) {
        [plugin fwHideProgress:self];
        return;
    }
    
    [FWAppToastPlugin.sharedInstance fwHideProgress:self];
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
    
    [FWAppToastPlugin.sharedInstance fwShowMessageWithAttributedText:attributedText style:style completion:completion inView:self];
}

- (void)fwHideMessage
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideMessage:)]) {
        [plugin fwHideMessage:self];
        return;
    }
    
    [FWAppToastPlugin.sharedInstance fwHideMessage:self];
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
