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
            
            FWNavigationBarConfig *config = [FWNavigationBarConfig configForStyle:style];
            if (config.backgroundColor) {
                [selfObject.navigationController.navigationBar setBackgroundImage:[UIImage fwImageWithColor:config.backgroundColor] forBarMetrics:UIBarMetricsDefault];
            }
            if (config.foregroundColor) {
                [selfObject.navigationController.navigationBar setTintColor:config.foregroundColor];
                [selfObject.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: config.foregroundColor}];
                if (@available(iOS 11.0, *)) {
                    [selfObject.navigationController.navigationBar setLargeTitleTextAttributes:@{NSForegroundColorAttributeName: config.foregroundColor}];
                }
            }
            if (config.configBlock) {
                config.configBlock(selfObject.navigationController.navigationBar);
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

@implementation FWNavigationBarConfig

- (instancetype)initWithBackgroundColor:(UIColor *)backgroundColor
                        foregroundColor:(UIColor *)foregroundColor
                            configBlock:(void (^)(UINavigationBar *))configBlock
{
    self = [super init];
    if (self) {
        _backgroundColor = backgroundColor;
        _foregroundColor = foregroundColor;
        _configBlock = configBlock;
    }
    return self;
}

+ (NSMutableDictionary *)styleConfigs
{
    static NSMutableDictionary *configs = nil;
    if (!configs) {
        configs = [[NSMutableDictionary alloc] init];
    }
    return configs;
}

+ (FWNavigationBarConfig *)configForStyle:(FWNavigationBarStyle)style
{
    return [[self styleConfigs] objectForKey:@(style)];
}

+ (void)setConfig:(FWNavigationBarConfig *)config forStyle:(FWNavigationBarStyle)style
{
    if (config) {
        [[self styleConfigs] setObject:config forKey:@(style)];
    } else {
        [[self styleConfigs] removeObjectForKey:@(style)];
    }
}

@end
