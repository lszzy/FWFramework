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

- (instancetype)initWithTraitEnvironment:(NSObject *)traitEnvironment
{
    self = [super init];
    if (self) {
        if (traitEnvironment && [traitEnvironment conformsToProtocol:@protocol(UITraitEnvironment)]) {
            _traitEnvironment = (id<UITraitEnvironment>)traitEnvironment;
        } else {
            _traitEnvironment = [UIScreen mainScreen];
        }
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
    if (@available(iOS 13, *)) {
        FWThemeStyle style = self.traitEnvironment.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
        [(NSObject *)self.traitEnvironment fwThemeChanged:style];
        [self.listeners enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            void (^listener)(FWThemeStyle) = obj;
            listener(style);
        }];
    }
}

@end

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

#pragma mark - NSObject+FWTheme

@implementation NSObject (FWTheme)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fwStaticNameColors = [NSMutableDictionary new];
        fwStaticNameImages = [NSMutableDictionary new];
        
        if (@available(iOS 13, *)) {
            FWSwizzleClass(UIScreen, @selector(traitCollectionDidChange:), FWSwizzleReturn(void), FWSwizzleArgs(UITraitCollection *traitCollection), FWSwizzleCode({
                FWSwizzleOriginal(traitCollection);
                
                if ([selfObject.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:traitCollection]) {
                    FWThemeObserver *observer = [selfObject fwInnerThemeObserver:NO];
                    if (observer) [observer notifyListeners];
                    
                    if (selfObject == [UIScreen mainScreen]) {
                        FWThemeStyle oldStyle = traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
                        FWThemeStyle style = selfObject.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? FWThemeStyleDark : FWThemeStyleLight;
                        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                        [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
                        [userInfo setObject:@(style) forKey:NSKeyValueChangeNewKey];
                        [[NSNotificationCenter defaultCenter] postNotificationName:FWThemeChangedNotification object:selfObject userInfo:userInfo.copy];
                    }
                }
            }));
            
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
        }
    });
}

- (FWThemeObserver *)fwInnerThemeObserver:(BOOL)lazyload
{
    if (@available(iOS 13, *)) {
        FWThemeObserver *observer = objc_getAssociatedObject(self, _cmd);
        if (!observer && lazyload) {
            observer = [[FWThemeObserver alloc] initWithTraitEnvironment:self];
            objc_setAssociatedObject(self, _cmd, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return observer;
    }
    return nil;
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
        
//        if (fwThemeSubscribed) {
//            __weak __typeof__(self) self_weak_ = self;
//            __typeof__(self) self = self_weak_;
//        } else {
//
//        }
    }
}

- (NSString *)fwAddThemeListener:(void (^)(FWThemeStyle))listener
{
    if (@available(iOS 13, *)) {
        return [[self fwInnerThemeObserver:YES] addListener:listener];
    }
    return nil;
}

- (void)fwRemoveThemeListener:(NSString *)identifier
{
    if (@available(iOS 13, *)) {
        [[self fwInnerThemeObserver:YES] removeListener:identifier];
    }
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    // 子类重写
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
