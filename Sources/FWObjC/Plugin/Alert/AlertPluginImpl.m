//
//  AlertPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "AlertPluginImpl.h"
#import "AlertController.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIDevice ()

@property (class, nonatomic, assign, readonly) BOOL fw_isIpad;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWAlertAppearance

@implementation __FWAlertAppearance

+ (__FWAlertAppearance *)appearance
{
    static __FWAlertAppearance *appearance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appearance = [[__FWAlertAppearance alloc] init];
    });
    return appearance;
}

- (BOOL)controllerEnabled
{
    return self.titleColor || self.titleFont || self.messageColor || self.messageFont;
}

- (BOOL)actionEnabled
{
    return self.actionColor || self.preferredActionColor || self.cancelActionColor || self.destructiveActionColor || self.disabledActionColor;
}

@end

#pragma mark - __FWAlertPluginImpl

@implementation __FWAlertPluginImpl

+ (__FWAlertPluginImpl *)sharedInstance
{
    static __FWAlertPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWAlertPluginImpl alloc] init];
    });
    return instance;
}

- (void)viewController:(UIViewController *)viewController
      showAlertWithTitle:(id)title
                 message:(id)message
                   style:(__FWAlertStyle)style
                  cancel:(id)cancel
                 actions:(NSArray *)actions
             promptCount:(NSInteger)promptCount
             promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
             actionBlock:(void (^)(NSArray<NSString *> *, NSInteger))actionBlock
             cancelBlock:(void (^)(void))cancelBlock
             customBlock:(void (^)(id))customBlock
{
    // 初始化Alert
    __FWAlertAppearance *customAppearance = self.customAlertAppearance;
    UIAlertController *alertController = [UIAlertController fw_alertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert
                                                                            appearance:customAppearance];
    alertController.fw_alertStyle = style;
    
    // 添加输入框
    for (NSInteger promptIndex = 0; promptIndex < promptCount; promptIndex++) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if (promptBlock) promptBlock(textField, promptIndex);
        }];
    }
    
    // 添加动作按钮
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        UIAlertAction *alertAction = [UIAlertAction fw_actionWithObject:actions[actionIndex] style:UIAlertActionStyleDefault appearance:customAppearance handler:^(UIAlertAction *action) {
            if (actionBlock) {
                NSMutableArray *values = [NSMutableArray new];
                for (NSInteger fieldIndex = 0; fieldIndex < promptCount; fieldIndex++) {
                    UITextField *textField = alertController.textFields[fieldIndex];
                    [values addObject:textField.text ?: @""];
                }
                actionBlock(values.copy, actionIndex);
            }
        }];
        [alertController addAction:alertAction];
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        UIAlertAction *cancelAction = [UIAlertAction fw_actionWithObject:cancel style:UIAlertActionStyleCancel appearance:customAppearance handler:^(UIAlertAction *action) {
            if (cancelBlock) cancelBlock();
        }];
        [alertController addAction:cancelAction];
    }
    
    // 添加首选按钮
    if (alertController.fw_alertAppearance.preferredActionBlock && alertController.actions.count > 0) {
        UIAlertAction *preferredAction = alertController.fw_alertAppearance.preferredActionBlock(alertController);
        if (preferredAction) {
            alertController.preferredAction = preferredAction;
        }
    }
    
    // 自定义Alert
    if (self.customBlock) self.customBlock(alertController);
    if (customBlock) customBlock(alertController);
    
    // 显示Alert
    [viewController presentViewController:alertController animated:YES completion:nil];
}

- (void)viewController:(UIViewController *)viewController
      showSheetWithTitle:(id)title
                 message:(id)message
                  cancel:(id)cancel
                 actions:(NSArray *)actions
            currentIndex:(NSInteger)currentIndex
             actionBlock:(void (^)(NSInteger))actionBlock
             cancelBlock:(void (^)(void))cancelBlock
             customBlock:(void (^)(id))customBlock
{
    // 初始化Alert
    __FWAlertAppearance *customAppearance = self.customSheetAppearance;
    UIAlertController *alertController = [UIAlertController fw_alertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleActionSheet
                                                                            appearance:customAppearance];
    
    // 添加动作按钮
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        UIAlertAction *alertAction = [UIAlertAction fw_actionWithObject:actions[actionIndex] style:UIAlertActionStyleDefault appearance:customAppearance handler:^(UIAlertAction *action) {
            if (actionBlock) {
                actionBlock(actionIndex);
            }
        }];
        [alertController addAction:alertAction];
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        UIAlertAction *cancelAction = [UIAlertAction fw_actionWithObject:cancel style:UIAlertActionStyleCancel appearance:customAppearance handler:^(UIAlertAction *action) {
            if (cancelBlock) cancelBlock();
        }];
        [alertController addAction:cancelAction];
    }
    
    // 添加首选按钮
    if (currentIndex >= 0 && alertController.actions.count > currentIndex) {
        alertController.preferredAction = alertController.actions[currentIndex];
    } else if (alertController.fw_alertAppearance.preferredActionBlock && alertController.actions.count > 0) {
        UIAlertAction *preferredAction = alertController.fw_alertAppearance.preferredActionBlock(alertController);
        if (preferredAction) {
            alertController.preferredAction = preferredAction;
        }
    }
    
    // 兼容iPad，默认居中显示ActionSheet。注意点击视图(如UIBarButtonItem)必须是sourceView及其子视图
    if ([UIDevice fw_isIpad] && alertController.popoverPresentationController) {
        UIView *ancestorView = [viewController fw_ancestorView];
        UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
        popoverController.sourceView = ancestorView;
        popoverController.sourceRect = CGRectMake(ancestorView.center.x, ancestorView.center.y, 0, 0);
        popoverController.permittedArrowDirections = 0;
    }
    
    // 自定义Alert
    if (self.customBlock) self.customBlock(alertController);
    if (customBlock) customBlock(alertController);
    
    // 显示Alert
    [viewController presentViewController:alertController animated:YES completion:nil];
}

- (void)viewController:(UIViewController *)viewController
             hideAlert:(BOOL)animated
            completion:(void (^)(void))completion
{
    UIViewController *alertController = [self showingAlertController:viewController];
    if (alertController) {
        [alertController.presentingViewController dismissViewControllerAnimated:animated completion:completion];
    } else {
        if (completion) completion();
    }
}

- (BOOL)isShowingAlert:(UIViewController *)viewController
{
    UIViewController *alertController = [self showingAlertController:viewController];
    return alertController ? YES : NO;
}

- (UIViewController *)showingAlertController:(UIViewController *)viewController
{
    UIViewController *alertController = nil;
    NSArray<Class> *alertClasses = self.customAlertClasses.count > 0 ? self.customAlertClasses : @[UIAlertController.class, __FWAlertController.class];
    
    UIViewController *presentedController = viewController.presentedViewController;
    while (presentedController != nil) {
        for (Class alertClass in alertClasses) {
            if ([presentedController isKindOfClass:alertClass]) {
                alertController = presentedController; break;
            }
        }
        if (alertController) break;
        presentedController = presentedController.presentedViewController;
    }
    
    return alertController;
}

@end
