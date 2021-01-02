/*!
 @header     FWLanguage.m
 @indexgroup FWFramework
 @brief      FWLanguage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/4/21
 */

#import "FWLanguage.h"
#import "FWSwizzle.h"
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

#pragma mark - NSLocale+FWLanguage

static NSString *fwStaticPreferredLanguage = nil;

@interface NSLocale (FWLanguage)

@end

@implementation NSLocale (FWLanguage)

+ (NSArray<NSString *> *)fwInnerPreferredLanguages
{
    NSArray<NSString *> *languages = [self fwInnerPreferredLanguages];
    if (fwStaticPreferredLanguage && fwStaticPreferredLanguage.length > 0) {
        return [NSArray arrayWithObjects:fwStaticPreferredLanguage, nil];
    }
    return languages;
}

@end

#pragma mark - NSBundle+FWLanguage

@implementation NSBundle (FWLanguage)

#pragma mark - Main

+ (void)load
{
    // 自动加载上一次语言设置，不发送通知
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *language = [self fwLocalizedLanguage];
        if (language) {
            [self fwLoadLocalizedLanguage:language];
        }
    });
}

+ (NSString *)fwSystemLanguage
{
    return [NSLocale preferredLanguages].firstObject;
}

+ (void)setFwSystemLanguage:(NSString *)language
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 动态替换preferredLanguages，支持自定义语言
        [NSLocale fwSwizzleClassMethod:@selector(preferredLanguages) with:@selector(fwInnerPreferredLanguages)];
    });
    
    fwStaticPreferredLanguage = language;
}

+ (NSString *)fwLocalizedLanguage
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalizedLanguage"];
}

+ (void)setFwLocalizedLanguage:(NSString *)language
{
    // 保存并加载当前语言设置
    if (language) {
        [[NSUserDefaults standardUserDefaults] setObject:language forKey:@"FWLocalizedLanguage"];
        [[NSUserDefaults standardUserDefaults] setObject:@[language] forKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWLocalizedLanguage"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self fwLoadLocalizedLanguage:language];
    
    // 发送语言改变通知，通知所有bundle监听者
    [[NSNotificationCenter defaultCenter] postNotificationName:FWLocalizedLanguageChangedNotification object:language];
}

+ (void)fwLoadLocalizedLanguage:(NSString *)language
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 默认只处理mainBundle，mainBundle不走通知方式
        object_setClass(NSBundle.mainBundle, [FWInnerBundle class]);
    });
    
    // 加载mainBundle对应语言文件，加载失败使用默认
    NSBundle *bundle = language ? [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:language ofType:@"lproj"]] : nil;
    objc_setAssociatedObject(NSBundle.mainBundle, @selector(localizedStringForKey:value:table:), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSString *)fwLocalizedString:(NSString *)key
{
    return [self fwLocalizedString:key table:nil];
}

+ (NSString *)fwLocalizedString:(NSString *)key table:(NSString *)table
{
    return [[NSBundle mainBundle] localizedStringForKey:key value:nil table:table];
}

#pragma mark - Bundle

+ (instancetype)fwBundleWithName:(NSString *)name
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:([name hasSuffix:@".bundle"] ? nil : @"bundle")];
    return path ? [NSBundle bundleWithPath:path] : nil;
}

+ (instancetype)fwBundleWithClass:(Class)clazz name:(NSString *)name
{
    NSBundle *bundle = [NSBundle bundleForClass:clazz];
    if (name.length == 0) return bundle;
    NSString *path = [bundle pathForResource:name ofType:([name hasSuffix:@".bundle"] ? nil : @"bundle")];
    return path ? [NSBundle bundleWithPath:path] : nil;
}

- (NSBundle *)fwLocalizedBundle
{
    if (![self isKindOfClass:[FWInnerBundle class]]) {
        // 处理bundle语言，使用通知方式
        object_setClass(self, [FWInnerBundle class]);
        
        // 自动加载上一次语言设置
        NSString *language = [NSBundle fwLocalizedLanguage];
        if (language) {
            [self fwLocalizedLanguageChanged:[NSNotification notificationWithName:FWLocalizedLanguageChangedNotification object:language]];
        }
        
        // 监听语言改变通知，切换bundle语言
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fwLocalizedLanguageChanged:) name:FWLocalizedLanguageChangedNotification object:nil];
    }
    return self;
}

- (void)fwLocalizedLanguageChanged:(NSNotification *)notification
{
    NSString *language = [notification.object isKindOfClass:[NSString class]] ? notification.object : nil;
    NSBundle *bundle = [self fwLocalizedBundleWithLanguage:language];
    objc_setAssociatedObject(self, @selector(localizedStringForKey:value:table:), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSBundle *)fwLocalizedBundleWithLanguage:(NSString *)language
{
    return language ? [NSBundle bundleWithPath:[self pathForResource:language ofType:@"lproj"]] : nil;
}

+ (NSString *)fwLocalizedString:(NSString *)key bundle:(NSBundle *)bundle
{
    return [self fwLocalizedString:key table:nil bundle:bundle];
}

+ (NSString *)fwLocalizedString:(NSString *)key table:(NSString *)table bundle:(NSBundle *)bundle
{
    if (bundle) {
        return [[bundle fwLocalizedBundle] localizedStringForKey:key value:nil table:table];
    } else {
        return [[NSBundle mainBundle] localizedStringForKey:key value:nil table:table];
    }
}

@end
