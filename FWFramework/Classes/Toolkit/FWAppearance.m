/**
 @header     FWAppearance.m
 @indexgroup FWFramework
      FWAppearance
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import "FWAppearance.h"
#import <objc/runtime.h>

@implementation FWAppearance

+ (id)appearanceForClass:(Class)aClass {
    static NSMutableDictionary *appearances = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appearances = [[NSMutableDictionary alloc] init];
    });
    
    NSString *className = NSStringFromClass(aClass);
    id appearance = appearances[className];
    if (!appearance) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@:%@:", @"appearanceForClass", @"withContainerList"]);
        appearance = [NSClassFromString(@"_UIAppearance") performSelector:selector withObject:aClass withObject:nil];
        appearances[className] = appearance;
#pragma clang diagnostic pop
    }
    return appearance;
}

@end

@implementation NSObject (FWAppearance)

- (void)fwApplyAppearance {
    Class class = self.class;
    if ([class respondsToSelector:@selector(appearance)]) {
        SEL appearanceGuideClassSelector = NSSelectorFromString(@"_appearanceGuideClass");
        if (!class_respondsToSelector(class, appearanceGuideClassSelector)) {
            const char * typeEncoding = method_getTypeEncoding(class_getInstanceMethod(UIView.class, appearanceGuideClassSelector));
            class_addMethod(class, appearanceGuideClassSelector, imp_implementationWithBlock(^Class(void) {
                return nil;
            }), typeEncoding);
        }
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@:%@:", @"applyInvocationsTo", @"window"]);
        [NSClassFromString(@"_UIAppearance") performSelector:selector withObject:self withObject:nil];
#pragma clang diagnostic pop
    }
}

@end
