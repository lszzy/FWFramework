//
//  Runtime.h
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (FWRuntime)

#pragma mark - Property

/// 读取关联属性
- (nullable id)__propertyForName:(NSString *)name;

/// 设置强关联属性，支持KVO
- (void)__setProperty:(nullable id)object forName:(NSString *)name;

/// 设置赋值关联属性，支持KVO，注意可能会产生野指针
- (void)__setPropertyAssign:(nullable id)object forName:(NSString *)name;

/// 设置拷贝关联属性，支持KVO
- (void)__setPropertyCopy:(nullable id)object forName:(NSString *)name;

/// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
- (void)__setPropertyWeak:(nullable id)object forName:(NSString *)name;

#pragma mark - Method

/// 安全调用方法，不能响应则忽略
- (nullable id)__invokeMethod:(SEL)aSelector;

/// 安全调用方法，不能响应则忽略。非id类型参数可使用桥接，示例：int a = 1;(__bridge id)(void *)a
- (nullable id)__invokeMethod:(SEL)aSelector withObject:(nullable id)object;

/// 安全调用方法，支持多个参数
- (nullable id)__invokeMethod:(SEL)aSelector withObjects:(NSArray *)objects NS_SWIFT_NAME(__invokeMethod(_:objects:));

/// 对super发送消息
- (nullable id)__invokeSuperMethod:(SEL)aSelector;

/// 对super发送消息，可传递参数
- (nullable id)__invokeSuperMethod:(SEL)aSelector withObject:(nullable id)object;

/// 安全调用内部属性获取方法，如果属性不存在，则忽略之
- (nullable id)__invokeGetter:(NSString *)name;

/// 安全调用内部属性设置方法，如果属性不存在，则忽略之
- (nullable id)__invokeSetter:(NSString *)name withObject:(nullable id)object;

@end

NS_ASSUME_NONNULL_END
