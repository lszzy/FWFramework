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

#pragma mark - FWToastPluginView

@implementation UIView (FWToastPluginView)

- (void)fwShowLoading
{
    [self fwShowLoadingWithText:nil];
}

- (void)fwShowLoadingWithText:(id)text
{
    NSAttributedString *attributedText = [text isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:text] : text;
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwShowLoadingWithAttributedText:inView:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin fwShowLoadingWithAttributedText:attributedText inView:self];
}

- (void)fwHideLoading
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwHideLoading:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin fwHideLoading:self];
}

- (void)fwShowProgressWithText:(id)text progress:(CGFloat)progress
{
    NSAttributedString *attributedText = [text isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:text] : text;
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwShowProgressWithAttributedText:progress:inView:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin fwShowProgressWithAttributedText:attributedText progress:progress inView:self];
}

- (void)fwHideProgress
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwHideProgress:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin fwHideProgress:self];
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
    NSAttributedString *attributedText = [text isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:text] : text;
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwShowMessageWithAttributedText:style:completion:inView:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin fwShowMessageWithAttributedText:attributedText style:style completion:completion inView:self];
}

- (void)fwHideMessage
{
    id<FWToastPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwHideMessage:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin fwHideMessage:self];
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
