//
//  CacheSqlite.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "CacheSqlite.h"
#import <sqlite3.h>

@interface __FWCacheSqlite () <__FWCacheEngineProtocol>

@property (nonatomic, strong) NSString *dbPath;
@property (nonatomic) sqlite3 *database;

@end

@implementation __FWCacheSqlite

+ (__FWCacheSqlite *)sharedInstance
{
    static __FWCacheSqlite *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWCacheSqlite alloc] init];
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
        _dbPath = dbPath;
        // 自动创建目录
        NSString *fileDir = [dbPath stringByDeletingLastPathComponent];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fileDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // 初始化数据库和创建缓存表
        if ([self open]) {
            NSString *sql = @"CREATE TABLE IF NOT EXISTS FWCache (key TEXT PRIMARY KEY, object BLOB);";
            sqlite3_exec(_database, [sql UTF8String], nil, nil, NULL);
            [self close];
        }
    }
    return self;
}

- (BOOL)open
{
    if (sqlite3_open([self.dbPath UTF8String], &_database) == SQLITE_OK) {
        return YES;
    }
    return NO;
}

- (void)close
{
    if (_database) {
        sqlite3_close(_database);
        _database = nil;
    }
}

#pragma mark - __FWCacheEngineProtocol

- (id)readCacheForKey:(NSString *)key
{
    id object = nil;
    @autoreleasepool {
        if ([self open]) {
            NSString *sql = @"SELECT object FROM FWCache WHERE key = ?";
            sqlite3_stmt *stmt;
            if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, 0) == SQLITE_OK) {
                sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_STATIC);
                
                while (sqlite3_step(stmt) == SQLITE_ROW) {
                    const char *dataBuffer = sqlite3_column_blob(stmt, 0);
                    int dataSize = sqlite3_column_bytes(stmt, 0);
                    if (dataBuffer != NULL) {
                        NSData *data = [NSData dataWithBytes:(const void *)dataBuffer length:(NSUInteger)dataSize];
                        @try {
                            object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                        } @catch (NSException *exception) {
                            NSLog(@"%@", exception);
                        }
                    }
                }
            }
            sqlite3_finalize(stmt);
            
            [self close];
        }
    }
    return object;
}

- (void)writeCache:(id)object forKey:(NSString *)key
{
    @autoreleasepool {
        if ([self open]) {
            NSData *data = nil;
            @try {
                data = [NSKeyedArchiver archivedDataWithRootObject:object];
            } @catch (NSException *exception) {
                NSLog(@"%@", exception);
            }
            NSString *sql = @"REPLACE INTO FWCache (key, object) VALUES (?, ?)";
            sqlite3_stmt *stmt;
            if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, 0) == SQLITE_OK) {
                sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_STATIC);
                
                const void *bytes = [data bytes];
                if (!bytes) bytes = "";
                sqlite3_bind_blob(stmt, 2, bytes, (int)[data length], SQLITE_STATIC);
                
                sqlite3_step(stmt);
            }
            sqlite3_finalize(stmt);
            
            [self close];
        }
    }
}

- (void)clearCacheForKey:(NSString *)key
{
    @autoreleasepool {
        if ([self open]) {
            NSString *sql = @"DELETE FROM FWCache WHERE key = ?";
            sqlite3_stmt *stmt;
            if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, 0) == SQLITE_OK) {
                sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_STATIC);
                
                sqlite3_step(stmt);
            }
            sqlite3_finalize(stmt);
            
            [self close];
        }
    }
}

- (void)clearAllCaches
{
    @autoreleasepool {
        if ([self open]) {
            NSString *sql = @"DELETE FROM FWCache";
            sqlite3_exec(_database, [sql UTF8String], nil, nil, NULL);
            
            sql = @"VACUUM";
            sqlite3_exec(_database, [sql UTF8String], nil, nil, NULL);
            
            [self close];
        }
    }
}

@end
