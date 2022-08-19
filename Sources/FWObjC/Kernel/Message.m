//
//  Message.m
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

#import "Message.h"

#pragma mark - __NotificationTarget

@implementation __NotificationTarget

- (instancetype)init {
    self = [super init];
    if (self) {
        _identifier = NSUUID.UUID.UUIDString;
    }
    return self;
}

- (void)dealloc {
    if (self.broadcast) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)handleNotification:(NSNotification *)notification {
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

- (BOOL)equalsObject:(id)object {
    return object == self.object;
}

- (BOOL)equalsObject:(id)object target:(id)target action:(SEL)action {
    return object == self.object && target == self.target && (!action || action == self.action);
}

@end

#pragma mark - __KvoTarget

@implementation __KvoTarget

- (instancetype)init {
    self = [super init];
    if (self) {
        _identifier = NSUUID.UUID.UUIDString;
    }
    return self;
}

- (void)dealloc {
    [self removeObserver];
}

- (void)addObserver {
    if (!_isObserving) {
        _isObserving = YES;
        [self.object addObserver:self forKeyPath:self.keyPath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)removeObserver {
    if (_isObserving) {
        _isObserving = NO;
        [self.object removeObserver:self forKeyPath:self.keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    BOOL isPrior = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
    if (isPrior) return;
    
    NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
    if (changeKind != NSKeyValueChangeSetting) return;
    
    NSMutableDictionary *newChange = [NSMutableDictionary dictionary];
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    if (oldValue && oldValue != [NSNull null]) {
        [newChange setObject:oldValue forKey:NSKeyValueChangeOldKey];
    }
    
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    if (newValue && newValue != [NSNull null]) {
        [newChange setObject:newValue forKey:NSKeyValueChangeNewKey];
    }
    
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

- (BOOL)equalsTarget:(id)target action:(SEL)action {
    return target == self.target && (!action || action == self.action);
}

@end
