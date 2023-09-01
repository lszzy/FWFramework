//
//  FWProxy.h
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWWeakProxy

/**
 弱引用代理类，用于解决NSTimer和CADisplayLink中的循环引用target问题(默认NSTimer会强引用target,直到invalidate)
 */
NS_SWIFT_NAME(WeakProxy)
@interface FWWeakProxy : NSProxy

/** 原target对象 */
@property (nullable, nonatomic, weak, readonly) id target;

/**
 初始化代理对象
 
 @param target 原target对象
 @return 代理对象
 */
- (instancetype)initWithTarget:(nullable id)target;

/**
 初始化代理对象
 
 @param target 原target对象
 @return 代理对象
 */
+ (instancetype)proxyWithTarget:(nullable id)target;

@end

#pragma mark - FWWeakObject

/**
 弱引用对象容器类，用于解决关联对象weak引用等
 */
NS_SWIFT_NAME(WeakObject)
@interface FWWeakObject : NSObject

/// 弱引用对象，释放后自动变为nil，不会产生野指针
@property (nonatomic, weak, nullable) id object;

/// 构造方法，快速创建弱引用容器对象
- (instancetype)initWithObject:(nullable id)object;

@end

#pragma mark - FWBlockProxy

/**
 Block代理
 
 @see https://github.com/BlocksKit/BlocksKit
 */
NS_SWIFT_NAME(BlockProxy)
@interface FWBlockProxy : NSObject

/** 只读block */
@property (nonatomic, copy, readonly) id block;

/** block签名 */
@property (nonatomic, strong, readonly) NSMethodSignature *methodSignature;

/**
 解析block签名
 
 @param block block代码
 @return 方法签名
 */
+ (nullable NSMethodSignature *)methodSignatureForBlock:(id)block;

/**
 初始化代理
 
 @param block 代理block
 @return 代理对象
 */
- (instancetype)initWithBlock:(id)block;

/**
 初始化代理
 
 @param block 代理block
 @return 代理对象
 */
+ (instancetype)proxyWithBlock:(id)block;

/**
 指定invocation调用block，并设置返回值
 
 @param invocation 调用对象
 @param returnValue 返回值
 @return 是否调用成功
 */
- (BOOL)invokeWithInvocation:(NSInvocation *)invocation returnValue:(out NSValue * __nullable * __nonnull)returnValue;

/**
 指定invocation调用block，并设置返回值
 
 @param invocation 调用对象
 */
- (void)invokeWithInvocation:(NSInvocation *)invocation;

@end

#pragma mark - FWDelegateProxy

/**
 事件协议代理基类，可继承重写事件代理方法
 */
NS_SWIFT_NAME(DelegateProxy)
@interface FWDelegateProxy : NSObject

/** 代理事件协议 */
@property (nonatomic, readonly) Protocol *protocol;

/** 事件代理对象 */
@property (nullable, nonatomic, weak) id delegate;

/**
 初始化事件协议代理对象
 
 @param protocol 代理协议
 @return 代理对象
 */
- (instancetype)initWithProtocol:(Protocol *)protocol;

/**
 初始化事件协议代理对象
 
 @param protocol 代理协议
 @return 代理对象
 */
+ (instancetype)proxyWithProtocol:(Protocol *)protocol;

/**
 使用block动态实现selector
 
 @param selector 目标方法
 @param block 实现的block
 */
- (void)setSelector:(SEL)selector withBlock:(nullable id)block;

/**
 获取动态实现block
 
 @param selector 目标方法
 @return 实现的block
 */
- (nullable id)blockForSelector:(SEL)selector;

@end

#pragma mark - FWMulticastDelegate

/**
 多代理转发类
 */
NS_SWIFT_NAME(MulticastDelegate)
@interface FWMulticastDelegate<__covariant T> : NSObject

/// 是否是空，不包含delegate
@property (nonatomic, assign, readonly) BOOL isEmpty;

/// 初始化，是否强引用delegate，默认NO
- (instancetype)initWithStrongReferences:(BOOL)strongReferences;

/// 初始化，自定义引用选项
- (instancetype)initWithOptions:(NSPointerFunctionsOptions)options;

/// 添加delegate
- (void)addDelegate:(T)delegate;

/// 移除delegate
- (void)removeDelegate:(T)delegate;

/// 移除所有delegate
- (void)removeAllDelegates;

/// 是否包含delegate
- (BOOL)containsDelegate:(T)delegate;

/// 调用所有delegates方法，忽略返回结果
- (void)invokeDelegates:(void (NS_NOESCAPE ^)(T))block;

/// 过滤并调用delegates代理方法，返回是否继续执行，为false时立即停止执行
- (BOOL)filterDelegates:(BOOL (NS_NOESCAPE ^)(T))filter;

@end

NS_ASSUME_NONNULL_END
