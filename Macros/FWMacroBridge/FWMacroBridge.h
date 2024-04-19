//
//  FWMacroBridge.h
//  FWFramework
//
//  Created by wuyong on 2024/4/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FWMacroBridge : NSObject

+ (void)tryCatch:(void (NS_NOESCAPE ^)(void))block exceptionHandler:(void (NS_NOESCAPE ^)(NSException *exception))exceptionHandler;

@end

NS_ASSUME_NONNULL_END
