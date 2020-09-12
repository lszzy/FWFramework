//
//  FWCacheFile.m
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheFile.h"
#import <CommonCrypto/CommonDigest.h>

@interface FWCacheFile ()

@property (nonatomic, copy, readonly) NSString *path;

@end

@implementation FWCacheFile

+ (FWCacheFile *)sharedInstance
{
    static FWCacheFile *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWCacheFile alloc] init];
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
        if (path && [path isAbsolutePath]) {
            _path = path;
        // 相对路径: Libray/Caches/FWCache/path[FWCache]
        } else {
            NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            _path = [[cachesPath stringByAppendingPathComponent:@"FWCache"] stringByAppendingPathComponent:(path.length > 0 ? path : @"FWCache")];
        }
    }
    return self;
}

#pragma mark - Private

- (NSString *)filePath:(NSString *)key
{
    // 文件名md5加密
    const char *cStr = [key UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *md5Str = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [md5Str appendFormat:@"%02x", digest[i]];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@.plist", md5Str];
    return [self.path stringByAppendingPathComponent:fileName];
}

#pragma mark - Protected

- (id)innerObjectForKey:(NSString *)key
{
    NSString *filePath = [self filePath:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    return nil;
}

- (void)innerSetObject:(id)object forKey:(NSString *)key
{
    NSString *filePath = [self filePath:key];
    // 自动创建目录
    NSString *fileDir = [filePath stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [NSKeyedArchiver archiveRootObject:object toFile:filePath];
}

- (void)innerRemoveObjectForKey:(NSString *)key
{
    NSString *filePath = [self filePath:key];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}

- (void)innerRemoveAllObjects
{
    NSString *filePath = self.path;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}

@end
