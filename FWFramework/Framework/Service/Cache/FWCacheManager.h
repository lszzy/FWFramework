/*!
 @header     FWCacheManager.h
 @indexgroup FWFramework
 @brief      FWCacheManager
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/26
 */

#import "FWCacheMemory.h"
#import "FWCacheUserDefaults.h"
#import "FWCacheKeychain.h"
#import "FWCacheFile.h"
#import "FWCacheSqlite.h"

NS_ASSUME_NONNULL_BEGIN

/// 缓存类型枚举
typedef NSInteger FWCacheType NS_TYPED_EXTENSIBLE_ENUM;
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

/*!
 @brief FWCacheManager
 */
@interface FWCacheManager : NSObject

/// 获取指定类型的缓存单例对象
+ (nullable id<FWCacheProtocol>)managerWithType:(FWCacheType)type;

@end

NS_ASSUME_NONNULL_END
