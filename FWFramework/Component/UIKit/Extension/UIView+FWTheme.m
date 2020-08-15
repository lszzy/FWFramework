/*!
 @header     UIView+FWTheme.m
 @indexgroup FWFramework
 @brief      UIView+FWTheme
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import "UIView+FWTheme.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - FWThemeObserver

@interface FWThemeObserver : NSObject

// 此处必须unsafe_unretained(类似weak，但如果引用的对象被释放会造成野指针，再次访问会crash)
@property (nonatomic, unsafe_unretained) id<UITraitEnvironment> traitEnvironment;

@property (nonatomic, strong) NSMutableDictionary *listeners;

- (NSString *)addListener:(void (^)(FWThemeStyle style))listener;

- (void)removeListener:(NSString *)identifier;

- (void)notifyListeners;

@end

@implementation FWThemeObserver

- (instancetype)initWithTraitEnvironment:(id<UITraitEnvironment>)traitEnvironment
{
    self = [super init];
    if (self) {
        _traitEnvironment = traitEnvironment;
        _listeners = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    [self.listeners removeAllObjects];
}

- (NSString *)addListener:(void (^)(FWThemeStyle))listener
{
    if (!listener) return;
    NSString *identifier = [[NSUUID UUID] UUIDString];
    [self.listeners setObject:[listener copy] forKey:identifier];
    return identifier;
}

- (void)removeListener:(NSString *)identifier
{
    if (!identifier) return;
    [self.listeners removeObjectForKey:identifier];
}

- (void)notifyListeners
{
    FWThemeStyle style = self.traitEnvironment.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
    [(NSObject *)self.traitEnvironment fwThemeChanged:style];
    [self.listeners enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        void (^listener)(FWThemeStyle) = objc;
        listener(style);
    }];
}

@end

#pragma mark - NSObject+FWTheme

@implementation NSObject (FWTheme)

- (FWThemeObserver *)fwInnerThemeObserver:(BOOL)lazyload
{
    if (![self conformsToProtocol:@protocol(UITraitEnvironment)]) return nil;
    
    FWThemeObserver *observer = objc_getAssociatedObject(self, _cmd);
    if (!observer && lazyload) {
        observer = [[FWThemeObserver alloc] initWithTraitEnvironment:self];
        objc_setAssociatedObject(self, _cmd, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return observer;
}

- (BOOL)fwThemeSubscribed
{
    if ([self conformsToProtocol:@protocol(UITraitEnvironment)]) return YES;
    
    return [objc_getAssociatedObject(self, @selector(fwThemeSubscribed)) boolValue];
}

- (void)setFwThemeSubscribed:(BOOL)fwThemeSubscribed
{
    if ([self conformsToProtocol:@protocol(UITraitEnvironment)]) return;
    
    if (fwThemeSubscribed != self.fwThemeSubscribed) {
        objc_setAssociatedObject(self, @selector(fwThemeSubscribed), @(fwThemeSubscribed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if (fwThemeEnabled) {
            //__weak __typeof__(self) self_weak_ = self;
            //__typeof__(self) self = self_weak_;
        } else {
            
        }
    }
}

- (NSString *)fwAddThemeListener:(void (^)(FWThemeStyle))listener
{
    [[self fwInnerThemeObserver:YES] addListener:listener];
}

- (void)fwRemoveThemeListener:(NSString *)identifier
{
    [[self fwInnerThemeObserver:YES] removeListener:identifier];
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    // 子类重写
}

@end

#pragma mark - FWThemeManager

NSString *const FWThemeChangedNotification = @"FWThemeChangedNotification";

static NSMutableDictionary<NSString *, UIColor *> *fwStaticNameColors = nil;
static NSMutableDictionary<NSString *, UIImage *> *fwStaticNameImages = nil;

@interface FWThemeManager ()

@property (nonatomic, strong) id<UITraitEnvironment> traitEnvironment;

@end

@implementation FWThemeManager

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fwStaticNameColors = [NSMutableDictionary new];
        fwStaticNameImages = [NSMutableDictionary new];
        [FWThemeManager sharedInstance];
        
        if (@available(iOS 13, *)) {
            FWSwizzleClass(UIView, @selector(traitCollectionDidChange:), FWSwizzleReturn(void), FWSwizzleArgs(UITraitCollection *traitCollection), FWSwizzleCode({
                FWSwizzleOriginal(traitCollection);
                
                if ([selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) {
                    FWThemeObserver *observer = [selfObject fwInnerThemeObserver:NO];
                    if (observer) [observer notifyListeners];
                }
            }));
            
            FWSwizzleClass(UIViewController, @selector(traitCollectionDidChange:), FWSwizzleReturn(void), FWSwizzleArgs(UITraitCollection *traitCollection), FWSwizzleCode({
                FWSwizzleOriginal(traitCollection);
                
                if ([selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) {
                    FWThemeObserver *observer = [selfObject fwInnerThemeObserver:NO];
                    if (observer) [observer notifyListeners];
                }
            }));
            
            FWSwizzleClass(UIScreen, @selector(traitCollectionDidChange:), FWSwizzleReturn(void), FWSwizzleArgs(UITraitCollection *traitCollection), FWSwizzleCode({
                FWSwizzleOriginal(traitCollection);
                
                if ([selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) {
                    FWThemeObserver *observer = [selfObject fwInnerThemeObserver:NO];
                    if (observer) [observer notifyListeners];
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
        // _traitEnvironment = [UIView new];
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
        FWThemeStyle style = self.style;
        
        if (@available(iOS 13, *)) {
            if (style != oldStyle) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
                [userInfo setObject:@(style) forKey:NSKeyValueChangeNewKey];
                [[NSNotificationCenter defaultCenter] postNotificationName:FWThemeChangedNotification object:self userInfo:userInfo.copy];
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
