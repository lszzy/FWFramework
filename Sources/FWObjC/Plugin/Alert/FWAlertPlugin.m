//
//  FWAlertPlugin.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWAlertPlugin.h"
#import "FWAlertPluginImpl.h"
#import "Plugin.h"
#import "Navigator.h"
#import "FWAppBundle.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIWindow ()

@property (class, nonatomic, readwrite, nullable) UIWindow *fw_mainWindow;
@property (nonatomic, readonly, nullable) UIViewController *fw_topPresentedController;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - UIViewController+FWAlertPlugin

@implementation UIViewController (FWAlertPlugin)

- (id<FWAlertPlugin>)fw_alertPlugin
{
    id<FWAlertPlugin> alertPlugin = objc_getAssociatedObject(self, @selector(fw_alertPlugin));
    if (!alertPlugin) alertPlugin = [__FWPluginManager loadPlugin:@protocol(FWAlertPlugin)];
    if (!alertPlugin) alertPlugin = FWAlertPluginImpl.sharedInstance;
    return alertPlugin;
}

- (void)setFw_alertPlugin:(id<FWAlertPlugin>)alertPlugin
{
    objc_setAssociatedObject(self, @selector(fw_alertPlugin), alertPlugin, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_showAlertWithTitle:(id)title
                     message:(id)message
{
    [self fw_showAlertWithTitle:title
                       message:message
                        cancel:nil
                   cancelBlock:nil];
}

- (void)fw_showAlertWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                 cancelBlock:(void (^)(void))cancelBlock
{
    [self fw_showAlertWithTitle:title
                     message:message
                       style:FWAlertStyleDefault
                        cancel:cancel
                       actions:nil
                   actionBlock:nil
                   cancelBlock:cancelBlock];
}

- (void)fw_showAlertWithTitle:(id)title
                   message:(id)message
                     style:(FWAlertStyle)style
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
{
    [self fw_showAlertWithTitle:title
                       message:message
                         style:style
                        cancel:cancel
                       actions:actions
                   promptCount:0
                   promptBlock:nil
                   actionBlock:^(NSArray<NSString *> *values, NSInteger index) {
                       if (actionBlock) actionBlock(index);
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil];
}

- (void)fw_showConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
{
    [self fw_showConfirmWithTitle:title
                         message:message
                          cancel:cancel
                         confirm:confirm
                    confirmBlock:confirmBlock
                     cancelBlock:nil];
}

- (void)fw_showConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
                   cancelBlock:(void (^)(void))cancelBlock
{
    if (!confirm) {
        confirm = FWAlertPluginImpl.sharedInstance.defaultConfirmButton ? FWAlertPluginImpl.sharedInstance.defaultConfirmButton() : FWAppBundle.confirmButton;
    }
    
    [self fw_showAlertWithTitle:title
                       message:message
                         style:FWAlertStyleDefault
                        cancel:cancel
                       actions:[NSArray arrayWithObjects:confirm, nil]
                   promptCount:0
                   promptBlock:nil
                   actionBlock:^(NSArray<NSString *> *values, NSInteger index) {
                       if (confirmBlock) confirmBlock();
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil];
}

- (void)fw_showPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                 confirmBlock:(void (^)(NSString *))confirmBlock
{
    [self fw_showPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptBlock:nil
                   confirmBlock:confirmBlock
                    cancelBlock:nil];
}

- (void)fw_showPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptBlock:(void (^)(UITextField *))promptBlock
                 confirmBlock:(void (^)(NSString *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
{
    [self fw_showPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptCount:1
                    promptBlock:^(UITextField *textField, NSInteger index) {
                        if (promptBlock) promptBlock(textField);
                    }
                   confirmBlock:^(NSArray<NSString *> *values) {
                        if (confirmBlock) confirmBlock(values.firstObject);
                    }
                    cancelBlock:cancelBlock];
}

- (void)fw_showPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptCount:(NSInteger)promptCount
                  promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 confirmBlock:(void (^)(NSArray<NSString *> *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
{
    if (!confirm) {
        confirm = FWAlertPluginImpl.sharedInstance.defaultConfirmButton ? FWAlertPluginImpl.sharedInstance.defaultConfirmButton() : FWAppBundle.confirmButton;
    }
    
    [self fw_showAlertWithTitle:title
                       message:message
                         style:FWAlertStyleDefault
                        cancel:cancel
                       actions:(confirm ? @[confirm] : nil)
                   promptCount:promptCount
                   promptBlock:promptBlock
                   actionBlock:^(NSArray<NSString *> *values, NSInteger index) {
                       if (confirmBlock) confirmBlock(values);
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil];
}

- (void)fw_showAlertWithTitle:(id)title
                     message:(id)message
                       style:(FWAlertStyle)style
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 promptCount:(NSInteger)promptCount
                 promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 actionBlock:(void (^)(NSArray<NSString *> *, NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id))customBlock
{
    // 处理取消按钮，Alert多按钮时默认取消，单按钮时默认关闭
    if (!cancel) {
        if (actions.count > 0) {
            cancel = FWAlertPluginImpl.sharedInstance.defaultCancelButton ? FWAlertPluginImpl.sharedInstance.defaultCancelButton(UIAlertControllerStyleAlert) : FWAppBundle.cancelButton;
        } else {
            cancel = FWAlertPluginImpl.sharedInstance.defaultCloseButton ? FWAlertPluginImpl.sharedInstance.defaultCloseButton(UIAlertControllerStyleAlert) : FWAppBundle.closeButton;
        }
    }
    
    // 优先调用插件，不存在时使用默认
    id<FWAlertPlugin> alertPlugin = self.fw_alertPlugin;
    if (!alertPlugin || ![alertPlugin respondsToSelector:@selector(viewController:showAlertWithTitle:message:style:cancel:actions:promptCount:promptBlock:actionBlock:cancelBlock:customBlock:)]) {
        alertPlugin = FWAlertPluginImpl.sharedInstance;
    }
    [alertPlugin viewController:self showAlertWithTitle:title message:message style:style cancel:cancel actions:actions promptCount:promptCount promptBlock:promptBlock actionBlock:actionBlock cancelBlock:cancelBlock customBlock:customBlock];
}

- (void)fw_showSheetWithTitle:(id)title
                   message:(id)message
                    cancel:(id)cancel
               cancelBlock:(void (^)(void))cancelBlock
{
    [self fw_showSheetWithTitle:title
                     message:message
                      cancel:cancel
                     actions:nil
                currentIndex:-1
                 actionBlock:nil
                 cancelBlock:cancelBlock];
}

- (void)fw_showSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
{
    [self fw_showSheetWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                  currentIndex:-1
                   actionBlock:actionBlock
                   cancelBlock:nil];
}

- (void)fw_showSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                currentIndex:(NSInteger)currentIndex
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
{
    [self fw_showSheetWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                  currentIndex:currentIndex
                   actionBlock:^(NSInteger index) {
                       if (actionBlock) actionBlock(index);
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil];
}

- (void)fw_showSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                currentIndex:(NSInteger)currentIndex
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id))customBlock
{
    // 处理取消按钮，Sheet多按钮时默认取消，单按钮时默认关闭
    if (!cancel) {
        if (actions.count > 0) {
            cancel = FWAlertPluginImpl.sharedInstance.defaultCancelButton ? FWAlertPluginImpl.sharedInstance.defaultCancelButton(UIAlertControllerStyleActionSheet) : FWAppBundle.cancelButton;
        } else {
            cancel = FWAlertPluginImpl.sharedInstance.defaultCloseButton ? FWAlertPluginImpl.sharedInstance.defaultCloseButton(UIAlertControllerStyleActionSheet) : FWAppBundle.closeButton;
        }
    }
    
    // 优先调用插件，不存在时使用默认
    id<FWAlertPlugin> alertPlugin = self.fw_alertPlugin;
    if (!alertPlugin || ![alertPlugin respondsToSelector:@selector(viewController:showSheetWithTitle:message:cancel:actions:currentIndex:actionBlock:cancelBlock:customBlock:)]) {
        alertPlugin = FWAlertPluginImpl.sharedInstance;
    }
    [alertPlugin viewController:self showSheetWithTitle:title message:message cancel:cancel actions:actions currentIndex:currentIndex actionBlock:actionBlock cancelBlock:cancelBlock customBlock:customBlock];
}

- (void)fw_hideAlert:(BOOL)animated
          completion:(void (^)(void))completion
{
    // 优先调用插件，不存在时使用默认
    id<FWAlertPlugin> alertPlugin = self.fw_alertPlugin;
    if (!alertPlugin || ![alertPlugin respondsToSelector:@selector(viewController:hideAlert:completion:)]) {
        alertPlugin = FWAlertPluginImpl.sharedInstance;
    }
    [alertPlugin viewController:self hideAlert:animated completion:completion];
}

- (BOOL)fw_isShowingAlert
{
    // 优先调用插件，不存在时使用默认
    id<FWAlertPlugin> alertPlugin = self.fw_alertPlugin;
    if (!alertPlugin || ![alertPlugin respondsToSelector:@selector(isShowingAlert:)]) {
        alertPlugin = FWAlertPluginImpl.sharedInstance;
    }
    return [alertPlugin isShowingAlert:self];
}

@end

#pragma mark - UIView+FWAlertPlugin

@implementation UIView (FWAlertPlugin)

- (void)fw_showAlertWithTitle:(id)title
                     message:(id)message
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showAlertWithTitle:title
                       message:message];
}

- (void)fw_showAlertWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                 cancelBlock:(void (^)(void))cancelBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showAlertWithTitle:title
                       message:message
                        cancel:cancel
                   cancelBlock:cancelBlock];
}

- (void)fw_showAlertWithTitle:(id)title
                     message:(id)message
                       style:(FWAlertStyle)style
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showAlertWithTitle:title
                       message:message
                         style:style
                        cancel:cancel
                       actions:actions
                   actionBlock:actionBlock
                   cancelBlock:cancelBlock];
}

- (void)fw_showConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showConfirmWithTitle:title
                         message:message
                          cancel:cancel
                         confirm:confirm
                    confirmBlock:confirmBlock];
}

- (void)fw_showConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
                   cancelBlock:(void (^)(void))cancelBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showConfirmWithTitle:title
                         message:message
                          cancel:cancel
                         confirm:confirm
                    confirmBlock:confirmBlock
                     cancelBlock:cancelBlock];
}

- (void)fw_showPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                 confirmBlock:(void (^)(NSString *))confirmBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                   confirmBlock:confirmBlock];
}

- (void)fw_showPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptBlock:(void (^)(UITextField *))promptBlock
                 confirmBlock:(void (^)(NSString *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptBlock:promptBlock
                   confirmBlock:confirmBlock
                    cancelBlock:cancelBlock];
}

- (void)fw_showPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptCount:(NSInteger)promptCount
                  promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 confirmBlock:(void (^)(NSArray<NSString *> *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptCount:promptCount
                    promptBlock:promptBlock
                   confirmBlock:confirmBlock
                    cancelBlock:cancelBlock];
}

- (void)fw_showAlertWithTitle:(id)title
                     message:(id)message
                       style:(FWAlertStyle)style
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 promptCount:(NSInteger)promptCount
                 promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 actionBlock:(void (^)(NSArray<NSString *> *, NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id))customBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showAlertWithTitle:title
                       message:message
                         style:style
                        cancel:cancel
                       actions:actions
                   promptCount:promptCount
                   promptBlock:promptBlock
                   actionBlock:actionBlock
                   cancelBlock:cancelBlock
                   customBlock:customBlock];
}

- (void)fw_showSheetWithTitle:(id)title
                   message:(id)message
                    cancel:(id)cancel
               cancelBlock:(void (^)(void))cancelBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showSheetWithTitle:title
                        message:message
                         cancel:cancel
                    cancelBlock:cancelBlock];
}

- (void)fw_showSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showSheetWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                   actionBlock:actionBlock];
}

- (void)fw_showSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                currentIndex:(NSInteger)currentIndex
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showSheetWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                   currentIndex:currentIndex
                   actionBlock:actionBlock
                   cancelBlock:cancelBlock];
}

- (void)fw_showSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                currentIndex:(NSInteger)currentIndex
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id))customBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showSheetWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                  currentIndex:currentIndex
                   actionBlock:actionBlock
                   cancelBlock:cancelBlock
                   customBlock:customBlock];
}

- (void)fw_hideAlert:(BOOL)animated
          completion:(void (^)(void))completion
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl) ctrl = UIWindow.fw_mainWindow.rootViewController;
    [ctrl fw_hideAlert:animated completion:completion];
}

- (BOOL)fw_isShowingAlert
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl) ctrl = UIWindow.fw_mainWindow.rootViewController;
    return [ctrl fw_isShowingAlert];
}

@end
