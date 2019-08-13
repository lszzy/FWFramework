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

#pragma mark - Singleton

/*!
 @brief 定义单例头文件
 
 @param cls 类名
 */
#define FWSingleton( cls ) \
    + (cls *)sharedInstance;

/*!
 @brief 定义单例实现
 
 @param cls 类名
 */
#define FWDefSingleton( cls ) \
    + (cls *)sharedInstance \
    { \
        static dispatch_once_t once; \
        static __strong id __singleton__ = nil; \
        dispatch_once( &once, ^{ __singleton__ = [[cls alloc] init]; } ); \
        return __singleton__; \
    }

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
 @brief 定义弱引用动态属性实现
 
 @param type 属性类型
 @param name 属性名称
 @param setter 属性setter
 */
#define FWDefDynamicWeak( type, name, setter ) \
    FWDefDynamicPolicy_( type, name, setter, OBJC_ASSOCIATION_ASSIGN )

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
    @property (nonatomic, readonly) NSString * name; \
    - (NSString *)name; \
    + (NSString *)name;

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
    @property (nonatomic, readonly) NSInteger name; \
    - (NSInteger)name; \
    + (NSInteger)name;

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
    @property (nonatomic, readonly) NSNumber * name; \
    - (NSNumber *)name; \
    + (NSNumber *)name;

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
    @property (nonatomic, readonly) NSString * name; \
    - (NSString *)name; \
    + (NSString *)name;

/*!
 @brief 定义静态字符串属性实现
 
 @param name 属性名称
 @param value 属性值
 */
#define FWDefStaticString( name, value ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return value; }

/*!
 @brief NSObject运行时分类
 @discussion 注意load可能被子类super调用导致调用多次，需dispatch_once避免；
    而initialize如果子类不实现，默认会调用父类initialize，也会导致调用多次，可判断class或dispatch_once避免
 */
@interface NSObject (FWRuntime)

#pragma mark - Property

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
 @brief 设置弱关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyWeak:(nullable id)object forName:(NSString *)name;

/*!
 @brief 设置拷贝关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyCopy:(nullable id)object forName:(NSString *)name;

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
- (nullable id)fwAssociatedObjectForKey:(const void *)key;

/*!
 @brief 设置强关联对象，不含KVO
 
 @param object 关联对象
 @param key 键名
 */
- (void)fwSetAssociatedObject:(nullable id)object forKey:(const void *)key;

/*!
 @brief 设置弱关联对象，不含KVO
 
 @param object 关联对象
 @param key 键名
 */
- (void)fwSetAssociatedObjectWeak:(nullable id)object forKey:(const void *)key;

/*!
 @brief 设置拷贝关联对象，不含KVO
 
 @param object 关联对象
 @param key 键名
 */
- (void)fwSetAssociatedObjectCopy:(nullable id)object forKey:(const void *)key;

/*!
 @brief 移除关联对象
 
 @param key 键名
 */
- (void)fwRemoveAssociatedObjectForKey:(const void *)key;

#pragma mark - Swizzle

/*!
 @brief 使用swizzle替换类实例方法
 
 @param originalSelector 原始方法
 @param swizzleSelector  替换方法
 @return 是否成功
 */
+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector;

/*!
 @brief 使用swizzle替换类静态方法
 
 @param originalSelector 原始方法
 @param swizzleSelector  替换方法
 @return 是否成功
 */
+ (BOOL)fwSwizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector;

/*!
 @brief 使用swizzle替换类实例方法为另一类方法
 
 @param originalSelector 原始方法
 @param originalClass 原始类
 @param swizzleSelector  替换方法
 @param swizzleClass 替换类
 @return 是否成功
 */
+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector in:(Class)originalClass with:(SEL)swizzleSelector in:(Class)swizzleClass;

/*!
 @brief 使用swizzle替换类实例方法为block实现
 @discussion 该block必须返回一个block，返回的block将被当成originalSelector的新实现，所以要在内部自己处理对super的调用，以及对当前调用方法的self的class的保护判断（因为如果originalClass的originalSelector是继承自父类的，originalClass内部并没有重写这个方法，则我们这个函数最终重写的其实是父类的originalSelector，所以会产生预期之外的class的影响，例如originalClass传进来UIButton.class，则最终可能会影响到UIView.class）。block的参数里第一个为你要修改的class，也即等同于originalClass，第二个参数为你要修改的selector，也即等同于originalSelector，第三个参数是一个block，用于获取originalSelector原本的实现，由于IMP可以直接当成C函数调用，所以可利用它来实现“调用 super”的效果，但由于originalSelector的参数个数、参数类型、返回值类型，都会影响IMP的调用写法，所以这个调用只能由业务自己写
 
 @param originalSelector 原始方法
 @param originalClass 原始类
 @param block 实现句柄
 @return 是否成功
 */
+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector in:(Class)originalClass withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

#pragma mark - Selector

/*!
 @brief 安全调用方法，如果不能响应，则忽略之
 
 @param aSelector 要执行的方法
 @return id 方法执行后返回的值
 */
- (nullable id)fwPerformSelector:(SEL)aSelector;

/*!
 @brief 安全调用方法，如果不能响应，则忽略之
 
 @param aSelector 要执行的方法
 @param object 传递的方法参数
 @return id 方法执行后返回的值
 */
- (nullable id)fwPerformSelector:(SEL)aSelector withObject:(nullable id)object;

/*!
 @brief 安全调用内部属性方法，如果属性不存在，则忽略之
 @discussion 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
 
 @param name 内部属性名称
 @return 属性值
 */
- (nullable id)fwPerformPropertySelector:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
