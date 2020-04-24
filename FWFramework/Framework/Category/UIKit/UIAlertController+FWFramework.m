/*!
 @header     UIAlertController+FWFramework.m
 @indexgroup FWFramework
 @brief      UIAlertController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/4/25
 */

#import "UIAlertController+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

#pragma mark - UIAlertController+FWFramework

static UIAlertController *fwAlertControllerAppearance = nil;

@implementation UIAlertController (FWFramework)

+ (instancetype)fwAlertControllerWithTitle:(id)title message:(id)message preferredStyle:(UIAlertControllerStyle)preferredStyle
{
    NSAttributedString *attributedTitle = [title isKindOfClass:[NSAttributedString class]] ? title : nil;
    NSAttributedString *attributedMessage = [message isKindOfClass:[NSAttributedString class]] ? message : nil;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:(attributedTitle ? nil : title)
                                                                             message:(attributedMessage ? nil : message)
                                                                      preferredStyle:preferredStyle];
    if (attributedTitle) {
        [alertController fwPerformPropertySelector:@"attributedTitle" withObject:attributedTitle];
    }
    if (attributedMessage) {
        [alertController fwPerformPropertySelector:@"attributedMessage" withObject:attributedMessage];
    }
    return alertController;
}

#pragma mark - Appearance

+ (instancetype)fwAppearance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fwAlertControllerAppearance = [[self alloc] init];
    });
    return fwAlertControllerAppearance;
}

- (UIColor *)fwTitleColor
{
    return objc_getAssociatedObject(self, @selector(fwTitleColor));
}

- (void)setFwTitleColor:(UIColor *)fwTitleColor
{
    objc_setAssociatedObject(self, @selector(fwTitleColor), fwTitleColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIFont *)fwTitleFont
{
    return objc_getAssociatedObject(self, @selector(fwTitleFont));
}

- (void)setFwTitleFont:(UIFont *)fwTitleFont
{
    objc_setAssociatedObject(self, @selector(fwTitleFont), fwTitleFont, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)fwMessageColor
{
    return objc_getAssociatedObject(self, @selector(fwMessageColor));
}

- (void)setFwMessageColor:(UIColor *)fwMessageColor
{
    objc_setAssociatedObject(self, @selector(fwMessageColor), fwMessageColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIFont *)fwMessageFont
{
    return objc_getAssociatedObject(self, @selector(fwMessageFont));
}

- (void)setFwMessageFont:(UIFont *)fwMessageFont
{
    objc_setAssociatedObject(self, @selector(fwMessageFont), fwMessageFont, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UIAlertAction+FWFramework

static UIAlertAction *fwAlertActionAppearance = nil;

@implementation UIAlertAction (FWFramework)

+ (instancetype)fwActionWithTitle:(NSString *)title style:(UIAlertActionStyle)style
{
    return [self actionWithTitle:title style:style handler:nil];
}

+ (instancetype)fwActionWithObject:(id)object style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *))handler
{
    UIAlertAction *action = [object isKindOfClass:[UIAlertAction class]] ? (UIAlertAction *)object : nil;
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:(action ? action.title : object)
                                                          style:(action ? action.style : style)
                                                         handler:handler];
    if (action) {
        alertAction.enabled = action.enabled;
        alertAction.fwIsPreferred = action.fwIsPreferred;
    }
    return alertAction;
}

- (BOOL)fwIsPreferred
{
    return [objc_getAssociatedObject(self, @selector(fwIsPreferred)) boolValue];
}

- (void)setFwIsPreferred:(BOOL)fwIsPreferred
{
    objc_setAssociatedObject(self, @selector(fwIsPreferred), @(fwIsPreferred), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIAlertAction *(^)(BOOL))fwPreferred
{
    return ^UIAlertAction *(BOOL preferred) {
        self.fwIsPreferred = preferred;
        return self;
    };
}

- (UIAlertAction *(^)(BOOL))fwEnabled
{
    return ^UIAlertAction *(BOOL enabled) {
        self.enabled = enabled;
        return self;
    };
}

#pragma mark - Appearance

+ (instancetype)fwAppearance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fwAlertActionAppearance = [[self alloc] init];
    });
    return fwAlertActionAppearance;
}

- (UIColor *)fwDefaultActionColor
{
    return objc_getAssociatedObject(self, @selector(fwDefaultActionColor));
}

- (void)setFwDefaultActionColor:(UIColor *)fwDefaultActionColor
{
    objc_setAssociatedObject(self, @selector(fwDefaultActionColor), fwDefaultActionColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)fwCancelActionColor
{
    return objc_getAssociatedObject(self, @selector(fwCancelActionColor));
}

- (void)setFwCancelActionColor:(UIColor *)fwCancelActionColor
{
    objc_setAssociatedObject(self, @selector(fwCancelActionColor), fwCancelActionColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)fwDestructiveActionColor
{
    return objc_getAssociatedObject(self, @selector(fwDestructiveActionColor));
}

- (void)setFwDestructiveActionColor:(UIColor *)fwDestructiveActionColor
{
    objc_setAssociatedObject(self, @selector(fwDestructiveActionColor), fwDestructiveActionColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)fwDisabledActionColor
{
    return objc_getAssociatedObject(self, @selector(fwDisabledActionColor));
}

- (void)setFwDisabledActionColor:(UIColor *)fwDisabledActionColor
{
    objc_setAssociatedObject(self, @selector(fwDisabledActionColor), fwDisabledActionColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)fwPreferredActionColor
{
    return objc_getAssociatedObject(self, @selector(fwPreferredActionColor));
}

- (void)setFwPreferredActionColor:(UIColor *)fwPreferredActionColor
{
    objc_setAssociatedObject(self, @selector(fwPreferredActionColor), fwPreferredActionColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
