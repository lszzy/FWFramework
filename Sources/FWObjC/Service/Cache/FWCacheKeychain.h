//
//  FWCacheKeychain.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWCacheEngine.h"

NS_ASSUME_NONNULL_BEGIN

/// Keychain缓存
NS_SWIFT_NAME(CacheKeychain)
@interface FWCacheKeychain : FWCacheEngine

/** 单例模式 */
@property (class, nonatomic, readonly) FWCacheKeychain *sharedInstance NS_SWIFT_NAME(shared);

/// 分组对象
- (instancetype)initWithGroup:(nullable NSString *)group;

@end

NS_ASSUME_NONNULL_END
