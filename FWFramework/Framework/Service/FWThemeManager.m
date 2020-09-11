/*!
 @header     FWThemeManager.m
 @indexgroup FWFramework
 @brief      FWThemeManager
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import "FWThemeManager.h"
#import "FWRouter.h"
#import "FWProxy.h"
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
    return [self style:nil];
}

- (FWThemeStyle)style:(UITraitCollection *)traitCollection
{
    if (self.mode == FWThemeModeSystem) {
        if (@available(iOS 13, *)) {
            if (!traitCollection) traitCollection = UITraitCollection.currentTraitCollection;
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
        } else {
            return FWThemeStyleLight;
        }
    } else {
        return self.mode == FWThemeModeDark ? FWThemeStyleDark : FWThemeStyleLight;
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

- (id)object:(FWThemeStyle)style
{
    return self.provider ? self.provider(style) : nil;
}

@end

#pragma mark - UIColor+FWTheme

static BOOL fwStaticColorARGB = NO;

@implementation UIColor (FWTheme)

+ (UIColor *)fwColorWithHex:(long)hex
{
    return [UIColor fwColorWithHex:hex alpha:1.0f];
}

+ (UIColor *)fwColorWithHex:(long)hex alpha:(CGFloat)alpha
{
    float red = ((float)((hex & 0xFF0000) >> 16)) / 255.0;
    float green = ((float)((hex & 0xFF00) >> 8)) / 255.0;
    float blue = ((float)(hex & 0xFF)) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (void)fwColorStandardARGB:(BOOL)enabled
{
    fwStaticColorARGB = enabled;
}

+ (UIColor *)fwColorWithHexString:(NSString *)hexString
{
    return [UIColor fwColorWithHexString:hexString alpha:1.0f];
}

+ (UIColor *)fwColorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha
{
    // 处理参数
    NSString *string = hexString ? hexString.uppercaseString : @"";
    if ([string hasPrefix:@"0X"]) {
        string = [string substringFromIndex:2];
    }
    if ([string hasPrefix:@"#"]) {
        string = [string substringFromIndex:1];
    }
    
    // 检查长度
    NSUInteger length = string.length;
    if (length != 3 && length != 4 && length != 6 && length != 8) {
        return [UIColor clearColor];
    }
    
    // 解析颜色
    NSString *strR = nil, *strG = nil, *strB = nil, *strA = nil;
    if (length < 5) {
        // ARGB
        if (fwStaticColorARGB && length == 4) {
            string = [NSString stringWithFormat:@"%@%@", [string substringWithRange:NSMakeRange(1, 3)], [string substringWithRange:NSMakeRange(0, 1)]];
        }
        // RGB|RGBA
        NSString *tmpR = [string substringWithRange:NSMakeRange(0, 1)];
        NSString *tmpG = [string substringWithRange:NSMakeRange(1, 1)];
        NSString *tmpB = [string substringWithRange:NSMakeRange(2, 1)];
        strR = [NSString stringWithFormat:@"%@%@", tmpR, tmpR];
        strG = [NSString stringWithFormat:@"%@%@", tmpG, tmpG];
        strB = [NSString stringWithFormat:@"%@%@", tmpB, tmpB];
        if (length == 4) {
            NSString *tmpA = [string substringWithRange:NSMakeRange(3, 1)];
            strA = [NSString stringWithFormat:@"%@%@", tmpA, tmpA];
        }
    } else {
        // AARRGGBB
        if (fwStaticColorARGB && length == 8) {
            string = [NSString stringWithFormat:@"%@%@", [string substringWithRange:NSMakeRange(2, 6)], [string substringWithRange:NSMakeRange(0, 2)]];
        }
        // RRGGBB|RRGGBBAA
        strR = [string substringWithRange:NSMakeRange(0, 2)];
        strG = [string substringWithRange:NSMakeRange(2, 2)];
        strB = [string substringWithRange:NSMakeRange(4, 2)];
        if (length == 8) {
            strA = [string substringWithRange:NSMakeRange(6, 2)];
        }
    }
    
    // 解析颜色
    unsigned int r, g, b;
    [[NSScanner scannerWithString:strR] scanHexInt:&r];
    [[NSScanner scannerWithString:strG] scanHexInt:&g];
    [[NSScanner scannerWithString:strB] scanHexInt:&b];
    float fr = (r * 1.0f) / 255.0f;
    float fg = (g * 1.0f) / 255.0f;
    float fb = (b * 1.0f) / 255.0f;
    
    // 解析透明度，字符串的透明度优先级高于alpha参数
    if (strA) {
        unsigned int a;
        [[NSScanner scannerWithString:strA] scanHexInt:&a];
        // 计算十六进制对应透明度
        alpha = (a * 1.0f) / 255.0f;
    }
    
    return [UIColor colorWithRed:fr green:fg blue:fb alpha:alpha];
}

+ (UIColor *)fwColorWithString:(NSString *)string
{
    return [UIColor fwColorWithString:string alpha:1.0f];
}

+ (UIColor *)fwColorWithString:(NSString *)string alpha:(CGFloat)alpha
{
    // 颜色值
    SEL colorSelector = NSSelectorFromString([NSString stringWithFormat:@"%@Color", string]);
    if ([[UIColor class] respondsToSelector:colorSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIColor *color = [[UIColor class] performSelector:colorSelector];
#pragma clang diagnostic pop
        return alpha < 1.0f ? [color colorWithAlphaComponent:alpha] : color;
    }
    
    // 十六进制
    return [UIColor fwColorWithHexString:string alpha:alpha];
}

- (long)fwHexValue
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    int8_t red = r * 255;
    uint8_t green = g * 255;
    uint8_t blue = b * 255;
    return (red << 16) + (green << 8) + blue;
}

- (CGFloat)fwAlphaValue
{
    return CGColorGetAlpha(self.CGColor);
}

- (NSString *)fwHexString
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

- (NSString *)fwHexStringWithAlpha
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    if (a >= 1.0) {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
    } else if (fwStaticColorARGB) {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX", lround(a * 255), lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
    } else {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lround(a * 255)];
    }
}

#pragma mark - Theme

+ (UIColor *)fwThemeLight:(UIColor *)light dark:(UIColor *)dark
{
    return [self fwThemeColor:^UIColor *(FWThemeStyle style) {
        return style == FWThemeStyleDark ? dark : light;
    }];
}

+ (UIColor *)fwThemeColor:(UIColor * (^)(FWThemeStyle))provider
{
    if (@available(iOS 13, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            return provider([FWThemeManager.sharedInstance style:traitCollection]);
        }];
    }
    return provider(FWThemeManager.sharedInstance.style);
}

+ (UIColor *)fwThemeNamed:(NSString *)name
{
    return [self fwThemeColor:^UIColor *(FWThemeStyle style) {
        UIColor *color = nil;
        if (@available(iOS 13, *)) {
            UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
            color = [[UIColor colorNamed:name] resolvedColorWithTraitCollection:traitCollection];
        }
        if (!color) {
            if (@available(iOS 11.0, *)) { color = [UIColor colorNamed:name]; }
            if (!color) { color = fwStaticNameColors[name]; }
        }
        return color ?: UIColor.clearColor;
    }];
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

- (UIColor *)fwThemeColor:(FWThemeStyle)style
{
    if (@available(iOS 13, *)) {
        UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
        return [self resolvedColorWithTraitCollection:traitCollection];
    }
    return self;
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
    UIImage *image = provider(FWThemeManager.sharedInstance.style) ?: [UIImage new];
    image.fwThemeObject = [FWThemeObject<UIImage *> objectWithProvider:provider];
    return image;
}

+ (UIImage *)fwThemeNamed:(NSString *)name
{
    return [self fwThemeImage:^UIImage * (FWThemeStyle style) {
        UIImage *image = nil;
        if (@available(iOS 13, *)) {
            UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:style == FWThemeStyleDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
            image = [[UIImage imageNamed:name] imageWithConfiguration:traitCollection.imageConfiguration];
        }
        if (!image) {
            image = [UIImage imageNamed:name];
            if (!image) image = fwStaticNameImages[name];
        }
        return image;
    }];
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

- (FWThemeObject<UIImage *> *)fwThemeObject
{
    return objc_getAssociatedObject(self, @selector(fwThemeObject));
}

- (void)setFwThemeObject:(FWThemeObject<UIImage *> *)fwThemeObject
{
    objc_setAssociatedObject(self, @selector(fwThemeObject), fwThemeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UIFont+FWTheme

UIFont * FWFontLight(CGFloat size) { return [UIFont systemFontOfSize:size weight:UIFontWeightLight]; }
UIFont * FWFontRegular(CGFloat size) { return [UIFont systemFontOfSize:size]; }
UIFont * FWFontBold(CGFloat size) { return [UIFont boldSystemFontOfSize:size]; }
UIFont * FWFontItalic(CGFloat size) { return [UIFont italicSystemFontOfSize:size]; }

@implementation UIFont (FWTheme)

+ (UIFont *)fwLightFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightLight];
}

+ (UIFont *)fwFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size];
}

+ (UIFont *)fwBoldFontOfSize:(CGFloat)size
{
    return [UIFont boldSystemFontOfSize:size];
}

+ (UIFont *)fwItalicFontOfSize:(CGFloat)size
{
    return [UIFont italicSystemFontOfSize:size];
}

+ (UIFont *)fwFontOfSize:(CGFloat)size weight:(UIFontWeight)weight
{
    return [UIFont systemFontOfSize:size weight:weight];
}

@end

#pragma mark - NSObject+FWTheme

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
            // UIImageView内部重写traitCollectionDidChange:时未调用super导致不回调fwThemeChanged:
            [self fwThemeSwizzleClass:[UIImageView class]];
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
            FWThemeStyle style = [FWThemeManager.sharedInstance style:selfObject.traitCollection];
            FWThemeStyle oldStyle = [FWThemeManager.sharedInstance style:traitCollection];
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
    self.image = fwThemeImage;
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeImage.fwThemeObject != nil) {
        self.image = self.fwThemeImage.fwThemeObject.object;
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
    if (self.fwThemeContents.fwThemeObject != nil) {
        self.contents = (id)self.fwThemeContents.fwThemeObject.object.CGImage;
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
