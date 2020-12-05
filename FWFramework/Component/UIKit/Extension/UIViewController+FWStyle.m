/*!
 @header     UIViewController+FWStyle.m
 @indexgroup FWFramework
 @brief      UIViewController+FWStyle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/5
 */

#import "UIViewController+FWStyle.h"
#import "UIImage+FWFramework.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

@implementation UIViewController (FWStyle)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(viewWillAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            
            if (!selfObject.navigationController) return;
            NSNumber *styleNumber = objc_getAssociatedObject(selfObject, @selector(fwNavigationBarStyle));
            if (!styleNumber) return;
            
            FWNavigationBarStyle style = [styleNumber integerValue];
            BOOL navigationBarHidden = (style == FWNavigationBarStyleHidden) ? YES : NO;
            if (navigationBarHidden != selfObject.navigationController.navigationBarHidden) {
                [selfObject.navigationController setNavigationBarHidden:navigationBarHidden animated:YES];
            }
            
            [selfObject.navigationController.navigationBar setShadowImage:[UIImage new]];
            if (style == FWNavigationBarStyleClear) {
                [selfObject.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            }
            
            FWNavigationBarAppearance *appearance = [FWNavigationBarAppearance appearanceForStyle:style];
            if (appearance.backgroundColor) {
                [selfObject.navigationController.navigationBar setBackgroundImage:[UIImage fwImageWithColor:appearance.backgroundColor] forBarMetrics:UIBarMetricsDefault];
            }
            if (appearance.foregroundColor) {
                [selfObject.navigationController.navigationBar setTintColor:appearance.foregroundColor];
                [selfObject.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: appearance.foregroundColor}];
                if (@available(iOS 11.0, *)) {
                    [selfObject.navigationController.navigationBar setLargeTitleTextAttributes:@{NSForegroundColorAttributeName: appearance.foregroundColor}];
                }
            }
            if (appearance.appearanceBlock) {
                appearance.appearanceBlock(selfObject.navigationController.navigationBar);
            }
        }));
    });
}

- (FWNavigationBarStyle)fwNavigationBarStyle
{
    return [objc_getAssociatedObject(self, @selector(fwNavigationBarStyle)) integerValue];
}

- (void)setFwNavigationBarStyle:(FWNavigationBarStyle)fwNavigationBarStyle
{
    objc_setAssociatedObject(self, @selector(fwNavigationBarStyle), @(fwNavigationBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation FWNavigationBarAppearance

- (instancetype)initWithBackgroundColor:(UIColor *)backgroundColor
                        foregroundColor:(UIColor *)foregroundColor
                        appearanceBlock:(void (^)(UINavigationBar *))appearanceBlock
{
    self = [super init];
    if (self) {
        _backgroundColor = backgroundColor;
        _foregroundColor = foregroundColor;
        _appearanceBlock = appearanceBlock;
    }
    return self;
}

+ (NSMutableDictionary *)styleAppearances
{
    static NSMutableDictionary *appearances = nil;
    if (!appearances) {
        appearances = [[NSMutableDictionary alloc] init];
    }
    return appearances;
}

+ (FWNavigationBarAppearance *)appearanceForStyle:(FWNavigationBarStyle)style
{
    return [[self styleAppearances] objectForKey:@(style)];
}

+ (void)setAppearance:(FWNavigationBarAppearance *)appearance forStyle:(FWNavigationBarStyle)style
{
    if (appearance) {
        [[self styleAppearances] setObject:appearance forKey:@(style)];
    } else {
        [[self styleAppearances] removeObjectForKey:@(style)];
    }
}

@end
