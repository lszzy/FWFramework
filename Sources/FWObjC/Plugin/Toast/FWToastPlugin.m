//
//  FWToastPlugin.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWToastPlugin.h"
#import "FWToastPluginImpl.h"
#import "FWPlugin.h"
#import "FWUIKit.h"
#import "FWNavigator.h"
#import <objc/runtime.h>

#pragma mark - FWToastPluginView

@implementation UIView (FWToastPlugin)

- (id<FWToastPlugin>)fw_toastPlugin
{
    id<FWToastPlugin> toastPlugin = objc_getAssociatedObject(self, @selector(fw_toastPlugin));
    if (!toastPlugin) toastPlugin = [FWPluginManager loadPlugin:@protocol(FWToastPlugin)];
    if (!toastPlugin) toastPlugin = FWToastPluginImpl.sharedInstance;
    return toastPlugin;
}

- (void)setFw_toastPlugin:(id<FWToastPlugin>)toastPlugin
{
    objc_setAssociatedObject(self, @selector(fw_toastPlugin), toastPlugin, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)fw_toastInsets
{
    NSValue *insets = objc_getAssociatedObject(self, @selector(fw_toastInsets));
    return insets ? [insets UIEdgeInsetsValue] : UIEdgeInsetsZero;
}

- (void)setFw_toastInsets:(UIEdgeInsets)toastInsets
{
    objc_setAssociatedObject(self, @selector(fw_toastInsets), [NSValue valueWithUIEdgeInsets:toastInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_showLoading
{
    [self fw_showLoadingWithText:nil];
}

- (void)fw_showLoadingWithText:(id)text
{
    [self fw_showLoadingWithText:text cancelBlock:nil];
}

- (void)fw_showLoadingWithText:(id)text cancelBlock:(void (^)(void))cancelBlock
{
    NSAttributedString *attributedText = [text isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:text] : text;
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(showLoadingWithAttributedText:cancelBlock:inView:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin showLoadingWithAttributedText:attributedText cancelBlock:cancelBlock inView:self];
}

- (void)fw_hideLoading
{
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(hideLoading:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin hideLoading:self];
}

- (UIView *)fw_showingLoadingView
{
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(showingLoadingView:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    return [plugin showingLoadingView:self];
}

- (BOOL)fw_isShowingLoading
{
    return self.fw_showingLoadingView != nil;
}

- (void)fw_showProgressWithText:(id)text progress:(CGFloat)progress
{
    [self fw_showProgressWithText:text progress:progress cancelBlock:nil];
}

- (void)fw_showProgressWithText:(id)text progress:(CGFloat)progress cancelBlock:(void (^)(void))cancelBlock
{
    NSAttributedString *attributedText = [text isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:text] : text;
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(showProgressWithAttributedText:progress:cancelBlock:inView:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin showProgressWithAttributedText:attributedText progress:progress cancelBlock:cancelBlock inView:self];
}

- (void)fw_hideProgress
{
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(hideProgress:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin hideProgress:self];
}

- (UIView *)fw_showingProgressView
{
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(showingProgressView:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    return [plugin showingProgressView:self];
}

- (BOOL)fw_isShowingProgress
{
    return self.fw_showingProgressView != nil;
}

- (void)fw_showMessageWithText:(id)text
{
    [self fw_showMessageWithText:text style:FWToastStyleDefault];
}

- (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style
{
    [self fw_showMessageWithText:text style:style completion:nil];
}

- (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style completion:(void (^)(void))completion
{
    [self fw_showMessageWithText:text style:style autoHide:YES interactive:completion ? NO : YES completion:completion];
}

- (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(void (^)(void))completion
{
    NSAttributedString *attributedText = [text isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:text] : text;
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(showMessageWithAttributedText:style:autoHide:interactive:completion:inView:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin showMessageWithAttributedText:attributedText style:style autoHide:autoHide interactive:interactive completion:completion inView:self];
}

- (void)fw_hideMessage
{
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(hideMessage:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    [plugin hideMessage:self];
}

- (UIView *)fw_showingMessageView
{
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(showingMessageView:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    return [plugin showingMessageView:self];
}

- (BOOL)fw_isShowingMessage
{
    return self.fw_showingMessageView != nil;
}

@end

@implementation UIViewController (FWToastPlugin)

- (BOOL)fw_toastInWindow
{
    return [objc_getAssociatedObject(self, @selector(fw_toastInWindow)) boolValue];
}

- (void)setFw_toastInWindow:(BOOL)toastInWindow
{
    objc_setAssociatedObject(self, @selector(fw_toastInWindow), @(toastInWindow), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_toastInAncestor
{
    return [objc_getAssociatedObject(self, @selector(fw_toastInAncestor)) boolValue];
}

- (void)setFw_toastInAncestor:(BOOL)toastInAncestor
{
    objc_setAssociatedObject(self, @selector(fw_toastInAncestor), @(toastInAncestor), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fw_toastContainerView
{
    if (self.fw_toastInWindow) return UIWindow.fw_mainWindow;
    if (self.fw_toastInAncestor) return self.fw_ancestorView;
    return self.view;
}

- (UIEdgeInsets)fw_toastInsets
{
    return self.fw_toastContainerView.fw_toastInsets;
}

- (void)setFw_toastInsets:(UIEdgeInsets)toastInsets
{
    self.fw_toastContainerView.fw_toastInsets = toastInsets;
}

- (void)fw_showLoading
{
    [self.fw_toastContainerView fw_showLoading];
}

- (void)fw_showLoadingWithText:(id)text
{
    [self.fw_toastContainerView fw_showLoadingWithText:text];
}

- (void)fw_showLoadingWithText:(id)text cancelBlock:(void (^)(void))cancelBlock
{
    [self.fw_toastContainerView fw_showLoadingWithText:text cancelBlock:cancelBlock];
}

- (void)fw_hideLoading
{
    [self.fw_toastContainerView fw_hideLoading];
}

- (UIView *)fw_showingLoadingView
{
    return [self.fw_toastContainerView fw_showingLoadingView];
}

- (BOOL)fw_isShowingLoading
{
    return [self.fw_toastContainerView fw_isShowingLoading];
}

- (void)fw_showProgressWithText:(id)text progress:(CGFloat)progress
{
    [self.fw_toastContainerView fw_showProgressWithText:text progress:progress];
}

- (void)fw_showProgressWithText:(id)text progress:(CGFloat)progress cancelBlock:(void (^)(void))cancelBlock
{
    [self.fw_toastContainerView fw_showProgressWithText:text progress:progress cancelBlock:cancelBlock];
}

- (void)fw_hideProgress
{
    [self.fw_toastContainerView fw_hideProgress];
}

- (UIView *)fw_showingProgressView
{
    return [self.fw_toastContainerView fw_showingProgressView];
}

- (BOOL)fw_isShowingProgress
{
    return [self.fw_toastContainerView fw_isShowingProgress];
}

- (void)fw_showMessageWithText:(id)text
{
    [self.fw_toastContainerView fw_showMessageWithText:text];
}

- (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style
{
    [self.fw_toastContainerView fw_showMessageWithText:text style:style];
}

- (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style completion:(void (^)(void))completion
{
    [self.fw_toastContainerView fw_showMessageWithText:text style:style completion:completion];
}

- (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(void (^)(void))completion
{
    [self.fw_toastContainerView fw_showMessageWithText:text style:style autoHide:autoHide interactive:interactive completion:completion];
}

- (void)fw_hideMessage
{
    [self.fw_toastContainerView fw_hideMessage];
}

- (UIView *)fw_showingMessageView
{
    return [self.fw_toastContainerView fw_showingMessageView];
}

- (BOOL)fw_isShowingMessage
{
    return [self.fw_toastContainerView fw_isShowingMessage];
}

@end

@implementation UIWindow (FWToastPlugin)

+ (UIEdgeInsets)fw_toastInsets
{
    return UIWindow.fw_mainWindow.fw_toastInsets;
}

+ (void)setFw_toastInsets:(UIEdgeInsets)toastInsets
{
    UIWindow.fw_mainWindow.fw_toastInsets = toastInsets;
}

+ (void)fw_showLoading
{
    [UIWindow.fw_mainWindow fw_showLoading];
}

+ (void)fw_showLoadingWithText:(id)text
{
    [UIWindow.fw_mainWindow fw_showLoadingWithText:text];
}

+ (void)fw_showLoadingWithText:(id)text cancelBlock:(void (^)(void))cancelBlock
{
    [UIWindow.fw_mainWindow fw_showLoadingWithText:text cancelBlock:cancelBlock];
}

+ (void)fw_hideLoading
{
    [UIWindow.fw_mainWindow fw_hideLoading];
}

+ (UIView *)fw_showingLoadingView
{
    return [UIWindow.fw_mainWindow fw_showingLoadingView];
}

+ (BOOL)fw_isShowingLoading
{
    return [UIWindow.fw_mainWindow fw_isShowingLoading];
}

+ (void)fw_showProgressWithText:(id)text progress:(CGFloat)progress
{
    [UIWindow.fw_mainWindow fw_showProgressWithText:text progress:progress];
}

+ (void)fw_showProgressWithText:(id)text progress:(CGFloat)progress cancelBlock:(void (^)(void))cancelBlock
{
    [UIWindow.fw_mainWindow fw_showProgressWithText:text progress:progress cancelBlock:cancelBlock];
}

+ (void)fw_hideProgress
{
    [UIWindow.fw_mainWindow fw_hideProgress];
}

+ (UIView *)fw_showingProgressView
{
    return [UIWindow.fw_mainWindow fw_showingProgressView];
}

+ (BOOL)fw_isShowingProgress
{
    return [UIWindow.fw_mainWindow fw_isShowingProgress];
}

+ (void)fw_showMessageWithText:(id)text
{
    [UIWindow.fw_mainWindow fw_showMessageWithText:text];
}

+ (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style
{
    [UIWindow.fw_mainWindow fw_showMessageWithText:text style:style];
}

+ (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style completion:(void (^)(void))completion
{
    [UIWindow.fw_mainWindow fw_showMessageWithText:text style:style completion:completion];
}

+ (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(void (^)(void))completion
{
    [UIWindow.fw_mainWindow fw_showMessageWithText:text style:style autoHide:autoHide interactive:interactive completion:completion];
}

+ (void)fw_hideMessage
{
    [UIWindow.fw_mainWindow fw_hideMessage];
}

+ (UIView *)fw_showingMessageView
{
    return [UIWindow.fw_mainWindow fw_showingMessageView];
}

+ (BOOL)fw_isShowingMessage
{
    return [UIWindow.fw_mainWindow fw_isShowingMessage];
}

@end
