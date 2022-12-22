//
//  CacheManager.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "CacheManager.h"

@implementation __FWCacheManager

+ (id<__FWCacheProtocol>)managerWithType:(__FWCacheType)type
{
    id<__FWCacheProtocol> manager = nil;
    switch (type) {
        case __FWCacheTypeMemory:
            manager = [__FWCacheMemory sharedInstance];
            break;
        case __FWCacheTypeUserDefaults:
            manager = [__FWCacheUserDefaults sharedInstance];
            break;
        case __FWCacheTypeKeychain:
            manager = [__FWCacheKeychain sharedInstance];
            break;
        case __FWCacheTypeFile:
            manager = [__FWCacheFile sharedInstance];
            break;
        case __FWCacheTypeSqlite:
            manager = [__FWCacheSqlite sharedInstance];
            break;
        default:
            break;
    }
    return manager;
}

@end
