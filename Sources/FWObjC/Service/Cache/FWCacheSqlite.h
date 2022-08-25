//
//  FWCacheSqlite.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWCacheEngine.h"

NS_ASSUME_NONNULL_BEGIN

/// Sqlite缓存
NS_SWIFT_NAME(CacheSqlite)
@interface FWCacheSqlite : FWCacheEngine

/** 单例模式 */
@property (class, nonatomic, readonly) FWCacheSqlite *sharedInstance NS_SWIFT_NAME(shared);

/// 指定路径
- (instancetype)initWithPath:(nullable NSString *)path;

@end

NS_ASSUME_NONNULL_END
