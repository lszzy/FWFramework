/**
 @header     FWMessage.h
 @indexgroup FWFramework
      点对点消息、广播通知
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-16
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/**
 定义类点对点消息
 
 @param name 消息名称
 */
#define FWMessage( name ) \
    @property (nonatomic, readonly) NSNotificationName name; \
    - (NSNotificationName)name; \
    + (NSNotificationName)name;

/**
 定义类点对点消息实现
 
 @param name 消息名称
 */
#define FWDefMessage( name ) \
    @dynamic name; \
    - (NSNotificationName)name { return [[self class] name]; } \
    + (NSNotificationName)name { return [NSString stringWithFormat:@"%@.%@.%s", @"message", NSStringFromClass([self class]), #name]; }

/**
 定义类广播通知
 
 @param name 通知名称
 */
#define FWNotification( name ) \
    @property (nonatomic, readonly) NSNotificationName name; \
    - (NSNotificationName)name; \
    + (NSNotificationName)name;

/**
 定义类广播通知实现
 
 @param name 通知名称
 */
#define FWDefNotification( name ) \
    @dynamic name; \
    - (NSNotificationName)name { return [[self class] name]; } \
    + (NSNotificationName)name { return [NSString stringWithFormat:@"%@.%@.%s", @"notification", NSStringFromClass([self class]), #name]; }

#pragma mark - NSObject+FWMessage

@interface NSObject (FWMessage)

#pragma mark - Observer

/**
 监听某个点对点消息，对象释放时自动移除监听，添加多次执行多次
 
 @param name  消息名称
 @param block 消息句柄
 @return 监听唯一标志
 */
- (NSString *)fw_observeMessage:(NSNotificationName)name block:(void (^)(NSNotification *notification))block NS_REFINED_FOR_SWIFT;

/**
 监听某个指定对象点对点消息，对象释放时自动移除监听，添加多次执行多次
 
 @param name   消息名称
 @param object 消息对象，值为nil时表示所有
 @param block  消息句柄
 @return 监听唯一标志
 */
- (NSString *)fw_observeMessage:(NSNotificationName)name object:(nullable id)object block:(void (^)(NSNotification *notification))block NS_REFINED_FOR_SWIFT;

/**
 监听某个点对点消息，对象释放时自动移除监听，添加多次执行多次
 
 @param name   消息名称
 @param target 消息目标
 @param action 目标动作，参数为通知对象
 @return 监听唯一标志
 */
- (NSString *)fw_observeMessage:(NSNotificationName)name target:(nullable id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/**
 监听某个指定对象点对点消息，对象释放时自动移除监听，添加多次执行多次
 
 @param name   消息名称
 @param object 消息对象，值为nil时表示所有
 @param target 消息目标
 @param action 目标动作，参数为通知对象
 @return 监听唯一标志
 */
- (NSString *)fw_observeMessage:(NSNotificationName)name object:(nullable id)object target:(nullable id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/**
 手工移除某个点对点消息指定监听
 
 @param name   消息名称
 @param target 消息目标
 @param action 目标动作
 */
- (void)fw_unobserveMessage:(NSNotificationName)name target:(nullable id)target action:(nullable SEL)action NS_REFINED_FOR_SWIFT;

/**
 手工移除某个指定对象点对点消息指定监听
 
 @param name   消息名称
 @param object 消息对象，值为nil时表示所有
 @param target 消息目标
 @param action 目标动作
 */
- (void)fw_unobserveMessage:(NSNotificationName)name object:(nullable id)object target:(nullable id)target action:(nullable SEL)action NS_REFINED_FOR_SWIFT;

/**
 手工移除某个指定对象点对点消息指定监听
 
 @param name       消息名称
 @param identifier 监听唯一标志
 */
- (void)fw_unobserveMessage:(NSNotificationName)name identifier:(NSString *)identifier NS_REFINED_FOR_SWIFT;

/**
 手工移除某个点对点消息所有监听
 
 @param name 消息名称
 */
- (void)fw_unobserveMessage:(NSNotificationName)name NS_REFINED_FOR_SWIFT;

/**
 手工移除某个指定对象点对点消息所有监听
 
 @param name   消息名称
 @param object 消息对象，值为nil时表示所有
 */
- (void)fw_unobserveMessage:(NSNotificationName)name object:(nullable id)object NS_REFINED_FOR_SWIFT;

/**
 手工移除所有点对点消息监听
 */
- (void)fw_unobserveAllMessages NS_REFINED_FOR_SWIFT;

#pragma mark - Subject

/**
 发送点对点消息
 
 @param name 消息名称
 @param receiver 消息接收者
 */
- (void)fw_sendMessage:(NSNotificationName)name toReceiver:(id)receiver NS_REFINED_FOR_SWIFT;

/**
 发送点对点消息，附带对象
 
 @param name   消息名称
 @param object 消息对象
 @param receiver 消息接收者
 */
- (void)fw_sendMessage:(NSNotificationName)name object:(nullable id)object toReceiver:(id)receiver NS_REFINED_FOR_SWIFT;

/**
 发送点对点消息，附带对象和用户信息
 
 @param name     消息名称
 @param object   消息对象
 @param userInfo 用户信息
 @param receiver 消息接收者
 */
- (void)fw_sendMessage:(NSNotificationName)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo toReceiver:(id)receiver NS_REFINED_FOR_SWIFT;

/**
 发送类点对点消息
 
 @param name 消息名称
 @param receiver 消息接收者
 */
+ (void)fw_sendMessage:(NSNotificationName)name toReceiver:(id)receiver NS_REFINED_FOR_SWIFT;

/**
 发送类点对点消息，附带对象
 
 @param name   消息名称
 @param object 消息对象
 @param receiver 消息接收者
 */
+ (void)fw_sendMessage:(NSNotificationName)name object:(nullable id)object toReceiver:(id)receiver NS_REFINED_FOR_SWIFT;

/**
 发送类点对点消息，附带对象和用户信息
 
 @param name     消息名称
 @param object   消息对象
 @param userInfo 用户信息
 @param receiver 消息接收者
 */
+ (void)fw_sendMessage:(NSNotificationName)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo toReceiver:(id)receiver NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSObject+FWNotification

@interface NSObject (FWNotification)

#pragma mark - Observer

/**
 监听某个广播通知，对象释放时自动移除监听，添加多次执行多次
 
 @param name  通知名称
 @param block 通知句柄
 @return 监听唯一标志
 */
- (NSString *)fw_observeNotification:(NSNotificationName)name block:(void (^)(NSNotification *notification))block NS_REFINED_FOR_SWIFT;

/**
 监听某个指定对象广播通知，对象释放时自动移除监听，添加多次执行多次
 
 @param name   通知名称
 @param object 通知对象，值为nil时表示所有
 @param block  通知句柄
 @return 监听唯一标志
 */
- (NSString *)fw_observeNotification:(NSNotificationName)name object:(nullable id)object block:(void (^)(NSNotification *notification))block NS_REFINED_FOR_SWIFT;

/**
 监听某个广播通知，对象释放时自动移除监听，添加多次执行多次
 
 @param name   通知名称
 @param target 通知目标
 @param action 目标动作，参数为通知对象
 @return 监听唯一标志
 */
- (NSString *)fw_observeNotification:(NSNotificationName)name target:(nullable id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/**
 监听某个指定对象广播通知，对象释放时自动移除监听，添加多次执行多次
 
 @param name   通知名称
 @param object 通知对象，值为nil时表示所有
 @param target 通知目标
 @param action 目标动作，参数为通知对象
 @return 监听唯一标志
 */
- (NSString *)fw_observeNotification:(NSNotificationName)name object:(nullable id)object target:(nullable id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/**
 手工移除某个广播通知指定监听
 
 @param name   通知名称
 @param target 通知目标
 @param action 目标动作
 */
- (void)fw_unobserveNotification:(NSNotificationName)name target:(nullable id)target action:(nullable SEL)action NS_REFINED_FOR_SWIFT;

/**
 手工移除某个指定对象广播通知指定监听
 
 @param name   通知名称
 @param object 通知对象，值为nil时表示所有
 @param target 通知目标
 @param action 目标动作
 */
- (void)fw_unobserveNotification:(NSNotificationName)name object:(nullable id)object target:(nullable id)target action:(nullable SEL)action NS_REFINED_FOR_SWIFT;

/**
 手工移除某个指定对象广播通知指定监听
 
 @param name       通知名称
 @param identifier 监听唯一标志
 */
- (void)fw_unobserveNotification:(NSNotificationName)name identifier:(NSString *)identifier NS_REFINED_FOR_SWIFT;

/**
 手工移除某个广播通知所有监听
 
 @param name 通知名称
 */
- (void)fw_unobserveNotification:(NSNotificationName)name NS_REFINED_FOR_SWIFT;

/**
 手工移除某个指定对象广播通知所有监听
 
 @param name   通知名称
 @param object 通知对象，值为nil时表示所有
 */
- (void)fw_unobserveNotification:(NSNotificationName)name object:(nullable id)object NS_REFINED_FOR_SWIFT;

/**
 手工移除所有广播通知监听
 */
- (void)fw_unobserveAllNotifications NS_REFINED_FOR_SWIFT;

#pragma mark - Subject

/**
 发送广播通知
 
 @param name 通知名称
 */
- (void)fw_postNotification:(NSNotificationName)name NS_REFINED_FOR_SWIFT;

/**
 发送广播通知，附带对象
 
 @param name   通知名称
 @param object 通知对象
 */
- (void)fw_postNotification:(NSNotificationName)name object:(nullable id)object NS_REFINED_FOR_SWIFT;

/**
 发送广播通知，附带对象和用户信息
 
 @param name     通知名称
 @param object   通知对象
 @param userInfo 用户信息
 */
- (void)fw_postNotification:(NSNotificationName)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo NS_REFINED_FOR_SWIFT;

/**
 发送广播通知
 
 @param name 通知名称
 */
+ (void)fw_postNotification:(NSNotificationName)name NS_REFINED_FOR_SWIFT;

/**
 发送广播通知，附带对象
 
 @param name   通知名称
 @param object 通知对象
 */
+ (void)fw_postNotification:(NSNotificationName)name object:(nullable id)object NS_REFINED_FOR_SWIFT;

/**
 发送广播通知，附带对象和用户信息
 
 @param name     通知名称
 @param object   通知对象
 @param userInfo 用户信息
 */
+ (void)fw_postNotification:(NSNotificationName)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSObject+FWKvo

@interface NSObject (FWKvo)

/**
 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
 
 @param property 属性名称
 @param block    目标句柄，block参数依次为object、优化的change字典(不含NSNull)
 @return 监听唯一标志
 */
- (NSString *)fw_observeProperty:(NSString *)property block:(void (^)(id object, NSDictionary<NSKeyValueChangeKey, id> *change))block NS_REFINED_FOR_SWIFT;

/**
 监听对象某个属性，对象释放时自动移除监听，添加多次执行多次
 
 @param property 属性名称
 @param target   目标对象
 @param action   目标动作，action参数依次为object、优化的change字典(不含NSNull)
 @return 监听唯一标志
 */
- (NSString *)fw_observeProperty:(NSString *)property target:(nullable id)target action:(SEL)action NS_REFINED_FOR_SWIFT;

/**
 手工移除某个属性指定监听
 
 @param property 属性名称
 @param target   目标对象，值为nil时移除所有对象(同UIControl)
 @param action   目标动作，值为nil时移除所有动作(同UIControl)
 */
- (void)fw_unobserveProperty:(NSString *)property target:(nullable id)target action:(nullable SEL)action NS_REFINED_FOR_SWIFT;

/**
 手工移除某个属性指定监听
 
 @param property   属性名称
 @param identifier 监听唯一标志
 */
- (void)fw_unobserveProperty:(NSString *)property identifier:(NSString *)identifier NS_REFINED_FOR_SWIFT;

/**
 手工移除某个属性所有监听
 
 @param property 属性名称
 */
- (void)fw_unobserveProperty:(NSString *)property NS_REFINED_FOR_SWIFT;

/**
 手工移除所有属性所有监听
 */
- (void)fw_unobserveAllProperties NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
