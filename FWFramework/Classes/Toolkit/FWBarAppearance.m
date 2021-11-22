/*!
 @header     FWBarAppearance.m
 @indexgroup FWFramework
 @brief      FWBarAppearance
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWBarAppearance.h"
#import "FWTheme.h"
#import "FWToolkit.h"
#import <objc/runtime.h>

#pragma mark - UINavigationBar+FWBarAppearance

@implementation UINavigationBar (FWBarAppearance)

- (UINavigationBarAppearance *)fwAppearance
{
    UINavigationBarAppearance *appearance = objc_getAssociatedObject(self, _cmd);
    if (!appearance) {
        appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)fwUpdateAppearance
{
    self.standardAppearance = self.fwAppearance;
    self.compactAppearance = self.fwAppearance;
    self.scrollEdgeAppearance = self.fwAppearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.compactScrollEdgeAppearance = self.fwAppearance;
    }
#endif
}

- (BOOL)fwIsTranslucent
{
    return [objc_getAssociatedObject(self, @selector(fwIsTranslucent)) boolValue];
}

- (void)setFwIsTranslucent:(BOOL)translucent
{
    objc_setAssociatedObject(self, @selector(fwIsTranslucent), @(translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (translucent) {
            [self.fwAppearance configureWithDefaultBackground];
        } else {
            [self.fwAppearance configureWithTransparentBackground];
        }
        [self fwUpdateAppearance];
    } else {
        if (translucent) {
            [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        } else {
            self.barTintColor = nil;
        }
    }
}

- (UIColor *)fwForegroundColor
{
    return self.tintColor;
}

- (void)setFwForegroundColor:(UIColor *)color
{
    self.tintColor = color;
    [self fwUpdateTitleColor];
}

- (UIColor *)fwTitleColor
{
    return objc_getAssociatedObject(self, @selector(fwTitleColor));
}

- (void)setFwTitleColor:(UIColor *)fwTitleColor
{
    objc_setAssociatedObject(self, @selector(fwTitleColor), fwTitleColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwUpdateTitleColor];
}

- (void)fwUpdateTitleColor
{
    if (@available(iOS 15.0, *)) {
        UIColor *titleColor = self.fwTitleColor ?: self.tintColor;
        NSMutableDictionary *titleAttrs = self.fwAppearance.titleTextAttributes ? [self.fwAppearance.titleTextAttributes mutableCopy] : [NSMutableDictionary new];
        titleAttrs[NSForegroundColorAttributeName] = titleColor;
        self.fwAppearance.titleTextAttributes = [titleAttrs copy];
        
        NSMutableDictionary *largeTitleAttrs = self.fwAppearance.largeTitleTextAttributes ? [self.fwAppearance.largeTitleTextAttributes mutableCopy] : [NSMutableDictionary new];
        largeTitleAttrs[NSForegroundColorAttributeName] = titleColor;
        self.fwAppearance.largeTitleTextAttributes = [largeTitleAttrs copy];
        [self fwUpdateAppearance];
    } else {
        UIColor *titleColor = self.fwTitleColor ?: self.tintColor;
        NSMutableDictionary *titleAttrs = self.titleTextAttributes ? [self.titleTextAttributes mutableCopy] : [NSMutableDictionary new];
        titleAttrs[NSForegroundColorAttributeName] = titleColor;
        self.titleTextAttributes = [titleAttrs copy];
        
        NSMutableDictionary *largeTitleAttrs = self.largeTitleTextAttributes ? [self.largeTitleTextAttributes mutableCopy] : [NSMutableDictionary new];
        largeTitleAttrs[NSForegroundColorAttributeName] = titleColor;
        self.largeTitleTextAttributes = [largeTitleAttrs copy];
    }
}

- (UIColor *)fwBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundColor));
}

- (void)setFwBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (self.fwIsTranslucent) {
            self.fwAppearance.backgroundColor = color;
            self.fwAppearance.backgroundImage = nil;
        } else {
            UIImage *image = [UIImage fwImageWithColor:color] ?: [UIImage new];
            self.fwAppearance.backgroundColor = nil;
            self.fwAppearance.backgroundImage = image;
        }
        [self fwUpdateAppearance];
    } else {
        if (self.fwIsTranslucent) {
            self.barTintColor = color;
            [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        } else {
            self.barTintColor = nil;
            UIImage *image = [UIImage fwImageWithColor:color] ?: [UIImage new];
            [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        }
    }
}

- (UIImage *)fwBackgroundImage
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundImage));
}

- (void)setFwBackgroundImage:(UIImage *)backgroundImage
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), backgroundImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = backgroundImage.fwImage ?: [UIImage new];
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.backgroundColor = nil;
        self.fwAppearance.backgroundImage = image;
        [self fwUpdateAppearance];
    } else {
        self.barTintColor = nil;
        [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
}

- (BOOL)fwBackgroundTransparent
{
    return [objc_getAssociatedObject(self, @selector(fwBackgroundTransparent)) boolValue];
}

- (void)setFwBackgroundTransparent:(BOOL)transparent
{
    objc_setAssociatedObject(self, @selector(fwBackgroundTransparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = transparent ? [UIImage new] : nil;
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.backgroundColor = nil;
        self.fwAppearance.backgroundImage = image;
        [self fwUpdateAppearance];
    } else {
        self.barTintColor = nil;
        [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
}

- (UIColor *)fwShadowColor
{
    return objc_getAssociatedObject(self, @selector(fwShadowColor));
}

- (void)setFwShadowColor:(UIColor *)shadowColor
{
    objc_setAssociatedObject(self, @selector(fwShadowColor), shadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwShadowImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.shadowColor = shadowColor;
        self.fwAppearance.shadowImage = nil;
        [self fwUpdateAppearance];
    } else {
        self.shadowImage = [UIImage fwImageWithColor:shadowColor] ?: [UIImage new];
    }
}

- (UIImage *)fwShadowImage
{
    return objc_getAssociatedObject(self, @selector(fwShadowImage));
}

- (void)setFwShadowImage:(UIImage *)shadowImage
{
    objc_setAssociatedObject(self, @selector(fwShadowColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwShadowImage), shadowImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.shadowColor = nil;
        self.fwAppearance.shadowImage = shadowImage.fwImage;
        [self fwUpdateAppearance];
    } else {
        self.shadowImage = shadowImage.fwImage ?: [UIImage new];
    }
}

- (UIImage *)fwBackImage
{
    if (@available(iOS 15.0, *)) {
        return self.fwAppearance.backIndicatorImage;
    } else {
        return self.backIndicatorImage;
    }
}

- (void)setFwBackImage:(UIImage *)backImage
{
    UIImage *image = [backImage fwImageWithInsets:UIEdgeInsetsMake(0, -8, 0, 0) color:nil];
    if (@available(iOS 15.0, *)) {
        [self.fwAppearance setBackIndicatorImage:image transitionMaskImage:image];
        [self fwUpdateAppearance];
    } else {
        self.backIndicatorImage = image;
        self.backIndicatorTransitionMaskImage = image;
    }
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwBackgroundColor && self.fwBackgroundColor.fwIsThemeColor) {
        if (@available(iOS 15.0, *)) {
            if (self.fwIsTranslucent) {
                self.fwAppearance.backgroundColor = self.fwBackgroundColor.fwColor;
                self.fwAppearance.backgroundImage = nil;
            } else {
                UIImage *image = [UIImage fwImageWithColor:self.fwBackgroundColor.fwColor] ?: [UIImage new];
                self.fwAppearance.backgroundColor = nil;
                self.fwAppearance.backgroundImage = image;
            }
            [self fwUpdateAppearance];
        } else {
            if (self.fwIsTranslucent) {
                self.barTintColor = self.fwBackgroundColor.fwColor;
                [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            } else {
                UIImage *image = [UIImage fwImageWithColor:self.fwBackgroundColor.fwColor] ?: [UIImage new];
                self.barTintColor = nil;
                [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
            }
        }
    }
    
    if (self.fwBackgroundImage && self.fwBackgroundImage.fwIsThemeImage) {
        UIImage *image = self.fwBackgroundImage.fwImage ?: [UIImage new];
        if (@available(iOS 15.0, *)) {
            self.fwAppearance.backgroundColor = nil;
            self.fwAppearance.backgroundImage = image;
            [self fwUpdateAppearance];
        } else {
            self.barTintColor = nil;
            [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        }
    }
    
    if (self.fwShadowColor && self.fwShadowColor.fwIsThemeColor) {
        if (@available(iOS 15.0, *)) {
            self.fwAppearance.shadowColor = self.fwShadowColor.fwColor;
            self.fwAppearance.shadowImage = nil;
            [self fwUpdateAppearance];
        } else {
            self.shadowImage = [UIImage fwImageWithColor:self.fwShadowColor.fwColor] ?: [UIImage new];
        }
    }
    
    if (self.fwShadowImage && self.fwShadowImage.fwIsThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.fwAppearance.shadowColor = nil;
            self.fwAppearance.shadowImage = self.fwShadowImage.fwImage;
            [self fwUpdateAppearance];
        } else {
            self.shadowImage = self.fwShadowImage.fwImage ?: [UIImage new];
        }
    }
}

@end

#pragma mark - UITabBar+FWBarAppearance

@implementation UITabBar (FWBarAppearance)

- (UITabBarAppearance *)fwAppearance
{
    UITabBarAppearance *appearance = objc_getAssociatedObject(self, _cmd);
    if (!appearance) {
        appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)fwUpdateAppearance
{
    self.standardAppearance = self.fwAppearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.scrollEdgeAppearance = self.fwAppearance;
    }
#endif
}

- (BOOL)fwIsTranslucent
{
    return [objc_getAssociatedObject(self, @selector(fwIsTranslucent)) boolValue];
}

- (void)setFwIsTranslucent:(BOOL)translucent
{
    objc_setAssociatedObject(self, @selector(fwIsTranslucent), @(translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (translucent) {
            [self.fwAppearance configureWithDefaultBackground];
        } else {
            [self.fwAppearance configureWithTransparentBackground];
        }
        [self fwUpdateAppearance];
    } else {
        if (translucent) {
            self.backgroundImage = nil;
        } else {
            self.barTintColor = nil;
        }
    }
}

- (UIColor *)fwForegroundColor
{
    return self.tintColor;
}

- (void)setFwForegroundColor:(UIColor *)color
{
    self.tintColor = color;
}

- (UIColor *)fwBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundColor));
}

- (void)setFwBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (self.fwIsTranslucent) {
            self.fwAppearance.backgroundColor = color;
            self.fwAppearance.backgroundImage = nil;
        } else {
            self.fwAppearance.backgroundColor = nil;
            self.fwAppearance.backgroundImage = [UIImage fwImageWithColor:color];
        }
        [self fwUpdateAppearance];
    } else {
        if (self.fwIsTranslucent) {
            self.barTintColor = color;
            self.backgroundImage = nil;
        } else {
            self.barTintColor = nil;
            self.backgroundImage = [UIImage fwImageWithColor:color];
        }
    }
}

- (UIImage *)fwBackgroundImage
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundImage));
}

- (void)setFwBackgroundImage:(UIImage *)image
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.backgroundColor = nil;
        self.fwAppearance.backgroundImage = image.fwImage;
        [self fwUpdateAppearance];
    } else {
        self.barTintColor = nil;
        self.backgroundImage = image.fwImage;
    }
}

- (BOOL)fwBackgroundTransparent
{
    return [objc_getAssociatedObject(self, @selector(fwBackgroundTransparent)) boolValue];
}

- (void)setFwBackgroundTransparent:(BOOL)transparent
{
    objc_setAssociatedObject(self, @selector(fwBackgroundTransparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = transparent ? [UIImage new] : nil;
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.backgroundColor = nil;
        self.fwAppearance.backgroundImage = image;
        [self fwUpdateAppearance];
    } else {
        self.barTintColor = nil;
        self.backgroundImage = image;
    }
}

- (UIColor *)fwShadowColor
{
    return objc_getAssociatedObject(self, @selector(fwShadowColor));
}

- (void)setFwShadowColor:(UIColor *)shadowColor
{
    objc_setAssociatedObject(self, @selector(fwShadowColor), shadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwShadowImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.shadowColor = shadowColor;
        self.fwAppearance.shadowImage = nil;
        [self fwUpdateAppearance];
    } else {
        self.shadowImage = [UIImage fwImageWithColor:shadowColor] ?: [UIImage new];
    }
}

- (UIImage *)fwShadowImage
{
    return objc_getAssociatedObject(self, @selector(fwShadowImage));
}

- (void)setFwShadowImage:(UIImage *)image
{
    objc_setAssociatedObject(self, @selector(fwShadowColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwShadowImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.shadowColor = nil;
        self.fwAppearance.shadowImage = image.fwImage;
        [self fwUpdateAppearance];
    } else {
        self.shadowImage = image.fwImage ?: [UIImage new];
    }
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwBackgroundColor && self.fwBackgroundColor.fwIsThemeColor) {
        if (@available(iOS 15.0, *)) {
            if (self.fwIsTranslucent) {
                self.fwAppearance.backgroundColor = self.fwBackgroundColor.fwColor;
                self.fwAppearance.backgroundImage = nil;
            } else {
                self.fwAppearance.backgroundColor = nil;
                self.fwAppearance.backgroundImage = [UIImage fwImageWithColor:self.fwBackgroundColor.fwColor];
            }
            [self fwUpdateAppearance];
        } else {
            if (self.fwIsTranslucent) {
                self.barTintColor = self.fwBackgroundColor.fwColor;
                self.backgroundImage = nil;
            } else {
                self.barTintColor = nil;
                self.backgroundImage = [UIImage fwImageWithColor:self.fwBackgroundColor.fwColor];
            }
        }
    }
    
    if (self.fwBackgroundImage && self.fwBackgroundImage.fwIsThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.fwAppearance.backgroundColor = nil;
            self.fwAppearance.backgroundImage = self.fwBackgroundImage.fwImage;
            [self fwUpdateAppearance];
        } else {
            self.barTintColor = nil;
            self.backgroundImage = self.fwBackgroundImage.fwImage;
        }
    }
    
    if (self.fwShadowColor && self.fwShadowColor.fwIsThemeColor) {
        if (@available(iOS 15.0, *)) {
            self.fwAppearance.shadowColor = self.fwShadowColor.fwColor;
            self.fwAppearance.shadowImage = nil;
            [self fwUpdateAppearance];
        } else {
            self.shadowImage = [UIImage fwImageWithColor:self.fwShadowColor.fwColor] ?: [UIImage new];
        }
    }
    
    if (self.fwShadowImage && self.fwShadowImage.fwIsThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.fwAppearance.shadowColor = nil;
            self.fwAppearance.shadowImage = self.fwShadowImage.fwImage;
            [self fwUpdateAppearance];
        } else {
            self.shadowImage = self.fwShadowImage.fwImage ?: [UIImage new];
        }
    }
}

@end

#pragma mark - UIToolbar+FWBarAppearance

@interface FWToolbarDelegate : NSObject <UIToolbarDelegate>

@property (nonatomic, assign) UIBarPosition barPosition;

@end

@implementation FWToolbarDelegate

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return self.barPosition;
}

@end

@implementation UIToolbar (FWBarAppearance)

- (UIToolbarAppearance *)fwAppearance
{
    UIToolbarAppearance *appearance = objc_getAssociatedObject(self, _cmd);
    if (!appearance) {
        appearance = [[UIToolbarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)fwUpdateAppearance
{
    self.standardAppearance = self.fwAppearance;
    self.compactAppearance = self.fwAppearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.scrollEdgeAppearance = self.fwAppearance;
        self.compactScrollEdgeAppearance = self.fwAppearance;
    }
#endif
}

- (BOOL)fwIsTranslucent
{
    return [objc_getAssociatedObject(self, @selector(fwIsTranslucent)) boolValue];
}

- (void)setFwIsTranslucent:(BOOL)translucent
{
    objc_setAssociatedObject(self, @selector(fwIsTranslucent), @(translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (translucent) {
            [self.fwAppearance configureWithDefaultBackground];
        } else {
            [self.fwAppearance configureWithTransparentBackground];
        }
        [self fwUpdateAppearance];
    } else {
        if (translucent) {
            [self setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        } else {
            self.barTintColor = nil;
        }
    }
}

- (UIColor *)fwForegroundColor
{
    return self.tintColor;
}

- (void)setFwForegroundColor:(UIColor *)color
{
    self.tintColor = color;
}

- (UIColor *)fwBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundColor));
}

- (void)setFwBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (self.fwIsTranslucent) {
            self.fwAppearance.backgroundColor = color;
            self.fwAppearance.backgroundImage = nil;
        } else {
            self.fwAppearance.backgroundColor = nil;
            self.fwAppearance.backgroundImage = [UIImage fwImageWithColor:color];
        }
        [self fwUpdateAppearance];
    } else {
        if (self.fwIsTranslucent) {
            self.barTintColor = color;
            [self setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        } else {
            self.barTintColor = nil;
            [self setBackgroundImage:[UIImage fwImageWithColor:color] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        }
    }
}

- (UIImage *)fwBackgroundImage
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundImage));
}

- (void)setFwBackgroundImage:(UIImage *)image
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.backgroundColor = nil;
        self.fwAppearance.backgroundImage = image.fwImage;
        [self fwUpdateAppearance];
    } else {
        self.barTintColor = nil;
        [self setBackgroundImage:image.fwImage forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    }
}

- (BOOL)fwBackgroundTransparent
{
    return [objc_getAssociatedObject(self, @selector(fwBackgroundTransparent)) boolValue];
}

- (void)setFwBackgroundTransparent:(BOOL)transparent
{
    objc_setAssociatedObject(self, @selector(fwBackgroundTransparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = transparent ? [UIImage new] : nil;
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.backgroundColor = nil;
        self.fwAppearance.backgroundImage = image;
        [self fwUpdateAppearance];
    } else {
        self.barTintColor = nil;
        [self setBackgroundImage:image forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    }
}

- (UIColor *)fwShadowColor
{
    return objc_getAssociatedObject(self, @selector(fwShadowColor));
}

- (void)setFwShadowColor:(UIColor *)shadowColor
{
    objc_setAssociatedObject(self, @selector(fwShadowColor), shadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwShadowImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.shadowColor = shadowColor;
        self.fwAppearance.shadowImage = nil;
        [self fwUpdateAppearance];
    } else {
        [self setShadowImage:[UIImage fwImageWithColor:shadowColor] ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
    }
}

- (UIImage *)fwShadowImage
{
    return objc_getAssociatedObject(self, @selector(fwShadowImage));
}

- (void)setFwShadowImage:(UIImage *)shadowImage
{
    objc_setAssociatedObject(self, @selector(fwShadowColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwShadowImage), shadowImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.fwAppearance.shadowColor = nil;
        self.fwAppearance.shadowImage = shadowImage.fwImage;
        [self fwUpdateAppearance];
    } else {
        [self setShadowImage:shadowImage.fwImage ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
    }
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwBackgroundColor && self.fwBackgroundColor.fwIsThemeColor) {
        if (@available(iOS 15.0, *)) {
            if (self.fwIsTranslucent) {
                self.fwAppearance.backgroundColor = self.fwBackgroundColor.fwColor;
                self.fwAppearance.backgroundImage = nil;
            } else {
                self.fwAppearance.backgroundColor = nil;
                self.fwAppearance.backgroundImage = [UIImage fwImageWithColor:self.fwBackgroundColor.fwColor];
            }
            [self fwUpdateAppearance];
        } else {
            if (self.fwIsTranslucent) {
                self.barTintColor = self.fwBackgroundColor.fwColor;
                [self setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            } else {
                self.barTintColor = nil;
                [self setBackgroundImage:[UIImage fwImageWithColor:self.fwBackgroundColor.fwColor] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            }
        }
    }
    
    if (self.fwBackgroundImage && self.fwBackgroundImage.fwIsThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.fwAppearance.backgroundColor = nil;
            self.fwAppearance.backgroundImage = self.fwBackgroundImage.fwImage;
            [self fwUpdateAppearance];
        } else {
            self.barTintColor = nil;
            [self setBackgroundImage:self.fwBackgroundImage.fwImage forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        }
    }
    
    if (self.fwShadowColor && self.fwShadowColor.fwIsThemeColor) {
        if (@available(iOS 15.0, *)) {
            self.fwAppearance.shadowColor = self.fwShadowColor.fwColor;
            self.fwAppearance.shadowImage = nil;
            [self fwUpdateAppearance];
        } else {
            [self setShadowImage:[UIImage fwImageWithColor:self.fwShadowColor.fwColor] ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
        }
    }
    
    if (self.fwShadowImage && self.fwShadowImage.fwIsThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.fwAppearance.shadowColor = nil;
            self.fwAppearance.shadowImage = self.fwShadowImage.fwImage;
            [self fwUpdateAppearance];
        } else {
            [self setShadowImage:self.fwShadowImage.fwImage ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
        }
    }
}

- (UIBarPosition)fwBarPosition
{
    return [objc_getAssociatedObject(self, @selector(fwBarPosition)) integerValue];
}

- (void)setFwBarPosition:(UIBarPosition)fwBarPosition
{
    objc_setAssociatedObject(self, @selector(fwBarPosition), @(fwBarPosition), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.fwToolbarDelegate.barPosition = fwBarPosition;
}

- (FWToolbarDelegate *)fwToolbarDelegate
{
    FWToolbarDelegate *delegate = objc_getAssociatedObject(self, _cmd);
    if (!delegate) {
        delegate = [[FWToolbarDelegate alloc] init];
        self.delegate = delegate;
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

@end
