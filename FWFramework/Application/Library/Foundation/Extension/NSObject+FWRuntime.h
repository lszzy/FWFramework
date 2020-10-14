/*!
 @header     NSObject+FWRuntime.h
 @indexgroup FWFramework
 @brief      NSObject运行时分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-18
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Property

/*!
 @brief 定义强引用属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyStrong( type, name ) \
    @property (nonatomic, strong) type name;

/*!
 @brief 定义弱引用属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyWeak( type, name )	\
    @property (nonatomic, weak) type name;

/*!
 @brief 定义赋值属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyAssign( type, name ) \
    @property (nonatomic, assign) type name;

/*!
 @brief 定义拷贝属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyCopy( type, name )	\
    @property (nonatomic, copy) type name;

/*!
 @brief 定义只读属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyReadonly( type, name )	\
    @property (nonatomic, readonly) type name;

/*!
 @brief 定义只读强引用属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyStrongReadonly( type, name ) \
    @property (nonatomic, strong, readonly) type name;

/*!
 @brief 定义只读弱引用属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyWeakReadonly( type, name ) \
    @property (nonatomic, weak, readonly) type name;

/*!
 @brief 定义只读赋值属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyAssignReadonly( type, name ) \
    @property (nonatomic, assign, readonly) type name;

/*!
 @brief 定义只读拷贝属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyCopyReadonly( type, name ) \
    @property (nonatomic, copy, readonly) type name;

/*!
 @brief 自定义属性(如unsafe_unretained类似weak，但如果引用的对象被释放会造成野指针，再次访问会crash，weak会置为nil，不会crash)
 
 @param type 属性类型
 @param name 属性名称
 @param ... 属性修饰符
 */
#define	FWPropertyCustom( type, name, ... ) \
    @property (nonatomic, __VA_ARGS__) type name;

/*!
 @brief 定义属性基本实现
 
 @param name 属性名称
 */
#define FWDefProperty( name ) \
    @synthesize name = _##name;

/*!
 @brief 定义属性动态实现
 
 @param name 属性名称
 */
#define FWDefDynamic( name ) \
    @dynamic name;

/*!
 @brief 按存储策略定义动态属性实现
 
 @parseOnly
 @param type 属性类型
 @param name 属性名称
 @param setter 属性setter
 @param policy 存储策略
 */
#define FWDefDynamicPolicy_( type, name, setter, policy ) \
    @dynamic name; \
    - (type)name \
    { \
        return objc_getAssociatedObject(self, #name); \
    } \
    - (void)setter:(type)object \
    { \
        if (object != [self name]) { \
            [self willChangeValueForKey:@#name]; \
            objc_setAssociatedObject(self, #name, object, policy); \
            [self didChangeValueForKey:@#name]; \
        } \
    }

/*!
 @brief 定义强引用动态属性实现
 
 @param type 属性类型
 @param name 属性名称
 @param setter 属性setter
 */
#define FWDefDynamicStrong( type, name, setter ) \
    FWDefDynamicPolicy_( type, name, setter, OBJC_ASSOCIATION_RETAIN_NONATOMIC )

/*!
 @brief 定义弱引用动态属性实现，注意可能会产生野指针
 
 @param type 属性类型
 @param name 属性名称
 @param setter 属性setter
 */
#define FWDefDynamicWeak( type, name, setter ) \
    @dynamic name; \
    - (type)name \
    { \
        id (^block)(void) = objc_getAssociatedObject(self, #name); \
        return block ? block() : nil; \
    } \
    - (void)setter:(type)object \
    { \
        if (object != [self name]) { \
            [self willChangeValueForKey:@#name]; \
            id __weak weakObject = object; \
            id (^block)(void) = ^{ return weakObject; }; \
            objc_setAssociatedObject(self, #name, block, OBJC_ASSOCIATION_COPY_NONATOMIC); \
            [self didChangeValueForKey:@#name]; \
        } \
    }

/*!
 @brief 定义赋值动态属性实现
 
 @param type 属性类型
 @param name 属性名称
 @param setter 属性setter
 */
#define FWDefDynamicAssign( type, name, setter ) \
    @dynamic name; \
    - (type)name \
    { \
        type cvalue = { 0 }; \
        NSValue *value = objc_getAssociatedObject(self, #name); \
        [value getValue:&cvalue]; \
        return cvalue; \
    } \
    - (void)setter:(type)object \
    { \
        if (object != [self name]) { \
            [self willChangeValueForKey:@#name]; \
            NSValue *value = [NSValue value:&object withObjCType:@encode(type)]; \
            objc_setAssociatedObject(self, #name, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
            [self didChangeValueForKey:@#name]; \
        } \
    }

/*!
 @brief 定义拷贝动态属性实现
 
 @param type 属性类型
 @param name 属性名称
 @param setter 属性setter
 */
#define FWDefDynamicCopy( type, name, setter ) \
    FWDefDynamicPolicy_( type, name, setter, OBJC_ASSOCIATION_COPY_NONATOMIC )

#pragma mark - Lazy

/*!
 @brief 定义懒加载属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define FWLazyProperty( type, name ) \
    @property (nonatomic, strong) type name;

/*!
 @brief 定义懒加载属性实现
 
 @param type 属性类型
 @param name 属性名称
 @param code 实现代码
 */
#define FWDefLazyProperty( type, name, code ) \
    - (type)name \
    { \
        if (!_##name) { \
            code \
        } \
        return _##name; \
    }

#pragma mark - Static

/*!
 @brief 定义静态属性
 
 @param name 属性名称
 */
#define FWStaticProperty( name ) \
    @property (class, nonatomic, readonly) NSString * name; \
    @property (nonatomic, readonly) NSString * name;

/*!
 @brief 定义静态属性实现
 
 @param name 属性名称
 */
#define FWDefStaticProperty( name ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return [NSString stringWithFormat:@"%s", #name]; }

/*!
 @brief 定义静态属性实现，含前缀
 
 @param name 属性名称
 @param prefix 属性前缀
 */
#define FWDefStaticProperty2( name, prefix ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return [NSString stringWithFormat:@"%@.%s", prefix, #name]; }

/*!
 @brief 定义静态属性实现，含分组、前缀
 
 @param name 属性名称
 @param group 属性分组
 @param prefix 属性前缀
 */
#define FWDefStaticProperty3( name, group, prefix ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return [NSString stringWithFormat:@"%@.%@.%s", group, prefix, #name]; }

/*!
 @brief 定义静态NSInteger属性
 
 @param name 属性名称
 */
#define FWStaticInteger( name ) \
    @property (class, nonatomic, readonly) NSInteger name; \
    @property (nonatomic, readonly) NSInteger name;

/*!
 @brief 定义静态NSInteger属性实现
 
 @param name 属性名称
 @param value 属性值
 */
#define FWDefStaticInteger( name, value ) \
    @dynamic name; \
    - (NSInteger)name { return [[self class] name]; } \
    + (NSInteger)name { return value; }

/*!
 @brief 定义静态NSNumber属性
 
 @param name 属性名称
 */
#define FWStaticNumber( name ) \
    @property (class, nonatomic, readonly) NSNumber * name; \
    @property (nonatomic, readonly) NSNumber * name;

/*!
 @brief 定义静态NSNumber属性实现
 
 @param name 属性名称
 @param value 属性值
 */
#define FWDefStaticNumber( name, value ) \
    @dynamic name; \
    - (NSNumber *)name { return [[self class] name]; } \
    + (NSNumber *)name { return @(value); }

/*!
 @brief 定义静态字符串属性
 
 @param name 属性名称
 */
#define FWStaticString( name ) \
    @property (class, nonatomic, readonly) NSString * name; \
    @property (nonatomic, readonly) NSString * name;

/*!
 @brief 定义静态字符串属性实现
 
 @param name 属性名称
 @param value 属性值
 */
#define FWDefStaticString( name, value ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return value; }

#pragma mark - NSObject+FWRuntime

/*!
 @brief NSObject运行时分类
 @discussion 注意load可能被子类super调用导致调用多次，需dispatch_once避免；
    而initialize如果子类不实现，默认会调用父类initialize，也会导致调用多次，可判断class或dispatch_once避免
 */
@interface NSObject (FWRuntime)

#pragma mark - Selector

/*!
 @brief 安全调用方法，如果不能响应，则忽略之
 
 @param aSelector 要执行的方法
 @return id 方法执行后返回的值。如果无返回值，则为nil
 */
- (nullable id)fwPerformSelector:(SEL)aSelector;

/*!
 @brief 安全调用方法，如果不能响应，则忽略之
 
 @param aSelector 要执行的方法
 @param object 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
 @return id 方法执行后返回的值。如果无返回值，则为nil
 */
- (nullable id)fwPerformSelector:(SEL)aSelector withObject:(nullable id)object;

/*!
 @brief 对super发送消息
 
 @param aSelector 要执行的方法，需返回id类型
 @return id 方法执行后返回的值
 */
- (nullable id)fwPerformSuperSelector:(SEL)aSelector;

/*!
 @brief 对super发送消息，可传递参数
 
 @param aSelector 要执行的方法，需返回id类型
 @param object 传递的方法参数
 @return id 方法执行后返回的值
 */
- (nullable id)fwPerformSuperSelector:(SEL)aSelector withObject:(nullable id)object;

/*!
 @brief 安全调用内部属性方法，如果属性不存在，则忽略之
 @discussion 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
 
 @param name 内部属性名称
 @return 属性值
 */
- (nullable id)fwPerformPropertySelector:(NSString *)name;

/*!
 @brief 安全调用内部属性设置方法，如果属性不存在，则忽略之
 @discussion 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
 
 @param name 内部属性名称
 @param object 传递的方法参数
 @return 方法执行后返回的值
 */
- (nullable id)fwPerformPropertySelector:(NSString *)name withObject:(nullable id)object;

@end

NS_ASSUME_NONNULL_END
