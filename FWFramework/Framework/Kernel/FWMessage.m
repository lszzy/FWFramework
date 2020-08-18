/*!
 @header     FWMessage.m
 @indexgroup FWFramework
 @brief      点对点消息、广播通知管理器
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-16
 */

#import "FWMessage.h"
#import <objc/runtime.h>

#pragma mark - FWInnerNotificationTarget

@interface FWInnerNotificationTarget : NSObject

@property (nonatomic, copy) NSString *identifier;

// 值为YES表示广播通知，为NO表示点对点消息
@property (nonatomic, assign) BOOL broadcast;

// NSNotification会强引用object，此处需要使用weak避免循环引用(如object为self)
@property (nonatomic, weak) id object;

@property (nonatomic, weak) id target;

@property (nonatomic) SEL action;

@property (nonatomic, copy) void (^block)(NSNotification *notification);

- (void)handleNotification:(NSNotification *)notification;

@end

@implementation FWInnerNotificationTarget

- (instancetype)init
{
    self = [super init];
    if (self) {
        _identifier = NSUUID.UUID.UUIDString;
    }
    return self;
}

- (void)dealloc
{
    if (self.broadcast) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)handleNotification:(NSNotification *)notification
{
    if (self.block) {
        self.block(notification);
        return;
    }
    
    if (self.target && self.action && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:notification];
#pragma clang diagnostic pop
    }
}

@end

#pragma mark - NSObject+FWMessage

@implementation NSObject (FWMessage)

#pragma mark - Observer

- (NSString *)fwObserveMessage:(NSString *)name block:(void (^)(NSNotification *))block
{
    return [self fwObserveMessage:name object:nil block:block];
}

- (NSString *)fwObserveMessage:(NSString *)name object:(id)object block:(void (^)(NSNotification *))block
{
    if (!name || !block) return nil;
    
    NSMutableDictionary *dict = [self fwInnerMessageTargets:YES];
    NSMutableArray *arr = dict[name];
    if (!arr) {
        arr = [NSMutableArray array];
        dict[name] = arr;
    }
    
    FWInnerNotificationTarget *messageTarget = [[FWInnerNotificationTarget alloc] init];
    messageTarget.broadcast = NO;
    messageTarget.object = object;
    messageTarget.block = block;
    [arr addObject:messageTarget];
    return messageTarget.identifier;
}

- (NSString *)fwObserveMessage:(NSString *)name target:(id)target action:(SEL)action
{
    return [self fwObserveMessage:name object:nil target:target action:action];
}

- (NSString *)fwObserveMessage:(NSString *)name object:(id)object target:(id)target action:(SEL)action
{
    if (!name || !target || !action) return nil;
    
    NSMutableDictionary *dict = [self fwInnerMessageTargets:YES];
    NSMutableArray *arr = dict[name];
    if (!arr) {
        arr = [NSMutableArray array];
        dict[name] = arr;
    }
    
    FWInnerNotificationTarget *messageTarget = [[FWInnerNotificationTarget alloc] init];
    messageTarget.broadcast = NO;
    messageTarget.object = object;
    messageTarget.target = target;
    messageTarget.action = action;
    [arr addObject:messageTarget];
    return messageTarget.identifier;
}

- (void)fwUnobserveMessage:(NSString *)name target:(id)target action:(SEL)action
{
    [self fwUnobserveMessage:name object:nil target:target action:action];
}

- (void)fwUnobserveMessage:(NSString *)name object:(id)object target:(id)target action:(SEL)action
{
    if (!name) return;
    
    NSMutableDictionary *dict = [self fwInnerMessageTargets:NO];
    if (!dict) return;
    
    NSMutableArray *arr = dict[name];
    // object为nil且target为nil始终移除
    if (!object && !target) {
        [dict removeObjectForKey:name];
    // object相同且target为nil时始终移除
    } else if (!target) {
        [arr enumerateObjectsUsingBlock:^(FWInnerNotificationTarget *obj, NSUInteger idx, BOOL *stop) {
            if (object == obj.object) {
                [arr removeObject:obj];
            }
        }];
    // object相同且target相同且action为NULL或者action相同才移除
    } else {
        [arr enumerateObjectsUsingBlock:^(FWInnerNotificationTarget *obj, NSUInteger idx, BOOL *stop) {
            if (object == obj.object && target == obj.target && (!action || action == obj.action)) {
                [arr removeObject:obj];
            }
        }];
    }
}

- (void)fwUnobserveMessage:(NSString *)name identifier:(NSString *)identifier
{
    if (!name || !identifier) return;
    
    NSMutableDictionary *dict = [self fwInnerMessageTargets:NO];
    if (!dict) return;
    
    NSMutableArray *arr = dict[name];
    [arr enumerateObjectsUsingBlock:^(FWInnerNotificationTarget *obj, NSUInteger idx, BOOL *stop) {
        if ([identifier isEqualToString:obj.identifier]) {
            [arr removeObject:obj];
        }
    }];
}

- (void)fwUnobserveMessage:(NSString *)name
{
    [self fwUnobserveMessage:name object:nil];
}

- (void)fwUnobserveMessage:(NSString *)name object:(id)object
{
    [self fwUnobserveMessage:name object:object target:nil action:NULL];
}

- (void)fwUnobserveAllMessages
{
    NSMutableDictionary *dict = [self fwInnerMessageTargets:NO];
    if (!dict) return;
    
    [dict removeAllObjects];
}

- (NSMutableDictionary *)fwInnerMessageTargets:(BOOL)lazyload
{
    NSMutableDictionary *targets = objc_getAssociatedObject(self, _cmd);
    if (!targets && lazyload) {
        targets = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

#pragma mark - Subject

+ (void)fwSendMessage:(NSString *)name toReceiver:(id)receiver
{
    [self fwSendMessage:name object:nil toReceiver:receiver];
}

+ (void)fwSendMessage:(NSString *)name object:(id)object toReceiver:(id)receiver
{
    [self fwSendMessage:name object:object userInfo:nil toReceiver:receiver];
}

+ (void)fwSendMessage:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo toReceiver:(id)receiver
{
    if (!name || !receiver) return;
    
    NSMutableDictionary *dict = [receiver fwInnerMessageTargets:NO];
    if (!dict) return;
    
    NSMutableArray *arr = dict[name];
    if (!arr) return;
    
    NSNotification *notification = [NSNotification notificationWithName:name object:object userInfo:userInfo];
    [arr enumerateObjectsUsingBlock:^(FWInnerNotificationTarget *obj, NSUInteger idx, BOOL *stop) {
        // obj.object为nil或者obj.object和object相同才触发
        if (!obj.object || obj.object == object) {
            [obj handleNotification:notification];
        }
    }];
}

- (void)fwSendMessage:(NSString *)name toReceiver:(id)receiver
{
    [self.class fwSendMessage:name toReceiver:receiver];
}

- (void)fwSendMessage:(NSString *)name object:(id)object toReceiver:(id)receiver
{
    [self.class fwSendMessage:name object:object toReceiver:receiver];
}

- (void)fwSendMessage:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo toReceiver:(id)receiver
{
    [self.class fwSendMessage:name object:object userInfo:userInfo toReceiver:receiver];
}

@end

#pragma mark - NSObject+FWNotification

@implementation NSObject (FWNotification)

#pragma mark - Observer

- (NSString *)fwObserveNotification:(NSString *)name block:(void (^)(NSNotification *notification))block
{
    return [self fwObserveNotification:name object:nil block:block];
}

- (NSString *)fwObserveNotification:(NSString *)name object:(id)object block:(void (^)(NSNotification *))block
{
    if (!name || !block) return nil;
    
    NSMutableDictionary *dict = [self fwInnerNotificationTargets:YES];
    NSMutableArray *arr = dict[name];
    if (!arr) {
        arr = [NSMutableArray array];
        dict[name] = arr;
    }
    
    FWInnerNotificationTarget *notificationTarget = [[FWInnerNotificationTarget alloc] init];
    notificationTarget.broadcast = YES;
    notificationTarget.object = object;
    notificationTarget.block = block;
    [arr addObject:notificationTarget];
    [[NSNotificationCenter defaultCenter] addObserver:notificationTarget selector:@selector(handleNotification:) name:name object:object];
    return notificationTarget.identifier;
}

- (NSString *)fwObserveNotification:(NSString *)name target:(id)target action:(SEL)action
{
    return [self fwObserveNotification:name object:nil target:target action:action];
}

- (NSString *)fwObserveNotification:(NSString *)name object:(id)object target:(id)target action:(SEL)action
{
    if (!name || !target || !action) return nil;
    
    NSMutableDictionary *dict = [self fwInnerNotificationTargets:YES];
    NSMutableArray *arr = dict[name];
    if (!arr) {
        arr = [NSMutableArray array];
        dict[name] = arr;
    }
    
    FWInnerNotificationTarget *notificationTarget = [[FWInnerNotificationTarget alloc] init];
    notificationTarget.broadcast = YES;
    notificationTarget.object = object;
    notificationTarget.target = target;
    notificationTarget.action = action;
    [arr addObject:notificationTarget];
    [[NSNotificationCenter defaultCenter] addObserver:notificationTarget selector:@selector(handleNotification:) name:name object:object];
    return notificationTarget.identifier;
}

- (void)fwUnobserveNotification:(NSString *)name target:(id)target action:(SEL)action
{
    [self fwUnobserveNotification:name object:nil target:target action:action];
}

- (void)fwUnobserveNotification:(NSString *)name object:(id)object target:(id)target action:(SEL)action
{
    if (!name) return;
    
    NSMutableDictionary *dict = [self fwInnerNotificationTargets:NO];
    if (!dict) return;
    
    NSMutableArray *arr = dict[name];
    // object为nil且target为nil始终移除
    if (!object && !target) {
        [arr enumerateObjectsUsingBlock:^(FWInnerNotificationTarget *obj, NSUInteger idx, BOOL *stop) {
            [[NSNotificationCenter defaultCenter] removeObserver:obj];
        }];
        [dict removeObjectForKey:name];
    // object相同且target为nil时始终移除
    } else if (!target) {
        [arr enumerateObjectsUsingBlock:^(FWInnerNotificationTarget *obj, NSUInteger idx, BOOL *stop) {
            if (object == obj.object) {
                [[NSNotificationCenter defaultCenter] removeObserver:obj];
                [arr removeObject:obj];
            }
        }];
    // object相同且target相同且action为NULL或者action相同才移除
    } else {
        [arr enumerateObjectsUsingBlock:^(FWInnerNotificationTarget *obj, NSUInteger idx, BOOL *stop) {
            if (object == obj.object && target == obj.target && (!action || action == obj.action)) {
                [[NSNotificationCenter defaultCenter] removeObserver:obj];
                [arr removeObject:obj];
            }
        }];
    }
}

- (void)fwUnobserveNotification:(NSString *)name identifier:(NSString *)identifier
{
    if (!name || !identifier) return;
    
    NSMutableDictionary *dict = [self fwInnerNotificationTargets:NO];
    if (!dict) return;
    
    NSMutableArray *arr = dict[name];
    [arr enumerateObjectsUsingBlock:^(FWInnerNotificationTarget *obj, NSUInteger idx, BOOL *stop) {
        if ([identifier isEqualToString:obj.identifier]) {
            [[NSNotificationCenter defaultCenter] removeObserver:obj];
            [arr removeObject:obj];
        }
    }];
}

- (void)fwUnobserveNotification:(NSString *)name
{
    [self fwUnobserveNotification:name object:nil];
}

- (void)fwUnobserveNotification:(NSString *)name object:(id)object
{
    [self fwUnobserveNotification:name object:object target:nil action:NULL];
}

- (void)fwUnobserveAllNotifications
{
    NSMutableDictionary *dict = [self fwInnerNotificationTargets:NO];
    if (!dict) return;
    
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *arr, BOOL *stop) {
        [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [[NSNotificationCenter defaultCenter] removeObserver:obj];
        }];
    }];
    [dict removeAllObjects];
}

- (NSMutableDictionary *)fwInnerNotificationTargets:(BOOL)lazyload
{
    NSMutableDictionary *targets = objc_getAssociatedObject(self, _cmd);
    if (!targets && lazyload) {
        targets = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

#pragma mark - Subject

+ (void)fwPostNotification:(NSString *)name
{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil];
}

+ (void)fwPostNotification:(NSString *)name object:(id)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:object];
}

+ (void)fwPostNotification:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:userInfo];
}

- (void)fwPostNotification:(NSString *)name
{
    [self.class fwPostNotification:name];
}

- (void)fwPostNotification:(NSString *)name object:(id)object
{
    [self.class fwPostNotification:name object:object];
}

- (void)fwPostNotification:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    [self.class fwPostNotification:name object:object userInfo:userInfo];
}

@end

#pragma mark - FWInnerKvoTarget

@interface FWInnerKvoTarget : NSObject

@property (nonatomic, copy) NSString *identifier;

// 此处必须unsafe_unretained(类似weak，但如果引用的对象被释放会造成野指针，再次访问会crash)
@property (nonatomic, unsafe_unretained) id object;

@property (nonatomic, copy) NSString *keyPath;

@property (nonatomic, weak) id target;

@property (nonatomic) SEL action;

@property (nonatomic, copy) void (^block)(__weak id object, NSDictionary *change);

@property (nonatomic, readonly) BOOL isObserving;

@end

@implementation FWInnerKvoTarget

- (instancetype)init
{
    self = [super init];
    if (self) {
        _identifier = NSUUID.UUID.UUIDString;
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver];
}

- (void)addObserver
{
    if (!_isObserving) {
        _isObserving = YES;
        [self.object addObserver:self forKeyPath:self.keyPath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)removeObserver
{
    // 不能重复调用移除方法，会导致崩溃
    if (_isObserving) {
        _isObserving = NO;
        [self.object removeObserver:self forKeyPath:self.keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    // 不回调的情况
    BOOL isPrior = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
    if (isPrior) return;
    
    NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
    if (changeKind != NSKeyValueChangeSetting) return;
    
    // 格式化change，去掉NSNull
    NSMutableDictionary *newChange = [NSMutableDictionary dictionary];
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    if (oldValue && oldValue != [NSNull null]) {
        [newChange setObject:oldValue forKey:NSKeyValueChangeOldKey];
    }
    
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    if (newValue && newValue != [NSNull null]) {
        [newChange setObject:newValue forKey:NSKeyValueChangeNewKey];
    }
    
    // 执行回调
    if (self.block) {
        self.block(object, [newChange copy]);
        return;
    }
    
    if (self.target && self.action && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:object withObject:[newChange copy]];
#pragma clang diagnostic pop
    }
}

@end

#pragma mark - NSObject+FWKvo

@implementation NSObject (FWKvo)

- (NSString *)fwObserveProperty:(NSString *)property block:(void (^)(__weak id object, NSDictionary *change))block
{
    if (!property || !block) return nil;
    
    NSMutableDictionary *dict = [self fwInnerKvoTargets:YES];
    NSMutableArray *arr = dict[property];
    if (!arr) {
        arr = [NSMutableArray array];
        dict[property] = arr;
    }
    
    FWInnerKvoTarget *kvoTarget = [[FWInnerKvoTarget alloc] init];
    kvoTarget.object = self;
    kvoTarget.keyPath = property;
    kvoTarget.block = block;
    [arr addObject:kvoTarget];
    [kvoTarget addObserver];
    return kvoTarget.identifier;
}

- (NSString *)fwObserveProperty:(NSString *)property target:(id)target action:(SEL)action
{
    if (!property || !target || !action) return nil;
    
    NSMutableDictionary *dict = [self fwInnerKvoTargets:YES];
    NSMutableArray *arr = dict[property];
    if (!arr) {
        arr = [NSMutableArray array];
        dict[property] = arr;
    }
    
    FWInnerKvoTarget *kvoTarget = [[FWInnerKvoTarget alloc] init];
    kvoTarget.object = self;
    kvoTarget.keyPath = property;
    kvoTarget.target = target;
    kvoTarget.action = action;
    [arr addObject:kvoTarget];
    [kvoTarget addObserver];
    return kvoTarget.identifier;
}

- (void)fwUnobserveProperty:(NSString *)property target:(id)target action:(SEL)action
{
    if (!property) return;
    
    NSMutableDictionary *dict = [self fwInnerKvoTargets:NO];
    if (!dict) return;
    
    NSMutableArray *arr = dict[property];
    // target为nil始终移除
    if (!target) {
        [arr enumerateObjectsUsingBlock:^(FWInnerKvoTarget *obj, NSUInteger idx, BOOL *stop) {
            [obj removeObserver];
        }];
        [dict removeObjectForKey:property];
    // target相同且action为NULL或者action相同才移除
    } else {
        [arr enumerateObjectsUsingBlock:^(FWInnerKvoTarget *obj, NSUInteger idx, BOOL *stop) {
            if (target == obj.target && (!action || action == obj.action)) {
                [obj removeObserver];
                [arr removeObject:obj];
            }
        }];
    }
}

- (void)fwUnobserveProperty:(NSString *)property identifier:(NSString *)identifier
{
    if (!property || !identifier) return;
    
    NSMutableDictionary *dict = [self fwInnerKvoTargets:NO];
    if (!dict) return;
    
    NSMutableArray *arr = dict[property];
    [arr enumerateObjectsUsingBlock:^(FWInnerKvoTarget *obj, NSUInteger idx, BOOL *stop) {
        if ([identifier isEqualToString:obj.identifier]) {
            [obj removeObserver];
            [arr removeObject:obj];
        }
    }];
}

- (void)fwUnobserveProperty:(NSString *)property
{
    [self fwUnobserveProperty:property target:nil action:NULL];
}

- (void)fwUnobserveAllProperties
{
    NSMutableDictionary *dict = [self fwInnerKvoTargets:NO];
    if (!dict) return;
    
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *arr, BOOL *stop) {
        [arr enumerateObjectsUsingBlock:^(FWInnerKvoTarget *obj, NSUInteger idx, BOOL *stop) {
            [obj removeObserver];
        }];
    }];
    [dict removeAllObjects];
}

- (NSMutableDictionary *)fwInnerKvoTargets:(BOOL)lazyload
{
    NSMutableDictionary *targets = objc_getAssociatedObject(self, _cmd);
    if (!targets && lazyload) {
        targets = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

@end
