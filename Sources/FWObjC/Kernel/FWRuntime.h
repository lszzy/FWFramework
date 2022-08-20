//
//  FWRuntime.h
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSObject+FWRuntime

/// 框架NSObject类包装器
@interface NSObject (FWRuntime)

#pragma mark - Class

/**
 获取类方法列表，自动缓存，支持meta类(objc_getMetaClass)
 
 @param clazz 指定类
 @param superclass 是否包含父类，包含则递归到NSObject
 @return 方法列表
 */
+ (NSArray<NSString *> *)fw_classMethods:(Class)clazz superclass:(BOOL)superclass NS_REFINED_FOR_SWIFT;

/**
 获取类属性列表，自动缓存，支持meta类(objc_getMetaClass)
 
 @param clazz 指定类
 @param superclass 是否包含父类，包含则递归到NSObject
 @return 属性列表
 */
+ (NSArray<NSString *> *)fw_classProperties:(Class)clazz superclass:(BOOL)superclass NS_REFINED_FOR_SWIFT;

/**
 获取类Ivar列表，自动缓存，支持meta类(objc_getMetaClass)
 
 @param clazz 指定类
 @param superclass 是否包含父类，包含则递归到NSObject
 @return Ivar列表
 */
+ (NSArray<NSString *> *)fw_classIvars:(Class)clazz superclass:(BOOL)superclass NS_REFINED_FOR_SWIFT;

#pragma mark - Runtime

/**
 安全调用方法，如果不能响应，则忽略之
 
 @param aSelector 要执行的方法
 @return id 方法执行后返回的值。如果无返回值，则为nil
 */
- (nullable id)fw_invokeMethod:(SEL)aSelector NS_REFINED_FOR_SWIFT;

/**
 安全调用方法，如果不能响应，则忽略之
 
 @param aSelector 要执行的方法
 @param object 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
 @return id 方法执行后返回的值。如果无返回值，则为nil
 */
- (nullable id)fw_invokeMethod:(SEL)aSelector withObject:(nullable id)object NS_REFINED_FOR_SWIFT;

/**
 安全调用方法，支持多个参数
 
 @param aSelector 要执行的方法
 @param objects 传递的参数数组
 @return id 方法执行后返回的值。如果无返回值，则为nil
 */
- (nullable id)fw_invokeMethod:(SEL)aSelector withObjects:(NSArray *)objects NS_SWIFT_NAME(__fw_invokeMethod(_:objects:)) NS_REFINED_FOR_SWIFT;

/**
 对super发送消息
 
 @param aSelector 要执行的方法，需返回id类型
 @return id 方法执行后返回的值
 */
- (nullable id)fw_invokeSuperMethod:(SEL)aSelector NS_REFINED_FOR_SWIFT;

/**
 对super发送消息，可传递参数
 
 @param aSelector 要执行的方法，需返回id类型
 @param object 传递的方法参数
 @return id 方法执行后返回的值
 */
- (nullable id)fw_invokeSuperMethod:(SEL)aSelector withObject:(nullable id)object NS_REFINED_FOR_SWIFT;

/**
 安全调用内部属性获取方法，如果属性不存在，则忽略之
 @note 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
 
 @param name 内部属性名称
 @return 属性值
 */
- (nullable id)fw_invokeGetter:(NSString *)name NS_REFINED_FOR_SWIFT;

/**
 安全调用内部属性设置方法，如果属性不存在，则忽略之
 @note 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
 
 @param name 内部属性名称
 @param object 传递的方法参数
 @return 方法执行后返回的值
 */
- (nullable id)fw_invokeSetter:(NSString *)name withObject:(nullable id)object NS_REFINED_FOR_SWIFT;

#pragma mark - Property

/**
 临时对象，强引用，支持KVO
 @note 备注：key的几种形式的声明和使用，下同
    1. 声明：static char kAssociatedObjectKey; 使用：&kAssociatedObjectKey
    2. 声明：static void *kAssociatedObjectKey = &kAssociatedObjectKey; 使用：kAssociatedObjectKey
    3. 声明和使用直接用getter方法的selector，如@selector(xxx)、_cmd
    4. 声明和使用直接用c字符串，如"kAssociatedObjectKey"
 */
@property (nullable, nonatomic, strong) id fw_tempObject NS_REFINED_FOR_SWIFT;

/**
 读取关联属性
 
 @param name 属性名称
 @return 属性值
 */
- (nullable id)fw_propertyForName:(NSString *)name NS_REFINED_FOR_SWIFT;

/**
 设置强关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fw_setProperty:(nullable id)object forName:(NSString *)name NS_REFINED_FOR_SWIFT;

/**
 设置赋值关联属性，支持KVO，注意可能会产生野指针
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fw_setPropertyAssign:(nullable id)object forName:(NSString *)name NS_REFINED_FOR_SWIFT;

/**
 设置拷贝关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fw_setPropertyCopy:(nullable id)object forName:(NSString *)name NS_REFINED_FOR_SWIFT;

/**
 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fw_setPropertyWeak:(nullable id)object forName:(NSString *)name NS_REFINED_FOR_SWIFT;

#pragma mark - Bind

/**
 给对象绑定上另一个对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
 
 @param object 对象，会被 strong 强引用
 @param key 键名
 */
- (void)fw_bindObject:(nullable id)object forKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 给对象绑定上另一个弱引用对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
 
 @param object 对象，不会被 strong 强引用
 @param key 键名
 */
- (void)fw_bindObjectWeak:(nullable id)object forKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 取出之前使用 bind 方法绑定的对象
 
 @param key 键名
 */
- (nullable id)fw_boundObjectForKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 给对象绑定上一个 double 值以供后续取出使用
 
 @param doubleValue double值
 @param key 键名
 */
- (void)fw_bindDouble:(double)doubleValue forKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 取出之前用 bindDouble:forKey: 绑定的值
 
 @param key 键名
 */
- (double)fw_boundDoubleForKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 给对象绑定上一个 BOOL 值以供后续取出使用
 
 @param boolValue 布尔值
 @param key 键名
 */
- (void)fw_bindBool:(BOOL)boolValue forKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 取出之前用 bindBool:forKey: 绑定的值
 
 @param key 键名
 */
- (BOOL)fw_boundBoolForKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 给对象绑定上一个 NSInteger 值以供后续取出使用
 
 @param integerValue 整数值
 
 @param key 键名
 */
- (void)fw_bindInt:(NSInteger)integerValue forKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 取出之前用 bindInt:forKey: 绑定的值
 
 @param key 键名
 */
- (NSInteger)fw_boundIntForKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 移除之前使用 bind 方法绑定的对象
 
 @param key 键名
 */
- (void)fw_removeBindingForKey:(NSString *)key NS_REFINED_FOR_SWIFT;

/**
 移除之前使用 bind 方法绑定的所有对象
 */
- (void)fw_removeAllBindings NS_REFINED_FOR_SWIFT;

/**
 返回当前有绑定对象存在的所有的 key 的数组，数组中元素的顺序是随机的，如果不存在任何 key，则返回一个空数组
 */
- (NSArray<NSString *> *)fw_allBindingKeys NS_REFINED_FOR_SWIFT;

/**
 返回是否设置了某个 key
 
 @param key 键名
 */
- (BOOL)fw_hasBindingKey:(NSString *)key NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
