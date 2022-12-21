//
//  State.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "State.h"

#pragma mark - __FWStateObject

@interface __FWStateObject ()

@property (nonatomic, copy) NSString *name;

@end

@implementation __FWStateObject

+ (instancetype)stateWithName:(NSString *)name
{
    __FWStateObject *state = [[self alloc] init];
    state.name = name;
    return state;
}

@end

#pragma mark - __FWStateEvent

@interface __FWStateEvent ()

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSArray<__FWStateObject *> *sourceStates;

@property (nonatomic, strong) __FWStateObject *targetState;

@end

@implementation __FWStateEvent

+ (instancetype)eventWithName:(NSString *)name fromStates:(NSArray<__FWStateObject *> *)sourceStates toState:(__FWStateObject *)targetState
{
    __FWStateEvent *event = [[self alloc] init];
    event.name = name;
    event.sourceStates = sourceStates;
    event.targetState = targetState;
    return event;
}

@end

#pragma mark - __FWStateTransition

@interface __FWStateTransition ()

@property (nonatomic, strong) __FWStateMachine *machine;

@property (nonatomic, strong) __FWStateEvent *event;

@property (nonatomic, strong) __FWStateObject *sourceState;

@property (nonatomic, strong) id object;

@end

@implementation __FWStateTransition

+ (instancetype)transitionInMachine:(__FWStateMachine *)machine forEvent:(__FWStateEvent *)event fromState:(__FWStateObject *)sourceState withObject:(id)object
{
    __FWStateTransition *transition = [[__FWStateTransition alloc] init];
    transition.machine = machine;
    transition.event = event;
    transition.sourceState = sourceState;
    transition.object = object;
    return transition;
}

- (__FWStateObject *)targetState
{
    return self.event.targetState;
}

@end

#pragma mark - __FWStateMachine

NSNotificationName const __FWStateChangedNotification = @"__FWStateChangedNotification";

@interface __FWStateMachine ()

@property (nonatomic, strong) NSMutableSet *mutableStates;

@property (nonatomic, strong) NSMutableSet *mutableEvents;

@property (nonatomic, strong) __FWStateObject *state;

@property (nonatomic, strong) NSRecursiveLock *lock;

@property (nonatomic, assign, getter=isActive) BOOL active;

@end

@implementation __FWStateMachine

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
        @throw [NSException exceptionWithName:@"__FWState" reason:@"__FWStateMachine is activated" userInfo:nil];
    }
}

- (void)setInitialState:(__FWStateObject *)initialState
{
    [self checkActive];
    
    _initialState = initialState;
}

- (void)setState:(__FWStateObject *)state
{
    if (!state) return;
    
    _state = state;
}

- (NSSet *)states
{
    return [NSSet setWithSet:_mutableStates];
}

- (void)addState:(__FWStateObject *)state
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
    
    for (__FWStateObject *state in states) {
        [self addState:state];
    }
}

- (__FWStateObject *)stateNamed:(NSString *)name
{
    for (__FWStateObject *state in _mutableStates) {
        if ([state.name isEqualToString:name]) {
            return state;
        }
    }
    return nil;
}

- (BOOL)isState:(id)state
{
    __FWStateObject *targetState = [state isKindOfClass:[__FWStateObject class]] ? state : [self stateNamed:state];
    if (!targetState) return NO;
    return [self.state isEqual:targetState];
}

- (NSSet *)events
{
    return [NSSet setWithSet:_mutableEvents];
}

- (void)addEvent:(__FWStateEvent *)event
{
    [self checkActive];
    
    if (!event || [self eventNamed:event.name]) return;
    
    [_mutableEvents addObject:event];
}

- (void)addEvents:(NSArray *)events
{
    [self checkActive];
    
    for (__FWStateEvent *event in events) {
        [self addEvent:event];
    }
}

- (__FWStateEvent *)eventNamed:(NSString *)name
{
    for (__FWStateEvent *event in _mutableEvents) {
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
    __FWStateEvent *event = [name isKindOfClass:[__FWStateEvent class]] ? name : [self eventNamed:name];
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
    __FWStateEvent *event = [name isKindOfClass:[__FWStateEvent class]] ? name : [self eventNamed:name];
    __FWStateTransition *transition = [__FWStateTransition transitionInMachine:self forEvent:event fromState:self.state withObject:object];
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

- (void)fireBegin:(__FWStateTransition *)transition
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

- (void)fireEnd:(__FWStateTransition *)transition finished:(BOOL)finished
{
    [_lock lock];
    if (finished) {
        __FWStateObject *oldState = self.state;
        __FWStateObject *newState = transition.event.targetState;
        
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
        [[NSNotificationCenter defaultCenter] postNotificationName:__FWStateChangedNotification object:self userInfo:userInfo.copy];
        
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
