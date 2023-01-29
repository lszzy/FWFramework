//
//  Thread.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWMutableArray

/**
 线程安全的可变数组，参考自YYKit
 
 @see https://github.com/ibireme/YYKit
 */
NS_SWIFT_NAME(MutableArray)
@interface __FWMutableArray<__covariant ObjectType> : NSMutableArray<ObjectType>

@end

#pragma mark - __FWMutableDictionary

/**
 线程安全的可变字典，参考自YYKit
 
 @see https://github.com/ibireme/YYKit
 */
NS_SWIFT_NAME(MutableDictionary)
@interface __FWMutableDictionary<__covariant KeyType, __covariant ObjectType> : NSMutableDictionary<KeyType, ObjectType>

@end

NS_ASSUME_NONNULL_END
