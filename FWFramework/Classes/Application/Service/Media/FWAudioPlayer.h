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

/// FWAudioPlayerDelegate, all delegate method is optional
@protocol FWAudioPlayerDelegate <NSObject>

@optional
- (void)audioPlayerWillChangedAtIndex:(NSInteger)index;
- (void)audioPlayerCurrentItemChanged:(AVPlayerItem *)item;
- (void)audioPlayerCurrentItemEvicted:(AVPlayerItem *)item;
- (void)audioPlayerRateChanged:(BOOL)isPlaying;
- (void)audioPlayerDidReachEnd;
- (void)audioPlayerCurrentTimeChanged:(CMTime)time;
- (void)audioPlayerCurrentItemPreloaded:(CMTime)time;
- (void)audioPlayerDidFailed:(nullable AVPlayerItem *)item error:(nullable NSError *)error;
- (void)audioPlayerReadyToPlay:(nullable AVPlayerItem *)item;
- (void)audioPlayerItemFailedToPlayEndTime:(AVPlayerItem *)item error:(nullable NSError *)error;
- (void)audioPlayerItemPlaybackStall:(AVPlayerItem *)item;

@end

@protocol FWAudioPlayerDataSource <NSObject>

@optional

/// Asks the data source to return the number of items that FWAudioPlayer would play
- (NSInteger)audioPlayerNumberOfItems;

/// Source URL provider, audioPlayerAsyncSetUrlForItemAtIndex:preBuffer: is for async task usage
- (nullable NSURL *)audioPlayerURLForItemAtIndex:(NSInteger)index preBuffer:(BOOL)preBuffer;

/// Source URL provider, would excute until you call setupPlayerItemWithUrl:index:
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
@interface FWAudioPlayer : NSObject

@property (class, nonatomic, readonly) FWAudioPlayer *sharedInstance;

@property (nonatomic, strong, nullable) AVQueuePlayer *audioPlayer;
@property (nonatomic, weak, nullable) id<FWAudioPlayerDelegate> delegate;
@property (nonatomic, weak, nullable) id<FWAudioPlayerDataSource> dataSource;
@property (nonatomic, assign) NSInteger itemsCount;
@property (nonatomic, assign) BOOL disableLogs;
@property (nonatomic, strong, readonly, nullable) NSArray *playerItems;

@property (nonatomic, assign) FWAudioPlayerRepeatMode repeatMode;
@property (nonatomic, assign) FWAudioPlayerShuffleMode shuffleMode;
@property (nonatomic, assign) BOOL isMemoryCached;

@property (nonatomic, assign, readonly) BOOL isPlaying;
@property (nonatomic, assign, readonly) NSInteger lastItemIndex;
@property (nonatomic, strong, readonly, nullable) AVPlayerItem *currentItem;
@property (nonatomic, assign, readonly) FWAudioPlayerStatus playerStatus;

@property (nonatomic, assign, readonly) float playingItemCurrentTime;
@property (nonatomic, assign, readonly) float playingItemDurationTime;
@property (nonatomic, assign) BOOL observePeriodicTime;

/// necessary if you implement audioPlayerAsyncSetUrlForItemAtIndex:preBuffer: delegate method, should not use this method outside of audioPlayerAsyncSetUrlForItemAtIndex:preBuffer: scope
- (void)setupPlayerItemWithUrl:(NSURL *)url index:(NSInteger)index;
- (void)setupPlayerItemWithAVURLAsset:(AVURLAsset *)asset index:(NSInteger)index;
- (void)fetchAndPlayPlayerItem:(NSInteger)startAt;
- (void)removeAllItems;
- (void)removeQueuesAtPlayer;

- (nullable NSNumber *)getAudioIndex:(nullable AVPlayerItem *)item;
- (void)removeItemAtIndex:(NSInteger)index;
- (void)moveItemFromIndex:(NSInteger)from toIndex:(NSInteger)to;
- (void)play;
- (void)pause;
- (void)playPrevious;
- (void)playNext;
- (void)seekToTime:(double)CMTime;
- (void)seekToTime:(double)CMTime withCompletionBlock:(nullable void (^)(BOOL finished))completionBlock;

- (id)addBoundaryTimeObserverForTimes:(NSArray *)times queue:(nullable dispatch_queue_t)queue usingBlock:(void (^)(void))block;
- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(nullable dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;
- (void)removeTimeObserver:(id)observer;

- (void)destroyPlayer;

@end

NS_ASSUME_NONNULL_END
