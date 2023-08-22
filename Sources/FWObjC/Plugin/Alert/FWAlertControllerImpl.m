//
//  FWAlertControllerImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWAlertControllerImpl.h"
#import "FWMessage.h"
#import <objc/runtime.h>

#pragma mark - FWAlertControllerPlugin

@interface FWAlertAction (FWAlertControllerPlugin)

@end

@implementation FWAlertAction (FWAlertControllerPlugin)

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

@implementation FWAlertControllerImpl

+ (FWAlertControllerImpl *)sharedInstance
{
    static FWAlertControllerImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWAlertControllerImpl alloc] init];
    });
    return instance;
}

- (void)viewController:(UIViewController *)viewController
      showAlertWithTitle:(id)title
                 message:(id)message
                   style:(FWAlertStyle)style
                  cancel:(id)cancel
                 actions:(NSArray *)actions
             promptCount:(NSInteger)promptCount
             promptBlock:(void (^)(UITextField * _Nonnull, NSInteger))promptBlock
             actionBlock:(void (^)(NSArray<NSString *> * _Nonnull, NSInteger))actionBlock
             cancelBlock:(void (^)(void))cancelBlock
             customBlock:(void (^)(id))customBlock
{
    // 初始化Alert
    FWAlertControllerAppearance *customAppearance = self.customAlertAppearance;
    FWAlertController *alertController = [self alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:FWAlertControllerStyleAlert
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
        FWAlertAction *alertAction = [self actionWithObject:actions[actionIndex] style:FWAlertActionStyleDefault appearance:customAppearance handler:^(FWAlertAction *action) {
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
        FWAlertAction *cancelAction = [self actionWithObject:cancel style:FWAlertActionStyleCancel appearance:customAppearance handler:^(FWAlertAction *action) {
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
        FWAlertAction *preferredAction = alertController.alertAppearance.preferredActionBlock(alertController);
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
    FWAlertControllerAppearance *customAppearance = self.customSheetAppearance;
    FWAlertController *alertController = [self alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:FWAlertControllerStyleActionSheet
                                                             appearance:customAppearance];
    
    // 添加动作按钮
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        FWAlertAction *alertAction = [self actionWithObject:actions[actionIndex] style:FWAlertActionStyleDefault appearance:customAppearance handler:^(FWAlertAction *action) {
            if (actionBlock) {
                actionBlock(actionIndex);
            }
        }];
        [alertController addAction:alertAction];
    }
    
    // 添加取消按钮
    if (cancel != nil && !self.hidesSheetCancel) {
        FWAlertAction *cancelAction = [self actionWithObject:cancel style:FWAlertActionStyleCancel appearance:customAppearance handler:^(FWAlertAction *action) {
            if (cancelBlock) cancelBlock();
        }];
        [alertController addAction:cancelAction];
    }
    
    // 点击背景
    if (self.dimmingTriggerCancel || self.hidesSheetCancel) {
        alertController.dismissCompletion = cancelBlock;
    }
    
    // 添加首选按钮
    if (currentIndex >= 0 && alertController.actions.count > currentIndex) {
        alertController.preferredAction = alertController.actions[currentIndex];
    } else if (alertController.alertAppearance.preferredActionBlock && alertController.actions.count > 0) {
        FWAlertAction *preferredAction = alertController.alertAppearance.preferredActionBlock(alertController);
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
    FWAlertControllerAppearance *customAppearance = style == UIAlertControllerStyleActionSheet ? self.customSheetAppearance : self.customAlertAppearance;
    FWAlertController *alertController = [self alertControllerWithHeaderView:headerView
                                                              preferredStyle:(FWAlertControllerStyle)style
                                                                  appearance:customAppearance];
    
    // 添加动作按钮
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        FWAlertAction *alertAction = [self actionWithObject:actions[actionIndex] style:FWAlertActionStyleDefault appearance:customAppearance handler:^(FWAlertAction *action) {
            if (actionBlock) actionBlock(actionIndex);
        }];
        [alertController addAction:alertAction];
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        FWAlertAction *cancelAction = [self actionWithObject:cancel style:FWAlertActionStyleCancel appearance:customAppearance handler:^(FWAlertAction *action) {
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
        FWAlertAction *preferredAction = alertController.alertAppearance.preferredActionBlock(alertController);
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

- (FWAlertController *)alertControllerWithTitle:(id)title message:(id)message preferredStyle:(FWAlertControllerStyle)preferredStyle appearance:(FWAlertControllerAppearance *)appearance
{
    NSAttributedString *attributedTitle = [title isKindOfClass:[NSAttributedString class]] ? title : nil;
    NSAttributedString *attributedMessage = [message isKindOfClass:[NSAttributedString class]] ? message : nil;
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:(attributedTitle ? nil : title)
                                                                             message:(attributedMessage ? nil : message)
                                                                      preferredStyle:preferredStyle
                                                                       animationType:FWAlertAnimationTypeDefault
                                                                          appearance:appearance];
    alertController.tapBackgroundViewDismiss = (preferredStyle == FWAlertControllerStyleActionSheet);
    
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
    
    [alertController fw_observeProperty:@"preferredAction" block:^(FWAlertController *object, NSDictionary *change) {
        [object.actions enumerateObjectsUsingBlock:^(FWAlertAction *obj, NSUInteger idx, BOOL *stop) {
            if (obj.isPreferred) obj.isPreferred = NO;
        }];
        object.preferredAction.isPreferred = YES;
    }];
    
    return alertController;
}

- (FWAlertController *)alertControllerWithHeaderView:(UIView *)headerView preferredStyle:(FWAlertControllerStyle)preferredStyle appearance:(FWAlertControllerAppearance *)appearance
{
    FWAlertController *alertController = [FWAlertController alertControllerWithCustomHeaderView:headerView
                                                                                 preferredStyle:preferredStyle
                                                                                  animationType:FWAlertAnimationTypeDefault
                                                                                     appearance:appearance];
    alertController.tapBackgroundViewDismiss = (preferredStyle == FWAlertControllerStyleActionSheet);
    
    [alertController fw_observeProperty:@"preferredAction" block:^(FWAlertController *object, NSDictionary *change) {
        [object.actions enumerateObjectsUsingBlock:^(FWAlertAction *obj, NSUInteger idx, BOOL *stop) {
            if (obj.isPreferred) obj.isPreferred = NO;
        }];
        object.preferredAction.isPreferred = YES;
    }];
    
    return alertController;
}

- (FWAlertAction *)actionWithObject:(id)object style:(FWAlertActionStyle)style appearance:(FWAlertControllerAppearance *)appearance handler:(void (^)(FWAlertAction *))handler
{
    NSAttributedString *attributedTitle = [object isKindOfClass:[NSAttributedString class]] ? object : nil;
    FWAlertAction *alertAction = [FWAlertAction actionWithTitle:(attributedTitle ? nil : object)
                                                          style:style
                                                     appearance:appearance
                                                        handler:handler];
    
    if (attributedTitle) {
        alertAction.attributedTitle = attributedTitle;
    } else {
        alertAction.isPreferred = NO;
    }
    
    [alertAction fw_observeProperty:@"enabled" block:^(FWAlertAction *object, NSDictionary *change) {
        object.isPreferred = object.isPreferred;
    }];
    
    return alertAction;
}

@end
