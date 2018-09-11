/*!
 @header     NSObject+FWRuntime.h
 @indexgroup FWFramework
 @brief      NSObject运行时分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-18
 */

#import <Foundation/Foundation.h>

/*!
 @brief NSObject运行时分类
 */
@interface NSObject (FWRuntime)

#pragma mark - Property

/*!
 @brief 读取关联属性
 
 @param name 属性名称
 @return 属性值
 */
- (id)fwPropertyForName:(NSString *)name;

/*!
 @brief 设置强关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetProperty:(id)object forName:(NSString *)name;

/*!
 @brief 设置弱关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyWeak:(id)object forName:(NSString *)name;

/*!
 @brief 设置拷贝关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyCopy:(id)object forName:(NSString *)name;

#pragma mark - Associate

/*!
 @brief 读取关联对象
 @discussion 备注：key的几种形式的声明和使用，下同
    1. 声明：static char kAssociatedObjectKey; 使用：&kAssociatedObjectKey
    2. 声明：static void *kAssociatedObjectKey = &kAssociatedObjectKey; 使用：kAssociatedObjectKey
    3. 声明和使用直接用getter方法的selector，如@selector(xxx)、_cmd
    4. 声明和使用直接用c字符串，如"kAssociatedObjectKey"
 
 @param key 键名
 @return 返回关联对象
 */
- (id)fwAssociatedObjectForKey:(const void *)key;

/*!
 @brief 设置强关联对象，不含KVO
 
 @param object 关联对象
 @param key 键名
 */
- (void)fwSetAssociatedObject:(id)object forKey:(const void *)key;

/*!
 @brief 设置弱关联对象，不含KVO
 
 @param object 关联对象
 @param key 键名
 */
- (void)fwSetAssociatedObjectWeak:(id)object forKey:(const void *)key;

/*!
 @brief 设置拷贝关联对象，不含KVO
 
 @param object 关联对象
 @param key 键名
 */
- (void)fwSetAssociatedObjectCopy:(id)object forKey:(const void *)key;

/*!
 @brief 移除关联对象
 
 @param key 键名
 */
- (void)fwRemoveAssociatedObjectForKey:(const void *)key;

#pragma mark - Swizzle

/*!
 @brief 使用swizzle替换类实例方法
 
 @param originalSelector 原方法
 @param swizzleSelector  替换方法
 @return 是否成功
 */
+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector;

/*!
 @brief 使用swizzle替换类静态方法
 
 @param originalSelector 原方法
 @param swizzleSelector  替换方法
 @return 是否成功
 */
+ (BOOL)fwSwizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector;

@end
