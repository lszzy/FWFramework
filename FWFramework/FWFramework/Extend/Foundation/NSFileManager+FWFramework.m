/*!
 @header     NSFileManager+FWFramework.m
 @indexgroup FWFramework
 @brief      NSFileManager+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "NSFileManager+FWFramework.h"
#import <AVFoundation/AVFoundation.h>

@implementation NSFileManager (FWFramework)

#pragma mark - Path

+ (NSString *)fwPathSearch:(NSSearchPathDirectory)directory
{
    NSArray *directories = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    return directories.count > 0 ? [directories objectAtIndex:0] : nil;
}

+ (NSString *)fwPathHome
{
    return NSHomeDirectory();
}

+ (NSString *)fwPathDocument
{
    return [self fwPathSearch:NSDocumentDirectory];
}

+ (NSString *)fwPathCaches
{
    return [self fwPathSearch:NSCachesDirectory];
}

+ (NSString *)fwPathLibrary
{
    return [self fwPathSearch:NSLibraryDirectory];
}

+ (NSString *)fwPathPreference
{
    return [[self fwPathLibrary] stringByAppendingPathComponent:@"Preference"];
}

+ (NSString *)fwPathTmp
{
    return NSTemporaryDirectory();
}

+ (NSString *)fwPathBundle
{
    return [[NSBundle mainBundle] bundlePath];
}

+ (NSString *)fwPathResource
{
    return [[NSBundle mainBundle] resourcePath];
}

+ (NSString *)fwAbbreviateTildePath:(NSString *)path
{
    return [path stringByAbbreviatingWithTildeInPath];
}

+ (NSString *)fwExpandTildePath:(NSString *)path
{
    return [path stringByExpandingTildeInPath];
}

#pragma mark - Size

+ (unsigned long long)fwFolderSize:(NSString *)folderPath
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }
    return folderSize;
}

+ (double)fwAvailableDiskSize
{
    NSDictionary *attributes = [self.defaultManager attributesOfFileSystemForPath:[self fwPathDocument] error:nil];
    return [attributes[NSFileSystemFreeSize] unsignedLongLongValue] / (double)0x100000;
}

#pragma mark - Addition

+ (BOOL)fwSkipBackup:(NSString *)path
{
    return [[NSURL.alloc initFileURLWithPath:path] setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];
}

#pragma mark - Audio

+ (void)fwAsyncAudioDuration:(NSString *)audioUrl completion:(void (^)(float))completion
{
    AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:audioUrl] options:nil];
    [urlAsset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
        AVKeyValueStatus keyValueState = [urlAsset statusOfValueForKey:@"duration" error:nil];
        float duration = 0.f;
        if (keyValueState == AVKeyValueStatusLoaded) {
            // duration = CMTimeGetSeconds(urlAsset.duration);
            CMTime cmTime = urlAsset.duration;
            duration = cmTime.value / cmTime.timescale;
        }
        
        // 主线程回调
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(duration);
            }
        });
    }];
}

@end
