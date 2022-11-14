//
//  FWSwizzle.h
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/// 方法交换快速定义宏
#define FWSwizzleClass( clazz, selector, FWSwizzleReturn, FWSwizzleArgs, FWSwizzleCode ) \
    FWSwizzleMethod_( [clazz class], selector, nil, clazz *, FWSwizzleReturn, FWSwizzleArgsWrap_(FWSwizzleArgs), FWSwizzleArgsWrap_(FWSwizzleCode) )
#define FWSwizzleMethod( target, selector, identifier, FWSwizzleType, FWSwizzleReturn, FWSwizzleArgs, FWSwizzleCode ) \
    FWSwizzleMethod_( target, selector, identifier, FWSwizzleType, FWSwizzleReturn, FWSwizzleArgsWrap_(FWSwizzleArgs), FWSwizzleArgsWrap_(FWSwizzleCode) )
#define FWSwizzleMethod_( target, sel, identity, FWSwizzleType, FWSwizzleReturn, FWSwizzleArgs, FWSwizzleCode ) \
    [NSObject fw_swizzleMethod:target selector:sel identifier:identity block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) { \
        return ^FWSwizzleReturn (FWSwizzleArgsDel2_(__unsafe_unretained FWSwizzleType selfObject, FWSwizzleArgs)) \
        { \
            FWSwizzleReturn (*originalMSG)(FWSwizzleArgsDel3_(id, SEL, FWSwizzleArgs)); \
            originalMSG = (FWSwizzleReturn (*)(FWSwizzleArgsDel3_(id, SEL, FWSwizzleArgs)))originalIMP(); \
            FWSwizzleCode \
        }; \
    }];

/// 方法交换句柄实现宏
#define FWSwizzleBlock( FWSwizzleType, FWSwizzleReturn, FWSwizzleArgs, FWSwizzleCode ) \
    FWSwizzleBlock_( FWSwizzleType, FWSwizzleReturn, FWSwizzleArgsWrap_(FWSwizzleArgs), FWSwizzleArgsWrap_(FWSwizzleCode) )
#define FWSwizzleBlock_( FWSwizzleType, FWSwizzleReturn, FWSwizzleArgs, FWSwizzleCode ) \
    ^FWSwizzleReturn (FWSwizzleArgsDel2_(__unsafe_unretained FWSwizzleType selfObject, FWSwizzleArgs)) \
    { \
        FWSwizzleReturn (*originalMSG)(FWSwizzleArgsDel3_(id, SEL, FWSwizzleArgs)); \
        originalMSG = (FWSwizzleReturn (*)(FWSwizzleArgsDel3_(id, SEL, FWSwizzleArgs)))originalIMP(); \
        FWSwizzleCode \
    };

/// 包裹参数类型、参数列表和句柄实现宏
#define FWSwizzleReturn( type ) type
#define FWSwizzleType( type ) type
#define FWSwizzleArgs( args... ) FWSwizzleArgs_(args)
#define FWSwizzleArgs_( args... ) DEL, ##args
#define FWSwizzleCode( code... ) code

/// 包裹原始方法调用宏
#define FWSwizzleOriginal( args... ) FWSwizzleOriginal_(args)
#define FWSwizzleOriginal_( args... ) originalMSG(selfObject, originalCMD, ##args)

/// 包裹参数处理宏，防止编译警告
#define FWSwizzleArgsWrap_( args... ) args
#define FWSwizzleArgsDel2_( a1, a2, args... ) a1, ##args
#define FWSwizzleArgsDel3_( a1, a2, a3, args... ) a1, a2, ##args

NS_ASSUME_NONNULL_END
