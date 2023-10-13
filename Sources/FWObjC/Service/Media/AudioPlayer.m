//
//  AudioPlayer.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "AudioPlayer.h"
#import "ObjC.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioSession.h>

typedef NS_ENUM(NSInteger, __FWAudioPauseReason) {
    __FWAudioPauseReasonNone,
    __FWAudioPauseReasonForced,
    __FWAudioPauseReasonBuffering,
};

@interface __FWAudioPlayer ()
{
    BOOL routeChangedWhilePlaying;
    BOOL interruptedWhilePlaying;
    BOOL isPreBuffered;
    BOOL tookAudioFocus;
    
    NSInteger prepareingItemHash;
    dispatch_queue_t audioQueue;
}

@property (nonatomic, strong, readwrite) NSArray<AVPlayerItem *> *playerItems;
@property (nonatomic) NSInteger lastItemIndex;
@property (nonatomic) __FWAudioPauseReason pauseReason;
@property (nonatomic, strong) NSMutableSet *playedItems;
@property (nonatomic, strong) id periodicTimeToken;

@end

@implementation __FWAudioPlayer

#pragma mark - Lifecycle

+ (__FWAudioPlayer *)sharedInstance
{
    static __FWAudioPlayer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        audioQueue = dispatch_queue_create("com.audio.queue", NULL);
        _playerItems = [NSArray array];
        _repeatMode = __FWAudioPlayerRepeatModeOff;
        _shuffleMode = __FWAudioPlayerShuffleModeOff;
    }
    return self;
}

- (void)preAction
{
    tookAudioFocus = YES;
    
    [self backgroundPlayable];
    self.audioPlayer = [[AVQueuePlayer alloc] init];
    self.audioPlayer.automaticallyWaitsToMinimizeStalling = NO;
    [self AVAudioSessionNotification];
}

- (void)backgroundPlayable
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    if (audioSession.category != AVAudioSessionCategoryPlayback) {
        UIDevice *device = [UIDevice currentDevice];
        if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
            if (device.multitaskingSupported) {
                NSError *aError = nil;
                [audioSession setCategory:AVAudioSessionCategoryPlayback error:&aError];
                if (aError) {
                    if (!self.disableLogs) {
                        FWLogDebug(@"FWAudioPlayer: set category error:%@",[aError description]);
                    }
                }
                aError = nil;
                [audioSession setActive:YES error:&aError];
                if (aError) {
                    if (!self.disableLogs) {
                        FWLogDebug(@"FWAudioPlayer: set active error:%@",[aError description]);
                    }
                }
            }
        }
    }else {
        if (!self.disableLogs) {
            FWLogDebug(@"FWAudioPlayer: unable to register background playback");
        }
    }
}

- (void)setAudioIndex:(AVPlayerItem *)item key:(NSNumber *)order
{
    if (!item) return;
    objc_setAssociatedObject(item, @selector(getAudioIndex:), order, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)getAudioIndex:(AVPlayerItem *)item
{
    if (!item) return nil;
    return objc_getAssociatedObject(item, @selector(getAudioIndex:));
}

#pragma mark - Player

- (void)willPlayPlayerItemAtIndex:(NSInteger)index
{
    if (!tookAudioFocus) {
        [self preAction];
    }
    self.lastItemIndex = index;
    [self.playedItems addObject:@(index)];
    
    if ([self.delegate respondsToSelector:@selector(audioPlayerWillChangedAtIndex:)]) {
        [self.delegate audioPlayerWillChangedAtIndex:self.lastItemIndex];
    }
}

- (void)playItemFromIndex:(NSInteger)startIndex
{
    [self willPlayPlayerItemAtIndex:startIndex];
    [self.audioPlayer pause];
    [self.audioPlayer removeAllItems];
    BOOL foundSource = [self findSourceInPlayerItems:startIndex];
    if (!foundSource) {
        [self getSourceURLAtIndex:startIndex preBuffer:NO];
    } else if (self.audioPlayer.currentItem.status == AVPlayerStatusReadyToPlay) {
        [self.audioPlayer play];
    }
}

- (NSInteger)audioPlayerItemsCount
{
    if ([self.dataSource respondsToSelector:@selector(audioPlayerNumberOfItems)]) {
        return [self.dataSource audioPlayerNumberOfItems];
    }
    return self.itemsCount;
}

- (void)getSourceURLAtIndex:(NSInteger)index preBuffer:(BOOL)preBuffer
{
    if ([self.dataSource respondsToSelector:@selector(audioPlayerURLForItemAtIndex:preBuffer:)]) {
        id url = [self.dataSource audioPlayerURLForItemAtIndex:index preBuffer:preBuffer];
        dispatch_async(audioQueue, ^{
            [self setupPlayerItemWithURL:url index:index];
        });
    } else if ([self.dataSource respondsToSelector:@selector(audioPlayerLoadItemAtIndex:preBuffer:)]) {
        [self.dataSource audioPlayerLoadItemAtIndex:index preBuffer:preBuffer];
    } else {
        if (index < self.itemURLs.count) {
            id url = self.itemURLs[index];
            dispatch_async(audioQueue, ^{
                [self setupPlayerItemWithURL:url index:index];
            });
        }
    }
}

- (void)setupPlayerItemWithURL:(id)url index:(NSInteger)index
{
    if (!url) return;
    AVPlayerItem *item;
    if ([url isKindOfClass:[AVPlayerItem class]]) {
        item = (AVPlayerItem *)url;
    } else if ([url isKindOfClass:[NSURL class]]) {
        item = [AVPlayerItem playerItemWithURL:(NSURL *)url];
    } else if ([url isKindOfClass:[AVURLAsset class]]) {
        item = [AVPlayerItem playerItemWithAsset:(AVURLAsset *)url];
    }
    if (!item) return;
    
    [self setupPlayerItemWithAVPlayerItem:item index:index];
}

- (void)setupPlayerItemWithAVPlayerItem:(AVPlayerItem *)playerItem index:(NSInteger)index
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setAudioIndex:playerItem key:[NSNumber numberWithInteger:index]];
        if (self.isMemoryCached) {
            NSMutableArray *playerItems = [NSMutableArray arrayWithArray:self.playerItems];
            [playerItems addObject:playerItem];
            self.playerItems = playerItems;
        }
        [self insertPlayerItem:playerItem];
    });
}

- (BOOL)findSourceInPlayerItems:(NSInteger)index
{
    for (AVPlayerItem *item in self.playerItems) {
        NSInteger checkIndex = [[self getAudioIndex:item] integerValue];
        if (checkIndex == index) {
            if (item.status == AVPlayerItemStatusReadyToPlay) {
                [item seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
                    [self insertPlayerItem:item];
                }];
                return YES;
            }
        }
    }
    return NO;
}

- (void)prepareNextPlayerItem
{
    if (_shuffleMode == __FWAudioPlayerShuffleModeOn || _repeatMode == __FWAudioPlayerRepeatModeOnce) return;
    
    NSInteger nowIndex = self.lastItemIndex;
    BOOL findInPlayerItems = NO;
    NSInteger itemsCount = [self audioPlayerItemsCount];
    
    if (nowIndex + 1 < itemsCount) {
        findInPlayerItems = [self findSourceInPlayerItems:nowIndex + 1];
        
        if (!findInPlayerItems) {
            [self getSourceURLAtIndex:nowIndex + 1 preBuffer:YES];
        }
    }
}

- (void)insertPlayerItem:(AVPlayerItem *)item
{
    if ([self.audioPlayer.items count] > 1) {
        for (int i = 1 ; i < [self.audioPlayer.items count] ; i ++) {
            [self.audioPlayer removeItem:[self.audioPlayer.items objectAtIndex:i]];
        }
    }
    if ([self.audioPlayer canInsertItem:item afterItem:nil]) {
        [self.audioPlayer insertItem:item afterItem:nil];
    }
}

- (void)removeAllItems
{
    for (AVPlayerItem *obj in self.audioPlayer.items) {
        [obj seekToTime:kCMTimeZero completionHandler:nil];
        @try {
            [obj removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
            [obj removeObserver:self forKeyPath:@"status" context:nil];
        } @catch(id anException) {
            //do nothing, obviously it wasn't attached because an exception was thrown
        }
    }
    
    self.playerItems = [self isMemoryCached] ? [NSArray array] : nil;
    [self.audioPlayer removeAllItems];
}

- (void)removeQueueItems
{
    while (self.audioPlayer.items.count > 1) {
        [self.audioPlayer removeItem:[self.audioPlayer.items objectAtIndex:1]];
    }
}

- (void)removeItemAtIndex:(NSInteger)index
{
    if ([self isMemoryCached]) {
        for (AVPlayerItem *item in [NSArray arrayWithArray:self.playerItems]) {
            NSInteger checkIndex = [[self getAudioIndex:item] integerValue];
            if (checkIndex == index) {
                NSMutableArray *playerItems = [NSMutableArray arrayWithArray:self.playerItems];
                [playerItems removeObject:item];
                self.playerItems = playerItems;
                
                if ([self.audioPlayer.items indexOfObject:item] != NSNotFound) {
                    [self.audioPlayer removeItem:item];
                }
            } else if (checkIndex > index) {
                [self setAudioIndex:item key:[NSNumber numberWithInteger:checkIndex -1]];
            }
        }
    } else {
        for (AVPlayerItem *item in self.audioPlayer.items) {
            NSInteger checkIndex = [[self getAudioIndex:item] integerValue];
            if (checkIndex == index) {
                [self.audioPlayer removeItem:item];
            } else if (checkIndex > index) {
                [self setAudioIndex:item key:[NSNumber numberWithInteger:checkIndex -1]];
            }
        }
    }
}

- (void)moveItemFromIndex:(NSInteger)from toIndex:(NSInteger)to
{
    for (AVPlayerItem *item in self.playerItems) {
        [self resetItemIndexIfNeeds:item fromIndex:from toIndex:to];
    }
    
    for (AVPlayerItem *item in self.audioPlayer.items) {
        if ([self resetItemIndexIfNeeds:item fromIndex:from toIndex:to]) {
            [self removeQueueItems];
        }
    }
}

- (BOOL)resetItemIndexIfNeeds:(AVPlayerItem *)item fromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex
{
    NSInteger checkIndex = [[self getAudioIndex:item] integerValue];
    BOOL found = NO;
    NSNumber *replaceOrder;
    if (checkIndex == sourceIndex) {
        replaceOrder = [NSNumber numberWithInteger:destinationIndex];
        found = YES;
    } else if (checkIndex == destinationIndex) {
        replaceOrder = sourceIndex > checkIndex ? @(checkIndex + 1) : @(checkIndex - 1);
        found = YES;
    } else if (checkIndex > destinationIndex && checkIndex < sourceIndex) {
        replaceOrder = [NSNumber numberWithInteger:(checkIndex + 1)];
        found = YES;
    } else if (checkIndex < destinationIndex && checkIndex > sourceIndex) {
        replaceOrder = [NSNumber numberWithInteger:(checkIndex - 1)];
        found = YES;
    }
    
    if (replaceOrder) {
        [self setAudioIndex:item key:replaceOrder];
        if (self.lastItemIndex == checkIndex) {
            self.lastItemIndex = [replaceOrder integerValue];
        }
    }
    return found;
}

- (void)seekToTime:(double)seconds
{
    [self.audioPlayer seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC)];
}

- (void)seekToTime:(double)seconds withCompletionBlock:(void (^)(BOOL))completionBlock
{
    [self.audioPlayer seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        if (completionBlock) {
            completionBlock(finished);
        }
    }];
}

- (void)play
{
    _pauseReason = __FWAudioPauseReasonNone;
    [self.audioPlayer play];
}

- (void)pause
{
    _pauseReason = __FWAudioPauseReasonForced;
    [self.audioPlayer pause];
}

- (void)playNext
{
    if (_shuffleMode == __FWAudioPlayerShuffleModeOn) {
        NSInteger nextIndex = [self randomIndex];
        if (nextIndex != NSNotFound) {
            [self playItemFromIndex:nextIndex];
        } else {
            _pauseReason = __FWAudioPauseReasonForced;
            if ([self.delegate respondsToSelector:@selector(audioPlayerDidReachEnd)]) {
                [self.delegate audioPlayerDidReachEnd];
            }
        }
    } else {
        NSNumber *nowIndexNumber = [self getAudioIndex:self.audioPlayer.currentItem];
        NSInteger nowIndex = nowIndexNumber ? [nowIndexNumber integerValue] : self.lastItemIndex;
        if (nowIndex + 1 < [self audioPlayerItemsCount]) {
            if (self.audioPlayer.items.count > 1) {
                [self willPlayPlayerItemAtIndex:nowIndex + 1];
                [self.audioPlayer advanceToNextItem];
            } else {
                [self playItemFromIndex:(nowIndex + 1)];
            }
        } else {
            if (_repeatMode == __FWAudioPlayerRepeatModeOff) {
                _pauseReason = __FWAudioPauseReasonForced;
                if ([self.delegate respondsToSelector:@selector(audioPlayerDidReachEnd)]) {
                    [self.delegate audioPlayerDidReachEnd];
                }
            } else {
                [self playItemFromIndex:0];
            }
        }
    }
}

- (void)playPrevious
{
    NSInteger nowIndex = [[self getAudioIndex:self.audioPlayer.currentItem] integerValue];
    if (nowIndex == 0) {
        if (_repeatMode == __FWAudioPlayerRepeatModeOn) {
            [self playItemFromIndex:[self audioPlayerItemsCount] - 1];
        } else {
            [self pause];
            [self.audioPlayer.currentItem seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
                [self play];
            }];
        }
    } else {
        [self playItemFromIndex:(nowIndex - 1)];
    }
}

- (CMTime)playerItemDuration
{
    NSError *err = nil;
    if ([self.audioPlayer.currentItem.asset statusOfValueForKey:@"duration" error:&err] == AVKeyValueStatusLoaded) {
        AVPlayerItem *playerItem = [self.audioPlayer currentItem];
        NSArray *loadedRanges = playerItem.seekableTimeRanges;
        if (loadedRanges.count > 0)
        {
            CMTimeRange range = [[loadedRanges objectAtIndex:0] CMTimeRangeValue];
            //Float64 duration = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration);
            return (range.duration);
        }else {
            return (kCMTimeInvalid);
        }
    } else {
        return (kCMTimeInvalid);
    }
}

- (void)setShuffleMode:(__FWAudioPlayerShuffleMode)mode
{
    switch (mode) {
        case __FWAudioPlayerShuffleModeOff:
            _shuffleMode = __FWAudioPlayerShuffleModeOff;
            [_playedItems removeAllObjects];
            _playedItems = nil;
            break;
        case __FWAudioPlayerShuffleModeOn:
            _shuffleMode = __FWAudioPlayerShuffleModeOn;
            _playedItems = [NSMutableSet set];
            if (self.audioPlayer.currentItem) {
                [self.playedItems addObject:[self getAudioIndex:self.audioPlayer.currentItem]];
            }
            break;
        default:
            break;
    }
}

#pragma mark - Info

- (BOOL)isPlaying
{
    return self.audioPlayer.rate != 0.f;
}

- (AVPlayerItem *)currentItem
{
    return self.audioPlayer.currentItem;
}

- (__FWAudioPlayerStatus)playerStatus
{
    if ([self isPlaying]) {
        return __FWAudioPlayerStatusPlaying;
    } else {
        switch (_pauseReason) {
            case __FWAudioPauseReasonForced:
                return __FWAudioPlayerStatusForcePause;
            case __FWAudioPauseReasonBuffering:
                return __FWAudioPlayerStatusBuffering;
            default:
                return __FWAudioPlayerStatusUnknown;
        }
    }
}

- (float)playingItemCurrentTime
{
    CMTime itemCurrentTime = [[self.audioPlayer currentItem] currentTime];
    float current = CMTimeGetSeconds(itemCurrentTime);
    if (CMTIME_IS_INVALID(itemCurrentTime) || !isfinite(current))
        return 0.0f;
    else
        return current;
}

- (float)playingItemDurationTime
{
    CMTime itemDurationTime = [self playerItemDuration];
    float duration = CMTimeGetSeconds(itemDurationTime);
    if (CMTIME_IS_INVALID(itemDurationTime) || !isfinite(duration))
        return 0.0f;
    else
        return duration;
}

- (void)setObservePeriodicTime:(BOOL)observePeriodicTime
{
    if (_observePeriodicTime == observePeriodicTime) return;
    _observePeriodicTime = observePeriodicTime;
    if (!observePeriodicTime && self.periodicTimeToken) {
        [self removeTimeObserver:self.periodicTimeToken];
        self.periodicTimeToken = nil;
    }
}

- (id)addBoundaryTimeObserverForTimes:(NSArray *)times queue:(dispatch_queue_t)queue usingBlock:(void (^)(void))block
{
    id boundaryObserver = [self.audioPlayer addBoundaryTimeObserverForTimes:times queue:queue usingBlock:block];
    return boundaryObserver;
}

- (id)addPeriodicTimeObserverForInterval:(CMTime)interval
                                   queue:(dispatch_queue_t)queue
                              usingBlock:(void (^)(CMTime time))block
{
    id mTimeObserver = [self.audioPlayer addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
    return mTimeObserver;
}

- (void)removeTimeObserver:(id)observer
{
    [self.audioPlayer removeTimeObserver:observer];
}

- (BOOL)isMemoryCached
{
    return self.playerItems != nil;
}

- (void)setIsMemoryCached:(BOOL)memoryCache
{
    if (self.playerItems == nil && memoryCache) {
        self.playerItems = [NSArray array];
    } else if (self.playerItems != nil && !memoryCache) {
        self.playerItems = nil;
    }
}

#pragma mark - Interruption

- (void)AVAudioSessionNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemFailedToPlayEndTime:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemPlaybackStall:)
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interruption:)
                                                 name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(routeChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    
    [self.audioPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    [self.audioPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
    [self.audioPlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)interruption:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interuptionType = [[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    
    if (interuptionType == AVAudioSessionInterruptionTypeBegan && _pauseReason != __FWAudioPauseReasonForced) {
        interruptedWhilePlaying = YES;
        [self pause];
    } else if (interuptionType == AVAudioSessionInterruptionTypeEnded && interruptedWhilePlaying) {
        interruptedWhilePlaying = NO;
        [self play];
    }
    if (!self.disableLogs) {
        FWLogDebug(@"FWAudioPlayer: interruption: %@", interuptionType == AVAudioSessionInterruptionTypeBegan ? @"began" : @"end");
    }
}

- (void)routeChange:(NSNotification *)notification
{
    NSDictionary *routeChangeDict = notification.userInfo;
    NSInteger routeChangeType = [[routeChangeDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    if (routeChangeType == AVAudioSessionRouteChangeReasonOldDeviceUnavailable && _pauseReason != __FWAudioPauseReasonForced) {
        routeChangedWhilePlaying = YES;
        [self pause];
    } else if (routeChangeType == AVAudioSessionRouteChangeReasonNewDeviceAvailable && routeChangedWhilePlaying) {
        routeChangedWhilePlaying = NO;
        [self play];
    }
    if (!self.disableLogs) {
        FWLogDebug(@"FWAudioPlayer: routeChanged: %@", routeChangeType == AVAudioSessionRouteChangeReasonNewDeviceAvailable ? @"New Device Available" : @"Old Device Unavailable");
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == self.audioPlayer && [keyPath isEqualToString:@"status"]) {
        if (self.audioPlayer.status == AVPlayerStatusReadyToPlay) {
            if (self.observePeriodicTime && !self.periodicTimeToken) {
                __weak __typeof__(self) self_weak_ = self;
                self.periodicTimeToken = [self addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                    __typeof__(self) self = self_weak_;
                    if ([self.delegate respondsToSelector:@selector(audioPlayerCurrentTimeChanged:)]) {
                        [self.delegate audioPlayerCurrentTimeChanged:time];
                    }
                }];
            }
            if ([self.delegate respondsToSelector:@selector(audioPlayerReadyToPlay:)]) {
                [self.delegate audioPlayerReadyToPlay:nil];
            }
            if (![self isPlaying]) {
                [self.audioPlayer play];
            }
        } else if (self.audioPlayer.status == AVPlayerStatusFailed) {
            if (!self.disableLogs) {
                FWLogDebug(@"FWAudioPlayer: %@", self.audioPlayer.error);
            }
            
            if ([self.delegate respondsToSelector:@selector(audioPlayerDidFailed:error:)]) {
                [self.delegate audioPlayerDidFailed:nil error:self.audioPlayer.error];
            }
        }
    }
    
    if (object == self.audioPlayer && [keyPath isEqualToString:@"rate"]) {
        if ([self.delegate respondsToSelector:@selector(audioPlayerRateChanged:)]) {
            [self.delegate audioPlayerRateChanged:[self isPlaying]];
        }
    }
    
    if (object == self.audioPlayer && [keyPath isEqualToString:@"currentItem"]) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        AVPlayerItem *lastPlayerItem = [change objectForKey:NSKeyValueChangeOldKey];
        if (lastPlayerItem != (id)[NSNull null] && lastPlayerItem != nil) {
            @try {
                [lastPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
                [lastPlayerItem removeObserver:self forKeyPath:@"status" context:nil];
            } @catch(id anException) {
                //do nothing, obviously it wasn't attached because an exception was thrown
            }
            
            if ([self.delegate respondsToSelector:@selector(audioPlayerCurrentItemEvicted:)]) {
                [self.delegate audioPlayerCurrentItemEvicted:lastPlayerItem];
            }
        }
        if (newPlayerItem != (id)[NSNull null]) {
            [newPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
            [newPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
            
            if ([self.delegate respondsToSelector:@selector(audioPlayerCurrentItemChanged:)]) {
                [self.delegate audioPlayerCurrentItemChanged:newPlayerItem];
            }
        }
    }
    
    if (object == self.audioPlayer.currentItem && [keyPath isEqualToString:@"status"]) {
        isPreBuffered = NO;
        if (self.audioPlayer.currentItem.status == AVPlayerItemStatusFailed) {
            if ([self.delegate respondsToSelector:@selector(audioPlayerDidFailed:error:)]) {
                [self.delegate audioPlayerDidFailed:self.audioPlayer.currentItem error:self.audioPlayer.currentItem.error];
            }
        } else if (self.audioPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            if ([self.delegate respondsToSelector:@selector(audioPlayerReadyToPlay:)]) {
                [self.delegate audioPlayerReadyToPlay:self.audioPlayer.currentItem];
            }
            if (![self isPlaying] && _pauseReason != __FWAudioPauseReasonForced) {
                [self.audioPlayer play];
            }
        }
    }
    
    if (self.audioPlayer.items.count > 1 && object == [self.audioPlayer.items objectAtIndex:1] && [keyPath isEqualToString:@"loadedTimeRanges"]) {
        isPreBuffered = YES;
    }
    
    if (object == self.audioPlayer.currentItem && [keyPath isEqualToString:@"loadedTimeRanges"]) {
        if (self.audioPlayer.currentItem.hash != prepareingItemHash) {
            [self prepareNextPlayerItem];
            prepareingItemHash = self.audioPlayer.currentItem.hash;
        }
        
        NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
        if (timeRanges && [timeRanges count]) {
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            
            if ([self.delegate respondsToSelector:@selector(audioPlayerCurrentItemPreloaded:)]) {
                [self.delegate audioPlayerCurrentItemPreloaded:CMTimeAdd(timerange.start, timerange.duration)];
            }
            
            if (self.audioPlayer.rate == 0 && _pauseReason != __FWAudioPauseReasonForced) {
                _pauseReason = __FWAudioPauseReasonBuffering;
                
                CMTime bufferdTime = CMTimeAdd(timerange.start, timerange.duration);
                CMTime milestone = CMTimeAdd(self.audioPlayer.currentTime, CMTimeMakeWithSeconds(5.0f, timerange.duration.timescale));
                
                if (CMTIME_COMPARE_INLINE(bufferdTime , >, milestone) && self.audioPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay && !interruptedWhilePlaying && !routeChangedWhilePlaying) {
                    if (![self isPlaying]) {
                        if (!self.disableLogs) {
                            FWLogDebug(@"FWAudioPlayer: resume from buffering..");
                        }
                        [self play];
                    }
                }
            }
        }
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    AVPlayerItem *item = [notification object];
    if (![item isEqual:self.audioPlayer.currentItem]) {
        return;
    }
    
    NSNumber *currentItemIndex = [self getAudioIndex:self.audioPlayer.currentItem];
    if (currentItemIndex) {
        if (_repeatMode == __FWAudioPlayerRepeatModeOnce) {
            NSInteger currentIndex = [currentItemIndex integerValue];
            [self playItemFromIndex:currentIndex];
        } else if (_shuffleMode == __FWAudioPlayerShuffleModeOn) {
            NSInteger nextIndex = [self randomIndex];
            if (nextIndex != NSNotFound) {
                [self playItemFromIndex:[self randomIndex]];
            } else {
                [self pause];
                if ([self.delegate respondsToSelector:@selector(audioPlayerDidReachEnd)]) {
                    [self.delegate audioPlayerDidReachEnd];
                }
            }
        } else {
            if (self.audioPlayer.items.count == 1 || !isPreBuffered) {
                NSInteger nowIndex = [currentItemIndex integerValue];
                if (nowIndex + 1 < [self audioPlayerItemsCount]) {
                    [self playNext];
                } else {
                    if (_repeatMode == __FWAudioPlayerRepeatModeOff) {
                        [self pause];
                        if ([self.delegate respondsToSelector:@selector(audioPlayerDidReachEnd)]) {
                            [self.delegate audioPlayerDidReachEnd];
                        }
                    }else {
                        [self playItemFromIndex:0];
                    }
                }
            }
        }
    }
}

- (void)playerItemFailedToPlayEndTime:(NSNotification *)notification {
    AVPlayerItem *item = [notification object];
    if (![item isEqual:self.audioPlayer.currentItem]) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(audioPlayerItemFailedToPlayEndTime:error:)]) {
        [self.delegate audioPlayerItemFailedToPlayEndTime:notification.object error:notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey]];
    }
}

- (void)playerItemPlaybackStall:(NSNotification *)notification {
    AVPlayerItem *item = [notification object];
    if (![item isEqual:self.audioPlayer.currentItem]) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(audioPlayerItemPlaybackStall:)]) {
        [self.delegate audioPlayerItemPlaybackStall:notification.object];
    }
}

- (NSInteger)randomIndex
{
    NSInteger itemsCount = [self audioPlayerItemsCount];
    if ([self.playedItems count] == itemsCount) {
        self.playedItems = [NSMutableSet set];
        if (_repeatMode == __FWAudioPlayerRepeatModeOff) {
            return NSNotFound;
        }
    }
    
    NSInteger index;
    do {
        index = arc4random() % itemsCount;
    } while ([_playedItems containsObject:[NSNumber numberWithInteger:index]]);
    
    return index;
}

#pragma mark - Deprecation

- (void)destroyPlayer
{
    tookAudioFocus = NO;
    NSError *error;
    [[AVAudioSession sharedInstance] setActive:NO error:&error];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    if (error) {
        if (!self.disableLogs) {
            FWLogDebug(@"FWAudioPlayer: set category error:%@", [error localizedDescription]);
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.periodicTimeToken) {
        [self removeTimeObserver:self.periodicTimeToken];
        self.periodicTimeToken = nil;
    }
    
    [self.audioPlayer removeObserver:self forKeyPath:@"status" context:nil];
    [self.audioPlayer removeObserver:self forKeyPath:@"rate" context:nil];
    [self.audioPlayer removeObserver:self forKeyPath:@"currentItem" context:nil];
    
    [self removeAllItems];
    
    [self.audioPlayer pause];
    self.delegate = nil;
    self.dataSource = nil;
    self.audioPlayer = nil;
}

@end
