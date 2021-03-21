/*!
 @header     FWLoader.m
 @indexgroup FWFramework
 @brief      FWLoader
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/15
 */

#import "FWLoader.h"
#import <objc/runtime.h>

@implementation FWLoader

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWLoader autoload];
    });
}

+ (void)autoload
{
    NSMutableArray<NSString *> *methodNames = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList([FWLoader class], &methodCount);
    for (unsigned int i = 0; i < methodCount; ++i) {
        const char *methodChar = sel_getName(method_getName(methods[i]));
        if (!methodChar) continue;
        NSString *methodName = [NSString stringWithUTF8String:methodChar];
        if (methodName && [methodName hasPrefix:@"load"]) {
            [methodNames addObject:methodName];
        }
    }
    free(methods);
    
    [methodNames sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    FWLoader *loader = [[FWLoader alloc] init];
    for (NSString *methodName in methodNames) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [loader performSelector:NSSelectorFromString(methodName)];
#pragma clang diagnostic pop
    }
}

@end
