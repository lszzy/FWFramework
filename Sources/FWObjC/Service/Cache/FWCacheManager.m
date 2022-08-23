//
//  FWCacheManager.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

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
