/*!
 @header     FWAnimatedImageView.h
 @indexgroup FWFramework
 @brief      FWAnimatedImageView
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/27
 */

#import <UIKit/UIKit.h>
#import "FWAnimatedImage.h"

@interface SDAnimatedImageView : UIImageView

/**
 Current display frame image. This value is KVO Compliance.
 */
@property (nonatomic, strong, readonly, nullable) UIImage *currentFrame;
/**
 Current frame index, zero based. This value is KVO Compliance.
 */
@property (nonatomic, assign, readonly) NSUInteger currentFrameIndex;
/**
 Current loop count since its latest animating. This value is KVO Compliance.
 */
@property (nonatomic, assign, readonly) NSUInteger currentLoopCount;
/**
 YES to choose `animationRepeatCount` property for animation loop count. No to use animated image's `animatedImageLoopCount` instead.
 Default is NO.
 */
@property (nonatomic, assign) BOOL shouldCustomLoopCount;
/**
 Total loop count for animated image rendering. Default is animated image's loop count.
 If you need to set custom loop count, set `shouldCustomLoopCount` to YES and change this value.
 This class override UIImageView's `animationRepeatCount` property on iOS, use this property as well.
 */
@property (nonatomic, assign) NSInteger animationRepeatCount;
/**
 The animation playback rate. Default is 1.0.
 `1.0` means the normal speed.
 `0.0` means stopping the animation.
 `0.0-1.0` means the slow speed.
 `> 1.0` means the fast speed.
 `< 0.0` is not supported currently and stop animation. (may support reverse playback in the future)
 */
@property (nonatomic, assign) double playbackRate;
/**
 Provide a max buffer size by bytes. This is used to adjust frame buffer count and can be useful when the decoding cost is expensive (such as Animated WebP software decoding). Default is 0.
 `0` means automatically adjust by calculating current memory usage.
 `1` means without any buffer cache, each of frames will be decoded and then be freed after rendering. (Lowest Memory and Highest CPU)
 `NSUIntegerMax` means cache all the buffer. (Lowest CPU and Highest Memory)
 */
@property (nonatomic, assign) NSUInteger maxBufferSize;
/**
 Whehter or not to enable incremental image load for animated image. This is for the animated image which `sd_isIncremental` is YES (See `UIImage+Metadata.h`). If enable, animated image rendering will stop at the last frame available currently, and continue when another `setImage:` trigger, where the new animated image's `animatedImageData` should be updated from the previous one. If the `sd_isIncremental` is NO. The incremental image load stop.
 @note If you are confused about this description, open Chrome browser to view some large GIF images with low network speed to see the animation behavior.
 @note The best practice to use incremental load is using `initWithAnimatedCoder:scale:` in `SDAnimatedImage` with animated coder which conform to `SDProgressiveImageCoder` as well. Then call incremental update and incremental decode method to produce the image.
 Default is YES. Set to NO to only render the static poster for incremental animated image.
 */
@property (nonatomic, assign) BOOL shouldIncrementalLoad;

/**
 Whether or not to clear the frame buffer cache when animation stopped. See `maxBufferSize`
 This is useful when you want to limit the memory usage during frequently visibility changes (such as image view inside a list view, then push and pop)
 Default is NO.
 */
@property (nonatomic, assign) BOOL clearBufferWhenStopped;

/**
 Whether or not to reset the current frame index when animation stopped.
 For some of use case, you may want to reset the frame index to 0 when stop, but some other want to keep the current frame index.
 Default is NO.
 */
@property (nonatomic, assign) BOOL resetFrameIndexWhenStopped;

/**
 You can specify a runloop mode to let it rendering.
 Default is NSRunLoopCommonModes on multi-core device, NSDefaultRunLoopMode on single-core device
 @note This is useful for some cases, for example, always specify NSDefaultRunLoopMode, if you want to pause the animation when user scroll (for Mac user, drag the mouse or touchpad)
 */
@property (nonatomic, copy, nonnull) NSRunLoopMode runLoopMode;
@end

@interface SDAnimatedImagePlayer : NSObject

/// Current playing frame image. This value is KVO Compliance.
@property (nonatomic, readonly, nullable) UIImage *currentFrame;

/// Current frame index, zero based. This value is KVO Compliance.
@property (nonatomic, readonly) NSUInteger currentFrameIndex;

/// Current loop count since its latest animating. This value is KVO Compliance.
@property (nonatomic, readonly) NSUInteger currentLoopCount;

/// Total frame count for niamted image rendering. Defaults is animated image's frame count.
/// @note For progressive animation, you can update this value when your provider receive more frames.
@property (nonatomic, assign) NSUInteger totalFrameCount;

/// Total loop count for animated image rendering. Default is animated image's loop count.
@property (nonatomic, assign) NSUInteger totalLoopCount;

/// The animation playback rate. Default is 1.0
/// `1.0` means the normal speed.
/// `0.0` means stopping the animation.
/// `0.0-1.0` means the slow speed.
/// `> 1.0` means the fast speed.
/// `< 0.0` is not supported currently and stop animation. (may support reverse playback in the future)
@property (nonatomic, assign) double playbackRate;

/// Provide a max buffer size by bytes. This is used to adjust frame buffer count and can be useful when the decoding cost is expensive (such as Animated WebP software decoding). Default is 0.
/// `0` means automatically adjust by calculating current memory usage.
/// `1` means without any buffer cache, each of frames will be decoded and then be freed after rendering. (Lowest Memory and Highest CPU)
/// `NSUIntegerMax` means cache all the buffer. (Lowest CPU and Highest Memory)
@property (nonatomic, assign) NSUInteger maxBufferSize;

/// You can specify a runloop mode to let it rendering.
/// Default is NSRunLoopCommonModes on multi-core device, NSDefaultRunLoopMode on single-core device
@property (nonatomic, copy, nonnull) NSRunLoopMode runLoopMode;

/// Create a player with animated image provider. If the provider's `animatedImageFrameCount` is less than 1, returns nil.
/// The provider can be any protocol implementation, like `SDAnimatedImage`, `SDImageGIFCoder`, etc.
/// @note This provider can represent mutable content, like prorgessive animated loading. But you need to update the frame count by yourself
/// @param provider The animated provider
- (nullable instancetype)initWithProvider:(nonnull id<SDAnimatedImageProvider>)provider;

/// Create a player with animated image provider. If the provider's `animatedImageFrameCount` is less than 1, returns nil.
/// The provider can be any protocol implementation, like `SDAnimatedImage` or `SDImageGIFCoder`, etc.
/// @note This provider can represent mutable content, like prorgessive animated loading. But you need to update the frame count by yourself
/// @param provider The animated provider
+ (nullable instancetype)playerWithProvider:(nonnull id<SDAnimatedImageProvider>)provider;

/// The handler block when current frame and index changed.
@property (nonatomic, copy, nullable) void (^animationFrameHandler)(NSUInteger index, UIImage * _Nonnull frame);

/// The handler block when one loop count finished.
@property (nonatomic, copy, nullable) void (^animationLoopHandler)(NSUInteger loopCount);

/// Return the status whehther animation is playing.
@property (nonatomic, readonly) BOOL isPlaying;

/// Start the animation. Or resume the previously paused animation.
- (void)startPlaying;

/// Pause the aniamtion. Keep the current frame index and loop count.
- (void)pausePlaying;

/// Stop the animation. Reset the current frame index and loop count.
- (void)stopPlaying;

/// Seek to the desired frame index and loop count.
/// @note This can be used for advanced control like progressive loading, or skipping specify frames.
/// @param index The frame index
/// @param loopCount The loop count
- (void)seekToFrameAtIndex:(NSUInteger)index loopCount:(NSUInteger)loopCount;

/// Clear the frame cache buffer. The frame cache buffer size can be controled by `maxBufferSize`.
/// By default, when stop or pause the animation, the frame buffer is still kept to ready for the next restart
- (void)clearFrameBuffer;

@end
