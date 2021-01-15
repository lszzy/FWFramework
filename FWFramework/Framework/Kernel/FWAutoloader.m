/*!
 @header     FWAutoloader.m
 @indexgroup FWFramework
 @brief      FWAutoloader
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/15
 */

#import "FWAutoloader.h"
#import <objc/runtime.h>

@implementation FWAutoloader

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[FWAutoloader sharedInstance] autoload];
    });
}

+ (FWAutoloader *)sharedInstance
{
    static FWAutoloader *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWAutoloader alloc] init];
    });
    return instance;
}

- (void)autoload
{
    NSMutableArray<NSString *> *methodNames = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList([FWAutoloader class], &methodCount);
    for (unsigned int i = 0; i < methodCount; ++i) {
        const char *methodChar = sel_getName(method_getName(methods[i]));
        if (!methodChar) continue;
        NSString *methodName = [NSString stringWithUTF8String:methodChar];
        if (methodName && [methodName hasPrefix:@"load"]) {
            [methodNames addObject:methodName];
        }
    }
    free(methods);
    
    for (NSString *methodName in methodNames) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString(methodName)];
#pragma clang diagnostic pop
    }
}

@end
