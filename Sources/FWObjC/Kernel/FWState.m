//
//  FWState.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWState.h"

#pragma mark - FWStateObject

@interface FWStateObject ()

@property (nonatomic, copy) NSString *name;

@end

@implementation FWStateObject

+ (instancetype)stateWithName:(NSString *)name
{
    FWStateObject *state = [[self alloc] init];
    state.name = name;
    return state;
}

@end

#pragma mark - FWStateEvent

@interface FWStateEvent ()

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSArray<FWStateObject *> *sourceStates;

@property (nonatomic, strong) FWStateObject *targetState;

@end

@implementation FWStateEvent

+ (instancetype)eventWithName:(NSString *)name fromStates:(NSArray<FWStateObject *> *)sourceStates toState:(FWStateObject *)targetState
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

@property (nonatomic, strong) FWStateObject *sourceState;

@property (nonatomic, strong) id object;

@end

@implementation FWStateTransition

+ (instancetype)transitionInMachine:(FWStateMachine *)machine forEvent:(FWStateEvent *)event fromState:(FWStateObject *)sourceState withObject:(id)object
{
    FWStateTransition *transition = [[FWStateTransition alloc] init];
    transition.machine = machine;
    transition.event = event;
    transition.sourceState = sourceState;
    transition.object = object;
    return transition;
}

- (FWStateObject *)targetState
{
    return self.event.targetState;
}

@end

#pragma mark - FWStateMachine

NSNotificationName const FWStateChangedNotification = @"FWStateChangedNotification";

@interface FWStateMachine ()

@property (nonatomic, strong) NSMutableSet *mutableStates;

@property (nonatomic, strong) NSMutableSet *mutableEvents;

@property (nonatomic, strong) FWStateObject *state;

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
        @throw [NSException exceptionWithName:@"FWState" reason:@"FWStateMachine is activated" userInfo:nil];
    }
}

- (void)setInitialState:(FWStateObject *)initialState
{
    [self checkActive];
    
    _initialState = initialState;
}

- (void)setState:(FWStateObject *)state
{
    if (!state) return;
    
    _state = state;
}

- (NSSet *)states
{
    return [NSSet setWithSet:_mutableStates];
}

- (void)addState:(FWStateObject *)state
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
    
    for (FWStateObject *state in states) {
        [self addState:state];
    }
}

- (FWStateObject *)stateNamed:(NSString *)name
{
    for (FWStateObject *state in _mutableStates) {
        if ([state.name isEqualToString:name]) {
            return state;
        }
    }
    return nil;
}

- (BOOL)isState:(id)state
{
    FWStateObject *targetState = [state isKindOfClass:[FWStateObject class]] ? state : [self stateNamed:state];
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
        FWStateObject *oldState = self.state;
        FWStateObject *newState = transition.event.targetState;
        
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
