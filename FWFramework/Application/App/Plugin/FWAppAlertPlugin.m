//
//  FWAppAlertPlugin.m
//  FWFramework
//
//  Created by wuyong on 2020/4/25.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "FWAppAlertPlugin.h"
#import "UIAlertController+FWFramework.h"
#import "FWAlertController.h"

@implementation FWAppAlertPlugin

- (void)fwViewController:(UIViewController *)viewController
               showAlert:(UIAlertControllerStyle)style
                   title:(id)title
                 message:(id)message
                  cancel:(id)cancel
                 actions:(NSArray *)actions
             promptCount:(NSInteger)promptCount
             promptBlock:(void (^)(UITextField * _Nonnull, NSInteger))promptBlock
             actionBlock:(void (^)(NSArray<NSString *> * _Nonnull, NSInteger))actionBlock
             cancelBlock:(void (^)(void))cancelBlock
                priority:(FWAlertPriority)priority
{
    // 初始化Alert
    FWAlertController *alertController = [self alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:(FWAlertControllerStyle)style];
    
    // 添加输入框并初始化输入框
    for (NSInteger promptIndex = 0; promptIndex < promptCount; promptIndex++) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if (promptBlock) promptBlock(textField, promptIndex);
        }];
    }
    
    // 添加动作按钮
    FWAlertAction *preferredAction = nil;
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        FWAlertAction *alertAction = [self actionWithObject:actions[actionIndex] style:FWAlertActionStyleDefault handler:^(FWAlertAction *action) {
            if (actionBlock) {
                NSMutableArray *values = [NSMutableArray new];
                for (NSInteger fieldIndex = 0; fieldIndex < promptCount; fieldIndex++) {
                    UITextField *textField = alertController.textFields[fieldIndex];
                    [values addObject:textField.text ?: @""];
                }
                actionBlock(values.copy, actionIndex);
            }
        }];
        // if (alertAction.fwIsPreferred) preferredAction = alertAction;
        [alertController addAction:alertAction];
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        FWAlertAction *cancelAction = [self actionWithObject:cancel style:FWAlertActionStyleCancel handler:^(FWAlertAction *action) {
            if (cancelBlock) cancelBlock();
        }];
        // if (cancelAction.fwIsPreferred) preferredAction = cancelAction;
        [alertController addAction:cancelAction];
    }
    
    // 添加首选按钮
    if (!preferredAction && alertController.actions.count > 0) {
        if (FWAlertAppearance.appearance.preferredActionBlock) {
            // preferredAction = FWAlertAppearance.appearance.preferredActionBlock(alertController);
            // if (preferredAction) preferredAction.fwIsPreferred = YES;
        }
    }
    
    // 显示Alert
    alertController.fwAlertPriorityEnabled = YES;
    alertController.fwAlertPriority = priority;
    // if (preferredAction != nil) alertController.preferredAction = preferredAction;
    [alertController fwAlertPriorityPresentIn:viewController];
}

- (FWAlertController *)alertControllerWithTitle:(id)title message:(id)message preferredStyle:(FWAlertControllerStyle)preferredStyle
{
    NSAttributedString *attributedTitle = [title isKindOfClass:[NSAttributedString class]] ? title : nil;
    NSAttributedString *attributedMessage = [message isKindOfClass:[NSAttributedString class]] ? message : nil;
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:(attributedTitle ? nil : title)
                                                                             message:(attributedMessage ? nil : message)
                                                                      preferredStyle:preferredStyle];
    
    if (attributedTitle) {
        alertController.attributedTitle = attributedTitle;
    } else if (alertController.title.length > 0 && FWAlertAppearance.appearance.controllerEnabled) {
        NSMutableDictionary *titleAttributes = [NSMutableDictionary new];
        if (FWAlertAppearance.appearance.titleFont) {
            titleAttributes[NSFontAttributeName] = FWAlertAppearance.appearance.titleFont;
        }
        if (FWAlertAppearance.appearance.titleColor) {
            titleAttributes[NSForegroundColorAttributeName] = FWAlertAppearance.appearance.titleColor;
        }
        alertController.attributedTitle = [[NSAttributedString alloc] initWithString:alertController.title attributes:titleAttributes];
    }
    
    if (attributedMessage) {
        alertController.attributedMessage = attributedMessage;
    } else if (alertController.message.length > 0 && FWAlertAppearance.appearance.controllerEnabled) {
        NSMutableDictionary *messageAttributes = [NSMutableDictionary new];
        if (FWAlertAppearance.appearance.messageFont) {
            messageAttributes[NSFontAttributeName] = FWAlertAppearance.appearance.messageFont;
        }
        if (FWAlertAppearance.appearance.messageColor) {
            messageAttributes[NSForegroundColorAttributeName] = FWAlertAppearance.appearance.messageColor;
        }
        alertController.attributedMessage = [[NSAttributedString alloc] initWithString:alertController.message attributes:messageAttributes];
    }
    
    return alertController;
}

- (FWAlertAction *)actionWithObject:(id)object style:(FWAlertActionStyle)style handler:(void (^)(FWAlertAction *))handler
{
    UIAlertAction *action = [object isKindOfClass:[UIAlertAction class]] ? object : nil;
    NSAttributedString *attributedTitle = [object isKindOfClass:[NSAttributedString class]] ? object : nil;
    FWAlertAction *alertAction = [FWAlertAction actionWithTitle:(action ? action.title : (attributedTitle ? nil : object))
                                                          style:(action ? (FWAlertActionStyle)action.style : style)
                                                         handler:handler];
    
    if (attributedTitle) {
        alertAction.attributedTitle = attributedTitle;
    }
    
    if (action) {
        alertAction.enabled = action.enabled;
        // alertAction.fwIsPreferred = action.fwIsPreferred;
    }
    
    if (action.fwTitleColor) {
        alertAction.titleColor = action.fwTitleColor;
    } else if (alertAction.title.length > 0 && FWAlertAppearance.appearance.actionEnabled) {
        UIColor *titleColor = nil;
        if (!alertAction.enabled) {
            titleColor = FWAlertAppearance.appearance.disabledActionColor;
        //} else if (alertAction.fwIsPreferred) {
            //titleColor = FWAlertAppearance.appearance.preferredActionColor;
        } else if (alertAction.style == UIAlertActionStyleDestructive) {
            titleColor = FWAlertAppearance.appearance.destructiveActionColor;
        } else if (alertAction.style == UIAlertActionStyleCancel) {
            titleColor = FWAlertAppearance.appearance.cancelActionColor;
        } else {
            titleColor = FWAlertAppearance.appearance.defaultActionColor;
        }
        alertAction.titleColor = titleColor;
    }
    
    return alertAction;
}

@end
