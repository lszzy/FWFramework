//
//  FWAlertPlugin.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWAlertPlugin.h"
#import "FWSwizzle.h"
#import "FWMessage.h"
#import "FWPlugin.h"
#import "FWProxy.h"
#import <objc/runtime.h>

#pragma mark - UIViewController+FWAlert

@implementation UIViewController (FWAlert)

#pragma mark - Alert

- (void)fwShowAlertWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                 cancelBlock:(void (^)(void))cancelBlock
{
    [self fwShowAlertWithTitle:title
                       message:message
                        cancel:cancel
                       actions:nil
                   actionBlock:nil
                   cancelBlock:cancelBlock
                      priority:FWAlertPriorityNormal];
}

- (void)fwShowAlertWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                    priority:(FWAlertPriority)priority
{
    [self fwShowAlertWithStyle:UIAlertControllerStyleAlert
                         title:title
                       message:message
                        cancel:cancel
                       actions:actions
                   promptCount:0
                   promptBlock:nil
                   actionBlock:^(NSArray<NSString *> *values, NSInteger index) {
                       if (actionBlock) actionBlock(index);
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil
                      priority:priority];
}

- (void)fwShowConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
{
    [self fwShowConfirmWithTitle:title
                         message:message
                          cancel:cancel
                         confirm:confirm
                    confirmBlock:confirmBlock
                     cancelBlock:nil
                        priority:FWAlertPriorityNormal];
}

- (void)fwShowConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
                   cancelBlock:(void (^)(void))cancelBlock
                      priority:(FWAlertPriority)priority
{
    [self fwShowAlertWithTitle:title
                       message:message
                        cancel:cancel
                       actions:[NSArray arrayWithObjects:confirm, nil]
                   actionBlock:^(NSInteger index) {
                       if (confirmBlock) confirmBlock();
                   }
                   cancelBlock:cancelBlock
                      priority:priority];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                 confirmBlock:(void (^)(NSString *))confirmBlock
{
    [self fwShowPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptBlock:nil
                   confirmBlock:confirmBlock
                    cancelBlock:nil
                       priority:FWAlertPriorityNormal];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptBlock:(void (^)(UITextField *))promptBlock
                 confirmBlock:(void (^)(NSString *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority
{
    [self fwShowPromptWithTitle:title
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
                    cancelBlock:cancelBlock
                       priority:priority];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptCount:(NSInteger)promptCount
                  promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 confirmBlock:(void (^)(NSArray<NSString *> *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority
{
    [self fwShowAlertWithStyle:UIAlertControllerStyleAlert
                         title:title
                       message:message
                        cancel:cancel
                       actions:(confirm ? @[confirm] : nil)
                   promptCount:promptCount
                   promptBlock:promptBlock
                   actionBlock:^(NSArray<NSString *> *values, NSInteger index) {
                       if (confirmBlock) confirmBlock(values);
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil
                      priority:priority];
}

#pragma mark - Sheet

- (void)fwShowSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
{
    [self fwShowSheetWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                   actionBlock:actionBlock
                   cancelBlock:nil
                      priority:FWAlertPriorityNormal];
}

- (void)fwShowSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                    priority:(FWAlertPriority)priority
{
    [self fwShowAlertWithStyle:UIAlertControllerStyleActionSheet
                         title:title
                       message:message
                        cancel:cancel
                       actions:actions
                   promptCount:0
                   promptBlock:nil
                   actionBlock:^(NSArray<NSString *> * _Nonnull values, NSInteger index) {
                       if (actionBlock) actionBlock(index);
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil
                      priority:priority];
}

#pragma mark - Style

- (void)fwShowAlertWithStyle:(UIAlertControllerStyle)style
                       title:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 promptCount:(NSInteger)promptCount
                 promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 actionBlock:(void (^)(NSArray<NSString *> *, NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id))customBlock
                    priority:(FWAlertPriority)priority
{
    // 优先调用插件
    id<FWAlertPlugin> alertPlugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWAlertPlugin)];
    if (alertPlugin && [alertPlugin respondsToSelector:@selector(fwViewController:showAlert:title:message:cancel:actions:promptCount:promptBlock:actionBlock:cancelBlock:customBlock:priority:)]) {
        [alertPlugin fwViewController:self showAlert:style title:title message:message cancel:cancel actions:actions promptCount:promptCount promptBlock:promptBlock actionBlock:actionBlock cancelBlock:cancelBlock customBlock:customBlock priority:priority];
        return;
    }
    
    // 初始化Alert
    UIAlertController *alertController = [UIAlertController fwAlertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:style];
    
    // 添加输入框
    for (NSInteger promptIndex = 0; promptIndex < promptCount; promptIndex++) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if (promptBlock) promptBlock(textField, promptIndex);
        }];
    }
    
    // 添加动作按钮
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        UIAlertAction *alertAction = [UIAlertAction fwActionWithObject:actions[actionIndex] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
        UIAlertAction *cancelAction = [UIAlertAction fwActionWithObject:cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (cancelBlock) cancelBlock();
        }];
        [alertController addAction:cancelAction];
    }
    
    // 添加首选按钮
    if (FWAlertAppearance.appearance.preferredActionBlock && alertController.actions.count > 0) {
        UIAlertAction *preferredAction = FWAlertAppearance.appearance.preferredActionBlock(alertController);
        if (preferredAction) {
            if (@available(iOS 9.0, *)) {
                alertController.preferredAction = preferredAction;
            }
        }
    }
    
    // 自定义Alert
    if (customBlock) {
        customBlock(alertController);
    }
    
    // 显示Alert
    alertController.fwAlertPriorityEnabled = YES;
    alertController.fwAlertPriority = priority;
    [alertController fwAlertPriorityPresentIn:self];
}

@end

#pragma mark - UIViewController+FWAlertPriority

// 优先级隐藏状态：0正常隐藏并移除队列；1立即隐藏并保留队列；2立即隐藏执行状态(解决弹出框还未显示完成时调用dismiss触发警告问题)。默认0
@implementation UIViewController (FWAlertPriority)

#pragma mark - Accessor

- (BOOL)fwAlertPriorityEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwAlertPriorityEnabled)) boolValue];
}

- (void)setFwAlertPriorityEnabled:(BOOL)fwAlertPriorityEnabled
{
    objc_setAssociatedObject(self, @selector(fwAlertPriorityEnabled), @(fwAlertPriorityEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWAlertPriority)fwAlertPriority
{
    return [objc_getAssociatedObject(self, @selector(fwAlertPriority)) integerValue];
}

- (void)setFwAlertPriority:(FWAlertPriority)fwAlertPriority
{
    objc_setAssociatedObject(self, @selector(fwAlertPriority), @(fwAlertPriority), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)fwAlertPriorityParentController
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwAlertPriorityParentController));
    return value.object;
}

- (void)setFwAlertPriorityParentController:(UIViewController *)fwAlertPriorityParentController
{
    objc_setAssociatedObject(self, @selector(fwAlertPriorityParentController), [[FWWeakObject alloc] initWithObject:fwAlertPriorityParentController], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)fwAlertPriorityDismissState
{
    return [objc_getAssociatedObject(self, @selector(fwAlertPriorityDismissState)) integerValue];
}

- (void)setFwAlertPriorityDismissState:(NSInteger)fwAlertPriorityDismissState
{
    objc_setAssociatedObject(self, @selector(fwAlertPriorityDismissState), @(fwAlertPriorityDismissState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Hook

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(viewDidAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            if (!selfObject.fwAlertPriorityEnabled) return;
            
            // 替换弹出框时显示完成立即隐藏
            if (selfObject.fwAlertPriorityDismissState == 1) {
                selfObject.fwAlertPriorityDismissState = 2;
                [selfObject dismissViewControllerAnimated:YES completion:nil];
            }
        }));
        FWSwizzleClass(UIViewController, @selector(viewDidDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            if (!selfObject.fwAlertPriorityEnabled) return;
            
            // 立即隐藏不移除队列，正常隐藏移除队列
            NSMutableArray *alertControllers = [selfObject fwInnerAlertPriorityControllers:NO];
            if (selfObject.fwAlertPriorityDismissState > 0) {
                selfObject.fwAlertPriorityDismissState = 0;
            } else {
                [alertControllers removeObject:selfObject];
            }
            
            // 按优先级显示下一个弹出框
            if (alertControllers.count > 0) {
                [selfObject.fwAlertPriorityParentController presentViewController:[alertControllers firstObject] animated:YES completion:nil];
            }
        }));
    });
}

- (void)fwAlertPriorityPresentIn:(UIViewController *)viewController
{
    if (!self.fwAlertPriorityEnabled) return;
    
    // 加入队列并按优先级排序
    self.fwAlertPriorityParentController = viewController;
    NSMutableArray *alertControllers = [self fwInnerAlertPriorityControllers:YES];
    if (![alertControllers containsObject:self]) {
        [alertControllers addObject:self];
    }
    [alertControllers sortUsingComparator:^NSComparisonResult(UIViewController *obj1, UIViewController *obj2) {
        return [@(obj2.fwAlertPriority) compare:@(obj1.fwAlertPriority)];
    }];
    // 独占优先级只显示一个
    UIAlertController *firstController = [alertControllers firstObject];
    if (firstController.fwAlertPriority == FWAlertPrioritySuper) {
        [alertControllers removeAllObjects];
        [alertControllers addObject:firstController];
    }
    
    UIViewController *currentController = viewController.presentedViewController;
    if (currentController && currentController.fwAlertPriorityEnabled) {
        if (currentController != firstController) {
            // 替换弹出框时显示完成立即隐藏。如果已经显示，直接隐藏；如果未显示完，等待显示完成立即隐藏。解决弹出框还未显示完成时调用dismiss触发警告问题
            currentController.fwAlertPriorityDismissState = 1;
            if (currentController.isViewLoaded && currentController.view.window && currentController.fwAlertPriorityDismissState == 1) {
                currentController.fwAlertPriorityDismissState = 2;
                [currentController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    } else {
        [viewController presentViewController:firstController animated:YES completion:nil];
    }
}

- (NSMutableArray *)fwInnerAlertPriorityControllers:(BOOL)autoCreate
{
    // parentController强引用弹出框数组，内部使用弱引用
    NSMutableArray *array = objc_getAssociatedObject(self.fwAlertPriorityParentController, _cmd);
    if (!array && autoCreate) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self.fwAlertPriorityParentController, _cmd, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return array;
}

@end

#pragma mark - UIAlertAction+FWAlert

@implementation UIAlertAction (FWAlert)

+ (instancetype)fwActionWithObject:(id)object style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *))handler
{
    NSAttributedString *attributedTitle = [object isKindOfClass:[NSAttributedString class]] ? object : nil;
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:(attributedTitle ? attributedTitle.string : object)
                                                          style:style
                                                         handler:handler];
    
    alertAction.fwIsPreferred = NO;
    
    return alertAction;
}

- (BOOL)fwIsPreferred
{
    return [objc_getAssociatedObject(self, @selector(fwIsPreferred)) boolValue];
}

- (void)setFwIsPreferred:(BOOL)fwIsPreferred
{
    objc_setAssociatedObject(self, @selector(fwIsPreferred), @(fwIsPreferred), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.fwTitleColor || self.title.length < 1 || !FWAlertAppearance.appearance.actionEnabled) return;
    
    UIColor *titleColor = nil;
    if (!self.enabled) {
        titleColor = FWAlertAppearance.appearance.disabledActionColor;
    } else if (fwIsPreferred) {
        titleColor = FWAlertAppearance.appearance.preferredActionColor;
    } else if (self.style == UIAlertActionStyleDestructive) {
        titleColor = FWAlertAppearance.appearance.destructiveActionColor;
    } else if (self.style == UIAlertActionStyleCancel) {
        titleColor = FWAlertAppearance.appearance.cancelActionColor;
    } else {
        titleColor = FWAlertAppearance.appearance.actionColor;
    }
    if (titleColor) {
        [self fwPerformPropertySelector:@"titleTextColor" withObject:titleColor];
    }
}

- (UIColor *)fwTitleColor
{
    return objc_getAssociatedObject(self, @selector(fwTitleColor));
}

- (void)setFwTitleColor:(UIColor *)fwTitleColor
{
    objc_setAssociatedObject(self, @selector(fwTitleColor), fwTitleColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwPerformPropertySelector:@"titleTextColor" withObject:fwTitleColor];
}

@end

#pragma mark - UIAlertController+FWAlert

@implementation UIAlertController (FWAlert)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIAlertController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.preferredStyle != UIAlertControllerStyleActionSheet) return;
            if (!selfObject.fwAttributedTitle && !selfObject.fwAttributedMessage) return;
            
            // 兼容iOS13操作表设置title和message样式不生效问题
            if (@available(iOS 13.0, *)) {
                Class targetClass = objc_getClass("_UIInterfaceActionGroupHeaderScrollView");
                if (!targetClass) return;
                
                [UIAlertController fwAlertSubview:selfObject.view block:^BOOL(UIView *view) {
                    if (![view isKindOfClass:targetClass]) return NO;
                    
                    [UIAlertController fwAlertSubview:view block:^BOOL(UIView *view) {
                        if ([view isKindOfClass:[UIVisualEffectView class]]) {
                            // 取消effect效果，否则样式不生效，全是灰色
                            ((UIVisualEffectView *)view).effect = nil;
                            return YES;
                        }
                        return NO;
                    }];
                    return YES;
                }];
            }
        }));
    });
}

+ (UIView *)fwAlertSubview:(UIView *)view block:(BOOL (^)(UIView *view))block
{
    if (block(view)) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *resultView = [UIAlertController fwAlertSubview:subview block:block];
        if (resultView) {
            return resultView;
        }
    }
    
    return nil;
}

+ (instancetype)fwAlertControllerWithTitle:(id)title message:(id)message preferredStyle:(UIAlertControllerStyle)preferredStyle
{
    NSAttributedString *attributedTitle = [title isKindOfClass:[NSAttributedString class]] ? title : nil;
    NSAttributedString *attributedMessage = [message isKindOfClass:[NSAttributedString class]] ? message : nil;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:(attributedTitle ? attributedTitle.string : title)
                                                                             message:(attributedMessage ? attributedMessage.string : message)
                                                                      preferredStyle:preferredStyle];
    
    if (attributedTitle) {
        alertController.fwAttributedTitle = attributedTitle;
    } else if (alertController.title.length > 0 && FWAlertAppearance.appearance.controllerEnabled) {
        NSMutableDictionary *titleAttributes = [NSMutableDictionary new];
        if (FWAlertAppearance.appearance.titleFont) {
            titleAttributes[NSFontAttributeName] = FWAlertAppearance.appearance.titleFont;
        }
        if (FWAlertAppearance.appearance.titleColor) {
            titleAttributes[NSForegroundColorAttributeName] = FWAlertAppearance.appearance.titleColor;
        }
        alertController.fwAttributedTitle = [[NSAttributedString alloc] initWithString:alertController.title attributes:titleAttributes];
    }
    
    if (attributedMessage) {
        alertController.fwAttributedMessage = attributedMessage;
    } else if (alertController.message.length > 0 && FWAlertAppearance.appearance.controllerEnabled) {
        NSMutableDictionary *messageAttributes = [NSMutableDictionary new];
        if (FWAlertAppearance.appearance.messageFont) {
            messageAttributes[NSFontAttributeName] = FWAlertAppearance.appearance.messageFont;
        }
        if (FWAlertAppearance.appearance.messageColor) {
            messageAttributes[NSForegroundColorAttributeName] = FWAlertAppearance.appearance.messageColor;
        }
        alertController.fwAttributedMessage = [[NSAttributedString alloc] initWithString:alertController.message attributes:messageAttributes];
    }
    
    if (@available(iOS 9.0, *)) {
        [alertController fwObserveProperty:@"preferredAction" block:^(UIAlertController *object, NSDictionary *change) {
            [object.actions enumerateObjectsUsingBlock:^(UIAlertAction *obj, NSUInteger idx, BOOL *stop) {
                if (obj.fwIsPreferred) obj.fwIsPreferred = NO;
            }];
            object.preferredAction.fwIsPreferred = YES;
        }];
    }
    
    return alertController;
}

- (NSAttributedString *)fwAttributedTitle
{
    return objc_getAssociatedObject(self, @selector(fwAttributedTitle));
}

- (void)setFwAttributedTitle:(NSAttributedString *)fwAttributedTitle
{
    objc_setAssociatedObject(self, @selector(fwAttributedTitle), fwAttributedTitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fwPerformPropertySelector:@"attributedTitle" withObject:fwAttributedTitle];
}

- (NSAttributedString *)fwAttributedMessage
{
    return objc_getAssociatedObject(self, @selector(fwAttributedMessage));
}

- (void)setFwAttributedMessage:(NSAttributedString *)fwAttributedMessage
{
    objc_setAssociatedObject(self, @selector(fwAttributedMessage), fwAttributedMessage, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fwPerformPropertySelector:@"attributedMessage" withObject:fwAttributedMessage];
}

@end

#pragma mark - FWAlertAppearance

@implementation FWAlertAppearance

+ (instancetype)appearance
{
    static FWAlertAppearance *appearance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appearance = [[self alloc] init];
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
