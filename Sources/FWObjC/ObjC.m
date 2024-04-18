//
//  ObjC.m
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import "ObjC.h"
#import <objc/runtime.h>

#pragma mark - ObjCBridge

@implementation FWObjCBridge

+ (id)appearanceForClass:(Class)aClass {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@:%@:", @"appearanceForClass", @"withContainerList"]);
    id appearance = [NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"_U", @"IAppea", @"rance"]) performSelector:selector withObject:aClass withObject:nil];
    #pragma clang diagnostic pop
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

+ (void)applyAppearance:(NSObject *)object {
    Class class = [object class];
    if (![class respondsToSelector:@selector(appearance)]) return;
    
    SEL appearanceGuideClassSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@", @"_a", @"ppearanceG", @"uideClass"]);
    if (!class_respondsToSelector(class, appearanceGuideClassSelector)) {
        const char * typeEncoding = method_getTypeEncoding(class_getInstanceMethod(UIView.class, appearanceGuideClassSelector));
        class_addMethod(class, appearanceGuideClassSelector, imp_implementationWithBlock(^Class(void) {
            return nil;
        }), typeEncoding);
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@:%@:", @"applyInvocationsTo", @"window"]);
    [NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"_U", @"IAppea", @"rance"]) performSelector:selector withObject:object withObject:nil];
    #pragma clang diagnostic pop
}

@end
