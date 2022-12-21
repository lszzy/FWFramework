//
//  FWAlertPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWAlertPluginImpl.h"
#import "FWAlertController.h"
#import "Swizzle.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

- (NSString *)fw_observeProperty:(NSString *)property block:(void (^)(id object, NSDictionary<NSKeyValueChangeKey, id> *change))block;
- (nullable id)fw_invokeSetter:(NSString *)name object:(nullable id)object;
+ (BOOL)fw_swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier block:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

@end

@interface UIDevice ()

@property (class, nonatomic, assign, readonly) BOOL fw_isIpad;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - UIAlertAction+FWAlert

@implementation UIAlertAction (FWAlert)

- (FWAlertAppearance *)fw_alertAppearance
{
    FWAlertAppearance *appearance = objc_getAssociatedObject(self, @selector(fw_alertAppearance));
    return appearance ?: FWAlertAppearance.appearance;
}

- (void)setFw_alertAppearance:(FWAlertAppearance *)alertAppearance
{
    objc_setAssociatedObject(self, @selector(fw_alertAppearance), alertAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_isPreferred
{
    return [objc_getAssociatedObject(self, @selector(fw_isPreferred)) boolValue];
}

- (void)setFw_isPreferred:(BOOL)isPreferred
{
    objc_setAssociatedObject(self, @selector(fw_isPreferred), @(isPreferred), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.fw_titleColor || self.title.length < 1 || !self.fw_alertAppearance.actionEnabled) return;
    
    UIColor *titleColor = nil;
    if (!self.enabled) {
        titleColor = self.fw_alertAppearance.disabledActionColor;
    } else if (isPreferred) {
        titleColor = self.fw_alertAppearance.preferredActionColor;
    } else if (self.style == UIAlertActionStyleDestructive) {
        titleColor = self.fw_alertAppearance.destructiveActionColor;
    } else if (self.style == UIAlertActionStyleCancel) {
        titleColor = self.fw_alertAppearance.cancelActionColor;
    } else {
        titleColor = self.fw_alertAppearance.actionColor;
    }
    if (titleColor) {
        [self fw_invokeSetter:@"titleTextColor" object:titleColor];
    }
}

- (UIColor *)fw_titleColor
{
    return objc_getAssociatedObject(self, @selector(fw_titleColor));
}

- (void)setFw_titleColor:(UIColor *)titleColor
{
    objc_setAssociatedObject(self, @selector(fw_titleColor), titleColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_invokeSetter:@"titleTextColor" object:titleColor];
}

+ (UIAlertAction *)fw_actionWithObject:(id)object style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *))handler
{
    return [self fw_actionWithObject:object style:style appearance:nil handler:handler];
}

+ (UIAlertAction *)fw_actionWithObject:(id)object style:(UIAlertActionStyle)style appearance:(FWAlertAppearance *)appearance handler:(void (^)(UIAlertAction *))handler
{
    NSAttributedString *attributedTitle = [object isKindOfClass:[NSAttributedString class]] ? object : nil;
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:(attributedTitle ? attributedTitle.string : object)
                                                          style:style
                                                         handler:handler];
    
    alertAction.fw_alertAppearance = appearance;
    alertAction.fw_isPreferred = NO;
    
    return alertAction;
}

@end

#pragma mark - UIAlertController+FWAlert

@implementation UIAlertController (FWAlert)

- (FWAlertAppearance *)fw_alertAppearance
{
    FWAlertAppearance *appearance = objc_getAssociatedObject(self, @selector(fw_alertAppearance));
    return appearance ?: FWAlertAppearance.appearance;
}

- (void)setFw_alertAppearance:(FWAlertAppearance *)alertAppearance
{
    objc_setAssociatedObject(self, @selector(fw_alertAppearance), alertAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWAlertStyle)fw_alertStyle
{
    return [objc_getAssociatedObject(self, @selector(fw_alertStyle)) integerValue];
}

- (void)setFw_alertStyle:(FWAlertStyle)alertStyle
{
    objc_setAssociatedObject(self, @selector(fw_alertStyle), @(alertStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSAttributedString *)fw_attributedTitle
{
    return objc_getAssociatedObject(self, @selector(fw_attributedTitle));
}

- (void)setFw_attributedTitle:(NSAttributedString *)attributedTitle
{
    objc_setAssociatedObject(self, @selector(fw_attributedTitle), attributedTitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fw_invokeSetter:@"attributedTitle" object:attributedTitle];
}

- (NSAttributedString *)fw_attributedMessage
{
    return objc_getAssociatedObject(self, @selector(fw_attributedMessage));
}

- (void)setFw_attributedMessage:(NSAttributedString *)attributedMessage
{
    objc_setAssociatedObject(self, @selector(fw_attributedMessage), attributedMessage, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fw_invokeSetter:@"attributedMessage" object:attributedMessage];
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __FWSwizzleClass(UIAlertController, @selector(viewDidLoad), __FWSwizzleReturn(void), __FWSwizzleArgs(), __FWSwizzleCode({
            __FWSwizzleOriginal();
            
            if (selfObject.preferredStyle != UIAlertControllerStyleActionSheet) return;
            if (!selfObject.fw_attributedTitle && !selfObject.fw_attributedMessage) return;
            
            // 兼容iOS13操作表设置title和message样式不生效问题
            if (@available(iOS 13.0, *)) {
                Class targetClass = objc_getClass("_UIInterfaceActionGroupHeaderScrollView");
                if (!targetClass) return;
                
                [UIAlertController fw_alertSubview:selfObject.view block:^BOOL(UIView *view) {
                    if (![view isKindOfClass:targetClass]) return NO;
                    
                    [UIAlertController fw_alertSubview:view block:^BOOL(UIView *view) {
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

+ (UIView *)fw_alertSubview:(UIView *)view block:(BOOL (^)(UIView *view))block
{
    if (block(view)) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *resultView = [self fw_alertSubview:subview block:block];
        if (resultView) {
            return resultView;
        }
    }
    
    return nil;
}

+ (UIAlertController *)fw_alertControllerWithTitle:(id)title message:(id)message preferredStyle:(UIAlertControllerStyle)preferredStyle
{
    return [self fw_alertControllerWithTitle:title message:message preferredStyle:preferredStyle appearance:nil];
}

+ (UIAlertController *)fw_alertControllerWithTitle:(id)title message:(id)message preferredStyle:(UIAlertControllerStyle)preferredStyle appearance:(FWAlertAppearance *)appearance
{
    NSAttributedString *attributedTitle = [title isKindOfClass:[NSAttributedString class]] ? title : nil;
    NSAttributedString *attributedMessage = [message isKindOfClass:[NSAttributedString class]] ? message : nil;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:(attributedTitle ? attributedTitle.string : title)
                                                                             message:(attributedMessage ? attributedMessage.string : message)
                                                                      preferredStyle:preferredStyle];
    
    alertController.fw_alertAppearance = appearance;
    if (attributedTitle) {
        alertController.fw_attributedTitle = attributedTitle;
    } else if (alertController.title.length > 0 && alertController.fw_alertAppearance.controllerEnabled) {
        NSMutableDictionary *titleAttributes = [NSMutableDictionary new];
        if (alertController.fw_alertAppearance.titleFont) {
            titleAttributes[NSFontAttributeName] = alertController.fw_alertAppearance.titleFont;
        }
        if (alertController.fw_alertAppearance.titleColor) {
            titleAttributes[NSForegroundColorAttributeName] = alertController.fw_alertAppearance.titleColor;
        }
        alertController.fw_attributedTitle = [[NSAttributedString alloc] initWithString:alertController.title attributes:titleAttributes];
    }
    
    if (attributedMessage) {
        alertController.fw_attributedMessage = attributedMessage;
    } else if (alertController.message.length > 0 && alertController.fw_alertAppearance.controllerEnabled) {
        NSMutableDictionary *messageAttributes = [NSMutableDictionary new];
        if (alertController.fw_alertAppearance.messageFont) {
            messageAttributes[NSFontAttributeName] = alertController.fw_alertAppearance.messageFont;
        }
        if (alertController.fw_alertAppearance.messageColor) {
            messageAttributes[NSForegroundColorAttributeName] = alertController.fw_alertAppearance.messageColor;
        }
        alertController.fw_attributedMessage = [[NSAttributedString alloc] initWithString:alertController.message attributes:messageAttributes];
    }
    
    [alertController fw_observeProperty:@"preferredAction" block:^(UIAlertController *object, NSDictionary *change) {
        [object.actions enumerateObjectsUsingBlock:^(UIAlertAction *obj, NSUInteger idx, BOOL *stop) {
            if (obj.fw_isPreferred) obj.fw_isPreferred = NO;
        }];
        object.preferredAction.fw_isPreferred = YES;
    }];
    
    return alertController;
}

@end

#pragma mark - FWAlertAppearance

@implementation FWAlertAppearance

+ (FWAlertAppearance *)appearance
{
    static FWAlertAppearance *appearance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appearance = [[FWAlertAppearance alloc] init];
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

#pragma mark - FWAlertPluginImpl

@implementation FWAlertPluginImpl

+ (FWAlertPluginImpl *)sharedInstance
{
    static FWAlertPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWAlertPluginImpl alloc] init];
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
             promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
             actionBlock:(void (^)(NSArray<NSString *> *, NSInteger))actionBlock
             cancelBlock:(void (^)(void))cancelBlock
             customBlock:(void (^)(id))customBlock
{
    // 初始化Alert
    FWAlertAppearance *customAppearance = self.customAlertAppearance;
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
    FWAlertAppearance *customAppearance = self.customSheetAppearance;
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
    NSArray<Class> *alertClasses = self.customAlertClasses.count > 0 ? self.customAlertClasses : @[UIAlertController.class, FWAlertController.class];
    
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
