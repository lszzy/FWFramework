//
//  FWCacheManager.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWCacheMemory.h"
#import "FWCacheUserDefaults.h"
#import "FWCacheKeychain.h"
#import "FWCacheFile.h"
#import "FWCacheSqlite.h"

NS_ASSUME_NONNULL_BEGIN

/// 缓存类型枚举
typedef NSInteger FWCacheType NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(CacheType);
/// 内存缓存
static const FWCacheType FWCacheTypeMemory = 1;
/// NSUserDefaults缓存
static const FWCacheType FWCacheTypeUserDefaults = 2;
/// Keychain缓存
static const FWCacheType FWCacheTypeKeychain = 3;
/// 文件缓存
static const FWCacheType FWCacheTypeFile = 4;
/// Sqlite数据库缓存
static const FWCacheType FWCacheTypeSqlite = 5;

/**
 FWCacheManager
 */
NS_SWIFT_NAME(CacheManager)
@interface FWCacheManager : NSObject

/// 获取指定类型的缓存单例对象
+ (nullable id<FWCacheProtocol>)managerWithType:(FWCacheType)type;

@end

NS_ASSUME_NONNULL_END
