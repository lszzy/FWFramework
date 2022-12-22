//
//  CacheManager.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "CacheMemory.h"
#import "CacheUserDefaults.h"
#import "CacheKeychain.h"
#import "CacheFile.h"
#import "CacheSqlite.h"

NS_ASSUME_NONNULL_BEGIN

/// 缓存类型枚举
typedef NSInteger __FWCacheType NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(CacheType);
/// 内存缓存
static const __FWCacheType __FWCacheTypeMemory = 1;
/// NSUserDefaults缓存
static const __FWCacheType __FWCacheTypeUserDefaults = 2;
/// Keychain缓存
static const __FWCacheType __FWCacheTypeKeychain = 3;
/// 文件缓存
static const __FWCacheType __FWCacheTypeFile = 4;
/// Sqlite数据库缓存
static const __FWCacheType __FWCacheTypeSqlite = 5;

/**
 __FWCacheManager
 */
NS_SWIFT_NAME(CacheManager)
@interface __FWCacheManager : NSObject

/// 获取指定类型的缓存单例对象
+ (nullable id<__FWCacheProtocol>)managerWithType:(__FWCacheType)type;

@end

NS_ASSUME_NONNULL_END
