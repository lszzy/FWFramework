//
//  Theme.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "Theme.h"
#import "Navigator.h"
#import "Swizzle.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIWindow ()

@property (class, nonatomic, readwrite, nullable) UIWindow *__fw_mainWindow;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWThemeManager

NSNotificationName const __FWThemeChangedNotification = @"FWThemeChangedNotification";

@implementation __FWThemeManager

+ (__FWThemeManager *)sharedInstance
{
    static __FWThemeManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWThemeManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"__FWThemeMode"] integerValue];
    }
    return self;
}

- (void)setOverrideWindow:(BOOL)overrideWindow
{
    if (overrideWindow != _overrideWindow) {
        _overrideWindow = overrideWindow;
        
        if (@available(iOS 13, *)) {
            UIUserInterfaceStyle style = UIUserInterfaceStyleUnspecified;
            if (overrideWindow && self.mode != __FWThemeModeSystem) {
                style = self.mode == __FWThemeModeDark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
            }
            UIWindow.__fw_mainWindow.overrideUserInterfaceStyle = style;
        }
    }
}

- (void)setMode:(__FWThemeMode)mode
{
    if (mode != _mode) {
        [[NSUserDefaults standardUserDefaults] setObject:@(mode) forKey:@"__FWThemeMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        __FWThemeStyle oldStyle = self.style;
        _mode = mode;
        __FWThemeStyle style = self.style;
        
        if (@available(iOS 13, *)) {
            if (style != oldStyle) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:@(oldStyle) forKey:NSKeyValueChangeOldKey];
                [userInfo setObject:@(style) forKey:NSKeyValueChangeNewKey];
                [[NSNotificationCenter defaultCenter] postNotificationName:__FWThemeChangedNotification object:self userInfo:userInfo.copy];
            }
            
            if (self.overrideWindow) {
                _overrideWindow = NO;
                [self setOverrideWindow:YES];
            }
        }
    }
}

- (__FWThemeStyle)style
{
    return [self styleForTraitCollection:nil];
}

- (__FWThemeStyle)styleForTraitCollection:(UITraitCollection *)traitCollection
{
    if (self.mode == __FWThemeModeSystem) {
        if (@available(iOS 13, *)) {
            if (!traitCollection) traitCollection = UITraitCollection.currentTraitCollection;
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? __FWThemeStyleDark : __FWThemeStyleLight;
        } else {
            return __FWThemeStyleLight;
        }
    } else {
        return (__FWThemeStyle)self.mode;
    }
}

@end

@interface __FWThemeObject ()

@property (nonatomic, copy) id (^provider)(__FWThemeStyle);

@end

@implementation __FWThemeObject

+ (instancetype)objectWithLight:(id)light dark:(id)dark
{
    return [self objectWithProvider:^id (__FWThemeStyle style) {
        return style == __FWThemeStyleDark ? dark : light;
    }];
}

+ (instancetype)objectWithProvider:(id (^)(__FWThemeStyle))provider
{
    __FWThemeObject *object = [[__FWThemeObject alloc] init];
    object.provider = provider;
    return object;
}

- (id)object
{
    return self.provider ? self.provider(__FWThemeManager.sharedInstance.style) : nil;
}

- (id)objectForStyle:(__FWThemeStyle)style
{
    return self.provider ? self.provider(style) : nil;
}

@end

@implementation NSObject (__FWTheme)

@end
