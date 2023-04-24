//
//  ToastPluginImpl.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ToastPlugin.h"
#import "ToastView.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWToastPluginImpl

/// 默认吐司插件
NS_SWIFT_NAME(ToastPluginImpl)
@interface __FWToastPluginImpl : NSObject <__FWToastPlugin>

/// 单例模式
@property (class, nonatomic, readonly) __FWToastPluginImpl *sharedInstance NS_SWIFT_NAME(shared);

/// 显示吐司时是否执行淡入动画，默认YES
@property (nonatomic, assign) BOOL fadeAnimated;
/// 消息吐司自动隐藏时间，默认2.0
@property (nonatomic, assign) NSTimeInterval autoHideTime;
/// 加载吐司延迟隐藏时间，默认0.1
@property (nonatomic, assign) NSTimeInterval delayHideTime;
/// 吐司自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(__FWToastView *toastView);
/// 吐司重用句柄，show方法重用时自动调用
@property (nonatomic, copy, nullable) void (^reuseBlock)(__FWToastView *toastView);

/// 默认加载吐司文本句柄
@property (nonatomic, copy, nullable) NSAttributedString * _Nullable (^defaultLoadingText)(void);
/// 默认进度条吐司文本句柄
@property (nonatomic, copy, nullable) NSAttributedString * _Nullable (^defaultProgressText)(void);
/// 默认消息吐司文本句柄
@property (nonatomic, copy, nullable) NSAttributedString * _Nullable (^defaultMessageText)(__FWToastStyle style);

@end

NS_ASSUME_NONNULL_END
