//
//  FWCacheFile.m
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWCacheSqlite.h"
#import "FWDatabaseManager.h"

@interface FWCacheSqlite ()

@property (nonatomic, strong) FWDatabaseManager *manager;

@end

@implementation FWCacheSqlite

+ (instancetype)sharedInstance
{
    static FWCacheSqlite *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWCacheSqlite alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    return [self initWithPath:nil];
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        // 绝对路径: path
        NSString *dbPath = nil;
        if (path && [path isAbsolutePath]) {
            dbPath = path;
        // 相对路径: Libray/Caches/FWCache/path[FWCache.sqlite]
        } else {
            NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            dbPath = [[cachesPath stringByAppendingPathComponent:@"FWCache"] stringByAppendingPathComponent:(path.length > 0 ? path : @"FWCache.sqlite")];
        }
        // 自动创建目录
        NSString *fileDir = [dbPath stringByDeletingLastPathComponent];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fileDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _manager = [[FWDatabaseManager alloc] initWithDBName:[dbPath lastPathComponent] path:[dbPath stringByDeletingLastPathComponent]];
        
        if (![_manager isExistTable:@"FWCache"]) {
            [_manager createTable:@"FWCache" withModel:@{@"key": @"TEXT", @"value": @"BLOB"}];
        }
    }
    return self;
}

#pragma mark - Protect

- (id)innerCacheForKey:(NSString *)key
{
    NSArray *objectDatas = [_manager queryTable:@"FWCache" withModel:@{@"value": @"BLOB"} whereFormat:@"WHERE key = ?", key];
    if (objectDatas.count > 0) {
        NSData *objectData = [objectDatas.firstObject objectForKey:@"value"];
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
    }
    return nil;
}

- (void)innerSetCache:(id)object forKey:(NSString *)key
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSMutableDictionary *model = [NSMutableDictionary dictionary];
    [model setObject:key forKey:@"key"];
    [model setObject:objectData forKey:@"value"];
    [_manager replaceTable:@"FWCache" withModel:model];
}

- (void)innerRemoveCacheForKey:(NSString *)key
{
    [_manager deleteTable:@"FWCache" whereFormat:@"WHERE key = ?", key];
}

- (void)innerRemoveAllCaches
{
    [_manager deleteAllDataFromTable:@"FWCache"];
}

@end
