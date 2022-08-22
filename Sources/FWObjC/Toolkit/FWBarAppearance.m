//
//  FWBarAppearance.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWBarAppearance.h"
#import "FWTheme.h"
#import "FWToolkit.h"
#import <objc/runtime.h>

#pragma mark - UINavigationBar+FWBarAppearance

static NSDictionary<NSAttributedStringKey, id> *fwStaticButtonAttributes = nil;
static BOOL fwStaticAppearanceEnabled = NO;

@implementation UINavigationBar (FWBarAppearance)

+ (BOOL)fw_appearanceEnabled
{
    if (@available(iOS 15.0, *)) {
        return YES;
    } else if (@available(iOS 13.0, *)) {
        return fwStaticAppearanceEnabled;
    }
    return NO;
}

+ (void)setFw_appearanceEnabled:(BOOL)appearanceEnabled
{
    fwStaticAppearanceEnabled = appearanceEnabled;
}

+ (NSDictionary<NSAttributedStringKey,id> *)fw_buttonAttributes
{
    return fwStaticButtonAttributes;
}

+ (void)setFw_buttonAttributes:(NSDictionary<NSAttributedStringKey,id> *)buttonAttributes
{
    fwStaticButtonAttributes = buttonAttributes;
    if (!fwStaticButtonAttributes) return;
    
    if (!UINavigationBar.fw_appearanceEnabled) {
        UIBarButtonItem *appearance = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObjects:UINavigationBar.class, nil]];
        NSArray<NSNumber *> *states = @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled), @(UIControlStateSelected), @(UIControlStateApplication), @(UIControlStateReserved)];
        for (NSNumber *state in states) {
            NSMutableDictionary *attributes = [[appearance titleTextAttributesForState:[state unsignedIntegerValue]] mutableCopy] ?: [NSMutableDictionary new];
            [attributes addEntriesFromDictionary:buttonAttributes];
            [appearance setTitleTextAttributes:attributes forState:[state unsignedIntegerValue]];
        }
    }
}

- (UINavigationBarAppearance *)fw_appearance
{
    UINavigationBarAppearance *appearance = objc_getAssociatedObject(self, _cmd);
    if (!appearance) {
        appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)fw_updateAppearance
{
    self.standardAppearance = self.fw_appearance;
    self.compactAppearance = self.fw_appearance;
    self.scrollEdgeAppearance = self.fw_appearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.compactScrollEdgeAppearance = self.fw_appearance;
    }
#endif
}

- (BOOL)fw_isTranslucent
{
    return [objc_getAssociatedObject(self, @selector(fw_isTranslucent)) boolValue];
}

- (void)setFw_isTranslucent:(BOOL)translucent
{
    objc_setAssociatedObject(self, @selector(fw_isTranslucent), @(translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        if (translucent) {
            [self.fw_appearance configureWithDefaultBackground];
        } else {
            [self.fw_appearance configureWithTransparentBackground];
        }
        [self fw_updateAppearance];
    }} else {
        if (translucent) {
            [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        } else {
            self.barTintColor = nil;
        }
    }
}

- (UIColor *)fw_foregroundColor
{
    return self.tintColor;
}

- (void)setFw_foregroundColor:(UIColor *)color
{
    self.tintColor = color;
    [self fw_updateTitleAttributes];
    [self fw_updateButtonAttributes];
}

- (NSDictionary<NSAttributedStringKey,id> *)fw_titleAttributes
{
    return objc_getAssociatedObject(self, @selector(fw_titleAttributes));
}

- (void)setFw_titleAttributes:(NSDictionary<NSAttributedStringKey,id> *)titleAttributes
{
    objc_setAssociatedObject(self, @selector(fw_titleAttributes), titleAttributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_updateTitleAttributes];
}

- (NSDictionary<NSAttributedStringKey,id> *)fw_buttonAttributes
{
    return objc_getAssociatedObject(self, @selector(fw_buttonAttributes));
}

- (void)setFw_buttonAttributes:(NSDictionary<NSAttributedStringKey,id> *)buttonAttributes
{
    objc_setAssociatedObject(self, @selector(fw_buttonAttributes), buttonAttributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_updateButtonAttributes];
}

- (void)fw_updateTitleAttributes
{
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        NSMutableDictionary *attributes = self.fw_appearance.titleTextAttributes.mutableCopy ?: [NSMutableDictionary new];
        attributes[NSForegroundColorAttributeName] = self.tintColor;
        if (self.fw_titleAttributes) [attributes addEntriesFromDictionary:self.fw_titleAttributes];
        self.fw_appearance.titleTextAttributes = [attributes copy];
        
        NSMutableDictionary *largeAttributes = self.fw_appearance.largeTitleTextAttributes.mutableCopy ?: [NSMutableDictionary new];
        largeAttributes[NSForegroundColorAttributeName] = self.tintColor;
        if (self.fw_titleAttributes) [largeAttributes addEntriesFromDictionary:self.fw_titleAttributes];
        self.fw_appearance.largeTitleTextAttributes = [largeAttributes copy];
        [self fw_updateAppearance];
    }} else {
        NSMutableDictionary *attributes = self.titleTextAttributes.mutableCopy ?: [NSMutableDictionary new];
        attributes[NSForegroundColorAttributeName] = self.tintColor;
        if (self.fw_titleAttributes) [attributes addEntriesFromDictionary:self.fw_titleAttributes];
        self.titleTextAttributes = [attributes copy];
        
        NSMutableDictionary *largeAttributes = self.largeTitleTextAttributes.mutableCopy ?: [NSMutableDictionary new];
        largeAttributes[NSForegroundColorAttributeName] = self.tintColor;
        if (self.fw_titleAttributes) [largeAttributes addEntriesFromDictionary:self.fw_titleAttributes];
        self.largeTitleTextAttributes = [largeAttributes copy];
    }
}

- (void)fw_updateButtonAttributes
{
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        NSDictionary *buttonAttributes = self.fw_buttonAttributes ?: fwStaticButtonAttributes;
        if (!buttonAttributes) return;
        
        NSArray<UIBarButtonItemAppearance *> *appearances = [NSArray arrayWithObjects:self.fw_appearance.buttonAppearance, self.fw_appearance.doneButtonAppearance, self.fw_appearance.backButtonAppearance, nil];
        for (UIBarButtonItemAppearance *appearance in appearances) {
            NSArray<UIBarButtonItemStateAppearance *> *stateAppearances = [NSArray arrayWithObjects:appearance.normal, appearance.highlighted, appearance.disabled, nil];
            for (UIBarButtonItemStateAppearance *stateAppearance in stateAppearances) {
                NSMutableDictionary *attributes = [stateAppearance.titleTextAttributes mutableCopy] ?: [NSMutableDictionary new];
                [attributes addEntriesFromDictionary:buttonAttributes];
                stateAppearance.titleTextAttributes = [attributes copy];
            }
        }
        [self fw_updateAppearance];
    }}
}

- (UIColor *)fw_backgroundColor
{
    return objc_getAssociatedObject(self, @selector(fw_backgroundColor));
}

- (void)setFw_backgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fw_backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        if (self.fw_isTranslucent) {
            self.fw_appearance.backgroundColor = color;
            self.fw_appearance.backgroundImage = nil;
        } else {
            UIImage *image = [UIImage fw_imageWithColor:color] ?: [UIImage new];
            self.fw_appearance.backgroundColor = nil;
            self.fw_appearance.backgroundImage = image;
        }
        [self fw_updateAppearance];
    }} else {
        if (self.fw_isTranslucent) {
            self.barTintColor = color;
            [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        } else {
            self.barTintColor = nil;
            UIImage *image = [UIImage fw_imageWithColor:color] ?: [UIImage new];
            [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        }
    }
}

- (UIImage *)fw_backgroundImage
{
    return objc_getAssociatedObject(self, @selector(fw_backgroundImage));
}

- (void)setFw_backgroundImage:(UIImage *)backgroundImage
{
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundImage), backgroundImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = backgroundImage.fw_image ?: [UIImage new];
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.backgroundColor = nil;
        self.fw_appearance.backgroundImage = image;
        [self fw_updateAppearance];
    }} else {
        self.barTintColor = nil;
        [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
}

- (BOOL)fw_backgroundTransparent
{
    return [objc_getAssociatedObject(self, @selector(fw_backgroundTransparent)) boolValue];
}

- (void)setFw_backgroundTransparent:(BOOL)transparent
{
    objc_setAssociatedObject(self, @selector(fw_backgroundTransparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = transparent ? [UIImage new] : nil;
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.backgroundColor = nil;
        self.fw_appearance.backgroundImage = image;
        [self fw_updateAppearance];
    }} else {
        self.barTintColor = nil;
        [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
}

- (UIColor *)fw_shadowColor
{
    return objc_getAssociatedObject(self, @selector(fw_shadowColor));
}

- (void)setFw_shadowColor:(UIColor *)shadowColor
{
    objc_setAssociatedObject(self, @selector(fw_shadowColor), shadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_shadowImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.shadowColor = shadowColor;
        self.fw_appearance.shadowImage = nil;
        [self fw_updateAppearance];
    }} else {
        self.shadowImage = [UIImage fw_imageWithColor:shadowColor] ?: [UIImage new];
    }
}

- (UIImage *)fw_shadowImage
{
    return objc_getAssociatedObject(self, @selector(fw_shadowImage));
}

- (void)setFw_shadowImage:(UIImage *)shadowImage
{
    objc_setAssociatedObject(self, @selector(fw_shadowColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_shadowImage), shadowImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.shadowColor = nil;
        self.fw_appearance.shadowImage = shadowImage.fw_image;
        [self fw_updateAppearance];
    }} else {
        self.shadowImage = shadowImage.fw_image ?: [UIImage new];
    }
}

- (UIImage *)fw_backImage
{
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        return self.fw_appearance.backIndicatorImage;
    }}
    return self.backIndicatorImage;
}

- (void)setFw_backImage:(UIImage *)backImage
{
    UIImage *image = [backImage fw_imageWithInsets:UIEdgeInsetsMake(0, -8, 0, 0) color:nil];
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        [self.fw_appearance setBackIndicatorImage:image transitionMaskImage:image];
        [self fw_updateAppearance];
    }} else {
        self.backIndicatorImage = image;
        self.backIndicatorTransitionMaskImage = image;
    }
}

- (void)fw_themeChanged:(FWThemeStyle)style
{
    [super fw_themeChanged:style];
    
    if (self.fw_backgroundColor && self.fw_backgroundColor.fw_isThemeColor) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            if (self.fw_isTranslucent) {
                self.fw_appearance.backgroundColor = self.fw_backgroundColor.fw_color;
                self.fw_appearance.backgroundImage = nil;
            } else {
                UIImage *image = [UIImage fw_imageWithColor:self.fw_backgroundColor.fw_color] ?: [UIImage new];
                self.fw_appearance.backgroundColor = nil;
                self.fw_appearance.backgroundImage = image;
            }
            [self fw_updateAppearance];
        }} else {
            if (self.fw_isTranslucent) {
                self.barTintColor = self.fw_backgroundColor.fw_color;
                [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            } else {
                UIImage *image = [UIImage fw_imageWithColor:self.fw_backgroundColor.fw_color] ?: [UIImage new];
                self.barTintColor = nil;
                [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
            }
        }
    }
    
    if (self.fw_backgroundImage && self.fw_backgroundImage.fw_isThemeImage) {
        UIImage *image = self.fw_backgroundImage.fw_image ?: [UIImage new];
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fw_appearance.backgroundColor = nil;
            self.fw_appearance.backgroundImage = image;
            [self fw_updateAppearance];
        }} else {
            self.barTintColor = nil;
            [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        }
    }
    
    if (self.fw_shadowColor && self.fw_shadowColor.fw_isThemeColor) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fw_appearance.shadowColor = self.fw_shadowColor.fw_color;
            self.fw_appearance.shadowImage = nil;
            [self fw_updateAppearance];
        }} else {
            self.shadowImage = [UIImage fw_imageWithColor:self.fw_shadowColor.fw_color] ?: [UIImage new];
        }
    }
    
    if (self.fw_shadowImage && self.fw_shadowImage.fw_isThemeImage) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fw_appearance.shadowColor = nil;
            self.fw_appearance.shadowImage = self.fw_shadowImage.fw_image;
            [self fw_updateAppearance];
        }} else {
            self.shadowImage = self.fw_shadowImage.fw_image ?: [UIImage new];
        }
    }
}

@end

#pragma mark - UITabBar+FWBarAppearance

@implementation UITabBar (FWBarAppearance)

- (UITabBarAppearance *)fw_appearance
{
    UITabBarAppearance *appearance = objc_getAssociatedObject(self, _cmd);
    if (!appearance) {
        appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)fw_updateAppearance
{
    self.standardAppearance = self.fw_appearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.scrollEdgeAppearance = self.fw_appearance;
    }
#endif
}

- (BOOL)fw_isTranslucent
{
    return [objc_getAssociatedObject(self, @selector(fw_isTranslucent)) boolValue];
}

- (void)setFw_isTranslucent:(BOOL)translucent
{
    objc_setAssociatedObject(self, @selector(fw_isTranslucent), @(translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        if (translucent) {
            [self.fw_appearance configureWithDefaultBackground];
        } else {
            [self.fw_appearance configureWithTransparentBackground];
        }
        [self fw_updateAppearance];
    }} else {
        if (translucent) {
            self.backgroundImage = nil;
        } else {
            self.barTintColor = nil;
        }
    }
}

- (UIColor *)fw_foregroundColor
{
    return self.tintColor;
}

- (void)setFw_foregroundColor:(UIColor *)color
{
    self.tintColor = color;
}

- (UIColor *)fw_backgroundColor
{
    return objc_getAssociatedObject(self, @selector(fw_backgroundColor));
}

- (void)setFw_backgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fw_backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        if (self.fw_isTranslucent) {
            self.fw_appearance.backgroundColor = color;
            self.fw_appearance.backgroundImage = nil;
        } else {
            self.fw_appearance.backgroundColor = nil;
            self.fw_appearance.backgroundImage = [UIImage fw_imageWithColor:color];
        }
        [self fw_updateAppearance];
    }} else {
        if (self.fw_isTranslucent) {
            self.barTintColor = color;
            self.backgroundImage = nil;
        } else {
            self.barTintColor = nil;
            self.backgroundImage = [UIImage fw_imageWithColor:color];
        }
    }
}

- (UIImage *)fw_backgroundImage
{
    return objc_getAssociatedObject(self, @selector(fw_backgroundImage));
}

- (void)setFw_backgroundImage:(UIImage *)image
{
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.backgroundColor = nil;
        self.fw_appearance.backgroundImage = image.fw_image;
        [self fw_updateAppearance];
    }} else {
        self.barTintColor = nil;
        self.backgroundImage = image.fw_image;
    }
}

- (BOOL)fw_backgroundTransparent
{
    return [objc_getAssociatedObject(self, @selector(fw_backgroundTransparent)) boolValue];
}

- (void)setFw_backgroundTransparent:(BOOL)transparent
{
    objc_setAssociatedObject(self, @selector(fw_backgroundTransparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = transparent ? [UIImage new] : nil;
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.backgroundColor = nil;
        self.fw_appearance.backgroundImage = image;
        [self fw_updateAppearance];
    }} else {
        self.barTintColor = nil;
        self.backgroundImage = image;
    }
}

- (UIColor *)fw_shadowColor
{
    return objc_getAssociatedObject(self, @selector(fw_shadowColor));
}

- (void)setFw_shadowColor:(UIColor *)shadowColor
{
    objc_setAssociatedObject(self, @selector(fw_shadowColor), shadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_shadowImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.shadowColor = shadowColor;
        self.fw_appearance.shadowImage = nil;
        [self fw_updateAppearance];
    }} else {
        self.shadowImage = [UIImage fw_imageWithColor:shadowColor] ?: [UIImage new];
    }
}

- (UIImage *)fw_shadowImage
{
    return objc_getAssociatedObject(self, @selector(fw_shadowImage));
}

- (void)setFw_shadowImage:(UIImage *)image
{
    objc_setAssociatedObject(self, @selector(fw_shadowColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_shadowImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.shadowColor = nil;
        self.fw_appearance.shadowImage = image.fw_image;
        [self fw_updateAppearance];
    }} else {
        self.shadowImage = image.fw_image ?: [UIImage new];
    }
}

- (void)fw_themeChanged:(FWThemeStyle)style
{
    [super fw_themeChanged:style];
    
    if (self.fw_backgroundColor && self.fw_backgroundColor.fw_isThemeColor) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            if (self.fw_isTranslucent) {
                self.fw_appearance.backgroundColor = self.fw_backgroundColor.fw_color;
                self.fw_appearance.backgroundImage = nil;
            } else {
                self.fw_appearance.backgroundColor = nil;
                self.fw_appearance.backgroundImage = [UIImage fw_imageWithColor:self.fw_backgroundColor.fw_color];
            }
            [self fw_updateAppearance];
        }} else {
            if (self.fw_isTranslucent) {
                self.barTintColor = self.fw_backgroundColor.fw_color;
                self.backgroundImage = nil;
            } else {
                self.barTintColor = nil;
                self.backgroundImage = [UIImage fw_imageWithColor:self.fw_backgroundColor.fw_color];
            }
        }
    }
    
    if (self.fw_backgroundImage && self.fw_backgroundImage.fw_isThemeImage) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fw_appearance.backgroundColor = nil;
            self.fw_appearance.backgroundImage = self.fw_backgroundImage.fw_image;
            [self fw_updateAppearance];
        }} else {
            self.barTintColor = nil;
            self.backgroundImage = self.fw_backgroundImage.fw_image;
        }
    }
    
    if (self.fw_shadowColor && self.fw_shadowColor.fw_isThemeColor) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fw_appearance.shadowColor = self.fw_shadowColor.fw_color;
            self.fw_appearance.shadowImage = nil;
            [self fw_updateAppearance];
        }} else {
            self.shadowImage = [UIImage fw_imageWithColor:self.fw_shadowColor.fw_color] ?: [UIImage new];
        }
    }
    
    if (self.fw_shadowImage && self.fw_shadowImage.fw_isThemeImage) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fw_appearance.shadowColor = nil;
            self.fw_appearance.shadowImage = self.fw_shadowImage.fw_image;
            [self fw_updateAppearance];
        }} else {
            self.shadowImage = self.fw_shadowImage.fw_image ?: [UIImage new];
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

- (UIToolbarAppearance *)fw_appearance
{
    UIToolbarAppearance *appearance = objc_getAssociatedObject(self, _cmd);
    if (!appearance) {
        appearance = [[UIToolbarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)fw_updateAppearance
{
    self.standardAppearance = self.fw_appearance;
    self.compactAppearance = self.fw_appearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.scrollEdgeAppearance = self.fw_appearance;
        self.compactScrollEdgeAppearance = self.fw_appearance;
    }
#endif
}

- (BOOL)fw_isTranslucent
{
    return [objc_getAssociatedObject(self, @selector(fw_isTranslucent)) boolValue];
}

- (void)setFw_isTranslucent:(BOOL)translucent
{
    objc_setAssociatedObject(self, @selector(fw_isTranslucent), @(translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        if (translucent) {
            [self.fw_appearance configureWithDefaultBackground];
        } else {
            [self.fw_appearance configureWithTransparentBackground];
        }
        [self fw_updateAppearance];
    }} else {
        if (translucent) {
            [self setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        } else {
            self.barTintColor = nil;
        }
    }
}

- (UIColor *)fw_foregroundColor
{
    return self.tintColor;
}

- (void)setFw_foregroundColor:(UIColor *)color
{
    self.tintColor = color;
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        [self fw_updateAppearance];
    }}
}

- (NSDictionary<NSAttributedStringKey,id> *)fw_buttonAttributes
{
    return objc_getAssociatedObject(self, @selector(fw_buttonAttributes));
}

- (void)setFw_buttonAttributes:(NSDictionary<NSAttributedStringKey,id> *)buttonAttributes
{
    objc_setAssociatedObject(self, @selector(fw_buttonAttributes), buttonAttributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_updateButtonAttributes];
}

- (void)fw_updateButtonAttributes
{
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        NSDictionary *buttonAttributes = self.fw_buttonAttributes;
        if (!buttonAttributes) return;
        
        NSArray<UIBarButtonItemAppearance *> *appearances = [NSArray arrayWithObjects:self.fw_appearance.buttonAppearance, self.fw_appearance.doneButtonAppearance, nil];
        for (UIBarButtonItemAppearance *appearance in appearances) {
            NSArray<UIBarButtonItemStateAppearance *> *stateAppearances = [NSArray arrayWithObjects:appearance.normal, appearance.highlighted, appearance.disabled, nil];
            for (UIBarButtonItemStateAppearance *stateAppearance in stateAppearances) {
                NSMutableDictionary *attributes = [stateAppearance.titleTextAttributes mutableCopy] ?: [NSMutableDictionary new];
                [attributes addEntriesFromDictionary:buttonAttributes];
                stateAppearance.titleTextAttributes = [attributes copy];
            }
        }
        [self fw_updateAppearance];
    }}
}

- (UIColor *)fw_backgroundColor
{
    return objc_getAssociatedObject(self, @selector(fw_backgroundColor));
}

- (void)setFw_backgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fw_backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        if (self.fw_isTranslucent) {
            self.fw_appearance.backgroundColor = color;
            self.fw_appearance.backgroundImage = nil;
        } else {
            self.fw_appearance.backgroundColor = nil;
            self.fw_appearance.backgroundImage = [UIImage fw_imageWithColor:color];
        }
        [self fw_updateAppearance];
    }} else {
        if (self.fw_isTranslucent) {
            self.barTintColor = color;
            [self setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        } else {
            self.barTintColor = nil;
            [self setBackgroundImage:[UIImage fw_imageWithColor:color] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        }
    }
}

- (UIImage *)fw_backgroundImage
{
    return objc_getAssociatedObject(self, @selector(fw_backgroundImage));
}

- (void)setFw_backgroundImage:(UIImage *)image
{
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.backgroundColor = nil;
        self.fw_appearance.backgroundImage = image.fw_image;
        [self fw_updateAppearance];
    }} else {
        self.barTintColor = nil;
        [self setBackgroundImage:image.fw_image forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    }
}

- (BOOL)fw_backgroundTransparent
{
    return [objc_getAssociatedObject(self, @selector(fw_backgroundTransparent)) boolValue];
}

- (void)setFw_backgroundTransparent:(BOOL)transparent
{
    objc_setAssociatedObject(self, @selector(fw_backgroundTransparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_backgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = transparent ? [UIImage new] : nil;
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.backgroundColor = nil;
        self.fw_appearance.backgroundImage = image;
        [self fw_updateAppearance];
    }} else {
        self.barTintColor = nil;
        [self setBackgroundImage:image forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    }
}

- (UIColor *)fw_shadowColor
{
    return objc_getAssociatedObject(self, @selector(fw_shadowColor));
}

- (void)setFw_shadowColor:(UIColor *)shadowColor
{
    objc_setAssociatedObject(self, @selector(fw_shadowColor), shadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_shadowImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.shadowColor = shadowColor;
        self.fw_appearance.shadowImage = nil;
        [self fw_updateAppearance];
    }} else {
        [self setShadowImage:[UIImage fw_imageWithColor:shadowColor] ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
    }
}

- (UIImage *)fw_shadowImage
{
    return objc_getAssociatedObject(self, @selector(fw_shadowImage));
}

- (void)setFw_shadowImage:(UIImage *)shadowImage
{
    objc_setAssociatedObject(self, @selector(fw_shadowColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_shadowImage), shadowImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fw_appearance.shadowColor = nil;
        self.fw_appearance.shadowImage = shadowImage.fw_image;
        [self fw_updateAppearance];
    }} else {
        [self setShadowImage:shadowImage.fw_image ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
    }
}

- (void)fw_themeChanged:(FWThemeStyle)style
{
    [super fw_themeChanged:style];
    
    if (self.fw_backgroundColor && self.fw_backgroundColor.fw_isThemeColor) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            if (self.fw_isTranslucent) {
                self.fw_appearance.backgroundColor = self.fw_backgroundColor.fw_color;
                self.fw_appearance.backgroundImage = nil;
            } else {
                self.fw_appearance.backgroundColor = nil;
                self.fw_appearance.backgroundImage = [UIImage fw_imageWithColor:self.fw_backgroundColor.fw_color];
            }
            [self fw_updateAppearance];
        }} else {
            if (self.fw_isTranslucent) {
                self.barTintColor = self.fw_backgroundColor.fw_color;
                [self setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            } else {
                self.barTintColor = nil;
                [self setBackgroundImage:[UIImage fw_imageWithColor:self.fw_backgroundColor.fw_color] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            }
        }
    }
    
    if (self.fw_backgroundImage && self.fw_backgroundImage.fw_isThemeImage) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fw_appearance.backgroundColor = nil;
            self.fw_appearance.backgroundImage = self.fw_backgroundImage.fw_image;
            [self fw_updateAppearance];
        }} else {
            self.barTintColor = nil;
            [self setBackgroundImage:self.fw_backgroundImage.fw_image forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        }
    }
    
    if (self.fw_shadowColor && self.fw_shadowColor.fw_isThemeColor) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fw_appearance.shadowColor = self.fw_shadowColor.fw_color;
            self.fw_appearance.shadowImage = nil;
            [self fw_updateAppearance];
        }} else {
            [self setShadowImage:[UIImage fw_imageWithColor:self.fw_shadowColor.fw_color] ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
        }
    }
    
    if (self.fw_shadowImage && self.fw_shadowImage.fw_isThemeImage) {
        if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fw_appearance.shadowColor = nil;
            self.fw_appearance.shadowImage = self.fw_shadowImage.fw_image;
            [self fw_updateAppearance];
        }} else {
            [self setShadowImage:self.fw_shadowImage.fw_image ?: [UIImage new] forToolbarPosition:UIBarPositionAny];
        }
    }
}

- (UIBarPosition)fw_barPosition
{
    return [objc_getAssociatedObject(self, @selector(fw_barPosition)) integerValue];
}

- (void)setFw_barPosition:(UIBarPosition)barPosition
{
    objc_setAssociatedObject(self, @selector(fw_barPosition), @(barPosition), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.fw_toolbarDelegate.barPosition = barPosition;
}

- (FWToolbarDelegate *)fw_toolbarDelegate
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
