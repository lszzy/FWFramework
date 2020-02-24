/*!
 @header     FWAnimatedImageView.h
 @indexgroup FWFramework
 @brief      FWAnimatedImageView
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/24
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 播放动画image视图，完全兼容UIImageView
 
 @see https://github.com/ibireme/YYImage
 */
@interface FWAnimatedImageView : UIImageView

// 是否自动播放动画图片，默认YES
@property (nonatomic) BOOL autoPlayAnimatedImage;

// 当前播放帧(从0开始)，可KVO监听
@property (nonatomic) NSUInteger currentAnimatedImageIndex;

// 当前是否正在播放动画
@property (nonatomic, readonly) BOOL currentIsPlayingAnimation;

// 当前动画timer模式，默认NSRunLoopCommonModes
@property (nonatomic, copy) NSString *runloopMode;

// 最大缓存大小，默认0动态计算
@property (nonatomic) NSUInteger maxBufferSize;

// 循环执行完成回调
@property (nonatomic, copy) void(^loopCompletionBlock)(NSUInteger loopCountRemaining);

@end

/*!
 @brief 动画image协议
 */
@protocol FWAnimatedImage <NSObject>

@required

// 动画image总frame数
- (NSUInteger)animatedImageFrameCount;

// 动画image循环次数，0为无限循环
- (NSUInteger)animatedImageLoopCount;

// 每帧的Bytes数
- (NSUInteger)animatedImageBytesPerFrame;

// 指定index的帧image，后台线程调用
- (nullable UIImage *)animatedImageFrameAtIndex:(NSUInteger)index;

// 指定index的帧时长
- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index;

@optional

// 指定index的动画图片区域，用于精灵动画
- (CGRect)animatedImageContentsRectAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
