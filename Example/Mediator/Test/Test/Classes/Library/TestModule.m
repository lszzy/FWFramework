//
//  TestModule.m
//  Pods
//
//  Created by wuyong on 2021/1/2.
//

#import "TestModule.h"
#import "TestModuleController.h"

@implementation TestModule

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWRegModule(TestModuleService);
    });
}

FWDefSingleton(TestModule);

- (void)setup
{
    FWLogDebug(@"TestModule.setup");
}

- (UIViewController *)testViewController
{
    return [[TestModuleController alloc] init];
}

@end

@implementation TestBundle

+ (NSBundle *)bundle
{
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundle = [[NSBundle fwBundleWithClass:[self class] name:@"TestModule"] fwLocalizedBundle];
    });
    return bundle;
}

@end
