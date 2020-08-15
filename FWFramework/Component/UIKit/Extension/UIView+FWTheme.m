/*!
 @header     UIView+FWTheme.m
 @indexgroup FWFramework
 @brief      UIView+FWTheme
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import "UIView+FWTheme.h"
#import "UIWindow+FWFramework.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - FWThemeManager

NSString *const FWThemeChangedNotification = @"FWThemeChangedNotification";

static NSMutableDictionary<NSString *, UIColor *> *fwStaticNameColors = nil;
static NSMutableDictionary<NSString *, UIImage *> *fwStaticNameImages = nil;

@implementation FWThemeManager

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

- (void)setOverrideWindow:(BOOL)overrideWindow
{
    if (overrideWindow != _overrideWindow) {
        _overrideWindow = overrideWindow;
        
        if (@available(iOS 13, *)) {
            UIUserInterfaceStyle style = UIUserInterfaceStyleUnspecified;
            if (overrideWindow && self.mode != FWThemeModeSystem) {
                style = self.mode == FWThemeModeDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
            }
            UIWindow.fwMainWindow.overrideUserInterfaceStyle = style;
        }
    }
}

- (void)setMode:(FWThemeMode)mode
{
    if (mode != _mode) {
        [[NSUserDefaults standardUserDefaults] setObject:@(mode) forKey:@"FWThemeMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        FWThemeStyle oldStyle = self.style;
        _mode = mode;
        FWThemeStyle style = self.style;
        
        if (@available(iOS 13, *)) {
            if (style != oldStyle) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
                [userInfo setObject:@(style) forKey:NSKeyValueChangeNewKey];
                [[NSNotificationCenter defaultCenter] postNotificationName:FWThemeChangedNotification object:self userInfo:userInfo.copy];
            }
            
            if (self.overrideWindow) {
                _overrideWindow = NO;
                [self setOverrideWindow:YES];
            }
        }
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
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            return FWThemeManager.sharedInstance.style == FWThemeStyleDark ? dark : light;
        }];
    }
    return FWThemeManager.sharedInstance.style == FWThemeStyleDark ? dark : light;
}

+ (UIColor *)fwThemeColor:(UIColor * _Nonnull (^)(FWThemeStyle))provider
{
    if (@available(iOS 13, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            return provider(FWThemeManager.sharedInstance.style);
        }];
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

@interface FWInnerThemeTarget : NSObject

@property (nonatomic, strong) NSString *identifier;

@end

@implementation FWInnerThemeTarget

- (void)dealloc
{
    [self removeListener];
}

- (void)addListener:(void (^)(FWThemeStyle style))listener
{
    self.identifier = [UIScreen.mainScreen fwAddThemeListener:listener];
}

- (void)removeListener
{
    [UIScreen.mainScreen fwRemoveThemeListener:self.identifier];
}

@end

@implementation NSObject (FWTheme)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fwStaticNameColors = [NSMutableDictionary new];
        fwStaticNameImages = [NSMutableDictionary new];
        
        if (@available(iOS 13, *)) {
            [self fwThemeSwizzleClass:[UIScreen class]];
            [self fwThemeSwizzleClass:[UIView class]];
            [self fwThemeSwizzleClass:[UIViewController class]];
            // 解决系统内部重写traitCollectionDidChange:时未调用super导致不调用fwThemeChanged:
            // [self fwThemeSwizzleClass:[UIImageView class]];
        }
    });
}

+ (void)fwThemeSwizzleClass:(Class)themeClass NS_AVAILABLE_IOS(13_0)
{
    [NSObject fwSwizzleClass:themeClass selector:@selector(traitCollectionDidChange:) withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return ^(__unsafe_unretained NSObject<UITraitEnvironment> *selfObject, UITraitCollection *traitCollection) {
            void (*originalMSG)(id, SEL, UITraitCollection *) = (void (*)(id, SEL, UITraitCollection *))originalIMP();
            originalMSG(selfObject, originalCMD, traitCollection);
            
            if ([selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) {
                FWThemeStyle style = selfObject.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
                [selfObject fwThemeChanged:style];
                [selfObject fwNotifyListeners:style];
                
                if (selfObject == [UIScreen mainScreen]) {
                    FWThemeStyle oldStyle = traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
                    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                    [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
                    [userInfo setObject:@(style) forKey:NSKeyValueChangeNewKey];
                    [[NSNotificationCenter defaultCenter] postNotificationName:FWThemeChangedNotification object:selfObject userInfo:userInfo.copy];
                }
            }
        };
    }];
}

- (NSMutableDictionary *)fwThemeListeners:(BOOL)lazyload NS_AVAILABLE_IOS(13_0)
{
    NSMutableDictionary *listeners = objc_getAssociatedObject(self, _cmd);
    if (!listeners && lazyload) {
        listeners = [NSMutableDictionary new];
        objc_setAssociatedObject(self, _cmd, listeners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return listeners;
}

- (void)fwNotifyListeners:(FWThemeStyle)style NS_AVAILABLE_IOS(13_0)
{
    NSMutableDictionary *listeners = [self fwThemeListeners:NO];
    [listeners enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        void (^listener)(FWThemeStyle) = obj;
        listener(style);
    }];
}

- (FWInnerThemeTarget *)fwInnerThemeTarget
{
    FWInnerThemeTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [FWInnerThemeTarget new];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (BOOL)fwThemeSubscribed
{
    if (@available(iOS 13, *)) {
        if ([self conformsToProtocol:@protocol(UITraitEnvironment)]) return YES;
        return [objc_getAssociatedObject(self, @selector(fwThemeSubscribed)) boolValue];
    }
    return NO;
}

- (void)setFwThemeSubscribed:(BOOL)fwThemeSubscribed
{
    if (@available(iOS 13, *)) {
        if ([self conformsToProtocol:@protocol(UITraitEnvironment)]) return;
        if (fwThemeSubscribed != self.fwThemeSubscribed) {
            objc_setAssociatedObject(self, @selector(fwThemeSubscribed), @(fwThemeSubscribed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            if (fwThemeSubscribed) {
                __weak __typeof__(self) self_weak_ = self;
                [self.fwInnerThemeTarget addListener:^(FWThemeStyle style) {
                    __typeof__(self) self = self_weak_;
                    [self fwThemeChanged:style];
                    [self fwNotifyListeners:style];
                }];
            } else {
                [self.fwInnerThemeTarget removeListener];
            }
        }
    }
}

- (NSString *)fwAddThemeListener:(void (^)(FWThemeStyle))listener
{
    if (@available(iOS 13, *)) {
        self.fwThemeSubscribed = YES;
        NSString *identifier = [[NSUUID UUID] UUIDString];
        NSMutableDictionary *listeners = [self fwThemeListeners:YES];
        [listeners setObject:[listener copy] forKey:identifier];
        return identifier;
    }
    return nil;
}

- (void)fwRemoveThemeListener:(NSString *)identifier
{
    if (@available(iOS 13, *)) {
        if (!identifier) return;
        NSMutableDictionary *listeners = [self fwThemeListeners:NO];
        [listeners removeObjectForKey:identifier];
    }
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    // 子类重写
}

@end

@implementation UIImageView (FWTheme)

- (UIImage *)fwThemeImage
{
    return objc_getAssociatedObject(self, @selector(fwThemeImage));
}

- (void)setFwThemeImage:(UIImage *)fwThemeImage
{
    objc_setAssociatedObject(self, @selector(fwThemeImage), fwThemeImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.image = fwThemeImage;
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeImage != nil) {
        self.image = self.fwThemeImage;
    }
}

@end

@implementation CALayer (FWTheme)

- (UIColor *)fwThemeBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeBackgroundColor));
}

- (void)setFwThemeBackgroundColor:(UIColor *)fwThemeBackgroundColor
{
    objc_setAssociatedObject(self, @selector(fwThemeBackgroundColor), fwThemeBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.fwThemeSubscribed = YES;
    self.backgroundColor = fwThemeBackgroundColor.CGColor;
}

- (UIColor *)fwThemeBorderColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeBorderColor));
}

- (void)setFwThemeBorderColor:(UIColor *)fwThemeBorderColor
{
    objc_setAssociatedObject(self, @selector(fwThemeBorderColor), fwThemeBorderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.fwThemeSubscribed = YES;
    self.borderColor = fwThemeBorderColor.CGColor;
}

- (UIColor *)fwThemeShadowColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeShadowColor));
}

- (void)setFwThemeShadowColor:(UIColor *)fwThemeShadowColor
{
    objc_setAssociatedObject(self, @selector(fwThemeShadowColor), fwThemeShadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.fwThemeSubscribed = YES;
    self.shadowColor = fwThemeShadowColor.CGColor;
}

- (UIImage *)fwThemeContents
{
    return objc_getAssociatedObject(self, @selector(fwThemeContents));
}

- (void)setFwThemeContents:(UIImage *)fwThemeContents
{
    objc_setAssociatedObject(self, @selector(fwThemeContents), fwThemeContents, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.fwThemeSubscribed = YES;
    self.contents = (id)fwThemeContents.CGImage;
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeBackgroundColor != nil) {
        self.backgroundColor = self.fwThemeBackgroundColor.CGColor;
    }
    if (self.fwThemeBorderColor != nil) {
        self.borderColor = self.fwThemeBorderColor.CGColor;
    }
    if (self.fwThemeShadowColor != nil) {
        self.shadowColor = self.fwThemeShadowColor.CGColor;
    }
    if (self.fwThemeContents != nil) {
        self.contents = (id)self.fwThemeContents.CGImage;
    }
}

@end

@implementation CAGradientLayer (FWTheme)

- (NSArray<UIColor *> *)fwThemeColors
{
    return objc_getAssociatedObject(self, @selector(fwThemeColors));
}

- (void)setFwThemeColors:(NSArray<UIColor *> *)fwThemeColors
{
    objc_setAssociatedObject(self, @selector(fwThemeColors), fwThemeColors, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    self.fwThemeSubscribed = YES;
    NSMutableArray *colors = nil;
    if (fwThemeColors != nil) {
        colors = [NSMutableArray new];
        for (UIColor *color in fwThemeColors) {
            [colors addObject:(id)color.CGColor];
        }
    }
    self.colors = colors.copy;
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeColors != nil) {
        NSMutableArray *colors = [NSMutableArray new];
        for (UIColor *color in self.fwThemeColors) {
            [colors addObject:(id)color.CGColor];
        }
        self.colors = colors.copy;
    }
}

@end
