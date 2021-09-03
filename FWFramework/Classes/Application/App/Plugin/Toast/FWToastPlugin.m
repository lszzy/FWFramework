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
#import "FWToolkit.h"
#import <objc/runtime.h>

#pragma mark - FWToastPluginView

@implementation UIView (FWToastPluginView)

- (UIEdgeInsets)fwToastInsets
{
    NSValue *insets = objc_getAssociatedObject(self, @selector(fwToastInsets));
    return insets ? [insets UIEdgeInsetsValue] : UIEdgeInsetsZero;
}

- (void)setFwToastInsets:(UIEdgeInsets)fwToastInsets
{
    objc_setAssociatedObject(self, @selector(fwToastInsets), [NSValue valueWithUIEdgeInsets:fwToastInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

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

- (UIEdgeInsets)fwToastInsets
{
    return self.fwView.fwToastInsets;
}

- (void)setFwToastInsets:(UIEdgeInsets)fwToastInsets
{
    self.fwView.fwToastInsets = fwToastInsets;
}

- (void)fwShowLoading
{
    [self.fwView fwShowLoading];
}

- (void)fwShowLoadingWithText:(id)text
{
    [self.fwView fwShowLoadingWithText:text];
}

- (void)fwHideLoading
{
    [self.fwView fwHideLoading];
}

- (void)fwShowProgressWithText:(id)text progress:(CGFloat)progress
{
    [self.fwView fwShowProgressWithText:text progress:progress];
}

- (void)fwHideProgress
{
    [self.fwView fwHideProgress];
}

- (void)fwShowMessageWithText:(id)text
{
    [self.fwView fwShowMessageWithText:text];
}

- (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style
{
    [self.fwView fwShowMessageWithText:text style:style];
}

- (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style completion:(void (^)(void))completion
{
    [self.fwView fwShowMessageWithText:text style:style completion:completion];
}

- (void)fwHideMessage
{
    [self.fwView fwHideMessage];
}

@end
