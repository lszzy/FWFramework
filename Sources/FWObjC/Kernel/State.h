//
//  State.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWStateObject

@class __FWStateTransition;

/// 状态类
NS_SWIFT_NAME(StateObject)
@interface __FWStateObject : NSObject

/// 状态名称，只读
@property (nonatomic, copy, readonly) NSString *name;

/// 即将进入block
@property (nonatomic, copy, nullable) void (^willEnterBlock)(__FWStateTransition * _Nullable transition);

/// 已进入block
@property (nonatomic, copy, nullable) void (^didEnterBlock)(__FWStateTransition * _Nullable transition);

/// 即将退出block
@property (nonatomic, copy, nullable) void (^willExitBlock)(__FWStateTransition *transition);

/// 已退出block
@property (nonatomic, copy, nullable) void (^didExitBlock)(__FWStateTransition *transition);

/// 从名称初始化
+ (instancetype)stateWithName:(NSString *)name;

@end

#pragma mark - __FWStateEvent

/// 状态事件类
NS_SWIFT_NAME(StateEvent)
@interface __FWStateEvent : NSObject

/// 事件名称，只读
@property (nonatomic, copy, readonly) NSString *name;

/// 来源状态列表，只读
@property (nonatomic, copy, readonly) NSArray<__FWStateObject *> *sourceStates;

/// 目标状态，只读
@property (nonatomic, strong, readonly) __FWStateObject *targetState;

/// 能否触发block
@property (nonatomic, copy, nullable) BOOL (^shouldFireBlock)(__FWStateTransition *transition);

/// 即将触发block
@property (nonatomic, copy, nullable) void (^willFireBlock)(__FWStateTransition *transition);

/// 正在触发block，必须调用completion标记完成结果。YES事件完成、状态改变，NO事件失败、状态不变。不设置默认完成
@property (nonatomic, copy, nullable) void (^fireBlock)(__FWStateTransition *transition, void (^completion)(BOOL finished));

/// 触发完成block，finished为完成状态
@property (nonatomic, copy, nullable) void (^didFireBlock)(__FWStateTransition *transition, BOOL finished);

/// 初始化事件
+ (instancetype)eventWithName:(NSString *)name fromStates:(NSArray<__FWStateObject *> *)sourceStates toState:(__FWStateObject *)targetState;

@end

#pragma mark - __FWStateTransition

@class __FWStateMachine;

/// 状态转换器
NS_SWIFT_NAME(StateTransition)
@interface __FWStateTransition : NSObject

/// 有限状态机，只读
@property (nonatomic, strong, readonly) __FWStateMachine *machine;

/// 事件对象，只读
@property (nonatomic, strong, readonly) __FWStateEvent *event;

/// 来源状态，只读
@property (nonatomic, strong, readonly) __FWStateObject *sourceState;

/// 目标状态，只读
@property (nonatomic, strong, readonly) __FWStateObject *targetState;

/// 附加参数，只读
@property (nonatomic, strong, readonly, nullable) id object;

/// 初始化转换器
+ (instancetype)transitionInMachine:(__FWStateMachine *)machine forEvent:(__FWStateEvent *)event fromState:(__FWStateObject *)sourceState withObject:(nullable id)object;

@end

#pragma mark - __FWStateMachine

/// 状态改变通知
extern NSNotificationName const __FWStateChangedNotification NS_SWIFT_NAME(StateChanged);

/**
 有限状态机
 
 @see https://github.com/blakewatters/TransitionKit
 */
NS_SWIFT_NAME(StateMachine)
@interface __FWStateMachine : NSObject

/// 状态列表，只读
@property (nonatomic, readonly) NSSet *states;

/// 事件列表，只读
@property (nonatomic, readonly) NSSet *events;

/// 当前状态，只读
@property (nonatomic, strong, readonly) __FWStateObject *state;

/// 初始化状态，可写
@property (nonatomic, strong, nullable) __FWStateObject *initialState;

/**
 *  添加状态
 *
 *  @param state 状态对象
 */
- (void)addState:(__FWStateObject *)state;

/**
 *  批量添加状态
 *
 *  @param states 状态数组
 */
- (void)addStates:(NSArray<__FWStateObject *> *)states;

/**
 *  从名称获取状态
 *
 *  @param name 状态名称
 *
 *  @return 状态对象
 */
- (nullable __FWStateObject *)stateNamed:(NSString *)name;

/**
 *  当前状态判断
 *
 *  @param state 状态名称或对象
 *
 *  @return 判断结果
 */
- (BOOL)isState:(nullable id)state;

/**
 *  添加事件
 *
 *  @param event 事件对象
 */
- (void)addEvent:(__FWStateEvent *)event;

/**
 *  批量添加事件
 *
 *  @param events 事件数组
 */
- (void)addEvents:(NSArray<__FWStateEvent *> *)events;

/**
 *  从名称获取事件
 *
 *  @param name 事件名称
 *
 *  @return 事件对象
 */
- (nullable __FWStateEvent *)eventNamed:(NSString *)name;

/**
 *  激活并锁定状态机
 */
- (void)activate;

/**
 *  是否已激活
 *
 *  @return 激活状态
 */
- (BOOL)isActive;

/**
 *  事件是否可触发
 *
 *  @param event 事件名称或对象
 *
 *  @return 是否可触发
 */
- (BOOL)canFireEvent:(nullable id)event;

/**
 *  触发事件
 *
 *  @param event 事件名称或对象
 *
 *  @return 触发状态
 */
- (BOOL)fireEvent:(nullable id)event;

/**
 *  触发事件
 *
 *  @param event  事件名称或对象
 *  @param object 附加参数
 *
 *  @return 触发状态
 */
- (BOOL)fireEvent:(nullable id)event withObject:(nullable id)object;

@end

NS_ASSUME_NONNULL_END
