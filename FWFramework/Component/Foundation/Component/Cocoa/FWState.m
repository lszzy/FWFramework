//
//  FWState.m
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWState.h"

#pragma mark - FWState

@interface FWState ()

@property (nonatomic, copy) NSString *name;

@end

@implementation FWState

+ (instancetype)stateWithName:(NSString *)name
{
    FWState *state = [[self alloc] init];
    state.name = name;
    return state;
}

@end

#pragma mark - FWStateEvent

@interface FWStateEvent ()

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSArray<FWState *> *sourceStates;

@property (nonatomic, strong) FWState *targetState;

@end

@implementation FWStateEvent

+ (instancetype)eventWithName:(NSString *)name fromStates:(NSArray<FWState *> *)sourceStates toState:(FWState *)targetState
{
    FWStateEvent *event = [[self alloc] init];
    event.name = name;
    event.sourceStates = sourceStates;
    event.targetState = targetState;
    return event;
}

@end

#pragma mark - FWStateTransition

@interface FWStateTransition ()

@property (nonatomic, strong) FWStateMachine *machine;

@property (nonatomic, strong) FWStateEvent *event;

@property (nonatomic, strong) FWState *sourceState;

@property (nonatomic, strong) id object;

@end

@implementation FWStateTransition

+ (instancetype)transitionInMachine:(FWStateMachine *)machine forEvent:(FWStateEvent *)event fromState:(FWState *)sourceState withObject:(id)object
{
    FWStateTransition *transition = [[FWStateTransition alloc] init];
    transition.machine = machine;
    transition.event = event;
    transition.sourceState = sourceState;
    transition.object = object;
    return transition;
}

- (FWState *)targetState
{
    return self.event.targetState;
}

@end

#pragma mark - FWStateMachine

NSString *const FWStateChangedNotification = @"FWStateChangedNotification";

@interface FWStateMachine ()

@property (nonatomic, strong) NSMutableSet *mutableStates;

@property (nonatomic, strong) NSMutableSet *mutableEvents;

@property (nonatomic, strong) FWState *state;

@property (nonatomic, strong) NSRecursiveLock *lock;

@property (nonatomic, assign, getter=isActive) BOOL active;

@end

@implementation FWStateMachine

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mutableStates = [NSMutableSet set];
        _mutableEvents = [NSMutableSet set];
        _lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (void)checkActive
{
    if (self.isActive) {
        @throw [NSException exceptionWithName:@"FWFramework" reason:@"FWStateMachine is activated" userInfo:nil];
    }
}

- (void)setInitialState:(FWState *)initialState
{
    [self checkActive];
    
    _initialState = initialState;
}

- (void)setState:(FWState *)state
{
    if (!state) return;
    
    _state = state;
}

- (NSSet *)states
{
    return [NSSet setWithSet:_mutableStates];
}

- (void)addState:(FWState *)state
{
    [self checkActive];
    
    if (!state || [self stateNamed:state.name]) return;
    
    if (self.initialState == nil) {
        self.initialState = state;
    }
    [_mutableStates addObject:state];
}

- (void)addStates:(NSArray *)states
{
    [self checkActive];
    
    for (FWState *state in states) {
        [self addState:state];
    }
}

- (FWState *)stateNamed:(NSString *)name
{
    for (FWState *state in _mutableStates) {
        if ([state.name isEqualToString:name]) {
            return state;
        }
    }
    return nil;
}

- (BOOL)isState:(id)state
{
    FWState *targetState = [state isKindOfClass:[FWState class]] ? state : [self stateNamed:state];
    if (!targetState) return NO;
    return [self.state isEqual:targetState];
}

- (NSSet *)events
{
    return [NSSet setWithSet:_mutableEvents];
}

- (void)addEvent:(FWStateEvent *)event
{
    [self checkActive];
    
    if (!event || [self eventNamed:event.name]) return;
    
    [_mutableEvents addObject:event];
}

- (void)addEvents:(NSArray *)events
{
    [self checkActive];
    
    for (FWStateEvent *event in events) {
        [self addEvent:event];
    }
}

- (FWStateEvent *)eventNamed:(NSString *)name
{
    for (FWStateEvent *event in _mutableEvents) {
        if ([event.name isEqualToString:name]) {
            return event;
        }
    }
    return nil;
}

- (void)activate
{
    [self checkActive];
    
    [_lock lock];
    self.active = YES;
    
    if (self.initialState.willEnterBlock) {
        self.initialState.willEnterBlock(nil);
    }
    self.state = self.initialState;
    if (self.initialState.didEnterBlock) {
        self.initialState.didEnterBlock(nil);
    }
    [_lock unlock];
}

- (BOOL)canFireEvent:(id)name
{
    FWStateEvent *event = [name isKindOfClass:[FWStateEvent class]] ? name : [self eventNamed:name];
    if (!event) return NO;
    return event.sourceStates == nil || [event.sourceStates containsObject:self.state];
}

- (BOOL)fireEvent:(id)name
{
    return [self fireEvent:name withObject:nil];
}

- (BOOL)fireEvent:(id)name withObject:(id)object
{
    [_lock lock];
    // 自动激活
    if (!self.isActive) {
        [self activate];
    }
    if (![self canFireEvent:name]) {
        [_lock unlock];
        return NO;
    }
    
    // 能否触发，event.shouldFire
    FWStateEvent *event = [name isKindOfClass:[FWStateEvent class]] ? name : [self eventNamed:name];
    FWStateTransition *transition = [FWStateTransition transitionInMachine:self forEvent:event fromState:self.state withObject:object];
    if (event.shouldFireBlock) {
        if (!event.shouldFireBlock(transition)) {
            [_lock unlock];
            return NO;
        }
    }
    
    // 触发事件
    [self fireBegin:transition];
    [_lock unlock];
    return YES;
}

- (void)fireBegin:(FWStateTransition *)transition
{
    // event.willFire
    if (transition.event.willFireBlock) {
        transition.event.willFireBlock(transition);
    }
    
    // event.fire
    if (transition.event.fireBlock) {
        transition.event.fireBlock(transition, ^(BOOL finished){
            [transition.machine fireEnd:transition finished:finished];
        });
    } else {
        [self fireEnd:transition finished:YES];
    }
}

- (void)fireEnd:(FWStateTransition *)transition finished:(BOOL)finished
{
    [_lock lock];
    if (finished) {
        FWState *oldState = self.state;
        FWState *newState = transition.event.targetState;
        
        // oldState.willExit
        if (oldState.willExitBlock) {
            oldState.willExitBlock(transition);
        }
        
        // newState.willEnter
        if (newState.willEnterBlock) {
            newState.willEnterBlock(transition);
        }
        
        self.state = newState;
        
        // 发送状态改变通知
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        if (oldState) [userInfo setObject:oldState forKey:NSKeyValueChangeOldKey];
        if (newState) [userInfo setObject:newState forKey:NSKeyValueChangeNewKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:FWStateChangedNotification object:self userInfo:userInfo.copy];
        
        // oldState.didExit
        if (oldState.didExitBlock) {
            oldState.didExitBlock(transition);
        }
        
        // newState.didEnter
        if (newState.didEnterBlock) {
            newState.didEnterBlock(transition);
        }
    }
    
    // event.didFire
    if (transition.event.didFireBlock) {
        transition.event.didFireBlock(transition, finished);
    }
    [_lock unlock];
}

@end
