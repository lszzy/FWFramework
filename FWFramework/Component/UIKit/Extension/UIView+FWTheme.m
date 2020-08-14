/*!
 @header     UIView+FWTheme.m
 @indexgroup FWFramework
 @brief      UIView+FWTheme
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import "UIView+FWTheme.h"
#import "FWMessage.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - FWThemeManager

NSString *const FWThemeChangedNotification = @"FWThemeChangedNotification";

static NSMutableDictionary<NSString *, UIColor *> *fwStaticNameColors = nil;
static NSMutableDictionary<NSString *, UIImage *> *fwStaticNameImages = nil;

@implementation FWThemeManager

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fwStaticNameColors = [NSMutableDictionary new];
        fwStaticNameImages = [NSMutableDictionary new];
        
        if (@available(iOS 13, *)) {
            FWSwizzleClass(UIScreen, @selector(traitCollectionDidChange:), FWSwizzleReturn(void), FWSwizzleArgs(UITraitCollection *traitCollection), FWSwizzleCode({
                FWSwizzleOriginal(traitCollection);
                
                if (selfObject != UIScreen.mainScreen) return;
                if (FWThemeManager.sharedInstance.mode != FWThemeModeSystem) return;
                if ([selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) {
                    FWThemeStyle oldStyle = traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
                    FWThemeStyle newStyle = selfObject.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
                    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                    [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
                    [userInfo setObject:@(newStyle) forKey:NSKeyValueChangeNewKey];
                    [[NSNotificationCenter defaultCenter] postNotificationName:FWThemeChangedNotification object:selfObject userInfo:userInfo.copy];
                }
            }));
            
            FWSwizzleClass(UIView, @selector(traitCollectionDidChange:), FWSwizzleReturn(void), FWSwizzleArgs(UITraitCollection *traitCollection), FWSwizzleCode({
                FWSwizzleOriginal(traitCollection);
                
                if (FWThemeManager.sharedInstance.mode != FWThemeModeSystem) return;
                if ([selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) {
                    FWThemeStyle style = FWThemeManager.sharedInstance.style;
                    if (selfObject.fwThemeChanged) {
                        selfObject.fwThemeChanged(style);
                    }
                    [selfObject fwThemeChanged:style];
                }
            }));
            
            FWSwizzleClass(UIViewController, @selector(traitCollectionDidChange:), FWSwizzleReturn(void), FWSwizzleArgs(UITraitCollection *traitCollection), FWSwizzleCode({
                FWSwizzleOriginal(traitCollection);
                
                if (FWThemeManager.sharedInstance.mode != FWThemeModeSystem) return;
                if ([selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) {
                    FWThemeStyle style = FWThemeManager.sharedInstance.style;
                    if (selfObject.fwThemeChanged) {
                        selfObject.fwThemeChanged(style);
                    }
                    [selfObject fwThemeChanged:style];
                }
            }));
        }
    });
}

+ (FWThemeManager *)sharedInstance
{
    static FWThemeManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWThemeManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"FWThemeMode"] integerValue];
    }
    return self;
}

- (void)setMode:(FWThemeMode)mode
{
    if (mode != _mode) {
        [[NSUserDefaults standardUserDefaults] setObject:@(mode) forKey:@"FWThemeMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        FWThemeStyle oldStyle = self.style;
        _mode = mode;
        FWThemeStyle newStyle = self.style;
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
        [userInfo setObject:@(newStyle) forKey:NSKeyValueChangeNewKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:FWThemeChangedNotification object:self userInfo:userInfo.copy];
    }
}

- (FWThemeStyle)style
{
    if (self.mode == FWThemeModeSystem) {
        if (@available(iOS 13, *)) {
            return UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
        } else {
            return FWThemeStyleLight;
        }
    } else {
        return self.mode == FWThemeModeDark ? FWThemeStyleDark : FWThemeStyleLight;
    }
}

@end

#pragma mark - UIColor+FWTheme

@implementation UIColor (FWTheme)

+ (UIColor *)fwThemeLight:(UIColor *)light dark:(UIColor *)dark
{
    if (@available(iOS 13, *)) {
        if (FWThemeManager.sharedInstance.mode == FWThemeModeSystem) {
            return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
                return FWThemeManager.sharedInstance.style == FWThemeStyleDark ? dark : light;
            }];
        }
    }
    return FWThemeManager.sharedInstance.style == FWThemeStyleDark ? dark : light;
}

+ (UIColor *)fwThemeColor:(UIColor * _Nonnull (^)(FWThemeStyle))provider
{
    if (@available(iOS 13, *)) {
        if (FWThemeManager.sharedInstance.mode == FWThemeModeSystem) {
            return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
                return provider(FWThemeManager.sharedInstance.style);
            }];
        }
    }
    return provider(FWThemeManager.sharedInstance.style);
}

+ (UIColor *)fwThemeNamed:(NSString *)name
{
    UIColor *color = nil;
    if (@available(iOS 11.0, *)) {
        color = [UIColor colorNamed:name];
    }
    if (!color) {
        color = fwStaticNameColors[name];
    }
    return color;
}

+ (void)fwSetThemeColor:(UIColor *)color forName:(NSString *)name
{
    if (color) {
        [fwStaticNameColors setObject:color forKey:name];
    } else {
        [fwStaticNameColors removeObjectForKey:name];
    }
}

+ (void)fwSetThemeColors:(NSDictionary<NSString *,UIColor *> *)nameColors
{
    [fwStaticNameColors addEntriesFromDictionary:nameColors];
}

@end

#pragma mark - UIImage+FWTheme

@implementation UIImage (FWTheme)

+ (UIImage *)fwThemeLight:(UIImage *)light dark:(UIImage *)dark
{
    return FWThemeManager.sharedInstance.style == FWThemeStyleDark ? dark : light;
}

+ (UIImage *)fwThemeImage:(UIImage * (^)(FWThemeStyle))provider
{
    return provider(FWThemeManager.sharedInstance.style);
}

+ (UIImage *)fwThemeNamed:(NSString *)name
{
    UIImage *image = [UIImage imageNamed:name];
    if (!image) {
        image = fwStaticNameImages[name];
    }
    return image;
}

+ (void)fwSetThemeImage:(UIImage *)image forName:(NSString *)name
{
    if (image) {
        [fwStaticNameImages setObject:image forKey:name];
    } else {
        [fwStaticNameImages removeObjectForKey:name];
    }
}

+ (void)fwSetThemeImages:(NSDictionary<NSString *,UIImage *> *)nameImages
{
    [fwStaticNameImages addEntriesFromDictionary:nameImages];
}

@end

#pragma mark - NSObject+FWTheme

@implementation NSObject (FWTheme)

- (BOOL)fwThemeEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwThemeEnabled)) boolValue];
}

- (void)setFwThemeEnabled:(BOOL)fwThemeEnabled
{
    if (fwThemeEnabled != self.fwThemeEnabled) {
        objc_setAssociatedObject(self, @selector(fwThemeEnabled), @(fwThemeEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if (fwThemeEnabled) {
            __weak __typeof__(self) self_weak_ = self;
            [self fwObserveNotification:FWThemeChangedNotification block:^(NSNotification *notification) {
                __typeof__(self) self = self_weak_;
                
                FWThemeStyle style = [notification.userInfo[NSKeyValueChangeNewKey] integerValue];
                if (self.fwThemeChanged) {
                    self.fwThemeChanged(style);
                }
                [self fwThemeChanged:style];
            }];
        } else {
            [self fwUnobserveNotification:FWThemeChangedNotification];
        }
    }
}

- (void (^)(FWThemeStyle))fwThemeChanged
{
    return objc_getAssociatedObject(self, @selector(fwThemeChanged));
}

- (void)setFwThemeChanged:(void (^)(FWThemeStyle))fwThemeChanged
{
    objc_setAssociatedObject(self, @selector(fwThemeChanged), fwThemeChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    // 子类重写
}

@end
