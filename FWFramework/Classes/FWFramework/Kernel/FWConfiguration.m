//
//  FWConfiguration.m
//  FWFramework
//
//  Created by wuyong on 2022/6/10.
//

#import "FWConfiguration.h"
#import <objc/runtime.h>

@implementation FWConfigurationTemplate

- (void)applyConfiguration {}

@end

@implementation FWConfiguration

+ (instancetype)sharedInstance {
    FWConfiguration *instance = objc_getAssociatedObject([self class], @selector(sharedInstance));
    if (instance) return instance;
    
    @synchronized ([self class]) {
        instance = objc_getAssociatedObject([self class], @selector(sharedInstance));
        if (!instance) {
            instance = [[self alloc] init];
            objc_setAssociatedObject([self class], @selector(sharedInstance), instance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return instance;
    }
}

- (void)initializeConfiguration {
    Class templateClass = NSClassFromString([NSStringFromClass([self class]) stringByAppendingString:@"Template"]);
    if (!templateClass) return;
    
    FWConfigurationTemplate *templateConfiguration = [[templateClass alloc] init];
    if ([templateConfiguration respondsToSelector:@selector(applyConfiguration)]) {
        [templateConfiguration applyConfiguration];
    }
}

@end
