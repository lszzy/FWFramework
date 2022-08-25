//
//  FWCacheMemory.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWCacheEngine.h"

NS_ASSUME_NONNULL_BEGIN

/// 内存缓存
NS_SWIFT_NAME(CacheMemory)
@interface FWCacheMemory : FWCacheEngine

/** 单例模式 */
@property (class, nonatomic, readonly) FWCacheMemory *sharedInstance NS_SWIFT_NAME(shared);

@end

NS_ASSUME_NONNULL_END
