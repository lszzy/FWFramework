//
//  UserModule.m
//  Pods
//
//  Created by wuyong on 2021/1/6.
//

#import <FWFramework/FWFramework.h>
#import <User/User-Swift.h>
#import <Mediator/Mediator-Swift.h>

@implementation UserModule (Mediator)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWRegModule(UserModuleService);
    });
}

@end
