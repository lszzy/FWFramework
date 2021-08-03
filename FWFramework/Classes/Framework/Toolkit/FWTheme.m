/*!
 @header     FWTheme.m
 @indexgroup FWFramework
 @brief      FWTheme
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import "FWTheme.h"
#import "FWImage.h"
#import "FWNavigation.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - FWThemeManager

NSString *const FWThemeChangedNotification = @"FWThemeChangedNotification";

static NSMutableDictionary<NSString *, UIColor *> *fwStaticThemeColors = nil;
static NSMutableDictionary<NSString *, UIImage *> *fwStaticThemeImages = nil;

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
    return [self styleForTraitCollection:nil];
}

- (FWThemeStyle)styleForTraitCollection:(UITraitCollection *)traitCollection
{
    if (self.mode == FWThemeModeSystem) {
        if (@available(iOS 13, *)) {
            if (!traitCollection) traitCollection = UITraitCollection.currentTraitCollection;
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
        } else {
            return FWThemeStyleLight;
        }
    } else {
        return (FWThemeStyle)self.mode;
    }
}

@end

@interface FWThemeObject ()

@property (nonatomic, copy) id (^provider)(FWThemeStyle);

@end

@implementation FWThemeObject

+ (instancetype)objectWithLight:(id)light dark:(id)dark
{
    return [self objectWithProvider:^id (FWThemeStyle style) {
        return style == FWThemeStyleDark ? dark : light;
    }];
}

+ (instancetype)objectWithProvider:(id (^)(FWThemeStyle))provider
{
    FWThemeObject *object = [[FWThemeObject alloc] init];
    object.provider = provider;
    return object;
}

- (id)object
{
    return self.provider ? self.provider(FWThemeManager.sharedInstance.style) : nil;
}

- (id)objectForStyle:(FWThemeStyle)style
{
    return self.provider ? self.provider(style) : nil;
}

@end

#pragma mark - UIColor+FWTheme

@implementation UIColor (FWTheme)

+ (UIColor *)fwThemeLight:(UIColor *)light dark:(UIColor *)dark
{
    return [self fwThemeColor:^UIColor *(FWThemeStyle style) {
        return style == FWThemeStyleDark ? dark : light;
    }];
}

+ (UIColor *)fwThemeColor:(UIColor * (^)(FWThemeStyle))provider
{
    if (@available(iOS 13, *)) {
        UIColor *color = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            return provider([FWThemeManager.sharedInstance styleForTraitCollection:traitCollection]);
        }];
        objc_setAssociatedObject(color, @selector(fwIsThemeColor), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return color;
    } else {
        UIColor *color = provider(FWThemeManager.sharedInstance.style);
        CGFloat r = 0, g = 0, b = 0, a = 0;
        if (![color getRed:&r green:&g blue:&b alpha:&a]) {
            if ([color getWhite:&r alpha:&a]) { g = r; b = r; }
        }
        color = [UIColor colorWithRed:r green:g blue:b alpha:a];
        color.fwThemeObject = [FWThemeObject<UIColor *> objectWithProvider:provider];
        return color;
    }
}

+ (UIColor *)fwThemeNamed:(NSString *)name
{
    return [self fwThemeNamed:name bundle:nil];
}

+ (UIColor *)fwThemeNamed:(NSString *)name bundle:(NSBundle *)bundle
{
    UIColor *themeColor = fwStaticThemeColors[name];
    if (themeColor) return themeColor;
    
    return [self fwThemeColor:^UIColor *(FWThemeStyle style) {
        if (@available(iOS 13, *)) {
            UIColor *color = [UIColor colorNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
            if (!color) return UIColor.clearColor;
            UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
            return [color resolvedColorWithTraitCollection:traitCollection];
        } else {
            if (@available(iOS 11.0, *)) {
                UIColor *color = [UIColor colorNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
                if (color) return color;
            }
            return UIColor.clearColor;
        }
    }];
}

+ (void)fwSetThemeColor:(UIColor *)color forName:(NSString *)name
{
    if (color) {
        [fwStaticThemeColors setObject:color forKey:name];
    } else {
        [fwStaticThemeColors removeObjectForKey:name];
    }
}

+ (void)fwSetThemeColors:(NSDictionary<NSString *,UIColor *> *)nameColors
{
    [fwStaticThemeColors addEntriesFromDictionary:nameColors];
}

- (FWThemeObject<UIColor *> *)fwThemeObject
{
    return objc_getAssociatedObject(self, @selector(fwThemeObject));
}

- (void)setFwThemeObject:(FWThemeObject<UIColor *> *)fwThemeObject
{
    objc_setAssociatedObject(self, @selector(fwThemeObject), fwThemeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)fwColor
{
    if (@available(iOS 13, *)) {
        return self;
    } else {
        return self.fwThemeObject ? self.fwThemeObject.object : self;
    }
}

- (UIColor *)fwColorForStyle:(FWThemeStyle)style
{
    if (@available(iOS 13, *)) {
        UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
        return [self resolvedColorWithTraitCollection:traitCollection];
    } else {
        return self.fwThemeObject ? [self.fwThemeObject objectForStyle:style] : self;
    }
}

- (BOOL)fwIsThemeColor
{
    if (@available(iOS 13, *)) {
        return [objc_getAssociatedObject(self, @selector(fwIsThemeColor)) boolValue];
    } else {
        return self.fwThemeObject ? YES : NO;
    }
}

@end

#pragma mark - UIImage+FWTheme

@implementation UIImage (FWTheme)

+ (UIImage *)fwThemeLight:(UIImage *)light dark:(UIImage *)dark
{
    return [self fwThemeImage:^UIImage * (FWThemeStyle style) {
        return style == FWThemeStyleDark ? dark : light;
    }];
}

+ (UIImage *)fwThemeImage:(UIImage * (^)(FWThemeStyle))provider
{
    UIImage *image = [UIImage new];
    image.fwThemeObject = [FWThemeObject<UIImage *> objectWithProvider:provider];
    return image;
}

+ (UIImage *)fwThemeNamed:(NSString *)name
{
    return [self fwThemeNamed:name bundle:nil];
}

+ (UIImage *)fwThemeNamed:(NSString *)name bundle:(NSBundle *)bundle
{
    UIImage *themeImage = fwStaticThemeImages[name];
    if (themeImage) return themeImage;

    return [self fwThemeImage:^UIImage * (FWThemeStyle style) {
        UIImage *image = [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
        if (@available(iOS 13, *)) {
            UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
            image = [image imageWithConfiguration:traitCollection.imageConfiguration];
        }
        return image;
    }];
}

+ (void)fwSetThemeImage:(UIImage *)image forName:(NSString *)name
{
    if (image) {
        [fwStaticThemeImages setObject:image forKey:name];
    } else {
        [fwStaticThemeImages removeObjectForKey:name];
    }
}

+ (void)fwSetThemeImages:(NSDictionary<NSString *,UIImage *> *)nameImages
{
    [fwStaticThemeImages addEntriesFromDictionary:nameImages];
}

- (FWThemeObject<UIImage *> *)fwThemeObject
{
    return objc_getAssociatedObject(self, @selector(fwThemeObject));
}

- (void)setFwThemeObject:(FWThemeObject<UIImage *> *)fwThemeObject
{
    objc_setAssociatedObject(self, @selector(fwThemeObject), fwThemeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)fwImage
{
    return self.fwThemeObject ? self.fwThemeObject.object : self;
}

- (UIImage *)fwImageForStyle:(FWThemeStyle)style
{
    return self.fwThemeObject ? [self.fwThemeObject objectForStyle:style] : self;
}

- (BOOL)fwIsThemeImage
{
    return self.fwThemeObject ? YES : NO;
}

#pragma mark - Color

+ (UIColor *)fwThemeImageColor
{
    UIColor *color = objc_getAssociatedObject([UIImage class], @selector(fwThemeImageColor));
    return color ?: [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
}

+ (void)setFwThemeImageColor:(UIColor *)fwThemeImageColor
{
    objc_setAssociatedObject([UIImage class], @selector(fwThemeImageColor), fwThemeImageColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)fwThemeImage
{
    return [self fwThemeImageWithColor:[UIImage fwThemeImageColor]];
}

- (UIImage *)fwThemeImageWithColor:(UIColor *)themeColor
{
    return [UIImage fwThemeImage:^UIImage *(FWThemeStyle style) {
        UIImage *image = [self fwImageForStyle:style];
        UIColor *color = [themeColor fwColorForStyle:style];
        return [image fwImageWithTintColor:color];
    }];
}

@end

#pragma mark - NSObject+FWTheme

@implementation NSObject (FWTheme)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fwStaticThemeColors = [NSMutableDictionary new];
        fwStaticThemeImages = [NSMutableDictionary new];
        
        if (@available(iOS 13, *)) {
            [self fwThemeSwizzleClass:[UIScreen class]];
            [self fwThemeSwizzleClass:[UIView class]];
            [self fwThemeSwizzleClass:[UIViewController class]];
            // UIImageView|UILabel内部重写traitCollectionDidChange:时未调用super导致不回调fwThemeChanged:
            [self fwThemeSwizzleClass:[UIImageView class]];
            [self fwThemeSwizzleClass:[UILabel class]];
        }
    });
}

+ (void)fwThemeSwizzleClass:(Class)themeClass NS_AVAILABLE_IOS(13_0)
{
    [NSObject fwSwizzleClass:themeClass selector:@selector(traitCollectionDidChange:) withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return ^(__unsafe_unretained NSObject<UITraitEnvironment> *selfObject, UITraitCollection *traitCollection) {
            void (*originalMSG)(id, SEL, UITraitCollection *) = (void (*)(id, SEL, UITraitCollection *))originalIMP();
            originalMSG(selfObject, originalCMD, traitCollection);
            
            if (![selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) return;
            FWThemeStyle style = [FWThemeManager.sharedInstance styleForTraitCollection:selfObject.traitCollection];
            FWThemeStyle oldStyle = [FWThemeManager.sharedInstance styleForTraitCollection:traitCollection];
            if (style == oldStyle) return;
            
            [selfObject fwThemeChanged:style];
            [selfObject fwNotifyThemeListeners:style];
            
            if (selfObject == [UIScreen mainScreen]) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
                [userInfo setObject:@(style) forKey:NSKeyValueChangeNewKey];
                [[NSNotificationCenter defaultCenter] postNotificationName:FWThemeChangedNotification object:selfObject userInfo:userInfo.copy];
            }
        };
    }];
}

- (NSMutableDictionary *)fwInnerThemeListeners:(BOOL)lazyload NS_AVAILABLE_IOS(13_0)
{
    NSMutableDictionary *listeners = objc_getAssociatedObject(self, _cmd);
    if (!listeners && lazyload) {
        listeners = [NSMutableDictionary new];
        objc_setAssociatedObject(self, _cmd, listeners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return listeners;
}

- (void)fwNotifyThemeListeners:(FWThemeStyle)style NS_AVAILABLE_IOS(13_0)
{
    NSMutableDictionary *listeners = [self fwInnerThemeListeners:NO];
    [listeners enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        void (^listener)(FWThemeStyle) = obj;
        listener(style);
    }];
}

- (NSString *)fwThemeContextIdentifier
{
    return objc_getAssociatedObject(self, @selector(fwThemeContextIdentifier));
}

- (void)setFwThemeContextIdentifier:(NSString *)identifier
{
    objc_setAssociatedObject(self, @selector(fwThemeContextIdentifier), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<UITraitEnvironment>)fwThemeContext
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwThemeContext));
    return value.object;
}

- (void)setFwThemeContext:(id<UITraitEnvironment>)themeContext
{
    if (@available(iOS 13, *)) {
        id<UITraitEnvironment> oldContext = self.fwThemeContext;
        if (themeContext != oldContext) {
            objc_setAssociatedObject(self, @selector(fwThemeContext), [[FWWeakObject alloc] initWithObject:themeContext], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            if (oldContext != nil) {
                [(NSObject *)oldContext fwRemoveThemeListener:[self fwThemeContextIdentifier]];
                [self setFwThemeContextIdentifier:nil];
            }
            
            if (themeContext != nil) {
                __weak __typeof__(self) self_weak_ = self;
                NSString *identifier = [(NSObject *)themeContext fwAddThemeListener:^(FWThemeStyle style) {
                    __typeof__(self) self = self_weak_;
                    [self fwThemeChanged:style];
                    [self fwNotifyThemeListeners:style];
                }];
                [self setFwThemeContextIdentifier:identifier];
            }
        }
    }
}

- (NSString *)fwAddThemeListener:(void (^)(FWThemeStyle))listener
{
    if (@available(iOS 13, *)) {
        NSString *identifier = [[NSUUID UUID] UUIDString];
        NSMutableDictionary *listeners = [self fwInnerThemeListeners:YES];
        [listeners setObject:[listener copy] forKey:identifier];
        return identifier;
    }
    return nil;
}

- (void)fwRemoveThemeListener:(NSString *)identifier
{
    if (@available(iOS 13, *)) {
        if (!identifier) return;
        NSMutableDictionary *listeners = [self fwInnerThemeListeners:NO];
        [listeners removeObjectForKey:identifier];
    }
}

- (void)fwRemoveAllThemeListeners
{
    if (@available(iOS 13, *)) {
        NSMutableDictionary *listeners = [self fwInnerThemeListeners:NO];
        [listeners removeAllObjects];
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
    self.image = fwThemeImage.fwImage;
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeImage && self.fwThemeImage.fwIsThemeImage) {
        self.image = self.fwThemeImage.fwImage;
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
    self.backgroundColor = fwThemeBackgroundColor.CGColor;
}

- (UIColor *)fwThemeBorderColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeBorderColor));
}

- (void)setFwThemeBorderColor:(UIColor *)fwThemeBorderColor
{
    objc_setAssociatedObject(self, @selector(fwThemeBorderColor), fwThemeBorderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.borderColor = fwThemeBorderColor.CGColor;
}

- (UIColor *)fwThemeShadowColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeShadowColor));
}

- (void)setFwThemeShadowColor:(UIColor *)fwThemeShadowColor
{
    objc_setAssociatedObject(self, @selector(fwThemeShadowColor), fwThemeShadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.shadowColor = fwThemeShadowColor.CGColor;
}

- (UIImage *)fwThemeContents
{
    return objc_getAssociatedObject(self, @selector(fwThemeContents));
}

- (void)setFwThemeContents:(UIImage *)fwThemeContents
{
    objc_setAssociatedObject(self, @selector(fwThemeContents), fwThemeContents, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.contents = (id)fwThemeContents.fwImage.CGImage;
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
    if (self.fwThemeContents && self.fwThemeContents.fwIsThemeImage) {
        self.contents = (id)self.fwThemeContents.fwImage.CGImage;
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
