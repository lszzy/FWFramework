//
//  AlertControllerImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "AlertControllerImpl.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

- (NSString *)fw_observeProperty:(NSString *)property block:(void (^)(id object, NSDictionary<NSKeyValueChangeKey, id> *change))block;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWAlertControllerPlugin

@interface __FWAlertAction (__FWAlertControllerPlugin)

@end

@implementation __FWAlertAction (__FWAlertControllerPlugin)

- (BOOL)isPreferred
{
    return [objc_getAssociatedObject(self, @selector(isPreferred)) boolValue];
}

- (void)setIsPreferred:(BOOL)isPreferred
{
    objc_setAssociatedObject(self, @selector(isPreferred), @(isPreferred), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.attributedTitle || self.title.length < 1 || !self.alertAppearance.actionEnabled) return;
    
    UIColor *titleColor = nil;
    if (!self.enabled) {
        titleColor = self.alertAppearance.disabledActionColor;
    } else if (isPreferred) {
        titleColor = self.alertAppearance.preferredActionColor;
    } else if (self.style == UIAlertActionStyleDestructive) {
        titleColor = self.alertAppearance.destructiveActionColor;
    } else if (self.style == UIAlertActionStyleCancel) {
        titleColor = self.alertAppearance.cancelActionColor;
    } else {
        titleColor = self.alertAppearance.actionColor;
    }
    if (titleColor) self.titleColor = titleColor;
}

@end

@implementation __FWAlertControllerImpl

+ (__FWAlertControllerImpl *)sharedInstance
{
    static __FWAlertControllerImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWAlertControllerImpl alloc] init];
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
             promptBlock:(void (^)(UITextField * _Nonnull, NSInteger))promptBlock
             actionBlock:(void (^)(NSArray<NSString *> * _Nonnull, NSInteger))actionBlock
             cancelBlock:(void (^)(void))cancelBlock
             customBlock:(void (^)(id))customBlock
{
    // 初始化Alert
    __FWAlertControllerAppearance *customAppearance = self.customAlertAppearance;
    __FWAlertController *alertController = [self alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:__FWAlertControllerStyleAlert
                                                             appearance:customAppearance];
    alertController.alertStyle = style;
    
    // 添加输入框
    for (NSInteger promptIndex = 0; promptIndex < promptCount; promptIndex++) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if (promptBlock) promptBlock(textField, promptIndex);
        }];
    }
    
    // 添加动作按钮
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        __FWAlertAction *alertAction = [self actionWithObject:actions[actionIndex] style:__FWAlertActionStyleDefault appearance:customAppearance handler:^(__FWAlertAction *action) {
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
        __FWAlertAction *cancelAction = [self actionWithObject:cancel style:__FWAlertActionStyleCancel appearance:customAppearance handler:^(__FWAlertAction *action) {
            if (cancelBlock) cancelBlock();
        }];
        [alertController addAction:cancelAction];
    }
    
    // 点击背景
    if (self.dimmingTriggerCancel) {
        alertController.dismissCompletion = cancelBlock;
    }
    
    // 添加首选按钮
    if (alertController.alertAppearance.preferredActionBlock && alertController.actions.count > 0) {
        __FWAlertAction *preferredAction = alertController.alertAppearance.preferredActionBlock(alertController);
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
    __FWAlertControllerAppearance *customAppearance = self.customSheetAppearance;
    __FWAlertController *alertController = [self alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:__FWAlertControllerStyleActionSheet
                                                             appearance:customAppearance];
    
    // 添加动作按钮
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        __FWAlertAction *alertAction = [self actionWithObject:actions[actionIndex] style:__FWAlertActionStyleDefault appearance:customAppearance handler:^(__FWAlertAction *action) {
            if (actionBlock) {
                actionBlock(actionIndex);
            }
        }];
        [alertController addAction:alertAction];
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        __FWAlertAction *cancelAction = [self actionWithObject:cancel style:__FWAlertActionStyleCancel appearance:customAppearance handler:^(__FWAlertAction *action) {
            if (cancelBlock) cancelBlock();
        }];
        [alertController addAction:cancelAction];
    }
    
    // 点击背景
    if (self.dimmingTriggerCancel) {
        alertController.dismissCompletion = cancelBlock;
    }
    
    // 添加首选按钮
    if (currentIndex >= 0 && alertController.actions.count > currentIndex) {
        alertController.preferredAction = alertController.actions[currentIndex];
    } else if (alertController.alertAppearance.preferredActionBlock && alertController.actions.count > 0) {
        __FWAlertAction *preferredAction = alertController.alertAppearance.preferredActionBlock(alertController);
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
    showAlertWithStyle:(UIAlertControllerStyle)style
            headerView:(UIView *)headerView
                cancel:(id)cancel
               actions:(NSArray *)actions
           actionBlock:(void (^)(NSInteger))actionBlock
           cancelBlock:(void (^)(void))cancelBlock
           customBlock:(void (^)(id _Nonnull))customBlock
{
    // 初始化Alert
    __FWAlertControllerAppearance *customAppearance = style == UIAlertControllerStyleActionSheet ? self.customSheetAppearance : self.customAlertAppearance;
    __FWAlertController *alertController = [self alertControllerWithHeaderView:headerView
                                                              preferredStyle:(__FWAlertControllerStyle)style
                                                                  appearance:customAppearance];
    
    // 添加动作按钮
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        __FWAlertAction *alertAction = [self actionWithObject:actions[actionIndex] style:__FWAlertActionStyleDefault appearance:customAppearance handler:^(__FWAlertAction *action) {
            if (actionBlock) actionBlock(actionIndex);
        }];
        [alertController addAction:alertAction];
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        __FWAlertAction *cancelAction = [self actionWithObject:cancel style:__FWAlertActionStyleCancel appearance:customAppearance handler:^(__FWAlertAction *action) {
            if (cancelBlock) cancelBlock();
        }];
        [alertController addAction:cancelAction];
    }
    
    // 点击背景
    if (self.dimmingTriggerCancel) {
        alertController.dismissCompletion = cancelBlock;
    }
    
    // 添加首选按钮
    if (alertController.alertAppearance.preferredActionBlock && alertController.actions.count > 0) {
        __FWAlertAction *preferredAction = alertController.alertAppearance.preferredActionBlock(alertController);
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

- (__FWAlertController *)alertControllerWithTitle:(id)title message:(id)message preferredStyle:(__FWAlertControllerStyle)preferredStyle appearance:(__FWAlertControllerAppearance *)appearance
{
    NSAttributedString *attributedTitle = [title isKindOfClass:[NSAttributedString class]] ? title : nil;
    NSAttributedString *attributedMessage = [message isKindOfClass:[NSAttributedString class]] ? message : nil;
    __FWAlertController *alertController = [__FWAlertController alertControllerWithTitle:(attributedTitle ? nil : title)
                                                                             message:(attributedMessage ? nil : message)
                                                                      preferredStyle:preferredStyle
                                                                       animationType:__FWAlertAnimationTypeDefault
                                                                          appearance:appearance];
    alertController.tapBackgroundViewDismiss = (preferredStyle == __FWAlertControllerStyleActionSheet);
    
    if (attributedTitle) {
        alertController.attributedTitle = attributedTitle;
    } else if (alertController.title.length > 0 && alertController.alertAppearance.controllerEnabled) {
        NSMutableDictionary *titleAttributes = [NSMutableDictionary new];
        if (alertController.alertAppearance.titleFont) {
            titleAttributes[NSFontAttributeName] = alertController.alertAppearance.titleFont;
        }
        if (alertController.alertAppearance.titleColor) {
            titleAttributes[NSForegroundColorAttributeName] = alertController.alertAppearance.titleColor;
        }
        alertController.attributedTitle = [[NSAttributedString alloc] initWithString:alertController.title attributes:titleAttributes];
    }
    
    if (attributedMessage) {
        alertController.attributedMessage = attributedMessage;
    } else if (alertController.message.length > 0 && alertController.alertAppearance.controllerEnabled) {
        NSMutableDictionary *messageAttributes = [NSMutableDictionary new];
        if (alertController.alertAppearance.messageFont) {
            messageAttributes[NSFontAttributeName] = alertController.alertAppearance.messageFont;
        }
        if (alertController.alertAppearance.messageColor) {
            messageAttributes[NSForegroundColorAttributeName] = alertController.alertAppearance.messageColor;
        }
        alertController.attributedMessage = [[NSAttributedString alloc] initWithString:alertController.message attributes:messageAttributes];
    }
    
    [alertController __fw_observeProperty:@"preferredAction" block:^(__FWAlertController *object, NSDictionary *change) {
        [object.actions enumerateObjectsUsingBlock:^(__FWAlertAction *obj, NSUInteger idx, BOOL *stop) {
            if (obj.isPreferred) obj.isPreferred = NO;
        }];
        object.preferredAction.isPreferred = YES;
    }];
    
    return alertController;
}

- (__FWAlertController *)alertControllerWithHeaderView:(UIView *)headerView preferredStyle:(__FWAlertControllerStyle)preferredStyle appearance:(__FWAlertControllerAppearance *)appearance
{
    __FWAlertController *alertController = [__FWAlertController alertControllerWithCustomHeaderView:headerView
                                                                                 preferredStyle:preferredStyle
                                                                                  animationType:__FWAlertAnimationTypeDefault
                                                                                     appearance:appearance];
    alertController.tapBackgroundViewDismiss = (preferredStyle == __FWAlertControllerStyleActionSheet);
    
    [alertController __fw_observeProperty:@"preferredAction" block:^(__FWAlertController *object, NSDictionary *change) {
        [object.actions enumerateObjectsUsingBlock:^(__FWAlertAction *obj, NSUInteger idx, BOOL *stop) {
            if (obj.isPreferred) obj.isPreferred = NO;
        }];
        object.preferredAction.isPreferred = YES;
    }];
    
    return alertController;
}

- (__FWAlertAction *)actionWithObject:(id)object style:(__FWAlertActionStyle)style appearance:(__FWAlertControllerAppearance *)appearance handler:(void (^)(__FWAlertAction *))handler
{
    NSAttributedString *attributedTitle = [object isKindOfClass:[NSAttributedString class]] ? object : nil;
    __FWAlertAction *alertAction = [__FWAlertAction actionWithTitle:(attributedTitle ? nil : object)
                                                          style:style
                                                     appearance:appearance
                                                        handler:handler];
    
    if (attributedTitle) {
        alertAction.attributedTitle = attributedTitle;
    } else {
        alertAction.isPreferred = NO;
    }
    
    [alertAction __fw_observeProperty:@"enabled" block:^(__FWAlertAction *object, NSDictionary *change) {
        object.isPreferred = object.isPreferred;
    }];
    
    return alertAction;
}

@end
