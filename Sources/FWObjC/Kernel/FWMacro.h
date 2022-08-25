//
//  FWMacro.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#ifndef FWMacro_h
#define FWMacro_h

#import <Foundation/Foundation.h>

#pragma mark - Block

#ifndef weakify

/**
 解决block循环引用，@weakify，和@strongify配对使用
 
 @param x 变量名，如self
 */
#define weakify( x ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    autoreleasepool{} __weak __typeof__(x) x##_weak_ = x; \
    _Pragma("clang diagnostic pop")

#endif /* weakify */

#ifndef strongify

/**
 解决block循环引用，@strongify，和@weakify配对使用
 
 @param x 变量名，如self
 */
#define strongify( x ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    try{} @finally{} __typeof__(x) x = x##_weak_; \
    _Pragma("clang diagnostic pop")

#endif /* strongify */

/**
 解决block循环引用，和FWStrongify配对使用
 
 @param x 变量名，如self
 */
#define FWWeakify( x ) \
    @_Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    autoreleasepool{} __weak __typeof__(x) x##_weak_ = x; \
    _Pragma("clang diagnostic pop")

/**
 解决block循环引用，和FWWeakify配对使用
 
 @param x 变量名，如self
 */
#define FWStrongify( x ) \
    @_Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    try{} @finally{} __typeof__(x) x = x##_weak_; \
    _Pragma("clang diagnostic pop")

/**
 解决self循环引用。等价于：typeof(self) __weak self_weak_ = self;
 */
#define FWWeakifySelf( ) \
    FWWeakify( self )

/**
 解决self循环引用。等价于：typeof(self_weak_) __strong self = self_weak_;
 */
#define FWStrongifySelf( ) \
    FWStrongify( self )

#pragma mark - Macro

/**
 参数字符串连接
 
 @param A 字符串A
 @param B 字符串B
 */
#define fw_macro_concat( A, B ) \
    fw_macro_concat_( A, B )
#define fw_macro_concat_( A, B ) \
    A##B

/**
 参数转C字符串
 
 @param A 参数字符串
 */
#define fw_macro_cstring( A ) \
    fw_macro_cstring_( A )
#define fw_macro_cstring_( A ) \
    #A

/**
 参数转OC字符串
 
 @param A 参数字符串
 */
#define fw_macro_string( A ) \
    fw_macro_string_(A)
#define fw_macro_string_( A ) \
    @(#A)

/**
 截取第一个参数
 
 @param ... 参数列表
 */
#define fw_macro_first(...) \
    fw_macro_first_( __VA_ARGS__, 0 )
#define fw_macro_first_( A, ... ) \
    A

/**
 截取第一个之后的其它参数
 
 @param ... 参数列表
 */
#define fw_macro_other(...) \
    fw_macro_other_( __VA_ARGS__, nil )
#define fw_macro_other_( A, ... ) \
    __VA_ARGS__

/**
 计算参数个数
 
 @param ... 参数列表
 */
#define fw_macro_count(...) \
    fw_macro_at( 8, __VA_ARGS__, 8, 7, 6, 5, 4, 3, 2, 1 )

/**
 计算指定参数个数
 
 @param N 参数个数
 @param ... 参数列表
 */
#define fw_macro_at(N, ...) \
    fw_macro_concat(fw_macro_at_, N)( __VA_ARGS__ )
#define fw_macro_at_0(...) \
    fw_macro_first(__VA_ARGS__)
#define fw_macro_at_1(_0, ...) \
    fw_macro_first(__VA_ARGS__)
#define fw_macro_at_2(_0, _1, ...) \
    fw_macro_first(__VA_ARGS__)
#define fw_macro_at_3(_0, _1, _2, ...) \
    fw_macro_first(__VA_ARGS__)
#define fw_macro_at_4(_0, _1, _2, _3, ...) \
    fw_macro_first(__VA_ARGS__)
#define fw_macro_at_5(_0, _1, _2, _3, _4 ...) \
    fw_macro_first(__VA_ARGS__)
#define fw_macro_at_6(_0, _1, _2, _3, _4, _5 ...) \
    fw_macro_first(__VA_ARGS__)
#define fw_macro_at_7(_0, _1, _2, _3, _4, _5, _6 ...) \
    fw_macro_first(__VA_ARGS__)
#define fw_macro_at_8(_0, _1, _2, _3, _4, _5, _6, _7, ...) \
    fw_macro_first(__VA_ARGS__)

/**
 参数默认值设置，需传入##__VA_ARGS__
 @note 调用示例：fw_macro_default(default, ##__VA_ARGS__)。##__VA_ARGS__前面的##作用在于，当可变参数的个数为0时，把前面多余的","去掉，否则会编译出错
 
 @param ... 参数列表
 */
#define fw_macro_default( ... ) \
    fw_macro_concat(fw_macro_default_, fw_macro_count(__VA_ARGS__))(__VA_ARGS__)
#define fw_macro_default_0( ... )
#define fw_macro_default_1( X ) \
    X
#define fw_macro_default_2( X, A ) \
    A
#define fw_macro_default_3( X, A, B ) \
    A
#define fw_macro_default_4( X, A, B, C ) \
    A
#define fw_macro_default_5( X, A, B, C, D ) \
    A
#define fw_macro_default_6( X, A, B, C, D, E ) \
    A
#define fw_macro_default_7( X, A, B, C, D, E, F ) \
    A
#define fw_macro_default_8( X, A, B, C, D, E, F, G ) \
    A

/**
 指定位置参数默认值设置，从1开始计数，需传入##__VA_ARGS__
 @note 调用示例：fw_macro_default_at(1, default, ##__VA_ARGS__)
 
 @param N 参数位置索引，从1开始
 @param ... 参数列表
 */
#define fw_macro_default_at( N, ... ) \
    fw_macro_concat(fw_macro_default_at_, fw_macro_count(__VA_ARGS__))(N, __VA_ARGS__)
#define fw_macro_default_at_0( ... )
#define fw_macro_default_at_1( N, X ) \
    X
#define fw_macro_default_at_2( N, X, A ) \
    N > 1 ? X : A
#define fw_macro_default_at_3( N, X, A, B ) \
    N > 2 ? X : fw_macro_default_at_2( N, B, A )
#define fw_macro_default_at_4( N, X, A, B, C ) \
    N > 3 ? X : fw_macro_default_at_3( N, C, A, B )
#define fw_macro_default_at_5( N, X, A, B, C, D ) \
    N > 4 ? X : fw_macro_default_at_4( N, D, A, B, C )
#define fw_macro_default_at_6( N, X, A, B, C, D, E ) \
    N > 5 ? X : fw_macro_default_at_5( N, E, A, B, C, D )
#define fw_macro_default_at_7( N, X, A, B, C, D, E, F ) \
    N > 6 ? X : fw_macro_default_at_6( N, F, A, B, C, D, E )
#define fw_macro_default_at_8( N, X, A, B, C, D, E, F, G ) \
    N > 7 ? X : fw_macro_default_at_7( N, G, A, B, C, D, E, F )

#pragma mark - Foundation

#ifdef DEBUG

/// 调试模式打开日志
#define NSLog(format, ...) \
    NSLog((@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__)

#else

/// 正式环境关闭日志
#define NSLog(...)

#endif

/// 标记废弃方法或属性
#define    FWDeprecated( msg ) \
    __attribute__((deprecated(msg)))

/// 标记未使用的变量
#define    FWUnused( x ) \
    { id __unused_var__ __attribute__((unused)) = (id)(x); }

/// 标记未完成的功能
#define FWTodo( msg ) \
    _Pragma(fw_macro_cstring(message("✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖ TODO: " msg)))

/// 声明dealloc方法，可不传参数，也可传code，或者{code}
#define FWDealloc( x ) \
    - (void)dealloc \
    { \
        [[NSNotificationCenter defaultCenter] removeObserver:self]; \
        NSLog(@"%@ did dealloc", NSStringFromClass(self.class)); \
        x \
    }

/// 标记忽略调用方法警告开始
#define FWIgnoredBegin( ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
    _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"") \
    _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")

/// 标记忽略警告结束
#define FWIgnoredEnd( ) \
    _Pragma("clang diagnostic pop")

#pragma mark - Singleton

/**
 定义单例头文件
 
 @param cls 类名
 */
#define FWSingleton( cls ) \
    @property (class, nonatomic, readonly) cls *sharedInstance NS_SWIFT_NAME(shared);

/**
 定义单例实现
 
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

/**
 定义强引用属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyStrong( type, name ) \
    @property (nonatomic, strong) type name;

/**
 定义弱引用属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyWeak( type, name )	\
    @property (nonatomic, weak) type name;

/**
 定义赋值属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyAssign( type, name ) \
    @property (nonatomic, assign) type name;

/**
 定义拷贝属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyCopy( type, name )	\
    @property (nonatomic, copy) type name;

/**
 定义只读属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyReadonly( type, name )	\
    @property (nonatomic, readonly) type name;

/**
 定义只读强引用属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyStrongReadonly( type, name ) \
    @property (nonatomic, strong, readonly) type name;

/**
 定义只读弱引用属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyWeakReadonly( type, name ) \
    @property (nonatomic, weak, readonly) type name;

/**
 定义只读赋值属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyAssignReadonly( type, name ) \
    @property (nonatomic, assign, readonly) type name;

/**
 定义只读拷贝属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define	FWPropertyCopyReadonly( type, name ) \
    @property (nonatomic, copy, readonly) type name;

/**
 自定义属性(如unsafe_unretained类似weak，但如果引用的对象被释放会造成野指针，再次访问会crash，weak会置为nil，不会crash)
 
 @param type 属性类型
 @param name 属性名称
 @param ... 属性修饰符
 */
#define	FWPropertyCustom( type, name, ... ) \
    @property (nonatomic, __VA_ARGS__) type name;

/**
 定义属性基本实现
 
 @param name 属性名称
 */
#define FWDefProperty( name ) \
    @synthesize name = _##name;

/**
 定义属性动态实现
 
 @param name 属性名称
 */
#define FWDefDynamic( name ) \
    @dynamic name;

/**
 按存储策略定义动态属性实现
 
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

/**
 定义强引用动态属性实现
 
 @param type 属性类型
 @param name 属性名称
 @param setter 属性setter
 */
#define FWDefDynamicStrong( type, name, setter ) \
    FWDefDynamicPolicy_( type, name, setter, OBJC_ASSOCIATION_RETAIN_NONATOMIC )

/**
 定义弱引用动态属性实现，注意可能会产生野指针
 
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

/**
 定义赋值动态属性实现
 
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

/**
 定义拷贝动态属性实现
 
 @param type 属性类型
 @param name 属性名称
 @param setter 属性setter
 */
#define FWDefDynamicCopy( type, name, setter ) \
    FWDefDynamicPolicy_( type, name, setter, OBJC_ASSOCIATION_COPY_NONATOMIC )

/**
 定义懒加载属性
 
 @param type 属性类型
 @param name 属性名称
 */
#define FWLazyProperty( type, name ) \
    @property (nonatomic, strong) type name;

/**
 定义懒加载属性实现
 
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

/**
 定义静态属性
 
 @param name 属性名称
 */
#define FWStaticProperty( name ) \
    @property (class, nonatomic, readonly) NSString * name; \
    @property (nonatomic, readonly) NSString * name;

/**
 定义静态属性实现
 
 @param name 属性名称
 */
#define FWDefStaticProperty( name ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return [NSString stringWithFormat:@"%s", #name]; }

/**
 定义静态属性实现，含前缀
 
 @param name 属性名称
 @param prefix 属性前缀
 */
#define FWDefStaticProperty2( name, prefix ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return [NSString stringWithFormat:@"%@.%s", prefix, #name]; }

/**
 定义静态属性实现，含分组、前缀
 
 @param name 属性名称
 @param group 属性分组
 @param prefix 属性前缀
 */
#define FWDefStaticProperty3( name, group, prefix ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return [NSString stringWithFormat:@"%@.%@.%s", group, prefix, #name]; }

/**
 定义静态NSInteger属性
 
 @param name 属性名称
 */
#define FWStaticInteger( name ) \
    @property (class, nonatomic, readonly) NSInteger name; \
    @property (nonatomic, readonly) NSInteger name;

/**
 定义静态NSInteger属性实现
 
 @param name 属性名称
 @param value 属性值
 */
#define FWDefStaticInteger( name, value ) \
    @dynamic name; \
    - (NSInteger)name { return [[self class] name]; } \
    + (NSInteger)name { return value; }

/**
 定义静态NSNumber属性
 
 @param name 属性名称
 */
#define FWStaticNumber( name ) \
    @property (class, nonatomic, readonly) NSNumber * name; \
    @property (nonatomic, readonly) NSNumber * name;

/**
 定义静态NSNumber属性实现
 
 @param name 属性名称
 @param value 属性值
 */
#define FWDefStaticNumber( name, value ) \
    @dynamic name; \
    - (NSNumber *)name { return [[self class] name]; } \
    + (NSNumber *)name { return @(value); }

/**
 定义静态字符串属性
 
 @param name 属性名称
 */
#define FWStaticString( name ) \
    @property (class, nonatomic, readonly) NSString * name; \
    @property (nonatomic, readonly) NSString * name;

/**
 定义静态字符串属性实现
 
 @param name 属性名称
 @param value 属性值
 */
#define FWDefStaticString( name, value ) \
    @dynamic name; \
    - (NSString *)name { return [[self class] name]; } \
    + (NSString *)name { return value; }

#endif /* FWMacro_h */
