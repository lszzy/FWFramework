/*!
 @header     FWSwizzle.h
 @indexgroup FWFramework
 @brief      FWSwizzle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/6/4
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/// 方法交换快速定义宏
#define FWSwizzleClass( clazz, selector, FWReturnType, FWArguments, FWCode ) \
    FWSwizzleMethod_( [clazz class], selector, nil, clazz *, FWReturnType, FWArgsWrap_(FWArguments), FWArgsWrap_(FWCode) )
#define FWSwizzleMethod( target, selector, identifier, FWClassType, FWReturnType, FWArguments, FWCode ) \
    FWSwizzleMethod_( target, selector, identifier, FWClassType, FWReturnType, FWArgsWrap_(FWArguments), FWArgsWrap_(FWCode) )
#define FWSwizzleMethod_( target, sel, identity, FWClassType, FWReturnType, FWArguments, FWCode ) \
    [FWSwizzle swizzleMethod:target selector:sel identifier:identity withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) { \
        return ^FWReturnType (FWArgsDel2_(FWClassType selfObject, FWArguments)) \
        { \
            FWReturnType (*originalMSG)(FWArgsDel3_(id, SEL, FWArguments)); \
            originalMSG = (FWReturnType (*)(FWArgsDel3_(id, SEL, FWArguments)))originalIMP(); \
            FWCode \
        }; \
    }];

/// 方法交换句柄实现宏
#define FWSwizzleBlock( FWClassType, FWReturnType, FWArguments, FWCode ) \
    FWSwizzleBlock_( FWClassType, FWReturnType, FWArgsWrap_(FWArguments), FWArgsWrap_(FWCode) )
#define FWSwizzleBlock_( FWClassType, FWReturnType, FWArguments, FWCode ) \
    ^FWReturnType (FWArgsDel2_(FWClassType selfObject, FWArguments)) \
    { \
        FWReturnType (*originalMSG)(FWArgsDel3_(id, SEL, FWArguments)); \
        originalMSG = (FWReturnType (*)(FWArgsDel3_(id, SEL, FWArguments)))originalIMP(); \
        FWCode \
    };

/// 包裹参数类型、参数列表和句柄实现宏
#define FWReturnType( type ) type
#define FWClassType( type ) type
#define FWArguments( arguments... ) FWArguments_(arguments)
#define FWArguments_( arguments... ) DEL, ##arguments
#define FWCode( code... ) code

/// 包裹原始方法调用宏
#define FWCallOriginal( arguments... ) FWCallOriginal_(arguments)
#define FWCallOriginal_( arguments... ) originalMSG(selfObject, originalCMD, ##arguments)

/// 包裹参数处理宏，防止编译警告
#define FWArgsWrap_( args... ) args
#define FWArgsDel2_( a1, a2, args... ) a1, ##args
#define FWArgsDel3_( a1, a2, a3, args... ) a1, a2, ##args

#pragma mark - FWSwizzle

/*!
 @brief Swizzle方法交换类
 @discussion 实现block必须返回一个block，返回的block将被当成originalSelector的新实现，所以要在内部自己处理对super的调用，以及对当前调用方法的self的class的保护判断（因为如果originalClass的originalSelector是继承自父类的，originalClass内部并没有重写这个方法，则我们这个函数最终重写的其实是父类的originalSelector，所以会产生预期之外的class的影响，例如originalClass传进来UIButton.class，则最终可能会影响到UIView.class）。block的参数里第一个为你要修改的class，也即等同于originalClass，第二个参数为你要修改的selector，也即等同于originalSelector，第三个参数是一个block，用于获取originalSelector原本的实现，由于IMP可以直接当成C函数调用，所以可利用它来实现“调用 super”的效果，但由于originalSelector的参数个数、参数类型、返回值类型，都会影响IMP的调用写法，所以这个调用只能由业务自己写
 */
@interface FWSwizzle : NSObject

/*!
 @brief 通用swizzle替换实例方法为block实现，支持类和对象，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
 
 @param target 目标类或对象
 @param originalSelector 原始方法
 @param identifier 唯一标识，有值且相同时仅执行一次
 @param block 实现句柄
 @return 是否成功
 */
+ (BOOL)swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/*!
 @brief 使用swizzle替换类实例方法为block实现。复杂情况不会冲突，推荐使用
 
 @param originalClass 原始类
 @param originalSelector 原始方法
 @param block 实现句柄
 @return 是否成功
 */
+ (BOOL)swizzleClass:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/*!
 @brief 使用swizzle替换类实例方法为block实现，identifier相同时仅执行一次。复杂情况不会冲突，推荐使用
 
 @param originalClass 原始类
 @param originalSelector 原始方法
 @param identifier 唯一标识
 @param block 实现句柄
 @return 是否成功
 */
+ (BOOL)swizzleClass:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/*!
 @brief 使用swizzle替换对象实例方法为block实现，identifier相同时仅执行一次。结合fwIsSwizzleMethod使用
 
 @param object 目标对象
 @param originalSelector 原始方法
 @param identifier 唯一标识
 @param block 实现句柄
 @return 是否成功
 */
+ (BOOL)swizzleObject:(nullable id)object selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/*!
 @brief 判断对象是否使用swizzle替换过指定identifier实例方法。结合fwSwizzleMethod使用
 @discussion 因为实际替换的是类方法，为了防止影响该类其它对象，需先判断该对象是否替换过，仅替换过才执行自定义流程

 @param object 目标对象
 @param originalSelector 原始方法
 @param identifier 唯一标识
 @return 是否替换
*/
+ (BOOL)isSwizzleObject:(nullable id)object selector:(SEL)originalSelector identifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
