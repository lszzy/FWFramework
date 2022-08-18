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
NS_REFINED_FOR_SWIFT
NS_SWIFT_NAME(__WeakProxy)
@interface __WeakProxy : NSProxy

/// 只读弱引用目标对象
@property (nonatomic, weak, nullable) id target NS_REFINED_FOR_SWIFT;

/// 初始化方法
- (instancetype)init;

@end

#pragma mark - __DelegateProxy

/// 事件协议代理基类，可继承重写事件代理方法
NS_REFINED_FOR_SWIFT
NS_SWIFT_NAME(__DelegateProxy)
@interface __DelegateProxy : NSObject

/// 代理事件协议
@property (nonatomic) Protocol *protocol NS_REFINED_FOR_SWIFT;

/// 事件代理对象
@property (nonatomic, weak, nullable) id delegate NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
