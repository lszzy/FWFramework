//
//  TestModule.h
//  Pods
//
//  Created by wuyong on 2021/1/2.
//

#import <FWFramework/FWFramework.h>
#import <Mediator/Mediator-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestModule : NSObject <FWModuleProtocol, TestModuleService>

@end

@interface TestBundle : FWModuleBundle

@end

NS_ASSUME_NONNULL_END
