//
//  FWCacheFile.m
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheSqlite.h"
#import "FWDatabaseQueue.h"

@interface FWCacheSqlite ()

@property (nonatomic, strong) FWDatabaseQueue *queue;

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
        
        // 初始化数据库和创建缓存表
        _queue = [FWDatabaseQueue databaseQueueWithPath:dbPath];
        [_queue inDatabase:^(FWDatabase * _Nonnull db) {
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS FWCache (key TEXT PRIMARY KEY, object BLOB);"];
        }];
    }
    return self;
}

- (void)dealloc
{
    [_queue close];
}

#pragma mark - Protect

- (id)innerCacheForKey:(NSString *)key
{
    __block id object = nil;
    [_queue inDatabase:^(FWDatabase * _Nonnull db) {
        FWResultSet *rs = [db executeQuery:@"SELECT object FROM FWCache WHERE key = ?", key];
        if ([rs next]) {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:[rs dataForColumn:@"object"]];
        }
        [rs close];
    }];
    return object;
}

- (void)innerSetCache:(id)object forKey:(NSString *)key
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
    [_queue inDatabase:^(FWDatabase * _Nonnull db) {
        [db executeUpdate:@"REPLACE INTO FWCache (key, object) VALUES (?, ?)", key, objectData];
    }];
}

- (void)innerRemoveCacheForKey:(NSString *)key
{
    [_queue inDatabase:^(FWDatabase * _Nonnull db) {
        [db executeUpdate:@"DELETE FROM FWCache WHERE key = ?", key];
    }];
}

- (void)innerRemoveAllCaches
{
    [_queue inDatabase:^(FWDatabase * _Nonnull db) {
        [db executeUpdate:@"DELETE FROM FWCache"];
        // 释放数据库空间
        [db executeUpdate:@"VACUUM"];
    }];
}

@end
