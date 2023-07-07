//
//  EmptyPluginImpl.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "EmptyPlugin.h"
#import "EmptyView.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWEmptyPluginImpl

/// 默认空界面插件
NS_SWIFT_NAME(EmptyPluginImpl)
@interface __FWEmptyPluginImpl : NSObject <__FWEmptyPlugin>

/// 单例模式
@property (class, nonatomic, readonly) __FWEmptyPluginImpl *sharedInstance NS_SWIFT_NAME(shared);

/// 显示空界面时是否执行淡入动画，默认YES
@property (nonatomic, assign) BOOL fadeAnimated;
/// 空界面自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(__FWEmptyView *emptyView);

/// 默认空界面文本句柄，非loading时才触发
@property (nonatomic, copy, nullable) id _Nullable (^defaultText)(void);
/// 默认空界面详细文本句柄，非loading时才触发
@property (nonatomic, copy, nullable) id _Nullable (^defaultDetail)(void);
/// 默认空界面图片句柄，非loading时才触发
@property (nonatomic, copy, nullable) UIImage * _Nullable (^defaultImage)(void);
/// 默认空界面动作按钮句柄，非loading时才触发
@property (nonatomic, copy, nullable) id _Nullable (^defaultAction)(void);

/// 错误空界面文本格式化句柄，error生效，默认nil
@property (nonatomic, copy, nullable) id _Nullable (^errorTextFormatter)(NSError * _Nullable error);
/// 错误空界面详细文本格式化句柄，error生效，默认nil
@property (nonatomic, copy, nullable) id _Nullable (^errorDetailFormatter)(NSError * _Nullable error);
/// 错误空界面图片格式化句柄，error生效，默认nil
@property (nonatomic, copy, nullable) UIImage * _Nullable (^errorImageFormatter)(NSError * _Nullable error);
/// 错误空界面动作按钮格式化句柄，error生效，默认nil
@property (nonatomic, copy, nullable) id _Nullable (^errorActionFormatter)(NSError * _Nullable error);

@end

NS_ASSUME_NONNULL_END
