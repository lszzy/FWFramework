/**
 @header     FWBarAppearance.m
 @indexgroup FWFramework
      FWBarAppearance
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWBarAppearance.h"
#import "FWTheme.h"
#import "FWToolkit.h"
#import <objc/runtime.h>

#pragma mark - FWNavigationBarWrapper+FWBarAppearance

static NSDictionary<NSAttributedStringKey, id> *fwStaticNavigationBarButtonAttributes = nil;

@implementation FWNavigationBarClassWrapper (FWBarAppearance)

- (NSDictionary<NSAttributedStringKey,id> *)buttonAttributes
{
    return fwStaticNavigationBarButtonAttributes;
}

- (void)setButtonAttributes:(NSDictionary<NSAttributedStringKey,id> *)buttonAttributes
{
    fwStaticNavigationBarButtonAttributes = buttonAttributes;
    if (!fwStaticNavigationBarButtonAttributes) return;
    
    if (@available(iOS 15.0, *)) {} else {
        UIBarButtonItem *appearance = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObjects:UINavigationBar.class, nil]];
        NSArray<NSNumber *> *states = @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled), @(UIControlStateSelected), @(UIControlStateApplication), @(UIControlStateReserved)];
        for (NSNumber *state in states) {
            [appearance setTitleTextAttributes:buttonAttributes forState:[state unsignedIntegerValue]];
        }
    }
}

@end

@implementation FWNavigationBarWrapper (FWBarAppearance)

- (UINavigationBarAppearance *)appearance
{
    UINavigationBarAppearance *appearance = objc_getAssociatedObject(self.base, _cmd);
    if (!appearance) {
        appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self.base, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)updateAppearance
{
    [self updateButtonAttributes];
    
    self.base.standardAppearance = self.appearance;
    self.base.compactAppearance = self.appearance;
    self.base.scrollEdgeAppearance = self.appearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.base.compactScrollEdgeAppearance = self.appearance;
    }
#endif
}

- (void)updateButtonAttributes
{
    if (@available(iOS 15.0, *)) {
        if (!fwStaticNavigationBarButtonAttributes) return;
        
        NSArray<UIBarButtonItemAppearance *> *appearances = [NSArray arrayWithObjects:self.appearance.buttonAppearance, self.appearance.doneButtonAppearance, self.appearance.backButtonAppearance, nil];
        for (UIBarButtonItemAppearance *appearance in appearances) {
            appearance.normal.titleTextAttributes = fwStaticNavigationBarButtonAttributes;
            appearance.highlighted.titleTextAttributes = fwStaticNavigationBarButtonAttributes;
            appearance.disabled.titleTextAttributes = fwStaticNavigationBarButtonAttributes;
        }
    }
}

- (BOOL)isTranslucent
{
    return [objc_getAssociatedObject(self.base, @selector(isTranslucent)) boolValue];
}

- (void)setIsTranslucent:(BOOL)translucent
{
    objc_setAssociatedObject(self.base, @selector(isTranslucent), @(translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (translucent) {
            [self.appearance configureWithDefaultBackground];
        } else {
            [self.appearance configureWithTransparentBackground];
        }
        [self updateAppearance];
    } else {
        if (translucent) {
            [self.base setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        } else {
            self.base.barTintColor = nil;
        }
    }
}

- (UIColor *)foregroundColor
{
    return self.base.tintColor;
}

- (void)setForegroundColor:(UIColor *)color
{
    self.base.tintColor = color;
    [self updateTitleAttributes];
}

- (NSDictionary<NSAttributedStringKey,id> *)titleAttributes
{
    return objc_getAssociatedObject(self.base, @selector(titleAttributes));
}

- (void)setTitleAttributes:(NSDictionary<NSAttributedStringKey,id> *)titleAttributes
{
    objc_setAssociatedObject(self.base, @selector(titleAttributes), titleAttributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updateTitleAttributes];
}

- (void)updateTitleAttributes
{
    if (@available(iOS 15.0, *)) {
        NSMutableDictionary *titleAttrs = self.appearance.titleTextAttributes ? [self.appearance.titleTextAttributes mutableCopy] : [NSMutableDictionary new];
        titleAttrs[NSForegroundColorAttributeName] = self.base.tintColor;
        if (self.titleAttributes) [titleAttrs addEntriesFromDictionary:self.titleAttributes];
        self.appearance.titleTextAttributes = [titleAttrs copy];
        
        NSMutableDictionary *largeTitleAttrs = self.appearance.largeTitleTextAttributes ? [self.appearance.largeTitleTextAttributes mutableCopy] : [NSMutableDictionary new];
        largeTitleAttrs[NSForegroundColorAttributeName] = self.base.tintColor;
        if (self.titleAttributes) [largeTitleAttrs addEntriesFromDictionary:self.titleAttributes];
        self.appearance.largeTitleTextAttributes = [largeTitleAttrs copy];
        [self updateAppearance];
    } else {
        NSMutableDictionary *titleAttrs = self.base.titleTextAttributes ? [self.base.titleTextAttributes mutableCopy] : [NSMutableDictionary new];
        titleAttrs[NSForegroundColorAttributeName] = self.base.tintColor;
        if (self.titleAttributes) [titleAttrs addEntriesFromDictionary:self.titleAttributes];
        self.base.titleTextAttributes = [titleAttrs copy];
        
        NSMutableDictionary *largeTitleAttrs = self.base.largeTitleTextAttributes ? [self.base.largeTitleTextAttributes mutableCopy] : [NSMutableDictionary new];
        largeTitleAttrs[NSForegroundColorAttributeName] = self.base.tintColor;
        if (self.titleAttributes) [largeTitleAttrs addEntriesFromDictionary:self.titleAttributes];
        self.base.largeTitleTextAttributes = [largeTitleAttrs copy];
    }
}

- (UIColor *)backgroundColor
{
    return objc_getAssociatedObject(self.base, @selector(backgroundColor));
}

- (void)setBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self.base, @selector(backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (self.isTranslucent) {
            self.appearance.backgroundColor = color;
            self.appearance.backgroundImage = nil;
        } else {
            UIImage *image = [UIImage.fw imageWithColor:color] ?: [UIImage new];
            self.appearance.backgroundColor = nil;
            self.appearance.backgroundImage = image;
        }
        [self updateAppearance];
    } else {
        if (self.isTranslucent) {
            self.base.barTintColor = color;
            [self.base setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        } else {
            self.base.barTintColor = nil;
            UIImage *image = [UIImage.fw imageWithColor:color] ?: [UIImage new];
            [self.base setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        }
    }
}

- (UIImage *)backgroundImage
{
    return objc_getAssociatedObject(self.base, @selector(backgroundImage));
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    objc_setAssociatedObject(self.base, @selector(backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundImage), backgroundImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = backgroundImage.fw.image ?: [UIImage new];
    if (@available(iOS 15.0, *)) {
        self.appearance.backgroundColor = nil;
        self.appearance.backgroundImage = image;
        [self updateAppearance];
    } else {
        self.base.barTintColor = nil;
        [self.base setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
}

- (BOOL)backgroundTransparent
{
    return [objc_getAssociatedObject(self.base, @selector(backgroundTransparent)) boolValue];
}

- (void)setBackgroundTransparent:(BOOL)transparent
{
    objc_setAssociatedObject(self.base, @selector(backgroundTransparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = transparent ? [UIImage new] : nil;
    if (@available(iOS 15.0, *)) {
        self.appearance.backgroundColor = nil;
        self.appearance.backgroundImage = image;
        [self updateAppearance];
    } else {
        self.base.barTintColor = nil;
        [self.base setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
}

- (UIColor *)shadowColor
{
    return objc_getAssociatedObject(self.base, @selector(shadowColor));
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    objc_setAssociatedObject(self.base, @selector(shadowColor), shadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(shadowImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.appearance.shadowColor = shadowColor;
        self.appearance.shadowImage = nil;
        [self updateAppearance];
    } else {
        self.base.shadowImage = [UIImage.fw imageWithColor:shadowColor] ?: [UIImage new];
    }
}

- (UIImage *)shadowImage
{
    return objc_getAssociatedObject(self.base, @selector(shadowImage));
}

- (void)setShadowImage:(UIImage *)shadowImage
{
    objc_setAssociatedObject(self.base, @selector(shadowColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(shadowImage), shadowImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.appearance.shadowColor = nil;
        self.appearance.shadowImage = shadowImage.fw.image;
        [self updateAppearance];
    } else {
        self.base.shadowImage = shadowImage.fw.image ?: [UIImage new];
    }
}

- (UIImage *)backImage
{
    if (@available(iOS 15.0, *)) {
        return self.appearance.backIndicatorImage;
    } else {
        return self.base.backIndicatorImage;
    }
}

- (void)setBackImage:(UIImage *)backImage
{
    UIImage *image = [backImage.fw imageWithInsets:UIEdgeInsetsMake(0, -8, 0, 0) color:nil];
    if (@available(iOS 15.0, *)) {
        [self.appearance setBackIndicatorImage:image transitionMaskImage:image];
        [self updateAppearance];
    } else {
        self.base.backIndicatorImage = image;
        self.base.backIndicatorTransitionMaskImage = image;
    }
}

- (void)themeChanged:(FWThemeStyle)style
{
    [super themeChanged:style];
    
    if (self.backgroundColor && self.backgroundColor.fw.isThemeColor) {
        if (@available(iOS 15.0, *)) {
            if (self.isTranslucent) {
                self.appearance.backgroundColor = self.backgroundColor.fw.color;
                self.appearance.backgroundImage = nil;
            } else {
                UIImage *image = [UIImage.fw imageWithColor:self.backgroundColor.fw.color] ?: [UIImage new];
                self.appearance.backgroundColor = nil;
                self.appearance.backgroundImage = image;
            }
            [self updateAppearance];
        } else {
            if (self.isTranslucent) {
                self.base.barTintColor = self.backgroundColor.fw.color;
                [self.base setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            } else {
                UIImage *image = [UIImage.fw imageWithColor:self.backgroundColor.fw.color] ?: [UIImage new];
                self.base.barTintColor = nil;
                [self.base setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
            }
        }
    }
    
    if (self.backgroundImage && self.backgroundImage.fw.isThemeImage) {
        UIImage *image = self.backgroundImage.fw.image ?: [UIImage new];
        if (@available(iOS 15.0, *)) {
            self.appearance.backgroundColor = nil;
            self.appearance.backgroundImage = image;
            [self updateAppearance];
        } else {
            self.base.barTintColor = nil;
            [self.base setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        }
    }
    
    if (self.shadowColor && self.shadowColor.fw.isThemeColor) {
        if (@available(iOS 15.0, *)) {
            self.appearance.shadowColor = self.shadowColor.fw.color;
            self.appearance.shadowImage = nil;
            [self updateAppearance];
        } else {
            self.base.shadowImage = [UIImage.fw imageWithColor:self.shadowColor.fw.color] ?: [UIImage new];
        }
    }
    
    if (self.shadowImage && self.shadowImage.fw.isThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.appearance.shadowColor = nil;
            self.appearance.shadowImage = self.shadowImage.fw.image;
            [self updateAppearance];
        } else {
            self.base.shadowImage = self.shadowImage.fw.image ?: [UIImage new];
        }
    }
}

@end

#pragma mark - FWTabBarWrapper+FWBarAppearance

@implementation FWTabBarWrapper (FWBarAppearance)

- (UITabBarAppearance *)appearance
{
    UITabBarAppearance *appearance = objc_getAssociatedObject(self.base, _cmd);
    if (!appearance) {
        appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self.base, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)updateAppearance
{
    self.base.standardAppearance = self.appearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.base.scrollEdgeAppearance = self.appearance;
    }
#endif
}

- (BOOL)isTranslucent
{
    return [objc_getAssociatedObject(self.base, @selector(isTranslucent)) boolValue];
}

- (void)setIsTranslucent:(BOOL)translucent
{
    objc_setAssociatedObject(self.base, @selector(isTranslucent), @(translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (translucent) {
            [self.appearance configureWithDefaultBackground];
        } else {
            [self.appearance configureWithTransparentBackground];
        }
        [self updateAppearance];
    } else {
        if (translucent) {
            self.base.backgroundImage = nil;
        } else {
            self.base.barTintColor = nil;
        }
    }
}

- (UIColor *)foregroundColor
{
    return self.base.tintColor;
}

- (void)setForegroundColor:(UIColor *)color
{
    self.base.tintColor = color;
}

- (UIColor *)backgroundColor
{
    return objc_getAssociatedObject(self.base, @selector(backgroundColor));
}

- (void)setBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self.base, @selector(backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (self.isTranslucent) {
            self.appearance.backgroundColor = color;
            self.appearance.backgroundImage = nil;
        } else {
            self.appearance.backgroundColor = nil;
            self.appearance.backgroundImage = [UIImage.fw imageWithColor:color];
        }
        [self updateAppearance];
    } else {
        if (self.isTranslucent) {
            self.base.barTintColor = color;
            self.base.backgroundImage = nil;
        } else {
            self.base.barTintColor = nil;
            self.base.backgroundImage = [UIImage.fw imageWithColor:color];
        }
    }
}

- (UIImage *)backgroundImage
{
    return objc_getAssociatedObject(self.base, @selector(backgroundImage));
}

- (void)setBackgroundImage:(UIImage *)image
{
    objc_setAssociatedObject(self.base, @selector(backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.appearance.backgroundColor = nil;
        self.appearance.backgroundImage = image.fw.image;
        [self updateAppearance];
    } else {
        self.base.barTintColor = nil;
        self.base.backgroundImage = image.fw.image;
    }
}

- (BOOL)backgroundTransparent
{
    return [objc_getAssociatedObject(self.base, @selector(backgroundTransparent)) boolValue];
}

- (void)setBackgroundTransparent:(BOOL)transparent
{
    objc_setAssociatedObject(self.base, @selector(backgroundTransparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = transparent ? [UIImage new] : nil;
    if (@available(iOS 15.0, *)) {
        self.appearance.backgroundColor = nil;
        self.appearance.backgroundImage = image;
        [self updateAppearance];
    } else {
        self.base.barTintColor = nil;
        self.base.backgroundImage = image;
    }
}

- (UIColor *)shadowColor
{
    return objc_getAssociatedObject(self.base, @selector(shadowColor));
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    objc_setAssociatedObject(self.base, @selector(shadowColor), shadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(shadowImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.appearance.shadowColor = shadowColor;
        self.appearance.shadowImage = nil;
        [self updateAppearance];
    } else {
        self.base.shadowImage = [UIImage.fw imageWithColor:shadowColor] ?: [UIImage new];
    }
}

- (UIImage *)shadowImage
{
    return objc_getAssociatedObject(self.base, @selector(shadowImage));
}

- (void)setShadowImage:(UIImage *)image
{
    objc_setAssociatedObject(self.base, @selector(shadowColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(shadowImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.appearance.shadowColor = nil;
        self.appearance.shadowImage = image.fw.image;
        [self updateAppearance];
    } else {
        self.base.shadowImage = image.fw.image ?: [UIImage new];
    }
}

- (void)themeChanged:(FWThemeStyle)style
{
    [super themeChanged:style];
    
    if (self.backgroundColor && self.backgroundColor.fw.isThemeColor) {
        if (@available(iOS 15.0, *)) {
            if (self.isTranslucent) {
                self.appearance.backgroundColor = self.backgroundColor.fw.color;
                self.appearance.backgroundImage = nil;
            } else {
                self.appearance.backgroundColor = nil;
                self.appearance.backgroundImage = [UIImage.fw imageWithColor:self.backgroundColor.fw.color];
            }
            [self updateAppearance];
        } else {
            if (self.isTranslucent) {
                self.base.barTintColor = self.backgroundColor.fw.color;
                self.base.backgroundImage = nil;
            } else {
                self.base.barTintColor = nil;
                self.base.backgroundImage = [UIImage.fw imageWithColor:self.backgroundColor.fw.color];
            }
        }
    }
    
    if (self.backgroundImage && self.backgroundImage.fw.isThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.appearance.backgroundColor = nil;
            self.appearance.backgroundImage = self.backgroundImage.fw.image;
            [self updateAppearance];
        } else {
            self.base.barTintColor = nil;
            self.base.backgroundImage = self.backgroundImage.fw.image;
        }
    }
    
    if (self.shadowColor && self.shadowColor.fw.isThemeColor) {
        if (@available(iOS 15.0, *)) {
            self.appearance.shadowColor = self.shadowColor.fw.color;
            self.appearance.shadowImage = nil;
            [self updateAppearance];
        } else {
            self.base.shadowImage = [UIImage.fw imageWithColor:self.shadowColor.fw.color] ?: [UIImage new];
        }
    }
    
    if (self.shadowImage && self.shadowImage.fw.isThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.appearance.shadowColor = nil;
            self.appearance.shadowImage = self.shadowImage.fw.image;
            [self updateAppearance];
        } else {
            self.base.shadowImage = self.shadowImage.fw.image ?: [UIImage new];
        }
    }
}

@end

#pragma mark - FWToolbarWrapper+FWBarAppearance

@interface FWToolbarDelegate : NSObject <UIToolbarDelegate>

@property (nonatomic, assign) UIBarPosition barPosition;

@end

@implementation FWToolbarDelegate

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return self.barPosition;
}

@end

static NSDictionary<NSAttributedStringKey, id> *fwStaticToolbarButtonAttributes = nil;

@implementation FWToolbarClassWrapper (FWBarAppearance)

- (NSDictionary<NSAttributedStringKey,id> *)buttonAttributes
{
    return fwStaticToolbarButtonAttributes;
}

- (void)setButtonAttributes:(NSDictionary<NSAttributedStringKey,id> *)buttonAttributes
{
    fwStaticToolbarButtonAttributes = buttonAttributes;
    if (!fwStaticToolbarButtonAttributes) return;
    
    if (@available(iOS 15.0, *)) {} else {
        UIBarButtonItem *appearance = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObjects:UIToolbar.class, nil]];
        NSArray<NSNumber *> *states = @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled), @(UIControlStateSelected), @(UIControlStateApplication), @(UIControlStateReserved)];
        for (NSNumber *state in states) {
            [appearance setTitleTextAttributes:buttonAttributes forState:[state unsignedIntegerValue]];
        }
    }
}

@end

@implementation FWToolbarWrapper (FWBarAppearance)

- (UIToolbarAppearance *)appearance
{
    UIToolbarAppearance *appearance = objc_getAssociatedObject(self.base, _cmd);
    if (!appearance) {
        appearance = [[UIToolbarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self.base, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)updateAppearance
{
    [self updateButtonAttributes];
    
    self.base.standardAppearance = self.appearance;
    self.base.compactAppearance = self.appearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.base.scrollEdgeAppearance = self.appearance;
        self.base.compactScrollEdgeAppearance = self.appearance;
    }
#endif
}

- (void)updateButtonAttributes
{
    if (@available(iOS 15.0, *)) {
        if (!fwStaticToolbarButtonAttributes) return;
        
        NSArray<UIBarButtonItemAppearance *> *appearances = [NSArray arrayWithObjects:self.appearance.buttonAppearance, self.appearance.doneButtonAppearance, nil];
        for (UIBarButtonItemAppearance *appearance in appearances) {
            appearance.normal.titleTextAttributes = fwStaticToolbarButtonAttributes;
            appearance.highlighted.titleTextAttributes = fwStaticToolbarButtonAttributes;
            appearance.disabled.titleTextAttributes = fwStaticToolbarButtonAttributes;
        }
    }
}

- (BOOL)isTranslucent
{
    return [objc_getAssociatedObject(self.base, @selector(isTranslucent)) boolValue];
}

- (void)setIsTranslucent:(BOOL)translucent
{
    objc_setAssociatedObject(self.base, @selector(isTranslucent), @(translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (translucent) {
            [self.appearance configureWithDefaultBackground];
        } else {
            [self.appearance configureWithTransparentBackground];
        }
        [self updateAppearance];
    } else {
        if (translucent) {
            [self.base setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        } else {
            self.base.barTintColor = nil;
        }
    }
}

- (UIColor *)foregroundColor
{
    return self.base.tintColor;
}

- (void)setForegroundColor:(UIColor *)color
{
    self.base.tintColor = color;
    if (@available(iOS 15.0, *)) {
        [self updateAppearance];
    }
}

- (UIColor *)backgroundColor
{
    return objc_getAssociatedObject(self.base, @selector(backgroundColor));
}

- (void)setBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self.base, @selector(backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        if (self.isTranslucent) {
            self.appearance.backgroundColor = color;
            self.appearance.backgroundImage = nil;
        } else {
            self.appearance.backgroundColor = nil;
            self.appearance.backgroundImage = [UIImage.fw imageWithColor:color];
        }
        [self updateAppearance];
    } else {
        if (self.isTranslucent) {
            self.base.barTintColor = color;
            [self.base setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        } else {
            self.base.barTintColor = nil;
            [self.base setBackgroundImage:[UIImage.fw imageWithColor:color] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        }
    }
}

- (UIImage *)backgroundImage
{
    return objc_getAssociatedObject(self.base, @selector(backgroundImage));
}

- (void)setBackgroundImage:(UIImage *)image
{
    objc_setAssociatedObject(self.base, @selector(backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.appearance.backgroundColor = nil;
        self.appearance.backgroundImage = image.fw.image;
        [self updateAppearance];
    } else {
        self.base.barTintColor = nil;
        [self.base setBackgroundImage:image.fw.image forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    }
}

- (BOOL)backgroundTransparent
{
    return [objc_getAssociatedObject(self.base, @selector(backgroundTransparent)) boolValue];
}

- (void)setBackgroundTransparent:(BOOL)transparent
{
    objc_setAssociatedObject(self.base, @selector(backgroundTransparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = transparent ? [UIImage new] : nil;
    if (@available(iOS 15.0, *)) {
        self.appearance.backgroundColor = nil;
        self.appearance.backgroundImage = image;
        [self updateAppearance];
    } else {
        self.base.barTintColor = nil;
        [self.base setBackgroundImage:image forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    }
}

- (UIColor *)shadowColor
{
    return objc_getAssociatedObject(self.base, @selector(shadowColor));
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    objc_setAssociatedObject(self.base, @selector(shadowColor), shadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(shadowImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.appearance.shadowColor = shadowColor;
        self.appearance.shadowImage = nil;
        [self updateAppearance];
    } else {
        [self.base setShadowImage:[UIImage.fw imageWithColor:shadowColor] ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
    }
}

- (UIImage *)shadowImage
{
    return objc_getAssociatedObject(self.base, @selector(shadowImage));
}

- (void)setShadowImage:(UIImage *)shadowImage
{
    objc_setAssociatedObject(self.base, @selector(shadowColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(shadowImage), shadowImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        self.appearance.shadowColor = nil;
        self.appearance.shadowImage = shadowImage.fw.image;
        [self updateAppearance];
    } else {
        [self.base setShadowImage:shadowImage.fw.image ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
    }
}

- (void)themeChanged:(FWThemeStyle)style
{
    [super themeChanged:style];
    
    if (self.backgroundColor && self.backgroundColor.fw.isThemeColor) {
        if (@available(iOS 15.0, *)) {
            if (self.isTranslucent) {
                self.appearance.backgroundColor = self.backgroundColor.fw.color;
                self.appearance.backgroundImage = nil;
            } else {
                self.appearance.backgroundColor = nil;
                self.appearance.backgroundImage = [UIImage.fw imageWithColor:self.backgroundColor.fw.color];
            }
            [self updateAppearance];
        } else {
            if (self.isTranslucent) {
                self.base.barTintColor = self.backgroundColor.fw.color;
                [self.base setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            } else {
                self.base.barTintColor = nil;
                [self.base setBackgroundImage:[UIImage.fw imageWithColor:self.backgroundColor.fw.color] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            }
        }
    }
    
    if (self.backgroundImage && self.backgroundImage.fw.isThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.appearance.backgroundColor = nil;
            self.appearance.backgroundImage = self.backgroundImage.fw.image;
            [self updateAppearance];
        } else {
            self.base.barTintColor = nil;
            [self.base setBackgroundImage:self.backgroundImage.fw.image forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        }
    }
    
    if (self.shadowColor && self.shadowColor.fw.isThemeColor) {
        if (@available(iOS 15.0, *)) {
            self.appearance.shadowColor = self.shadowColor.fw.color;
            self.appearance.shadowImage = nil;
            [self updateAppearance];
        } else {
            [self.base setShadowImage:[UIImage.fw imageWithColor:self.shadowColor.fw.color] ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
        }
    }
    
    if (self.shadowImage && self.shadowImage.fw.isThemeImage) {
        if (@available(iOS 15.0, *)) {
            self.appearance.shadowColor = nil;
            self.appearance.shadowImage = self.shadowImage.fw.image;
            [self updateAppearance];
        } else {
            [self.base setShadowImage:self.shadowImage.fw.image ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
        }
    }
}

- (UIBarPosition)barPosition
{
    return [objc_getAssociatedObject(self.base, @selector(barPosition)) integerValue];
}

- (void)setBarPosition:(UIBarPosition)barPosition
{
    objc_setAssociatedObject(self.base, @selector(barPosition), @(barPosition), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.toolbarDelegate.barPosition = barPosition;
}

- (FWToolbarDelegate *)toolbarDelegate
{
    FWToolbarDelegate *delegate = objc_getAssociatedObject(self.base, _cmd);
    if (!delegate) {
        delegate = [[FWToolbarDelegate alloc] init];
        self.base.delegate = delegate;
        objc_setAssociatedObject(self.base, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

@end
