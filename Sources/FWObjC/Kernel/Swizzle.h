//
//  FWSwizzle.h
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 方法交换快速定义宏
#define __FWSwizzleClass( clazz, selector, __FWSwizzleReturn, __FWSwizzleArgs, __FWSwizzleCode ) \
    __FWSwizzleMethod_( [clazz class], selector, nil, clazz *, __FWSwizzleReturn, __FWSwizzleArgsWrap_(__FWSwizzleArgs), __FWSwizzleArgsWrap_(__FWSwizzleCode) )
#define __FWSwizzleMethod( target, selector, identifier, __FWSwizzleType, __FWSwizzleReturn, __FWSwizzleArgs, __FWSwizzleCode ) \
    __FWSwizzleMethod_( target, selector, identifier, __FWSwizzleType, __FWSwizzleReturn, __FWSwizzleArgsWrap_(__FWSwizzleArgs), __FWSwizzleArgsWrap_(__FWSwizzleCode) )
#define __FWSwizzleMethod_( target, sel, identity, __FWSwizzleType, __FWSwizzleReturn, __FWSwizzleArgs, __FWSwizzleCode ) \
    [NSObject fw_swizzleMethod:target selector:sel identifier:identity block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) { \
        return ^__FWSwizzleReturn (__FWSwizzleArgsDel2_(__unsafe_unretained __FWSwizzleType selfObject, __FWSwizzleArgs)) \
        { \
            __FWSwizzleReturn (*originalMSG)(__FWSwizzleArgsDel3_(id, SEL, __FWSwizzleArgs)); \
            originalMSG = (__FWSwizzleReturn (*)(__FWSwizzleArgsDel3_(id, SEL, __FWSwizzleArgs)))originalIMP(); \
            __FWSwizzleCode \
        }; \
    }];

/// 方法交换句柄实现宏
#define __FWSwizzleBlock( __FWSwizzleType, __FWSwizzleReturn, __FWSwizzleArgs, __FWSwizzleCode ) \
    __FWSwizzleBlock_( __FWSwizzleType, __FWSwizzleReturn, __FWSwizzleArgsWrap_(__FWSwizzleArgs), __FWSwizzleArgsWrap_(__FWSwizzleCode) )
#define __FWSwizzleBlock_( __FWSwizzleType, __FWSwizzleReturn, __FWSwizzleArgs, __FWSwizzleCode ) \
    ^__FWSwizzleReturn (__FWSwizzleArgsDel2_(__unsafe_unretained __FWSwizzleType selfObject, __FWSwizzleArgs)) \
    { \
        __FWSwizzleReturn (*originalMSG)(__FWSwizzleArgsDel3_(id, SEL, __FWSwizzleArgs)); \
        originalMSG = (__FWSwizzleReturn (*)(__FWSwizzleArgsDel3_(id, SEL, __FWSwizzleArgs)))originalIMP(); \
        __FWSwizzleCode \
    };

/// 包裹参数类型、参数列表和句柄实现宏
#define __FWSwizzleReturn( type ) type
#define __FWSwizzleType( type ) type
#define __FWSwizzleArgs( args... ) __FWSwizzleArgs_(args)
#define __FWSwizzleArgs_( args... ) DEL, ##args
#define __FWSwizzleCode( code... ) code

/// 包裹原始方法调用宏
#define __FWSwizzleOriginal( args... ) __FWSwizzleOriginal_(args)
#define __FWSwizzleOriginal_( args... ) originalMSG(selfObject, originalCMD, ##args)

/// 包裹参数处理宏，防止编译警告
#define __FWSwizzleArgsWrap_( args... ) args
#define __FWSwizzleArgsDel2_( a1, a2, args... ) a1, ##args
#define __FWSwizzleArgsDel3_( a1, a2, a3, args... ) a1, a2, ##args

NS_ASSUME_NONNULL_END
