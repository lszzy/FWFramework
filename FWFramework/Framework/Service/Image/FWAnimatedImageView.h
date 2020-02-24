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

NS_ASSUME_NONNULL_END
