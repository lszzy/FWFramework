//
//  PlayerCache.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWPlayerCacheLoaderManager

@protocol FWPlayerCacheLoaderManagerDelegate;

// [VIMediaCache](https://github.com/vitoziv/VIMediaCache)
NS_SWIFT_NAME(PlayerCacheLoaderManager)
@interface FWPlayerCacheLoaderManager : NSObject <AVAssetResourceLoaderDelegate>

@property (nonatomic, weak, nullable) id<FWPlayerCacheLoaderManagerDelegate> delegate;

/**
 Normally you no need to call this method to clean cache. Cache cleaned after AVPlayer delloc.
 If you have a singleton AVPlayer then you need call this method to clean cache at suitable time.
 */
- (void)cleanCache;

/**
 Cancel all downloading loaders.
 */
- (void)cancelLoaders;

+ (NSURL *)assetURLWithURL:(NSURL *)url;

- (AVURLAsset *)URLAssetWithURL:(NSURL *)url;
- (AVPlayerItem *)playerItemWithURL:(NSURL *)url;

@end

NS_SWIFT_NAME(PlayerCacheLoaderManagerDelegate)
@protocol FWPlayerCacheLoaderManagerDelegate <NSObject>

- (void)resourceLoaderManagerLoadURL:(NSURL *)url didFailWithError:(NSError *)error;

@end

#pragma mark - FWPlayerCacheLoader

@protocol FWPlayerCacheLoaderDelegate;

NS_SWIFT_NAME(PlayerCacheLoader)
@interface FWPlayerCacheLoader : NSObject

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, weak) id<FWPlayerCacheLoaderDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url;

- (void)addRequest:(AVAssetResourceLoadingRequest *)request;
- (void)removeRequest:(AVAssetResourceLoadingRequest *)request;

- (void)cancel;

@end

NS_SWIFT_NAME(PlayerCacheLoaderDelegate)
@protocol FWPlayerCacheLoaderDelegate <NSObject>

- (void)resourceLoader:(FWPlayerCacheLoader *)resourceLoader didFailWithError:(NSError *)error;

@end

#pragma mark - FWPlayerCacheDownloader

@protocol FWPlayerCacheDownloaderDelegate;
@class FWPlayerCacheContentInfo;
@class FWPlayerCacheWorker;

NS_SWIFT_NAME(PlayerCacheDownloaderStatus)
@interface FWPlayerCacheDownloaderStatus : NSObject

+ (instancetype)shared;

- (void)addURL:(NSURL *)url;
- (void)removeURL:(NSURL *)url;

/**
 return YES if downloading the url source
 */
- (BOOL)containsURL:(NSURL *)url;
- (NSSet *)urls;

@end

NS_SWIFT_NAME(PlayerCacheDownloader)
@interface FWPlayerCacheDownloader : NSObject

- (instancetype)initWithURL:(NSURL *)url cacheWorker:(FWPlayerCacheWorker *)cacheWorker;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, weak) id<FWPlayerCacheDownloaderDelegate> delegate;
@property (nonatomic, strong) FWPlayerCacheContentInfo *info;
@property (nonatomic, assign) BOOL saveToCache;

- (void)downloadTaskFromOffset:(unsigned long long)fromOffset
                        length:(NSUInteger)length
                         toEnd:(BOOL)toEnd;
- (void)downloadFromStartToEnd;

- (void)cancel;

@end

NS_SWIFT_NAME(PlayerCacheDownloaderDelegate)
@protocol FWPlayerCacheDownloaderDelegate <NSObject>

@optional
- (void)mediaDownloader:(FWPlayerCacheDownloader *)downloader didReceiveResponse:(NSURLResponse *)response;
- (void)mediaDownloader:(FWPlayerCacheDownloader *)downloader didReceiveData:(NSData *)data;
- (void)mediaDownloader:(FWPlayerCacheDownloader *)downloader didFinishedWithError:(NSError *)error;

@end

#pragma mark - FWPlayerCacheRequestWorker

@class FWPlayerCacheDownloader, AVAssetResourceLoadingRequest;
@protocol FWPlayerCacheRequestWorkerDelegate;

NS_SWIFT_NAME(PlayerCacheRequestWorker)
@interface FWPlayerCacheRequestWorker : NSObject

- (instancetype)initWithMediaDownloader:(FWPlayerCacheDownloader *)mediaDownloader resourceLoadingRequest:(AVAssetResourceLoadingRequest *)request;

@property (nonatomic, weak) id<FWPlayerCacheRequestWorkerDelegate> delegate;

@property (nonatomic, strong, readonly) AVAssetResourceLoadingRequest *request;

- (void)startWork;
- (void)cancel;
- (void)finish;

@end

NS_SWIFT_NAME(PlayerCacheRequestWorkerDelegate)
@protocol FWPlayerCacheRequestWorkerDelegate <NSObject>

- (void)resourceLoadingRequestWorker:(FWPlayerCacheRequestWorker *)requestWorker didCompleteWithError:(NSError *)error;

@end

#pragma mark - FWPlayerCacheContentInfo

NS_SWIFT_NAME(PlayerCacheContentInfo)
@interface FWPlayerCacheContentInfo : NSObject <NSCoding>

@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, assign) BOOL byteRangeAccessSupported;
@property (nonatomic, assign) unsigned long long contentLength;
@property (nonatomic) unsigned long long downloadedContentLength;

@end

#pragma mark - FWPlayerCacheAction

typedef NS_ENUM(NSUInteger, FWPlayerCacheAtionType) {
    FWPlayerCacheAtionTypeLocal = 0,
    FWPlayerCacheAtionTypeRemote
} NS_SWIFT_NAME(PlayerCacheAtionType);

NS_SWIFT_NAME(PlayerCacheAction)
@interface FWPlayerCacheAction : NSObject

- (instancetype)initWithActionType:(FWPlayerCacheAtionType)actionType range:(NSRange)range;

@property (nonatomic) FWPlayerCacheAtionType actionType;
@property (nonatomic) NSRange range;

@end

#pragma mark - FWPlayerCacheConfiguration

NS_SWIFT_NAME(PlayerCacheConfiguration)
@interface FWPlayerCacheConfiguration : NSObject <NSCopying>

+ (NSString *)configurationFilePathForFilePath:(NSString *)filePath;

+ (instancetype)configurationWithFilePath:(NSString *)filePath;

@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, strong) FWPlayerCacheContentInfo *contentInfo;
@property (nonatomic, strong) NSURL *url;

- (NSArray<NSValue *> *)cacheFragments;

/**
 *  cached progress
 */
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) long long downloadedBytes;
@property (nonatomic, readonly) float downloadSpeed; // kb/s

#pragma mark - update API

- (void)save;
- (void)addCacheFragment:(NSRange)fragment;

/**
 *  Record the download speed
 */
- (void)addDownloadedBytes:(long long)bytes spent:(NSTimeInterval)time;

+ (BOOL)createAndSaveDownloadedConfigurationForURL:(NSURL *)url error:(NSError **)error;

@end

#pragma mark - FWPlayerCacheManager

extern NSNotificationName FWPlayerCacheManagerDidUpdateCacheNotification NS_SWIFT_NAME(PlayerCacheManagerDidUpdate);
extern NSNotificationName FWPlayerCacheManagerDidFinishCacheNotification NS_SWIFT_NAME(PlayerCacheManagerDidFinish);

extern NSString *FWPlayerCacheConfigurationKey NS_SWIFT_NAME(PlayerCacheConfigurationKey);
extern NSString *FWPlayerCacheFinishedErrorKey NS_SWIFT_NAME(PlayerCacheFinishedErrorKey);

NS_SWIFT_NAME(PlayerCacheManager)
@interface FWPlayerCacheManager : NSObject

+ (void)setCacheDirectory:(NSString *)cacheDirectory;
+ (NSString *)cacheDirectory;


/**
 How often trigger `FWPlayerCacheManagerDidUpdateCacheNotification` notification

 @param interval Minimum interval
 */
+ (void)setCacheUpdateNotifyInterval:(NSTimeInterval)interval;
+ (NSTimeInterval)cacheUpdateNotifyInterval;

+ (NSString *)cachedFilePathForURL:(NSURL *)url;
+ (FWPlayerCacheConfiguration *)cacheConfigurationForURL:(NSURL *)url;

+ (void)setFileNameRules:(NSString *(^)(NSURL *url))rules;


/**
 Calculate cached files size

 @param error If error not empty, calculate failed
 @return files size, respresent by `byte`, if error occurs, return -1
 */
+ (unsigned long long)calculateCachedSizeWithError:(NSError **)error;
+ (void)cleanAllCacheWithError:(NSError **)error;
+ (void)cleanCacheForURL:(NSURL *)url error:(NSError **)error;


/**
 Useful when you upload a local file to the server

 @param filePath local file path
 @param url remote resource url
 @param error On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information.
 */
+ (BOOL)addCacheFile:(NSString *)filePath forURL:(NSURL *)url error:(NSError **)error;

@end

#pragma mark - FWPlayerCacheSessionManager

NS_SWIFT_NAME(PlayerCacheSessionManager)
@interface FWPlayerCacheSessionManager : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *downloadQueue;

+ (instancetype)shared;

@end

#pragma mark - FWPlayerCacheWorker

NS_SWIFT_NAME(PlayerCacheWorker)
@interface FWPlayerCacheWorker : NSObject

- (instancetype)initWithURL:(NSURL *)url;

@property (nonatomic, strong, readonly) FWPlayerCacheConfiguration *cacheConfiguration;
@property (nonatomic, strong, readonly) NSError *setupError; // Create fileHandler error, can't save/use cache

- (void)cacheData:(NSData *)data forRange:(NSRange)range error:(NSError **)error;
- (NSArray<FWPlayerCacheAction *> *)cachedDataActionsForRange:(NSRange)range;
- (NSData *)cachedDataForRange:(NSRange)range error:(NSError **)error;

- (void)setContentInfo:(FWPlayerCacheContentInfo *)contentInfo error:(NSError **)error;

- (void)save;

- (void)startWritting;
- (void)finishWritting;

@end

NS_ASSUME_NONNULL_END
