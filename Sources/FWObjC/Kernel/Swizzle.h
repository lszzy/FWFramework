//
//  Swizzle.h
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 内部方法交换类
@interface __Swizzle : NSObject

/// 使用swizzle替换类实例方法为block实现。复杂情况不会冲突，推荐使用
+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/// 使用swizzle替换类实例方法为block实现，identifier相同时仅执行一次。复杂情况不会冲突，推荐使用
+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/// 交换类实例方法。复杂情况可能会冲突
+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector;

/// 交换类实例方法为block实现。复杂情况可能会冲突
///
/// swizzleBlock示例：^(__unsafe_unretained UIViewController *selfObject, BOOL animated){ ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector, animated); }
+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector withBlock:(id)swizzleBlock;

@end

NS_ASSUME_NONNULL_END
