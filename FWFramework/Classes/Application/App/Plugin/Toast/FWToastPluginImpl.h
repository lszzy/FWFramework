/*!
 @header     FWToastPluginImpl.h
 @indexgroup FWFramework
 @brief      FWToastPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWToastPlugin.h"
#import "FWToastView.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWToastPluginImpl

/// 默认吐司插件
@interface FWToastPluginImpl : NSObject <FWToastPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWToastPluginImpl *sharedInstance;

/// 显示吐司时是否执行淡入动画，默认YES
@property (nonatomic, assign) BOOL fadeAnimated;
/// 吐司自动隐藏时间，默认2.0
@property (nonatomic, assign) NSTimeInterval delayTime;
/// 吐司自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(FWToastView *toastView);

/// 默认加载吐司文本句柄
@property (nonatomic, copy, nullable) NSAttributedString * _Nullable (^defaultLoadingText)(void);
/// 默认进度条吐司文本句柄
@property (nonatomic, copy, nullable) NSAttributedString * _Nullable (^defaultProgressText)(void);
/// 默认消息吐司文本句柄
@property (nonatomic, copy, nullable) NSAttributedString * _Nullable (^defaultMessageText)(FWToastStyle style);

@end

NS_ASSUME_NONNULL_END
