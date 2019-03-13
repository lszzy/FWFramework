/*!
 @header     NSBundle+FWFramework.m
 @indexgroup FWFramework
 @brief      NSBundle分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import "NSBundle+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

NSString *const FWLocalizedLanguageChangedNotification = @"FWLocalizedLanguageChangedNotification";

#pragma mark - FWInnerBundle

@interface FWInnerBundle : NSBundle

@end

@implementation FWInnerBundle

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    NSBundle *bundle = objc_getAssociatedObject(self, @selector(localizedStringForKey:value:table:));
    if (bundle) {
        return [bundle localizedStringForKey:key value:value table:tableName];
    } else {
        return [super localizedStringForKey:key value:value table:tableName];
    }
}

@end

#pragma mark - NSBundle+FWFramework

@implementation NSBundle (FWFramework)

#pragma mark - Accessor

- (BOOL (^)(NSBundle *bundle))fwCustomDetectorBlock
{
    return objc_getAssociatedObject(self, @selector(fwCustomDetectorBlock));
}

- (void)setFwCustomDetectorBlock:(BOOL (^)(NSBundle *bundle))detector
{
    objc_setAssociatedObject(self, @selector(fwCustomDetectorBlock), detector, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString * (^)(NSBundle *bundle, NSString *language))fwCustomFinderBlock
{
    return objc_getAssociatedObject(self, @selector(fwCustomFinderBlock));
}

- (void)setFwCustomFinderBlock:(NSString * (^)(NSBundle *bundle, NSString *language))finder
{
    objc_setAssociatedObject(self, @selector(fwCustomFinderBlock), finder, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - Public

+ (NSString *)fwSystemLanguage
{
    return [NSLocale preferredLanguages].firstObject;
}

+ (NSString *)fwLocalizedLanguage
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalizedLanguage"];
}

+ (void)fwSetLocalizedLanguage:(NSString *)language
{
    if (language) {
        [[NSUserDefaults standardUserDefaults] setObject:language forKey:@"FWLocalizedLanguage"];
        [[NSUserDefaults standardUserDefaults] setObject:@[language] forKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWLocalizedLanguage"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self fwApplyLocalizedLanguage:language];
}

+ (void)fwLoadLocalizedLanguage
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *language = [self fwLocalizedLanguage];
        if (language) {
            [self fwApplyLocalizedLanguage:language];
        }
    });
}

+ (void)fwSetCustomDetectorBlock:(BOOL (^)(NSBundle *))detector
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 动态替换initWithPath:拦截处理。如果不需要处理三方SDK和系统组件，则不替换
        [self fwSwizzleInstanceMethod:@selector(initWithPath:) with:@selector(fwInnerInitWithPath:)];
    });
    
    [NSBundle.mainBundle setFwCustomDetectorBlock:detector];
}

+ (void)fwSetCustomFinderBlock:(NSString *(^)(NSBundle *, NSString *))finder
{
    [NSBundle.mainBundle setFwCustomFinderBlock:finder];
}

#pragma mark - Private

+ (void)fwApplyLocalizedLanguage:(NSString *)language
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 默认只处理mainBundle，mainBundle不走通知方式
        object_setClass(NSBundle.mainBundle, [FWInnerBundle class]);
    });
    
    // 处理mainBundle语言
    [NSBundle.mainBundle fwLocalizedLanguageChanged:language];
    
    // 发送语言改变通知，通知所有bundle监听者
    [[NSNotificationCenter defaultCenter] postNotificationName:FWLocalizedLanguageChangedNotification object:language];
}

- (instancetype)fwInnerInitWithPath:(NSString *)path
{
    // bundle不存在或者已经处理过，直接返回
    NSBundle *bundle = [self fwInnerInitWithPath:path];
    if (!bundle || [bundle isKindOfClass:[FWInnerBundle class]]) {
        return bundle;
    }
    
    // 检测bundle是否需要查找本地化语言
    BOOL (^detector)(NSBundle *bundle) = [NSBundle.mainBundle fwCustomDetectorBlock];
    if (detector && detector(bundle)) {
        if (![bundle isKindOfClass:[FWInnerBundle class]]) {
            object_setClass(bundle, [FWInnerBundle class]);
            // 监听语言改变通知，切换bundle语言
            [[NSNotificationCenter defaultCenter] addObserver:bundle selector:@selector(fwLocalizedLanguageChanged:) name:FWLocalizedLanguageChangedNotification object:nil];
        }
    }
    return bundle;
}

- (void)fwLocalizedLanguageChanged:(id)parameter
{
    // 切换bundle语言，兼容通知和字符串
    NSString *language = nil;
    if ([parameter isKindOfClass:[NSNotification class]]) {
        parameter = ((NSNotification *)parameter).object;
    }
    if ([parameter isKindOfClass:[NSString class]]) {
        language = (NSString *)parameter;
    }
    
    // 查找bundle是否支持该语言
    NSBundle *bundle = language ? [NSBundle bundleWithPath:[self pathForResource:language ofType:@"lproj"]] : nil;
    if (!bundle) {
        NSString * (^finder)(NSBundle *bundle, NSString *language) = [NSBundle.mainBundle fwCustomFinderBlock];
        if (finder) {
            NSString *bundleName = finder(bundle, language);
            bundle = bundleName ? [NSBundle bundleWithPath:[self pathForResource:bundleName ofType:@"lproj"]] : nil;
        }
    }
    objc_setAssociatedObject(self, @selector(localizedStringForKey:value:table:), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
