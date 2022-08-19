//
//  Message.h
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __NotificationTarget

/// 内部通知监听Target
@interface __NotificationTarget : NSObject

/// 唯一标志
@property (nonatomic, copy, readonly) NSString *identifier;

/// 值为YES表示广播通知，为NO表示点对点消息
@property (nonatomic, assign) BOOL broadcast;

/// NSNotification会强引用object，此处需要使用weak避免循环引用(如object为self)
@property (nonatomic, weak, nullable) id object;

/// 弱引用target
@property (nonatomic, weak, nullable) id target;

/// 动作action
@property (nonatomic) SEL action;

/// 自定义句柄
@property (nonatomic, copy, nullable) void (^block)(NSNotification *notification);

/// 处理通知
- (void)handleNotification:(NSNotification *)notification;

/// object是否相等
- (BOOL)equalsObject:(nullable id)object;

/// object是否相等，且响应动作也相等
- (BOOL)equalsObject:(nullable id)object target:(nullable id)target action:(nullable SEL)action;

@end

#pragma mark - __KvoTarget

/// 内部KVO监听Target
@interface __KvoTarget : NSObject

/// 唯一标志
@property (nonatomic, copy, readonly) NSString *identifier;

/// 此处必须unsafe_unretained(类似weak，但如果引用的对象被释放会造成野指针，再次访问会crash)
@property (nonatomic, unsafe_unretained, nullable) id object;

/// 监听路径
@property (nonatomic, copy, nullable) NSString *keyPath;

/// 弱引用target
@property (nonatomic, weak, nullable) id target;

/// 动作action
@property (nonatomic) SEL action;

/// 自定义句柄
@property (nonatomic, copy, nullable) void (^block)(__weak id object, NSDictionary<NSKeyValueChangeKey, id> *change);

/// 是否正在监听
@property (nonatomic, assign, readonly) BOOL isObserving;

/// 添加监听
- (void)addObserver;

/// 移除监听
- (void)removeObserver;

/// target是否相等，且响应动作也相等
- (BOOL)equalsTarget:(nullable id)target action:(nullable SEL)action;

@end

NS_ASSUME_NONNULL_END
