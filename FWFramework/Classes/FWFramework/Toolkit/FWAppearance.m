/**
 @header     FWAppearance.m
 @indexgroup FWFramework
      FWAppearance
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import "FWAppearance.h"
#import "FWSwizzle.h"
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

+ (Class)classForAppearance:(id)appearance {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@%@", @"customizable", @"ClassInfo"]);
    if (![appearance respondsToSelector:selector]) return [appearance class];

    id classInfo = [appearance performSelector:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_%@%@", @"customizable", @"ViewClass"]);
    if (!classInfo || ![classInfo respondsToSelector:selector]) return [appearance class];
    
    Class viewClass = [classInfo performSelector:selector];
    if (viewClass && object_isClass(viewClass)) return viewClass;
    #pragma clang diagnostic pop
    return [appearance class];
}

@end

@implementation FWObjectWrapper (FWAppearance)

- (void)applyAppearance {
    Class class = [self.base class];
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
        [NSClassFromString(@"_UIAppearance") performSelector:selector withObject:self.base withObject:nil];
#pragma clang diagnostic pop
    }
}

@end
