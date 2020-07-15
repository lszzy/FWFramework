/*!
 @header     FWProxy.h
 @indexgroup FWFramework
 @brief      FWProxy代理类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-18
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWWeakProxy

/*!
 @brief 弱引用代理类，用于解决NSTimer和CADisplayLink中的循环引用target问题(默认NSTimer会强引用target,直到invalidate)
 */
@interface FWWeakProxy : NSProxy

/*! @brief 原target对象 */
@property (nullable, nonatomic, weak, readonly) id target;

/*!
 @brief 初始化代理对象
 
 @param target 原target对象
 @return 代理对象
 */
- (instancetype)initWithTarget:(nullable id)target;

/*!
 @brief 初始化代理对象
 
 @param target 原target对象
 @return 代理对象
 */
+ (instancetype)proxyWithTarget:(nullable id)target;

@end

#pragma mark - FWWeakObject

/*!
 @brief 弱引用对象容器类，用于解决关联对象weak引用等
 */
@interface FWWeakObject : NSObject

// 弱引用对象，释放后自动变为nil，不会产生野指针
@property (nonatomic, weak, nullable) id object;

// 构造方法，快速创建弱引用容器对象
- (instancetype)initWithObject:(nullable id)object;

@end

#pragma mark - FWBlockProxy

/*!
 @brief Block代理
 
 @see https://github.com/BlocksKit/BlocksKit
 */
@interface FWBlockProxy : NSObject

/*! @brief 只读block */
@property (nonatomic, copy, readonly) id block;

/*! @brief block签名 */
@property (nonatomic, strong, readonly) NSMethodSignature *methodSignature;

/*!
 @brief 解析block签名
 
 @param block block代码
 @return 方法签名
 */
+ (nullable NSMethodSignature *)methodSignatureForBlock:(id)block;

/*!
 @brief 初始化代理
 
 @param block 代理block
 @return 代理对象
 */
- (instancetype)initWithBlock:(id)block;

/*!
 @brief 初始化代理
 
 @param block 代理block
 @return 代理对象
 */
+ (instancetype)proxyWithBlock:(id)block;

/*!
 @brief 指定invocation调用block，并设置返回值
 
 @param invocation 调用对象
 @param returnValue 返回值
 @return 是否调用成功
 */
- (BOOL)invokeWithInvocation:(NSInvocation *)invocation returnValue:(out NSValue * __nullable * __nonnull)returnValue;

/*!
 @brief 指定invocation调用block，并设置返回值
 
 @param invocation 调用对象
 */
- (void)invokeWithInvocation:(NSInvocation *)invocation;

@end

#pragma mark - FWDelegateProxy

/*!
 @brief 事件协议代理基类，可继承重写事件代理方法
 */
@interface FWDelegateProxy : NSObject

/*! @brief 代理事件协议 */
@property (nonatomic, readonly) Protocol *protocol;

/*! @brief 事件代理对象 */
@property (nullable, nonatomic, weak) id delegate;

/*!
 @brief 初始化事件协议代理对象
 
 @param protocol 代理协议
 @return 代理对象
 */
- (instancetype)initWithProtocol:(Protocol *)protocol;

/*!
 @brief 初始化事件协议代理对象
 
 @param protocol 代理协议
 @return 代理对象
 */
+ (instancetype)proxyWithProtocol:(Protocol *)protocol;

/*!
 @brief 使用block动态实现selector
 
 @param selector 目标方法
 @param block 实现的block
 */
- (void)setSelector:(SEL)selector withBlock:(nullable id)block;

/*!
 @brief 获取动态实现block
 
 @param selector 目标方法
 @return 实现的block
 */
- (nullable id)blockForSelector:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
