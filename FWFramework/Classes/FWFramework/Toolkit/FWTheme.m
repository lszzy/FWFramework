/**
 @header     FWTheme.m
 @indexgroup FWFramework
      FWTheme
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import "FWTheme.h"
#import "FWNavigation.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - FWThemeManager

NSNotificationName const FWThemeChangedNotification = @"FWThemeChangedNotification";

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
            UIWindow.fw_mainWindow.overrideUserInterfaceStyle = style;
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

+ (UIColor *)fw_themeLight:(UIColor *)light dark:(UIColor *)dark
{
    return [self fw_themeColor:^UIColor *(FWThemeStyle style) {
        return style == FWThemeStyleDark ? dark : light;
    }];
}

+ (UIColor *)fw_themeColor:(UIColor * (^)(FWThemeStyle))provider
{
    if (@available(iOS 13, *)) {
        UIColor *color = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            return provider([FWThemeManager.sharedInstance styleForTraitCollection:traitCollection]);
        }];
        color.fw_themeObject = [FWThemeObject<UIColor *> objectWithProvider:provider];
        return color;
    } else {
        UIColor *color = provider(FWThemeManager.sharedInstance.style);
        CGFloat r = 0, g = 0, b = 0, a = 0;
        if (![color getRed:&r green:&g blue:&b alpha:&a]) {
            if ([color getWhite:&r alpha:&a]) { g = r; b = r; }
        }
        color = [UIColor colorWithRed:r green:g blue:b alpha:a];
        color.fw_themeObject = [FWThemeObject<UIColor *> objectWithProvider:provider];
        return color;
    }
}

+ (UIColor *)fw_themeNamed:(NSString *)name
{
    return [self fw_themeNamed:name bundle:nil];
}

+ (UIColor *)fw_themeNamed:(NSString *)name bundle:(NSBundle *)bundle
{
    UIColor *themeColor = fwStaticThemeColors[name];
    if (themeColor) return themeColor;
    
    return [self fw_themeColor:^UIColor *(FWThemeStyle style) {
        if (@available(iOS 13, *)) {
            UIColor *color = [UIColor colorNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
            if (!color) return UIColor.clearColor;
            UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
            return [color resolvedColorWithTraitCollection:traitCollection];
        } else {
            UIColor *color = [UIColor colorNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
            return color ?: UIColor.clearColor;
        }
    }];
}

+ (void)fw_setThemeColor:(UIColor *)color forName:(NSString *)name
{
    if (color) {
        [fwStaticThemeColors setObject:color forKey:name];
    } else {
        [fwStaticThemeColors removeObjectForKey:name];
    }
}

+ (void)fw_setThemeColors:(NSDictionary<NSString *,UIColor *> *)nameColors
{
    [fwStaticThemeColors addEntriesFromDictionary:nameColors];
}

- (UIColor *)fw_color
{
    if (@available(iOS 13, *)) {
        return self;
    } else {
        return self.fw_themeObject ? self.fw_themeObject.object : self;
    }
}

- (UIColor *)fw_colorForStyle:(FWThemeStyle)style
{
    if (self.fw_themeObject) {
        return [self.fw_themeObject objectForStyle:style];
    }
    
    if (@available(iOS 13, *)) {
        UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
        return [self resolvedColorWithTraitCollection:traitCollection];
    } else {
        return self;
    }
}

- (BOOL)fw_isThemeColor
{
    return self.fw_themeObject ? YES : NO;
}

- (FWThemeObject<UIColor *> *)fw_themeObject
{
    return objc_getAssociatedObject(self, @selector(fw_themeObject));
}

- (void)setFw_themeObject:(FWThemeObject<UIColor *> *)themeObject
{
    objc_setAssociatedObject(self, @selector(fw_themeObject), themeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UIImage+FWTheme

@implementation UIImage (FWTheme)

+ (UIImage *)fw_themeLight:(UIImage *)light dark:(UIImage *)dark
{
    return [self fw_themeImage:^UIImage * (FWThemeStyle style) {
        return style == FWThemeStyleDark ? dark : light;
    }];
}

+ (UIImage *)fw_themeImage:(UIImage * (^)(FWThemeStyle))provider
{
    UIImage *image = [UIImage new];
    image.fw_themeObject = [FWThemeObject<UIImage *> objectWithProvider:provider];
    return image;
}

+ (UIImage *)fw_themeNamed:(NSString *)name
{
    return [self fw_themeNamed:name bundle:nil];
}

+ (UIImage *)fw_themeNamed:(NSString *)name bundle:(NSBundle *)bundle
{
    UIImage *themeImage = fwStaticThemeImages[name];
    if (themeImage) return themeImage;

    return [self fw_themeImage:^UIImage * (FWThemeStyle style) {
        UIImage *image = [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
        if (@available(iOS 13, *)) {
            UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
            image = [image imageWithConfiguration:traitCollection.imageConfiguration];
        }
        return image;
    }];
}

+ (void)fw_setThemeImage:(UIImage *)image forName:(NSString *)name
{
    if (image) {
        [fwStaticThemeImages setObject:image forKey:name];
    } else {
        [fwStaticThemeImages removeObjectForKey:name];
    }
}

+ (void)fw_setThemeImages:(NSDictionary<NSString *,UIImage *> *)nameImages
{
    [fwStaticThemeImages addEntriesFromDictionary:nameImages];
}

- (FWThemeObject<UIImage *> *)fw_themeObject
{
    return objc_getAssociatedObject(self, @selector(fw_themeObject));
}

- (void)setFw_themeObject:(FWThemeObject<UIImage *> *)themeObject
{
    objc_setAssociatedObject(self, @selector(fw_themeObject), themeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)fw_image
{
    return self.fw_themeObject ? self.fw_themeObject.object : self;
}

- (UIImage *)fw_imageForStyle:(FWThemeStyle)style
{
    return self.fw_themeObject ? [self.fw_themeObject objectForStyle:style] : self;
}

- (BOOL)fw_isThemeImage
{
    return self.fw_themeObject ? YES : NO;
}

#pragma mark - Color

+ (UIColor *)fw_themeImageColor
{
    UIColor *color = objc_getAssociatedObject([UIImage class], @selector(fw_themeImageColor));
    return color ?: [UIColor fw_themeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
}

+ (void)setFw_themeImageColor:(UIColor *)themeImageColor
{
    objc_setAssociatedObject([UIImage class], @selector(fw_themeImageColor), themeImageColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)fw_themeImage
{
    return [self fw_themeImageWithColor:[UIImage fw_themeImageColor]];
}

- (UIImage *)fw_themeImageWithColor:(UIColor *)themeColor
{
    return [UIImage fw_themeImage:^UIImage *(FWThemeStyle style) {
        UIImage *image = [self fw_imageForStyle:style];
        UIColor *color = [themeColor fw_colorForStyle:style];
        
        UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
        [color setFill];
        CGRect bounds = CGRectMake(0, 0, image.size.width, image.size.height);
        UIRectFill(bounds);
        [image drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
        UIImage *themeImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return themeImage;
    }];
}

@end

#pragma mark - UIImageAsset+FWTheme

@implementation UIImageAsset (FWTheme)

+ (UIImageAsset *)fw_themeLight:(UIImage *)light dark:(UIImage *)dark
{
    if (@available(iOS 13, *)) {
        UIImageAsset *asset = [[UIImageAsset alloc] init];
        if (light) [asset registerImage:light withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        if (dark) [asset registerImage:dark withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        objc_setAssociatedObject(asset, @selector(fw_isThemeAsset), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return asset;
    } else {
        return [self fw_themeAsset:^UIImage * (FWThemeStyle style) {
            return style == FWThemeStyleDark ? dark : light;
        }];
    }
}

+ (UIImageAsset *)fw_themeAsset:(UIImage * _Nullable (^)(FWThemeStyle))provider
{
    UIImageAsset *asset = [[UIImageAsset alloc] init];
    asset.fw_themeObject = [FWThemeObject<UIImage *> objectWithProvider:provider];
    return asset;
}

- (FWThemeObject<UIImage *> *)fw_themeObject
{
    return objc_getAssociatedObject(self, @selector(fw_themeObject));
}

- (void)setFw_themeObject:(FWThemeObject<UIImage *> *)themeObject
{
    objc_setAssociatedObject(self, @selector(fw_themeObject), themeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)fw_image
{
    return [self fw_imageForStyle:FWThemeManager.sharedInstance.style];
}

- (UIImage *)fw_imageForStyle:(FWThemeStyle)style
{
    BOOL isThemeAsset = [objc_getAssociatedObject(self, @selector(fw_isThemeAsset)) boolValue];
    if (isThemeAsset) {
        if (@available(iOS 13, *)) {
            UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
            return [self imageWithTraitCollection:traitCollection];
        }
    }
    
    return self.fw_themeObject ? [self.fw_themeObject objectForStyle:style] : nil;
}

- (BOOL)fw_isThemeAsset
{
    BOOL isThemeAsset = [objc_getAssociatedObject(self, @selector(fw_isThemeAsset)) boolValue];
    return isThemeAsset || self.fw_themeObject != nil;
}

@end

#pragma mark - FWObjectWrapper+FWTheme

@implementation NSObject (FWTheme)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fwStaticThemeColors = [NSMutableDictionary new];
        fwStaticThemeImages = [NSMutableDictionary new];
        
        if (@available(iOS 13, *)) {
            [self fw_themeSwizzleClass:[UIScreen class]];
            [self fw_themeSwizzleClass:[UIView class]];
            [self fw_themeSwizzleClass:[UIViewController class]];
            // UIImageView|UILabel内部重写traitCollectionDidChange:时未调用super导致不回调fwThemeChanged:
            [self fw_themeSwizzleClass:[UIImageView class]];
            [self fw_themeSwizzleClass:[UILabel class]];
        }
    });
}

+ (void)fw_themeSwizzleClass:(Class)themeClass NS_AVAILABLE_IOS(13_0)
{
    [NSObject fw_swizzleInstanceMethod:themeClass selector:@selector(traitCollectionDidChange:) withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return ^(__unsafe_unretained NSObject<UITraitEnvironment> *selfObject, UITraitCollection *traitCollection) {
            void (*originalMSG)(id, SEL, UITraitCollection *) = (void (*)(id, SEL, UITraitCollection *))originalIMP();
            originalMSG(selfObject, originalCMD, traitCollection);
            
            if (![selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) return;
            FWThemeStyle style = [FWThemeManager.sharedInstance styleForTraitCollection:selfObject.traitCollection];
            FWThemeStyle oldStyle = [FWThemeManager.sharedInstance styleForTraitCollection:traitCollection];
            if (style == oldStyle) return;
            
            [selfObject fw_notifyThemeChanged:style];
            if (selfObject == [UIScreen mainScreen]) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
                [userInfo setObject:@(style) forKey:NSKeyValueChangeNewKey];
                [[NSNotificationCenter defaultCenter] postNotificationName:FWThemeChangedNotification object:selfObject userInfo:userInfo.copy];
            }
        };
    }];
}

- (NSString *)fw_themeContextIdentifier
{
    return objc_getAssociatedObject(self, @selector(fw_themeContextIdentifier));
}

- (void)setFw_themeContextIdentifier:(NSString *)identifier
{
    objc_setAssociatedObject(self, @selector(fw_themeContextIdentifier), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<UITraitEnvironment>)fw_themeContext
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fw_themeContext));
    return value.object;
}

- (void)setFw_themeContext:(id<UITraitEnvironment>)themeContext
{
    if (@available(iOS 13, *)) {
        id<UITraitEnvironment> oldContext = self.fw_themeContext;
        if (themeContext != oldContext) {
            objc_setAssociatedObject(self, @selector(fw_themeContext), [[FWWeakObject alloc] initWithObject:themeContext], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            if (oldContext != nil) {
                [((NSObject *)oldContext) fw_removeThemeListener:self.fw_themeContextIdentifier];
                self.fw_themeContextIdentifier = nil;
            }
            
            if (themeContext != nil) {
                __weak __typeof__(self) self_weak_ = self;
                NSString *identifier = [((NSObject *)themeContext) fw_addThemeListener:^(FWThemeStyle style) {
                    __typeof__(self) self = self_weak_;
                    [self fw_notifyThemeChanged:style];
                }];
                self.fw_themeContextIdentifier = identifier;
            }
        }
    }
}

- (NSString *)fw_addThemeListener:(void (^)(FWThemeStyle))listener
{
    if (@available(iOS 13, *)) {
        NSString *identifier = [[NSUUID UUID] UUIDString];
        NSMutableDictionary *listeners = [self fw_innerThemeListeners:YES];
        [listeners setObject:[listener copy] forKey:identifier];
        return identifier;
    }
    return nil;
}

- (void)fw_removeThemeListener:(NSString *)identifier
{
    if (@available(iOS 13, *)) {
        if (!identifier) return;
        NSMutableDictionary *listeners = [self fw_innerThemeListeners:NO];
        [listeners removeObjectForKey:identifier];
    }
}

- (void)fw_removeAllThemeListeners
{
    if (@available(iOS 13, *)) {
        NSMutableDictionary *listeners = [self fw_innerThemeListeners:NO];
        [listeners removeAllObjects];
    }
}

- (NSMutableDictionary *)fw_innerThemeListeners:(BOOL)lazyload NS_AVAILABLE_IOS(13_0)
{
    NSMutableDictionary *listeners = objc_getAssociatedObject(self, _cmd);
    if (!listeners && lazyload) {
        listeners = [NSMutableDictionary new];
        objc_setAssociatedObject(self, _cmd, listeners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return listeners;
}

- (void)fw_notifyThemeChanged:(FWThemeStyle)style NS_AVAILABLE_IOS(13_0)
{
    // 1. 调用fw_themeChanged钩子
    [self fw_themeChanged:style];
    
    // 2. 调用fw_themeListeners句柄
    NSMutableDictionary *listeners = [self fw_innerThemeListeners:NO];
    [listeners enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        void (^listener)(FWThemeStyle) = obj;
        listener(style);
    }];
    
    // 3. 调用renderTheme渲染钩子
    if ([self respondsToSelector:@selector(renderTheme:)]) {
        [self renderTheme:style];
    }
}

- (void)fw_themeChanged:(FWThemeStyle)style
{
    // 子类重写
}

@end

@implementation UIImageView (FWTheme)

- (UIImage *)fw_themeImage
{
    return objc_getAssociatedObject(self, @selector(fw_themeImage));
}

- (void)setFw_themeImage:(UIImage *)themeImage
{
    objc_setAssociatedObject(self, @selector(fw_themeImage), themeImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_themeAsset), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.image = themeImage.fw_image;
}

- (UIImageAsset *)fw_themeAsset
{
    return objc_getAssociatedObject(self, @selector(fw_themeAsset));
}

- (void)setFw_themeAsset:(UIImageAsset *)themeAsset
{
    objc_setAssociatedObject(self, @selector(fw_themeAsset), themeAsset, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fw_themeImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.image = themeAsset.fw_image;
}

- (void)fw_themeChanged:(FWThemeStyle)style
{
    [super fw_themeChanged:style];
    
    if (self.fw_themeImage && self.fw_themeImage.fw_isThemeImage) {
        self.image = self.fw_themeImage.fw_image;
    }
    if (self.fw_themeAsset && self.fw_themeAsset.fw_isThemeAsset) {
        self.image = self.fw_themeAsset.fw_image;
    }
}

@end
