/*!
 @header     NSBundle+FWLanguage.m
 @indexgroup FWFramework
 @brief      NSBundle+FWLanguage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/4/21
 */

#import "NSBundle+FWLanguage.h"
#import "NSObject+FWSwizzle.h"
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

#pragma mark - NSBundle+FWLanguage

@implementation NSBundle (FWLanguage)

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

+ (NSString *)fwLocalizedLanguage
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalizedLanguage"];
}

+ (void)fwSetLocalizedLanguage:(NSString *)language
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

@end

#pragma mark - NSBundle+FWBundle

@implementation NSBundle (FWBundle)

+ (void)fwSetBundleFilter:(BOOL (^)(NSBundle *))filter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 动态替换initWithPath:拦截处理。如果不需要处理三方SDK和系统组件，则不替换
        [NSObject fwSwizzleInstanceMethod:@selector(initWithPath:) in:[NSBundle class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^NSBundle *(NSBundle *selfObject, NSString *path) {
                // bundle不存在或者已经处理过，直接返回
                NSBundle *bundle = ((NSBundle *(*)(id, SEL, NSString *))originalIMP())(selfObject, originalCMD, path);
                if (!bundle || [bundle isKindOfClass:[FWInnerBundle class]]) {
                    return bundle;
                }
                
                // 过滤bundle是否需要查找本地化语言
                BOOL (^filter)(NSBundle *bundle) = objc_getAssociatedObject(NSBundle.mainBundle, @selector(fwSetBundleFilter:));
                if (filter && filter(bundle)) {
                    if (![bundle isKindOfClass:[FWInnerBundle class]]) {
                        // 处理bundle语言，使用通知方式
                        object_setClass(bundle, [FWInnerBundle class]);
                        
                        // 自动加载上一次语言设置
                        NSString *language = [NSBundle fwLocalizedLanguage];
                        if (language) {
                            [bundle fwLocalizedLanguageChanged:[NSNotification notificationWithName:FWLocalizedLanguageChangedNotification object:language]];
                        }
                        
                        // 监听语言改变通知，切换bundle语言
                        [[NSNotificationCenter defaultCenter] addObserver:bundle selector:@selector(fwLocalizedLanguageChanged:) name:FWLocalizedLanguageChangedNotification object:nil];
                    }
                }
                return bundle;
            };
        }];
    });
    
    // 保存自定义过滤block到mainBundle
    objc_setAssociatedObject(NSBundle.mainBundle, @selector(fwSetBundleFilter:), filter, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (void)fwSetBundleFinder:(NSString *(^)(NSBundle *, NSString *))finder
{
    // 保存自定义查找block到mainBundle
    objc_setAssociatedObject(NSBundle.mainBundle, @selector(fwSetBundleFinder:), finder, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSBundle *)fwLocalizedBundle:(NSString *)language
{
    return language ? [NSBundle bundleWithPath:[self pathForResource:language ofType:@"lproj"]] : nil;
}

- (void)fwLocalizedLanguageChanged:(NSNotification *)notification
{
    NSString *language = [notification.object isKindOfClass:[NSString class]] ? notification.object : nil;
    NSBundle *bundle = [self fwLocalizedBundle:language];
    if (!bundle) {
        NSString * (^finder)(NSBundle *bundle, NSString *language) = objc_getAssociatedObject(NSBundle.mainBundle, @selector(fwSetBundleFinder:));
        if (finder) {
            NSString *bundleName = finder(self, language);
            bundle = [self fwLocalizedBundle:bundleName];
        }
    }
    objc_setAssociatedObject(self, @selector(localizedStringForKey:value:table:), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
