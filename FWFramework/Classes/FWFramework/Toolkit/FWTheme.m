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
            UIWindow.fw.mainWindow.overrideUserInterfaceStyle = style;
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

#pragma mark - FWColorWrapper+FWTheme

@implementation FWColorWrapper (FWTheme)

- (FWThemeObject<UIColor *> *)themeObject
{
    return objc_getAssociatedObject(self.base, @selector(themeObject));
}

- (void)setThemeObject:(FWThemeObject<UIColor *> *)themeObject
{
    objc_setAssociatedObject(self.base, @selector(themeObject), themeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)color
{
    if (@available(iOS 13, *)) {
        return self.base;
    } else {
        return self.themeObject ? self.themeObject.object : self.base;
    }
}

- (UIColor *)colorForStyle:(FWThemeStyle)style
{
    if (@available(iOS 13, *)) {
        UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
        return [self.base resolvedColorWithTraitCollection:traitCollection];
    } else {
        return self.themeObject ? [self.themeObject objectForStyle:style] : self.base;
    }
}

- (BOOL)isThemeColor
{
    if (@available(iOS 13, *)) {
        return [objc_getAssociatedObject(self.base, @selector(isThemeColor)) boolValue];
    } else {
        return self.themeObject ? YES : NO;
    }
}

@end

@implementation FWColorClassWrapper (FWTheme)

- (UIColor *)themeLight:(UIColor *)light dark:(UIColor *)dark
{
    return [self themeColor:^UIColor *(FWThemeStyle style) {
        return style == FWThemeStyleDark ? dark : light;
    }];
}

- (UIColor *)themeColor:(UIColor * (^)(FWThemeStyle))provider
{
    if (@available(iOS 13, *)) {
        UIColor *color = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            return provider([FWThemeManager.sharedInstance styleForTraitCollection:traitCollection]);
        }];
        objc_setAssociatedObject(color, @selector(isThemeColor), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return color;
    } else {
        UIColor *color = provider(FWThemeManager.sharedInstance.style);
        CGFloat r = 0, g = 0, b = 0, a = 0;
        if (![color getRed:&r green:&g blue:&b alpha:&a]) {
            if ([color getWhite:&r alpha:&a]) { g = r; b = r; }
        }
        color = [UIColor colorWithRed:r green:g blue:b alpha:a];
        color.fw.themeObject = [FWThemeObject<UIColor *> objectWithProvider:provider];
        return color;
    }
}

- (UIColor *)themeNamed:(NSString *)name
{
    return [self themeNamed:name bundle:nil];
}

- (UIColor *)themeNamed:(NSString *)name bundle:(NSBundle *)bundle
{
    UIColor *themeColor = fwStaticThemeColors[name];
    if (themeColor) return themeColor;
    
    return [self themeColor:^UIColor *(FWThemeStyle style) {
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

- (void)setThemeColor:(UIColor *)color forName:(NSString *)name
{
    if (color) {
        [fwStaticThemeColors setObject:color forKey:name];
    } else {
        [fwStaticThemeColors removeObjectForKey:name];
    }
}

- (void)setThemeColors:(NSDictionary<NSString *,UIColor *> *)nameColors
{
    [fwStaticThemeColors addEntriesFromDictionary:nameColors];
}

@end

#pragma mark - FWImageWrapper+FWTheme

@implementation FWImageWrapper (FWTheme)

- (FWThemeObject<UIImage *> *)themeObject
{
    return objc_getAssociatedObject(self.base, @selector(themeObject));
}

- (void)setThemeObject:(FWThemeObject<UIImage *> *)themeObject
{
    objc_setAssociatedObject(self.base, @selector(themeObject), themeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)image
{
    return self.themeObject ? self.themeObject.object : self.base;
}

- (UIImage *)imageForStyle:(FWThemeStyle)style
{
    return self.themeObject ? [self.themeObject objectForStyle:style] : self.base;
}

- (BOOL)isThemeImage
{
    return self.themeObject ? YES : NO;
}

#pragma mark - Color

- (UIImage *)themeImage
{
    return [self themeImageWithColor:[UIImage.fw themeImageColor]];
}

- (UIImage *)themeImageWithColor:(UIColor *)themeColor
{
    __weak UIImage *weakBase = self.base;
    return [UIImage.fw themeImage:^UIImage *(FWThemeStyle style) {
        UIImage *image = [weakBase.fw imageForStyle:style];
        UIColor *color = [themeColor.fw colorForStyle:style];
        
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

@implementation FWImageClassWrapper (FWTheme)

- (UIImage *)themeLight:(UIImage *)light dark:(UIImage *)dark
{
    return [self themeImage:^UIImage * (FWThemeStyle style) {
        return style == FWThemeStyleDark ? dark : light;
    }];
}

- (UIImage *)themeImage:(UIImage * (^)(FWThemeStyle))provider
{
    UIImage *image = [UIImage new];
    image.fw.themeObject = [FWThemeObject<UIImage *> objectWithProvider:provider];
    return image;
}

- (UIImage *)themeNamed:(NSString *)name
{
    return [self themeNamed:name bundle:nil];
}

- (UIImage *)themeNamed:(NSString *)name bundle:(NSBundle *)bundle
{
    UIImage *themeImage = fwStaticThemeImages[name];
    if (themeImage) return themeImage;

    return [self themeImage:^UIImage * (FWThemeStyle style) {
        UIImage *image = [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
        if (@available(iOS 13, *)) {
            UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
            image = [image imageWithConfiguration:traitCollection.imageConfiguration];
        }
        return image;
    }];
}

- (void)setThemeImage:(UIImage *)image forName:(NSString *)name
{
    if (image) {
        [fwStaticThemeImages setObject:image forKey:name];
    } else {
        [fwStaticThemeImages removeObjectForKey:name];
    }
}

- (void)setThemeImages:(NSDictionary<NSString *,UIImage *> *)nameImages
{
    [fwStaticThemeImages addEntriesFromDictionary:nameImages];
}

#pragma mark - Color

- (UIColor *)themeImageColor
{
    UIColor *color = objc_getAssociatedObject([UIImage class], @selector(themeImageColor));
    return color ?: [UIColor.fw themeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
}

- (void)setThemeImageColor:(UIColor *)themeImageColor
{
    objc_setAssociatedObject([UIImage class], @selector(themeImageColor), themeImageColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - FWImageAssetWrapper+FWTheme

@implementation FWImageAssetWrapper (FWTheme)

- (FWThemeObject<UIImage *> *)themeObject
{
    return objc_getAssociatedObject(self.base, @selector(themeObject));
}

- (void)setThemeObject:(FWThemeObject<UIImage *> *)themeObject
{
    objc_setAssociatedObject(self.base, @selector(themeObject), themeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)image
{
    return [self imageForStyle:FWThemeManager.sharedInstance.style];
}

- (UIImage *)imageForStyle:(FWThemeStyle)style
{
    BOOL isThemeAsset = [objc_getAssociatedObject(self.base, @selector(isThemeAsset)) boolValue];
    if (isThemeAsset) {
        if (@available(iOS 13, *)) {
            UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
            return [self.base imageWithTraitCollection:traitCollection];
        }
    }
    
    return self.themeObject ? [self.themeObject objectForStyle:style] : nil;
}

- (BOOL)isThemeAsset
{
    BOOL isThemeAsset = [objc_getAssociatedObject(self.base, @selector(isThemeAsset)) boolValue];
    return isThemeAsset || self.themeObject != nil;
}

@end

@implementation FWImageAssetClassWrapper (FWTheme)

- (UIImageAsset *)themeLight:(UIImage *)light dark:(UIImage *)dark
{
    if (@available(iOS 13, *)) {
        UIImageAsset *asset = [[UIImageAsset alloc] init];
        if (light) [asset registerImage:light withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        if (dark) [asset registerImage:dark withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        objc_setAssociatedObject(asset, @selector(isThemeAsset), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return asset;
    } else {
        return [self themeAsset:^UIImage * (FWThemeStyle style) {
            return style == FWThemeStyleDark ? dark : light;
        }];
    }
}

- (UIImageAsset *)themeAsset:(UIImage * _Nullable (^)(FWThemeStyle))provider
{
    UIImageAsset *asset = [[UIImageAsset alloc] init];
    asset.fw.themeObject = [FWThemeObject<UIImage *> objectWithProvider:provider];
    return asset;
}

@end

#pragma mark - FWObjectWrapper+FWTheme

@implementation NSObject (FWTheme)

@end

@implementation FWObjectWrapper (FWTheme)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fwStaticThemeColors = [NSMutableDictionary new];
        fwStaticThemeImages = [NSMutableDictionary new];
        
        if (@available(iOS 13, *)) {
            [self themeSwizzleClass:[UIScreen class]];
            [self themeSwizzleClass:[UIView class]];
            [self themeSwizzleClass:[UIViewController class]];
            // UIImageView|UILabel内部重写traitCollectionDidChange:时未调用super导致不回调fwThemeChanged:
            [self themeSwizzleClass:[UIImageView class]];
            [self themeSwizzleClass:[UILabel class]];
        }
    });
}

+ (void)themeSwizzleClass:(Class)themeClass NS_AVAILABLE_IOS(13_0)
{
    [NSObject.fw swizzleInstanceMethod:themeClass selector:@selector(traitCollectionDidChange:) withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return ^(__unsafe_unretained NSObject<UITraitEnvironment> *selfObject, UITraitCollection *traitCollection) {
            void (*originalMSG)(id, SEL, UITraitCollection *) = (void (*)(id, SEL, UITraitCollection *))originalIMP();
            originalMSG(selfObject, originalCMD, traitCollection);
            
            if (![selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) return;
            FWThemeStyle style = [FWThemeManager.sharedInstance styleForTraitCollection:selfObject.traitCollection];
            FWThemeStyle oldStyle = [FWThemeManager.sharedInstance styleForTraitCollection:traitCollection];
            if (style == oldStyle) return;
            
            [selfObject.fw notifyThemeChanged:style];
            if (selfObject == [UIScreen mainScreen]) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
                [userInfo setObject:@(style) forKey:NSKeyValueChangeNewKey];
                [[NSNotificationCenter defaultCenter] postNotificationName:FWThemeChangedNotification object:selfObject userInfo:userInfo.copy];
            }
        };
    }];
}

- (NSString *)themeContextIdentifier
{
    return objc_getAssociatedObject(self.base, @selector(themeContextIdentifier));
}

- (void)setThemeContextIdentifier:(NSString *)identifier
{
    objc_setAssociatedObject(self.base, @selector(themeContextIdentifier), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<UITraitEnvironment>)themeContext
{
    FWWeakObject *value = objc_getAssociatedObject(self.base, @selector(themeContext));
    return value.object;
}

- (void)setThemeContext:(id<UITraitEnvironment>)themeContext
{
    if (@available(iOS 13, *)) {
        id<UITraitEnvironment> oldContext = self.themeContext;
        if (themeContext != oldContext) {
            objc_setAssociatedObject(self.base, @selector(themeContext), [[FWWeakObject alloc] initWithObject:themeContext], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            if (oldContext != nil) {
                [((NSObject *)oldContext).fw removeThemeListener:self.themeContextIdentifier];
                self.themeContextIdentifier = nil;
            }
            
            if (themeContext != nil) {
                __weak NSObject *weakBase = self.base;
                NSString *identifier = [((NSObject *)themeContext).fw addThemeListener:^(FWThemeStyle style) {
                    [weakBase.fw notifyThemeChanged:style];
                }];
                self.themeContextIdentifier = identifier;
            }
        }
    }
}

- (NSString *)addThemeListener:(void (^)(FWThemeStyle))listener
{
    if (@available(iOS 13, *)) {
        NSString *identifier = [[NSUUID UUID] UUIDString];
        NSMutableDictionary *listeners = [self innerThemeListeners:YES];
        [listeners setObject:[listener copy] forKey:identifier];
        return identifier;
    }
    return nil;
}

- (void)removeThemeListener:(NSString *)identifier
{
    if (@available(iOS 13, *)) {
        if (!identifier) return;
        NSMutableDictionary *listeners = [self innerThemeListeners:NO];
        [listeners removeObjectForKey:identifier];
    }
}

- (void)removeAllThemeListeners
{
    if (@available(iOS 13, *)) {
        NSMutableDictionary *listeners = [self innerThemeListeners:NO];
        [listeners removeAllObjects];
    }
}

- (NSMutableDictionary *)innerThemeListeners:(BOOL)lazyload NS_AVAILABLE_IOS(13_0)
{
    NSMutableDictionary *listeners = objc_getAssociatedObject(self.base, _cmd);
    if (!listeners && lazyload) {
        listeners = [NSMutableDictionary new];
        objc_setAssociatedObject(self.base, _cmd, listeners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return listeners;
}

- (void)notifyThemeChanged:(FWThemeStyle)style NS_AVAILABLE_IOS(13_0)
{
    // 1. 调用themeChanged钩子
    [self themeChanged:style];
    
    // 2. 调用themeListeners句柄
    NSMutableDictionary *listeners = [self innerThemeListeners:NO];
    [listeners enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        void (^listener)(FWThemeStyle) = obj;
        listener(style);
    }];
    
    // 3. 调用renderTheme渲染钩子
    if ([self.base respondsToSelector:@selector(renderTheme:)]) {
        [self.base renderTheme:style];
    }
}

- (void)themeChanged:(FWThemeStyle)style
{
    // 子类重写
}

@end

@implementation FWImageViewWrapper (FWTheme)

- (UIImage *)themeImage
{
    return objc_getAssociatedObject(self.base, @selector(themeImage));
}

- (void)setThemeImage:(UIImage *)themeImage
{
    objc_setAssociatedObject(self.base, @selector(themeImage), themeImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(themeAsset), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.base.image = themeImage.fw.image;
}

- (UIImageAsset *)themeAsset
{
    return objc_getAssociatedObject(self.base, @selector(themeAsset));
}

- (void)setThemeAsset:(UIImageAsset *)themeAsset
{
    objc_setAssociatedObject(self.base, @selector(themeAsset), themeAsset, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.base, @selector(themeImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.base.image = themeAsset.fw.image;
}

- (void)themeChanged:(FWThemeStyle)style
{
    [super themeChanged:style];
    
    if (self.themeImage && self.themeImage.fw.isThemeImage) {
        self.base.image = self.themeImage.fw.image;
    }
    if (self.themeAsset && self.themeAsset.fw.isThemeAsset) {
        self.base.image = self.themeAsset.fw.image;
    }
}

@end
