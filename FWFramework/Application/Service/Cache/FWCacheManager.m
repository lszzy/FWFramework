/*!
 @header     FWCacheManager.m
 @indexgroup FWFramework
 @brief      FWCacheManager
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/26
 */

#import "FWCacheManager.h"

@implementation FWCacheManager

+ (id<FWCacheProtocol>)managerWithType:(FWCacheType)type
{
    id<FWCacheProtocol> manager = nil;
    switch (type) {
        case FWCacheTypeMemory:
            manager = [FWCacheMemory sharedInstance];
            break;
        case FWCacheTypeUserDefaults:
            manager = [FWCacheUserDefaults sharedInstance];
            break;
        case FWCacheTypeKeychain:
            manager = [FWCacheKeychain sharedInstance];
            break;
        case FWCacheTypeFile:
            manager = [FWCacheFile sharedInstance];
            break;
        case FWCacheTypeSqlite:
            manager = [FWCacheSqlite sharedInstance];
            break;
        default:
            break;
    }
    return manager;
}

@end
