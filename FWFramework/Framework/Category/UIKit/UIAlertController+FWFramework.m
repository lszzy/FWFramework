/*!
 @header     UIAlertController+FWFramework.m
 @indexgroup FWFramework
 @brief      UIAlertController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/4/25
 */

#import "UIAlertController+FWFramework.h"
#import "UIView+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

#pragma mark - UIAlertAction+FWFramework

@implementation UIAlertAction (FWFramework)

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
        titleColor = FWAlertAppearance.appearance.defaultActionColor;
    }
    [self fwPerformPropertySelector:@"titleTextColor" withObject:titleColor];
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

#pragma mark - UIAlertController+FWFramework

@implementation UIAlertController (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(viewDidLoad) with:@selector(fwInnerAlertViewDidLoad)];
        if (@available(iOS 9.0, *)) {
            [self fwSwizzleInstanceMethod:@selector(setPreferredAction:) with:@selector(fwInnerSetPreferredAction:)];
        }
    });
}

- (void)fwInnerAlertViewDidLoad
{
    [self fwInnerAlertViewDidLoad];
    if (self.preferredStyle != UIAlertControllerStyleActionSheet) return;
    if (!self.fwAttributedTitle && !self.fwAttributedMessage) return;
    
    // 兼容iOS13操作表设置title和message样式不生效问题
    if (@available(iOS 13.0, *)) {
        Class targetClass = objc_getClass("_UIInterfaceActionGroupHeaderScrollView");
        if (!targetClass) return;
        
        [self.view fwSubviewOfBlock:^BOOL(UIView * _Nonnull view) {
            if (![view isKindOfClass:targetClass]) return NO;
            
            [view fwSubviewOfBlock:^BOOL(UIView * _Nonnull view) {
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
}

- (void)fwInnerSetPreferredAction:(UIAlertAction *)preferredAction
{
    [self fwInnerSetPreferredAction:preferredAction];
    
    [self.actions enumerateObjectsUsingBlock:^(UIAlertAction *obj, NSUInteger idx, BOOL *stop) {
        if (obj.fwIsPreferred) obj.fwIsPreferred = NO;
    }];
    preferredAction.fwIsPreferred = YES;
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
    return self.titleColor || self.titleFont ||
           self.messageColor || self.messageFont;
}

- (BOOL)actionEnabled
{
    return self.cancelActionColor || self.defaultActionColor || self.destructiveActionColor ||
           self.disabledActionColor || self.preferredActionColor;
}

@end
