//
//  ObjC.h
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWAutoloader

/// Swift自动加载器，扩展实现objc静态autoload方法即可自动调用
@interface __FWAutoloader : NSObject

@end

#pragma mark - __FWWeakProxy

/// 弱引用代理类，用于解决NSTimer等循环引用target问题(默认NSTimer会强引用target,直到invalidate)
@interface __FWWeakProxy : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

- (instancetype)initWithTarget:(nullable id)target;

@end

#pragma mark - __FWDelegateProxy

/// 事件协议代理基类，可继承重写事件代理方法
@interface __FWDelegateProxy : NSObject

@property (nonatomic, weak, nullable) id target;

@end

#pragma mark - __FWUnsafeProxy

/// 非安全对象代理类，不同于weak，自动释放时仍可访问target，可用于自动解绑、释放监听等场景
@interface __FWUnsafeProxy : NSObject

@property (nonatomic, unsafe_unretained, nullable) id target;

- (void)proxyDealloc;

@end

#pragma mark - __FWObjC

/// ObjC桥接类，用于桥接Swift不支持的ObjC特性方法
@interface __FWObjC : NSObject

@end

NS_ASSUME_NONNULL_END
