//
//  Proxy.h
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __WeakProxy

/// 内部弱引用代理类，解决NSTimer等循环引用target问题
@interface __WeakProxy : NSProxy

/// 只读弱引用目标对象
@property (nonatomic, weak, nullable) id target NS_REFINED_FOR_SWIFT;

/// 初始化方法
- (instancetype)init;

@end

#pragma mark - __DelegateProxy

/// 事件协议代理基类，可继承重写事件代理方法
@interface __DelegateProxy : NSObject

/// 代理事件协议
@property (nonatomic) Protocol *protocol NS_REFINED_FOR_SWIFT;

/// 事件代理对象
@property (nonatomic, weak, nullable) id delegate NS_REFINED_FOR_SWIFT;

@end

#pragma mark - __WeakObject

/// 弱引用对象容器类，用于解决关联对象weak引用等
@interface __WeakObject : NSObject

/// 弱引用对象，释放后自动变为nil，不会产生野指针
@property (nonatomic, weak, readonly, nullable) id object;

/// 构造方法，快速创建弱引用容器对象
- (instancetype)initWithObject:(nullable id)object;

@end

NS_ASSUME_NONNULL_END
