//
//  UserModule.m
//  User
//
//  Created by wuyong on 2021/1/1.
//

#import <FWFramework/FWFramework.h>
#import <User/User-Swift.h>
#import <Mediator/Mediator-Swift.h>

@interface UserModuleLoader : NSObject

@end

@implementation UserModuleLoader

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWMediator registerService:@protocol(UserModuleService) withModule:NSClassFromString(@"User.UserModule")];
    });
}

@end
