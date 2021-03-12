/*!
 @header     FWView.h
 @indexgroup FWFramework
 @brief      FWView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 定义类事件名称
 
 @param name 事件名称
 */
#define FWEvent( name ) \
    @property (nonatomic, readonly) NSString * name; \
    - (NSString *)name; \
    + (NSString *)name;

/*!
 @brief 定义类事件名称实现
 
 @param name 事件名称
 */
#define FWDefEvent( name ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return [NSString stringWithFormat:@"%@.%@.%s", @"event", NSStringFromClass([self class]), #name]; }

/*!
 @brief FWViewDelegate
 */
@protocol FWViewDelegate <NSObject>

/// 通用事件代理方法，通知名称即为事件名称
- (void)fwEventReceived:(__kindof UIView *)view withNotification:(NSNotification *)notification;

@end

/*!
 @brief UIView+FWView
 */
@interface UIView (FWView)

/// 通用视图模型，可监听
@property (nonatomic, strong, nullable) id fwViewModel;

/// 通用事件接收代理，弱引用，Delegate方式
@property (nonatomic, weak, nullable) id<FWViewDelegate> fwViewDelegate;

/// 通用事件接收句柄，Block方式
@property (nonatomic, copy, nullable) void (^fwEventReceived)(__kindof UIView *view, NSNotification *notification);

/// 发送指定事件，通知代理，支持附带对象和用户信息
- (void)fwSendEvent:(NSString *)name;
- (void)fwSendEvent:(NSString *)name object:(nullable id)object;
- (void)fwSendEvent:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
