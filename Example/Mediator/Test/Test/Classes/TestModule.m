//
//  TestModule.m
//  Pods
//
//  Created by wuyong on 2021/1/2.
//

#import "TestModule.h"
#import "TestModuleViewController.h"

@implementation TestModule

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWModuleRegister(TestModuleService);
    });
}

FWDefSingleton(TestModule);

- (void)setup
{
    NSLog(@"TestModule.setup");
}

- (UIViewController *)testViewController
{
    return [[TestModuleViewController alloc] init];
}

@end

@implementation TestBundle

+ (NSBundle *)bundle
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"TestModule" ofType:@"bundle"];
    return [NSBundle bundleWithPath:path];
}

@end
