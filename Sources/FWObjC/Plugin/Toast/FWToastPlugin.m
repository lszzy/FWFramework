//
//  FWToastPlugin.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWToastPlugin.h"
#import "FWToastPluginImpl.h"
#import "FWPlugin.h"
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

- (BOOL)fw_isShowingLoading
{
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(isShowingLoading:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    return [plugin isShowingLoading:self];
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

- (BOOL)fw_isShowingProgress
{
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(isShowingProgress:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    return [plugin isShowingProgress:self];
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

- (BOOL)fw_isShowingMessage
{
    id<FWToastPlugin> plugin = self.fw_toastPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(isShowingMessage:)]) {
        plugin = FWToastPluginImpl.sharedInstance;
    }
    return [plugin isShowingMessage:self];
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

- (UIEdgeInsets)fw_toastInsets
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    return view.fw_toastInsets;
}

- (void)setFw_toastInsets:(UIEdgeInsets)toastInsets
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    view.fw_toastInsets = toastInsets;
}

- (void)fw_showLoading
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_showLoading];
}

- (void)fw_showLoadingWithText:(id)text
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_showLoadingWithText:text];
}

- (void)fw_showLoadingWithText:(id)text cancelBlock:(void (^)(void))cancelBlock
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_showLoadingWithText:text cancelBlock:cancelBlock];
}

- (void)fw_hideLoading
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_hideLoading];
}

- (BOOL)fw_isShowingLoading
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    return [view fw_isShowingLoading];
}

- (void)fw_showProgressWithText:(id)text progress:(CGFloat)progress
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_showProgressWithText:text progress:progress];
}

- (void)fw_showProgressWithText:(id)text progress:(CGFloat)progress cancelBlock:(void (^)(void))cancelBlock
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_showProgressWithText:text progress:progress cancelBlock:cancelBlock];
}

- (void)fw_hideProgress
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_hideProgress];
}

- (BOOL)fw_isShowingProgress
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    return [view fw_isShowingProgress];
}

- (void)fw_showMessageWithText:(id)text
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_showMessageWithText:text];
}

- (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_showMessageWithText:text style:style];
}

- (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style completion:(void (^)(void))completion
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_showMessageWithText:text style:style completion:completion];
}

- (void)fw_showMessageWithText:(id)text style:(FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(void (^)(void))completion
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_showMessageWithText:text style:style autoHide:autoHide interactive:interactive completion:completion];
}

- (void)fw_hideMessage
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    [view fw_hideMessage];
}

- (BOOL)fw_isShowingMessage
{
    UIView *view = self.fw_toastInWindow ? UIWindow.fw_mainWindow : self.view;
    return [view fw_isShowingMessage];
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

+ (BOOL)fw_isShowingMessage
{
    return [UIWindow.fw_mainWindow fw_isShowingMessage];
}

@end
