/*!
 @header     FWMessage.h
 @indexgroup FWFramework
 @brief      点对点消息、广播通知管理器
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-16
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/*!
 @brief 定义类点对点消息
 
 @param name 消息名称
 */
#define FWMessage( name ) \
    @property (nonatomic, readonly) NSString * name; \
    - (NSString *)name; \
    + (NSString *)name;

/*!
 @brief 定义类点对点消息实现
 
 @param name 消息名称
 */
#define FWDefMessage( name ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return [NSString stringWithFormat:@"%@.%@.%s", @"message", NSStringFromClass([self class]), #name]; }

/*!
 @brief 定义类广播通知
 
 @param name 通知名称
 */
#define FWNotification( name ) \
    @property (nonatomic, readonly) NSString * name; \
    - (NSString *)name; \
    + (NSString *)name;

/*!
 @brief 定义类广播通知实现
 
 @param name 通知名称
 */
#define FWDefNotification( name ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return [NSString stringWithFormat:@"%@.%@.%s", @"notification", NSStringFromClass([self class]), #name]; }

#pragma mark - NSObject+FWMessage

/*!
 @brief 点对点消息分类
 */
@interface NSObject (FWMessage)

#pragma mark - Observer

/*!
 @brief 监听某个点对点消息，对象释放时自动移除监听，添加多次执行多次
 
 @param name  消息名称
 @param block 消息句柄
 */
- (void)fwObserveMessage:(NSString *)name block:(void (^)(NSNotification *notification))block;

/*!
 @brief 监听某个指定对象点对点消息，对象释放时自动移除监听，添加多次执行多次
 
 @param name   消息名称
 @param object 消息对象，值为nil时表示所有
 @param block  消息句柄
 */
- (void)fwObserveMessage:(NSString *)name object:(nullable id)object block:(void (^)(NSNotification *notification))block;

/*!
 @brief 监听某个点对点消息，对象释放时自动移除监听，添加多次执行多次
 
 @param name   消息名称
 @param target 消息目标
 @param action 目标动作，参数为通知对象
 */
- (void)fwObserveMessage:(NSString *)name target:(id)target action:(SEL)action;

/*!
 @brief 监听某个指定对象点对点消息，对象释放时自动移除监听，添加多次执行多次
 
 @param name   消息名称
 @param object 消息对象，值为nil时表示所有
 @param target 消息目标
 @param action 目标动作，参数为通知对象
 */
- (void)fwObserveMessage:(NSString *)name object:(nullable id)object target:(id)target action:(SEL)action;

/*!
 @brief 手工移除某个点对点消息指定监听
 
 @param name   消息名称
 @param target 消息目标
 @param action 目标动作
 */
- (void)fwUnobserveMessage:(NSString *)name target:(nullable id)target action:(nullable SEL)action;

/*!
 @brief 手工移除某个指定对象点对点消息指定监听
 
 @param name   消息名称
 @param object 消息对象，值为nil时表示所有
 @param target 消息目标
 @param action 目标动作
 */
- (void)fwUnobserveMessage:(NSString *)name object:(nullable id)object target:(nullable id)target action:(nullable SEL)action;

/*!
 @brief 手工移除某个点对点消息所有监听
 
 @param name 消息名称
 */
- (void)fwUnobserveMessage:(NSString *)name;

/*!
 @brief 手工移除某个指定对象点对点消息所有监听
 
 @param name   消息名称
 @param object 消息对象，值为nil时表示所有
 */
- (void)fwUnobserveMessage:(NSString *)name object:(nullable id)object;

/*!
 @brief 手工移除所有点对点消息监听
 */
- (void)fwUnobserveAllMessages;

#pragma mark - Subject

/*!
 @brief 发送类点对点消息
 
 @param name 消息名称
 @param receiver 消息接收者
 */
+ (void)fwSendMessage:(NSString *)name toReceiver:(id)receiver;

/*!
 @brief 发送类点对点消息，附带对象
 
 @param name   消息名称
 @param object 消息对象
 @param receiver 消息接收者
 */
+ (void)fwSendMessage:(NSString *)name object:(nullable id)object toReceiver:(id)receiver;

/*!
 @brief 发送类点对点消息，附带对象和用户信息
 
 @param name     消息名称
 @param object   消息对象
 @param userInfo 用户信息
 @param receiver 消息接收者
 */
+ (void)fwSendMessage:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo toReceiver:(id)receiver;

/*!
 @brief 发送点对点消息
 
 @param name 消息名称
 @param receiver 消息接收者
 */
- (void)fwSendMessage:(NSString *)name toReceiver:(id)receiver;

/*!
 @brief 发送点对点消息，附带对象
 
 @param name   消息名称
 @param object 消息对象
 @param receiver 消息接收者
 */
- (void)fwSendMessage:(NSString *)name object:(nullable id)object toReceiver:(id)receiver;

/*!
 @brief 发送点对点消息，附带对象和用户信息
 
 @param name     消息名称
 @param object   消息对象
 @param userInfo 用户信息
 @param receiver 消息接收者
 */
- (void)fwSendMessage:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo toReceiver:(id)receiver;

@end

#pragma mark - NSObject+FWNotification

/*!
 @brief 广播通知分类
 */
@interface NSObject (FWNotification)

#pragma mark - Observer

/*!
 @brief 监听某个广播通知，对象释放时自动移除监听，添加多次执行多次
 
 @param name  通知名称
 @param block 通知句柄
 */
- (void)fwObserveNotification:(NSString *)name block:(void (^)(NSNotification *notification))block;

/*!
 @brief 监听某个指定对象广播通知，对象释放时自动移除监听，添加多次执行多次
 
 @param name   通知名称
 @param object 通知对象，值为nil时表示所有
 @param block  通知句柄
 */
- (void)fwObserveNotification:(NSString *)name object:(nullable id)object block:(void (^)(NSNotification *notification))block;

/*!
 @brief 监听某个广播通知，对象释放时自动移除监听，添加多次执行多次
 
 @param name   通知名称
 @param target 通知目标
 @param action 目标动作，参数为通知对象
 */
- (void)fwObserveNotification:(NSString *)name target:(id)target action:(SEL)action;

/*!
 @brief 监听某个指定对象广播通知，对象释放时自动移除监听，添加多次执行多次
 
 @param name   通知名称
 @param object 通知对象，值为nil时表示所有
 @param target 通知目标
 @param action 目标动作，参数为通知对象
 */
- (void)fwObserveNotification:(NSString *)name object:(nullable id)object target:(id)target action:(SEL)action;

/*!
 @brief 手工移除某个广播通知指定监听
 
 @param name   通知名称
 @param target 通知目标
 @param action 目标动作
 */
- (void)fwUnobserveNotification:(NSString *)name target:(nullable id)target action:(nullable SEL)action;

/*!
 @brief 手工移除某个指定对象广播通知指定监听
 
 @param name   通知名称
 @param object 通知对象，值为nil时表示所有
 @param target 通知目标
 @param action 目标动作
 */
- (void)fwUnobserveNotification:(NSString *)name object:(nullable id)object target:(nullable id)target action:(nullable SEL)action;

/*!
 @brief 手工移除某个广播通知所有监听
 
 @param name 通知名称
 */
- (void)fwUnobserveNotification:(NSString *)name;

/*!
 @brief 手工移除某个指定对象广播通知所有监听
 
 @param name   通知名称
 @param object 通知对象，值为nil时表示所有
 */
- (void)fwUnobserveNotification:(NSString *)name object:(nullable id)object;

/*!
 @brief 手工移除所有广播通知监听
 */
- (void)fwUnobserveAllNotifications;

#pragma mark - Subject

/*!
 @brief 发送广播通知
 
 @param name 通知名称
 */
+ (void)fwPostNotification:(NSString *)name;

/*!
 @brief 发送广播通知，附带对象
 
 @param name   通知名称
 @param object 通知对象
 */
+ (void)fwPostNotification:(NSString *)name object:(nullable id)object;

/*!
 @brief 发送广播通知，附带对象和用户信息
 
 @param name     通知名称
 @param object   通知对象
 @param userInfo 用户信息
 */
+ (void)fwPostNotification:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

/*!
 @brief 发送广播通知
 
 @param name 通知名称
 */
- (void)fwPostNotification:(NSString *)name;

/*!
 @brief 发送广播通知，附带对象
 
 @param name   通知名称
 @param object 通知对象
 */
- (void)fwPostNotification:(NSString *)name object:(nullable id)object;

/*!
 @brief 发送广播通知，附带对象和用户信息
 
 @param name     通知名称
 @param object   通知对象
 @param userInfo 用户信息
 */
- (void)fwPostNotification:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end

#pragma mark - NSObject+FWKvo

/*!
 @brief KVO属性监听分类
 */
@interface NSObject (FWKvo)

/*!
 @brief 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
 
 @param property 属性名称
 @param block    目标句柄，block参数依次为object、优化的change字典(不含NSNull)
 */
- (void)fwObserveProperty:(NSString *)property block:(void (^)(id object, NSDictionary *change))block;

/*!
 @brief 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
 
 @param property 属性名称
 @param target   目标对象
 @param action   目标动作，action参数依次为object、优化的change字典(不含NSNull)
 */
- (void)fwObserveProperty:(NSString *)property target:(id)target action:(SEL)action;

/*!
 @brief 手工移除某个属性指定监听
 
 @param property 属性名称
 @param target   目标对象，值为nil时移除所有对象(同UIControl)
 @param action   目标动作，值为nil时移除所有动作(同UIControl)
 */
- (void)fwUnobserveProperty:(NSString *)property target:(nullable id)target action:(nullable SEL)action;

/*!
 @brief 手工移除某个属性所有监听
 
 @param property 属性名称
 */
- (void)fwUnobserveProperty:(NSString *)property;

/*!
 @brief 手工移除所有属性所有监听
 */
- (void)fwUnobserveAllProperties;

@end

NS_ASSUME_NONNULL_END
