/*!
 @header     FWViewControllerStyle.m
 @indexgroup FWFramework
 @brief      FWViewControllerStyle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/5
 */

#import "FWViewControllerStyle.h"
#import "FWBlock.h"
#import "FWSwizzle.h"
#import "FWImage.h"
#import <objc/runtime.h>

@implementation UIViewController (FWStyle)

#pragma mark - Bar

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(prefersStatusBarHidden), FWSwizzleReturn(BOOL), FWSwizzleArgs(), FWSwizzleCode({
            NSNumber *hiddenValue = objc_getAssociatedObject(selfObject, @selector(fwStatusBarHidden));
            if (hiddenValue) {
                return [hiddenValue boolValue];
            } else {
                return FWSwizzleOriginal();
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(preferredStatusBarStyle), FWSwizzleReturn(UIStatusBarStyle), FWSwizzleArgs(), FWSwizzleCode({
            NSNumber *styleValue = objc_getAssociatedObject(selfObject, @selector(fwStatusBarStyle));
            if (styleValue) {
                return [styleValue integerValue];
            } else {
                return FWSwizzleOriginal();
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            
            if (!selfObject.navigationController) return;
            NSNumber *styleNumber = objc_getAssociatedObject(selfObject, @selector(fwNavigationBarStyle));
            if (!styleNumber) return;
            
            FWNavigationBarStyle style = [styleNumber integerValue];
            if (style == FWNavigationBarStyleClear) {
                [selfObject.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
                [selfObject.navigationController.navigationBar setShadowImage:[UIImage new]];
            }
            
            FWNavigationBarAppearance *appearance = [FWNavigationBarAppearance appearanceForStyle:style];
            if (appearance.backgroundColor) {
                [selfObject.navigationController.navigationBar setBackgroundImage:[UIImage fwImageWithColor:appearance.backgroundColor] forBarMetrics:UIBarMetricsDefault];
                [selfObject.navigationController.navigationBar setShadowImage:[UIImage new]];
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

- (BOOL)fwStatusBarHidden
{
    return [objc_getAssociatedObject(self, @selector(fwStatusBarHidden)) boolValue];
}

- (void)setFwStatusBarHidden:(BOOL)fwStatusBarHidden
{
    if (fwStatusBarHidden != self.fwStatusBarHidden) {
        [self willChangeValueForKey:@"fwStatusBarHidden"];
        objc_setAssociatedObject(self, @selector(fwStatusBarHidden), @(fwStatusBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwStatusBarHidden"];
        
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (UIStatusBarStyle)fwStatusBarStyle
{
    return [objc_getAssociatedObject(self, @selector(fwStatusBarStyle)) integerValue];
}

- (void)setFwStatusBarStyle:(UIStatusBarStyle)fwStatusBarStyle
{
    if (fwStatusBarStyle != self.fwStatusBarStyle) {
        [self willChangeValueForKey:@"fwStatusBarStyle"];
        objc_setAssociatedObject(self, @selector(fwStatusBarStyle), @(fwStatusBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwStatusBarStyle"];
        
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BOOL)fwNavigationBarHidden
{
    return self.navigationController.navigationBarHidden;
}

- (void)setFwNavigationBarHidden:(BOOL)fwNavigationBarHidden
{
    self.navigationController.navigationBarHidden = fwNavigationBarHidden;
}

- (void)fwSetNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:hidden animated:animated];
}

- (FWNavigationBarStyle)fwNavigationBarStyle
{
    return [objc_getAssociatedObject(self, @selector(fwNavigationBarStyle)) integerValue];
}

- (void)setFwNavigationBarStyle:(FWNavigationBarStyle)fwNavigationBarStyle
{
    objc_setAssociatedObject(self, @selector(fwNavigationBarStyle), @(fwNavigationBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwTabBarHidden
{
    return self.tabBarController.tabBar.hidden;
}

- (void)setFwTabBarHidden:(BOOL)fwTabBarHidden
{
    self.tabBarController.tabBar.hidden = fwTabBarHidden;
}

- (BOOL)fwToolBarHidden
{
    return self.navigationController.toolbarHidden;
}

- (void)setFwToolBarHidden:(BOOL)fwToolBarHidden
{
    self.navigationController.toolbarHidden = fwToolBarHidden;
}

- (void)fwSetToolBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    [self.navigationController setToolbarHidden:hidden animated:animated];
}

- (void)fwSetBarExtendEdge:(UIRectEdge)edge
{
    self.edgesForExtendedLayout = edge;
    self.extendedLayoutIncludesOpaqueBars = YES;
}

#pragma mark - Item

- (void)fwSetBarTitle:(id)title
{
    if ([title isKindOfClass:[UIView class]]) {
        self.navigationItem.titleView = title;
    } else {
        self.navigationItem.title = title;
    }
}

- (void)fwSetLeftBarItem:(id)object target:(id)target action:(SEL)action
{
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
}

- (void)fwSetLeftBarItem:(id)object block:(void (^)(id sender))block
{
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:block];
}

- (void)fwSetRightBarItem:(id)object target:(id)target action:(SEL)action
{
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
}

- (void)fwSetRightBarItem:(id)object block:(void (^)(id sender))block
{
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:block];
}

#pragma mark - Back

- (void)fwSetBackBarTitle:(NSString *)title
{
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.backIndicatorImage = nil;
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = nil;
}

- (void)fwSetBackBarImage:(UIImage *)image
{
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
    if (!image) {
        self.navigationController.navigationBar.backIndicatorImage = nil;
        self.navigationController.navigationBar.backIndicatorTransitionMaskImage = nil;
        return;
    }
    
    // 左侧偏移8个像素，和左侧按钮位置一致
    UIEdgeInsets insets = UIEdgeInsetsMake(0, -8, 0, 0);
    CGSize size = image.size;
    size.width -= insets.left + insets.right;
    size.height -= insets.top + insets.bottom;
    CGRect rect = CGRectMake(-insets.left, -insets.top, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:rect];
    UIImage *indicatorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.navigationController.navigationBar.backIndicatorImage = indicatorImage;
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = indicatorImage;
}

- (void)fwSetBackBarClear
{
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
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
