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

typedef NS_ENUM(NSInteger, FWCacheType) {
    FWCacheTypeMemory = 1,
    FWCacheTypeUserDefaults,
    FWCacheTypeKeychain,
    FWCacheTypeFile,
    FWCacheTypeSqlite,
};

/*!
 @brief FWCacheManager
 */
@interface FWCacheManager : NSObject

// 获取指定类型的缓存单例对象
+ (id<FWCacheProtocol>)managerWithType:(FWCacheType)type;

@end
