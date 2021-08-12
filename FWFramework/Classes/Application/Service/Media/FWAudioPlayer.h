/*!
 @header     FWAudioPlayer.h
 @indexgroup FWFramework
 @brief      FWAudioPlayer
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <AvailabilityMacros.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FWAudioPlayerReadyToPlay) {
    FWAudioPlayerReadyToPlayPlayer = 3000,
    FWAudioPlayerReadyToPlayCurrentItem = 3001,
};

typedef NS_ENUM(NSInteger, FWAudioPlayerFailed) {
    FWAudioPlayerFailedPlayer = 4000,
    FWAudioPlayerFailedCurrentItem = 4001,
};

/**
 *  FWAudioPlayerDelegate, all delegate method is optional.
 */
@protocol FWAudioPlayerDelegate <NSObject>

@optional
- (void)audioPlayerWillChangedAtIndex:(NSInteger)index;
- (void)audioPlayerCurrentItemChanged:(AVPlayerItem *)item;
- (void)audioPlayerCurrentItemEvicted:(AVPlayerItem *)item;
- (void)audioPlayerRateChanged:(BOOL)isPlaying;
- (void)audioPlayerDidReachEnd;
- (void)audioPlayerCurrentItemPreloaded:(CMTime)time;
- (void)audioPlayerDidFailed:(FWAudioPlayerFailed)identifier error:(nullable NSError *)error;
- (void)audioPlayerReadyToPlay:(FWAudioPlayerReadyToPlay)identifier;

- (void)audioPlayerItemFailedToPlayEndTime:(AVPlayerItem *)item error:(nullable NSError *)error;
- (void)audioPlayerItemPlaybackStall:(AVPlayerItem *)item;

@end

@protocol FWAudioPlayerDataSource <NSObject>

@optional

/**
 *  Asks the data source to return the number of items that FWAudioPlayer would play.
 *
 *  @return items count
 */
- (NSInteger)audioPlayerNumberOfItems;

/**
 *  Source URL provider, audioPlayerAsyncSetUrlForItemAtIndex:preBuffer: is for async task usage.
 *
 *  @param index     index of the item
 *  @param preBuffer ask URL for pre buffer or not
 *
 *  @return source URL
 */
- (NSURL *)audioPlayerURLForItemAtIndex:(NSInteger)index preBuffer:(BOOL)preBuffer;

/**
 *  Source URL provider, would excute until you call setupPlayerItemWithUrl:index:
 *
 *  @param index     index of the item
 *  @param preBuffer ask URL for pre buffer or not
 */
- (void)audioPlayerAsyncSetUrlForItemAtIndex:(NSInteger)index preBuffer:(BOOL)preBuffer;

@end

typedef NS_ENUM(NSInteger, FWAudioPlayerStatus) {
    FWAudioPlayerStatusPlaying = 0,
    FWAudioPlayerStatusForcePause,
    FWAudioPlayerStatusBuffering,
    FWAudioPlayerStatusUnknown,
};

typedef NS_ENUM(NSInteger, FWAudioPlayerRepeatMode) {
    FWAudioPlayerRepeatModeOn = 0,
    FWAudioPlayerRepeatModeOnce,
    FWAudioPlayerRepeatModeOff,
};

typedef NS_ENUM(NSInteger, FWAudioPlayerShuffleMode) {
    FWAudioPlayerShuffleModeOn = 0,
    FWAudioPlayerShuffleModeOff,
};

/**
 * FWAudioPlayer
 *
 * @see https://github.com/StreetVoice/HysteriaPlayer
 */
@interface FWAudioPlayer : NSObject <AVAudioPlayerDelegate>

@property (nonatomic, strong, nullable) AVQueuePlayer *audioPlayer;
@property (nonatomic, weak, nullable) id<FWAudioPlayerDelegate> delegate;
@property (nonatomic, weak, nullable) id<FWAudioPlayerDataSource> dataSource;
@property (nonatomic) NSInteger itemsCount;
@property (nonatomic) BOOL disableLogs;
@property (nonatomic, strong, readonly, nullable) NSArray *playerItems;

+ (FWAudioPlayer *)sharedInstance;

/**
 *   This method is necessary if you implement audioPlayerAsyncSetUrlForItemAtIndex:preBuffer: delegate method,
     provide source URL to FWAudioPlayer.
     Should not use this method outside of audioPlayerAsyncSetUrlForItemAtIndex:preBuffer: scope.
 *
 *  @param url   source URL
 *  @param index index which audioPlayerAsyncSetUrlForItemAtIndex:preBuffer: sent you
 */
- (void)setupPlayerItemWithUrl:(NSURL *)url index:(NSInteger)index;
- (void)setupPlayerItemWithAVURLAsset:(AVURLAsset *)asset index:(NSInteger)index;
- (void)fetchAndPlayPlayerItem: (NSInteger )startAt;
- (void)removeAllItems;
- (void)removeQueuesAtPlayer;

/**
 *   Be sure you update audioPlayerNumberOfItems or itemsCount when you remove items
 *
 *  @param index index to removed
 */
- (void)removeItemAtIndex:(NSInteger)index;
- (void)moveItemFromIndex:(NSInteger)from toIndex:(NSInteger)to;
- (void)play;
- (void)pause;
- (void)playPrevious;
- (void)playNext;
- (void)seekToTime:(double) CMTime;
- (void)seekToTime:(double) CMTime withCompletionBlock:(nullable void (^)(BOOL finished))completionBlock;

- (void)setPlayerRepeatMode:(FWAudioPlayerRepeatMode)mode;
- (FWAudioPlayerRepeatMode)getPlayerRepeatMode;
- (void)setPlayerShuffleMode:(FWAudioPlayerShuffleMode)mode;
- (FWAudioPlayerShuffleMode)getPlayerShuffleMode;

- (BOOL)isPlaying;
- (NSInteger)getLastItemIndex;
- (AVPlayerItem *)getCurrentItem;
- (FWAudioPlayerStatus)getAudioPlayerStatus;

- (float)getPlayingItemCurrentTime;
- (float)getPlayingItemDurationTime;
- (id)addBoundaryTimeObserverForTimes:(NSArray *)times queue:(dispatch_queue_t)queue usingBlock:(void (^)(void))block;
- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;
- (void)removeTimeObserver:(id)observer;

/**
 *  Default is true
 *
 *  @param memoryCache cache
 */
- (void)enableMemoryCached:(BOOL)memoryCache;
- (BOOL)isMemoryCached;

/**
 *  Indicating Playeritem's play index
 *
 *  @param item item
 *
 *  @return index of the item
 */
- (nullable NSNumber *)getAudioIndex:(AVPlayerItem *)item;

- (void)destroyPlayer;

@end

NS_ASSUME_NONNULL_END
