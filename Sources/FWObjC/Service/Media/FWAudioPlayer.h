//
//  FWAudioPlayer.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <AvailabilityMacros.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// FWAudioPlayerDelegate, all delegate method is optional
NS_SWIFT_NAME(AudioPlayerDelegate)
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

NS_SWIFT_NAME(AudioPlayerDataSource)
@protocol FWAudioPlayerDataSource <NSObject>

@optional

/// Asks the data source to return the number of items that FWAudioPlayer would play
- (NSInteger)audioPlayerNumberOfItems;

/// Source URL provider, support NSURL|AVURLAsset|AVPlayerItem
- (nullable id)audioPlayerURLForItemAtIndex:(NSInteger)index preBuffer:(BOOL)preBuffer;

/// Source URL provider, would excute until you call setupPlayerItemWithURL:index:
- (void)audioPlayerLoadItemAtIndex:(NSInteger)index preBuffer:(BOOL)preBuffer;

@end

typedef NS_ENUM(NSInteger, FWAudioPlayerStatus) {
    FWAudioPlayerStatusPlaying = 0,
    FWAudioPlayerStatusForcePause,
    FWAudioPlayerStatusBuffering,
    FWAudioPlayerStatusUnknown,
} NS_SWIFT_NAME(AudioPlayerStatus);

typedef NS_ENUM(NSInteger, FWAudioPlayerRepeatMode) {
    FWAudioPlayerRepeatModeOn = 0,
    FWAudioPlayerRepeatModeOnce,
    FWAudioPlayerRepeatModeOff,
} NS_SWIFT_NAME(AudioPlayerRepeatMode);

typedef NS_ENUM(NSInteger, FWAudioPlayerShuffleMode) {
    FWAudioPlayerShuffleModeOn = 0,
    FWAudioPlayerShuffleModeOff,
} NS_SWIFT_NAME(AudioPlayerShuffleMode);

/**
 * FWAudioPlayer
 *
 * @see https://github.com/StreetVoice/HysteriaPlayer
 */
NS_SWIFT_NAME(AudioPlayer)
@interface FWAudioPlayer : NSObject

@property (class, nonatomic, readonly) FWAudioPlayer *sharedInstance;

@property (nonatomic, strong, nullable) AVQueuePlayer *audioPlayer;
@property (nonatomic, weak, nullable) id<FWAudioPlayerDelegate> delegate;
@property (nonatomic, weak, nullable) id<FWAudioPlayerDataSource> dataSource;
@property (nonatomic, assign) NSInteger itemsCount;
@property (nonatomic, copy, nullable) NSArray *itemURLs;
@property (nonatomic, assign) BOOL disableLogs;
@property (nonatomic, strong, readonly, nullable) NSArray<AVPlayerItem *> *playerItems;

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

/// should not use this method outside of audioPlayerLoadItemAtIndex:preBuffer: scope
- (void)setupPlayerItemWithURL:(id)url index:(NSInteger)index;
- (void)playItemFromIndex:(NSInteger)startIndex;
- (void)removeAllItems;
- (void)removeQueueItems;

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
