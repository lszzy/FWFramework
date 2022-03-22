/**
 @header     FWAutoloader.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/15
 */

#import "FWAutoloader.h"
#import <objc/runtime.h>

@protocol FWInnerAutoloadProtocol <NSObject>
@optional

+ (BOOL)autoload:(id)clazz;

@end

@interface FWAutoloader () <FWInnerAutoloadProtocol>

@end

BOOL FWAutoload(id clazz) {
    if ([FWAutoloader respondsToSelector:@selector(autoload:)]) {
        return [FWAutoloader autoload:clazz];
    }
    return NO;
}

static NSArray<NSString *> *fwStaticAutoloadMethods = nil;

@implementation FWAutoloader

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWAutoloader autoload];
    });
}

+ (void)autoload
{
    NSMutableArray<NSString *> *methodNames = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList([FWAutoloader class], &methodCount);
    for (unsigned int i = 0; i < methodCount; ++i) {
        const char *methodChar = sel_getName(method_getName(methods[i]));
        if (!methodChar) continue;
        NSString *methodName = [NSString stringWithUTF8String:methodChar];
        if (![methodName hasPrefix:@"load"]) continue;
        if ([methodName containsString:@":"]) continue;
        [methodNames addObject:methodName];
    }
    free(methods);
    [methodNames sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    fwStaticAutoloadMethods = [methodNames copy];
    
    FWAutoloader *autoloader = [[FWAutoloader alloc] init];
    for (NSString *methodName in methodNames) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [autoloader performSelector:NSSelectorFromString(methodName)];
#pragma clang diagnostic pop
    }
}

+ (NSString *)debugDescription
{
    NSMutableString *debugDescription = [[NSMutableString alloc] init];
    NSInteger debugCount = 0;
    for (NSString *methodName in fwStaticAutoloadMethods) {
        [debugDescription appendFormat:@"%@. %@\n", @(++debugCount), methodName];
    }
    return [NSString stringWithFormat:@"\n========== AUTOLOADER ==========\n%@========== AUTOLOADER ==========", debugDescription];
}

@end
