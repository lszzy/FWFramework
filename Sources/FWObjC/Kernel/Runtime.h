//
//  Runtime.h
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/// 内部运行时类
@interface __Runtime : NSObject

#pragma mark - Property

/// 读取关联属性
+ (nullable id)getProperty:(id)target forName:(NSString *)name;

/// 设置强关联属性，支持KVO
+ (void)setPropertyPolicy:(id)target withObject:(nullable id)object policy:(objc_AssociationPolicy)policy forName:(NSString *)name;

/// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
+ (void)setPropertyWeak:(id)target withObject:(nullable id)object forName:(NSString *)name;

#pragma mark - Method

/// 安全调用方法，不能响应则忽略
+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector;

/// 安全调用方法，不能响应则忽略。非id类型参数可使用桥接，示例：int a = 1;(__bridge id)(void *)a
+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector object:(nullable id)object;

/// 安全调用方法，支持多个参数
+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector objects:(NSArray *)objects;

/// 安全调用内部属性获取方法，如果属性不存在，则忽略之
+ (nullable id)invokeGetter:(id)target name:(NSString *)name;

/// 安全调用内部属性设置方法，如果属性不存在，则忽略之
+ (nullable id)invokeSetter:(id)target name:(NSString *)name object:(nullable id)object;

@end

NS_ASSUME_NONNULL_END
