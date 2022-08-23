//
//  FWThread.h
//  
//
//  Created by wuyong on 2022/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWMutableArray

/**
 线程安全的可变数组，参考自YYKit
 
 @see https://github.com/ibireme/YYKit
 */
NS_SWIFT_NAME(MutableArray)
@interface FWMutableArray<__covariant ObjectType> : NSMutableArray<ObjectType>

@end

#pragma mark - FWMutableDictionary

/**
 线程安全的可变字典，参考自YYKit
 
 @see https://github.com/ibireme/YYKit
 */
NS_SWIFT_NAME(MutableDictionary)
@interface FWMutableDictionary<__covariant KeyType, __covariant ObjectType> : NSMutableDictionary<KeyType, ObjectType>

@end

NS_ASSUME_NONNULL_END
