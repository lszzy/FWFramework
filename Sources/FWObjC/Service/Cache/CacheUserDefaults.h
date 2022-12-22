//
//  CacheUserDefaults.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "CacheEngine.h"

NS_ASSUME_NONNULL_BEGIN

/// NSUserDefaults缓存
NS_SWIFT_NAME(CacheUserDefaults)
@interface __FWCacheUserDefaults : __FWCacheEngine

/** 单例模式 */
@property (class, nonatomic, readonly) __FWCacheUserDefaults *sharedInstance NS_SWIFT_NAME(shared);

/// 分组对象
- (instancetype)initWithGroup:(nullable NSString *)group;

@end

NS_ASSUME_NONNULL_END
