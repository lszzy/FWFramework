/*!
 @header     FWSwizzle.h
 @indexgroup FWFramework
 @brief      FWSwizzle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/6/5
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/// 方法交换快速定义宏
#define FWSwizzleClass( clazz, selector, FWSwizzleReturn, FWSwizzleArgs, FWSwizzleCode ) \
    FWSwizzleMethod_( [clazz class], selector, nil, clazz *, FWSwizzleReturn, FWSwizzleArgsWrap_(FWSwizzleArgs), FWSwizzleArgsWrap_(FWSwizzleCode) )
#define FWSwizzleMethod( target, selector, identifier, FWSwizzleType, FWSwizzleReturn, FWSwizzleArgs, FWSwizzleCode ) \
    FWSwizzleMethod_( target, selector, identifier, FWSwizzleType, FWSwizzleReturn, FWSwizzleArgsWrap_(FWSwizzleArgs), FWSwizzleArgsWrap_(FWSwizzleCode) )
#define FWSwizzleMethod_( target, sel, identity, FWSwizzleType, FWSwizzleReturn, FWSwizzleArgs, FWSwizzleCode ) \
    [NSObject fwSwizzleMethod:target selector:sel identifier:identity withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) { \
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

#pragma mark - NSObject+FWSwizzle

/*!
 @brief NSObject方法交换分类
 @discussion 实现block必须返回一个block，返回的block将被当成originalSelector的新实现，所以要在内部自己处理对super的调用，以及对当前调用方法的self的class的保护判断（因为如果originalClass的originalSelector是继承自父类的，originalClass内部并没有重写这个方法，则我们这个函数最终重写的其实是父类的originalSelector，所以会产生预期之外的class的影响，例如originalClass传进来UIButton.class，则最终可能会影响到UIView.class）。block的参数里第一个为你要修改的class，也即等同于originalClass，第二个参数为你要修改的selector，也即等同于originalSelector，第三个参数是一个block，用于获取originalSelector原本的实现，由于IMP可以直接当成C函数调用，所以可利用它来实现“调用 super”的效果，但由于originalSelector的参数个数、参数类型、返回值类型，都会影响IMP的调用写法，所以这个调用只能由业务自己写
*/
@interface NSObject (FWSwizzle)

#pragma mark - Simple

/*!
 @brief 使用swizzle替换类实例方法。复杂情况可能会冲突
 
 @param originalSelector 原始方法
 @param swizzleSelector  替换方法
 @return 是否成功
 */
+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector;

/*!
 @brief 使用swizzle替换类静态方法。复杂情况可能会冲突
 
 @param originalSelector 原始方法
 @param swizzleSelector  替换方法
 @return 是否成功
 */
+ (BOOL)fwSwizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector;

/*!
 @brief 使用swizzle替换类实例方法为block实现。复杂情况可能会冲突
 @discussion swizzleBlock示例：^(__unsafe_unretained UIViewController *selfObject, BOOL animated){ ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector, animated); }
 
 @param originalSelector 原始方法
 @param swizzleSelector  替换方法
 @param swizzleBlock 实现block
 @return 是否成功
 */
+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector block:(id)swizzleBlock;

/*!
 @brief 使用swizzle替换类静态方法为block实现。复杂情况可能会冲突
 @discussion swizzleBlock示例：^(__unsafe_unretained UIViewController *selfObject, BOOL animated){ ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector, animated); }
 
 @param originalSelector 原始方法
 @param swizzleSelector  替换方法
 @param swizzleBlock 实现block
 @return 是否成功
 */
+ (BOOL)fwSwizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector block:(id)swizzleBlock;

/*!
 @brief 生成原始方法对应的随机替换方法
 
 @param selector 原始方法
 @return 替换方法
 */
+ (SEL)fwSwizzleSelectorForSelector:(SEL)selector;

#pragma mark - Complex

/*!
 @brief 通用swizzle替换实例方法为block实现，支持类和对象，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
 
 @param target 目标类或对象
 @param originalSelector 原始方法
 @param identifier 唯一标识，有值且相同时仅执行一次
 @param block 实现句柄
 @return 是否成功
 */
+ (BOOL)fwSwizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/*!
 @brief 使用swizzle替换类实例方法为block实现。复杂情况不会冲突，推荐使用
 
 @param originalClass 原始类
 @param originalSelector 原始方法
 @param block 实现句柄
 @return 是否成功
 */
+ (BOOL)fwSwizzleClass:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/*!
 @brief 使用swizzle替换类实例方法为block实现，identifier相同时仅执行一次。复杂情况不会冲突，推荐使用
 
 @param originalClass 原始类
 @param originalSelector 原始方法
 @param identifier 唯一标识
 @param block 实现句柄
 @return 是否成功
 */
+ (BOOL)fwSwizzleClass:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/*!
 @brief 使用swizzle替换对象实例方法为block实现，identifier相同时仅执行一次。结合fwIsSwizzleMethod使用
 
 @param originalSelector 原始方法
 @param identifier 唯一标识
 @param block 实现句柄
 @return 是否成功
 */
- (BOOL)fwSwizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

/*!
 @brief 判断对象是否使用swizzle替换过指定identifier实例方法。结合fwSwizzleMethod使用
 @discussion 因为实际替换的是类方法，为了防止影响该类其它对象，需先判断该对象是否替换过，仅替换过才执行自定义流程

 @param originalSelector 原始方法
 @param identifier 唯一标识
 @return 是否替换
*/
- (BOOL)fwIsSwizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier;

#pragma mark - Property

/*!
 @brief 临时对象，强引用，支持KVO
 @discussion 备注：key的几种形式的声明和使用，下同
    1. 声明：static char kAssociatedObjectKey; 使用：&kAssociatedObjectKey
    2. 声明：static void *kAssociatedObjectKey = &kAssociatedObjectKey; 使用：kAssociatedObjectKey
    3. 声明和使用直接用getter方法的selector，如@selector(xxx)、_cmd
    4. 声明和使用直接用c字符串，如"kAssociatedObjectKey"
 */
@property (nullable, nonatomic, strong) id fwTempObject;

/*!
 @brief 读取关联属性
 
 @param name 属性名称
 @return 属性值
 */
- (nullable id)fwPropertyForName:(NSString *)name;

/*!
 @brief 设置强关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetProperty:(nullable id)object forName:(NSString *)name;

/*!
 @brief 设置赋值关联属性，支持KVO，注意可能会产生野指针
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyAssign:(nullable id)object forName:(NSString *)name;

/*!
 @brief 设置拷贝关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyCopy:(nullable id)object forName:(NSString *)name;

/*!
 @brief 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyWeak:(nullable id)object forName:(NSString *)name;

#pragma mark - Bind

/*!
 @brief 给对象绑定上另一个对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
 
 @param object 对象，会被 strong 强引用
 @param key 键名
 */
- (void)fwBindObject:(nullable id)object forKey:(NSString *)key;

/*!
 @brief 给对象绑定上另一个弱引用对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
 
 @param object 对象，不会被 strong 强引用
 @param key 键名
 */
- (void)fwBindObjectWeak:(nullable id)object forKey:(NSString *)key;

/*!
 @brief 取出之前使用 bind 方法绑定的对象
 
 @param key 键名
 */
- (nullable id)fwBoundObjectForKey:(NSString *)key;

/*!
 @brief 给对象绑定上一个 double 值以供后续取出使用
 
 @param doubleValue double值
 @param key 键名
 */
- (void)fwBindDouble:(double)doubleValue forKey:(NSString *)key;

/*!
 @brief 取出之前用 bindDouble:forKey: 绑定的值
 
 @param key 键名
 */
- (double)fwBoundDoubleForKey:(NSString *)key;

/*!
 @brief 给对象绑定上一个 BOOL 值以供后续取出使用
 
 @param boolValue 布尔值
 @param key 键名
 */
- (void)fwBindBool:(BOOL)boolValue forKey:(NSString *)key;

/*!
 @brief 取出之前用 bindBool:forKey: 绑定的值
 
 @param key 键名
 */
- (BOOL)fwBoundBoolForKey:(NSString *)key;

/*!
 @brief 给对象绑定上一个 NSInteger 值以供后续取出使用
 
 @param integerValue 整数值
 
 @param key 键名
 */
- (void)fwBindInt:(NSInteger)integerValue forKey:(NSString *)key;

/*!
 @brief 取出之前用 bindInt:forKey: 绑定的值
 
 @param key 键名
 */
- (NSInteger)fwBoundIntForKey:(NSString *)key;

/*!
 @brief 移除之前使用 bind 方法绑定的对象
 
 @param key 键名
 */
- (void)fwRemoveBindingForKey:(NSString *)key;

/*!
 @brief 移除之前使用 bind 方法绑定的所有对象
 */
- (void)fwRemoveAllBindings;

/*!
 @brief 返回当前有绑定对象存在的所有的 key 的数组，数组中元素的顺序是随机的，如果不存在任何 key，则返回一个空数组
 */
- (NSArray<NSString *> *)fwAllBindingKeys;

/*!
 @brief 返回是否设置了某个 key
 
 @param key 键名
 */
- (BOOL)fwHasBindingKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
