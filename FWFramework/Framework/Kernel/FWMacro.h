/*!
 @header     FWMacro.h
 @indexgroup FWFramework
 @brief      核心宏定义
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#ifndef FWMacro_h
#define FWMacro_h

#pragma mark - Meta

/*!
 @brief 参数字符串连接
 
 @param A 字符串A
 @param B 字符串B
 */
#define fw_macro_concat( A, B ) \
    fw_macro_concat_( A, B )
#define fw_macro_concat_( A, B ) \
    A##B

/*!
 @brief 参数转C字符串
 
 @param A 参数字符串
 */
#define fw_macro_cstring( A ) \
    fw_macro_cstring_( A )
#define fw_macro_cstring_( A ) \
    #A

/*!
 @brief 参数转OC字符串
 
 @param A 参数字符串
 */
#define fw_macro_string( A ) \
    fw_macro_string_(A)
#define fw_macro_string_( A ) \
    @(#A)

/*!
 @brief 截取第一个参数
 
 @param ... 参数列表
 */
#define fw_macro_first(...) \
    fw_macro_first_( __VA_ARGS__, 0 )
#define fw_macro_first_( A, ... ) \
    A

/*!
 @brief 截取第一个之后的其它参数
 
 @param ... 参数列表
 */
#define fw_macro_other(...) \
    fw_macro_other_( __VA_ARGS__, nil )
#define fw_macro_other_( A, ... ) \
    __VA_ARGS__

/*!
 @brief 计算参数个数
 
 @param ... 参数列表
 */
#define fw_macro_count(...) \
    fw_macro_at( 8, __VA_ARGS__, 8, 7, 6, 5, 4, 3, 2, 1 )

/*!
 @brief 计算指定参数个数
 
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

/*!
 @brief 根据参数拼接方法名称
 
 @param ... 参数列表
 */
#define fw_macro_method( ... ) \
    fw_macro_concat(fw_macro_join_, fw_macro_count(__VA_ARGS__))(____, __VA_ARGS__)

/*!
 @brief 参数按指定分隔符连接
 
 @param X 分隔符
 @param ... 参数列表
 */
#define fw_macro_join( X, ... ) \
    fw_macro_concat(fw_macro_join_, fw_macro_count(__VA_ARGS__))(X, __VA_ARGS__)
#define fw_macro_join_0( ... )
#define fw_macro_join_1( X, A ) \
    A
#define fw_macro_join_2( X, A, B ) \
    A##X##B
#define fw_macro_join_3( X, A, B, C ) \
    A##X##B##X##C
#define fw_macro_join_4( X, A, B, C, D ) \
    A##X##B##X##C##X##D
#define fw_macro_join_5( X, A, B, C, D, E ) \
    A##X##B##X##C##X##D##X##E
#define fw_macro_join_6( X, A, B, C, D, E, F ) \
    A##X##B##X##C##X##D##X##E##X##F
#define fw_macro_join_7( X, A, B, C, D, E, F, G ) \
    A##X##B##X##C##X##D##X##E##X##F##X##G
#define fw_macro_join_8( X, A, B, C, D, E, F, G, H ) \
    A##X##B##X##C##X##D##X##E##X##F##X##G##X##H

/*!
 @brief 参数按.分隔符连接
 
 @param ... 参数列表
 */
#define fw_macro_make( ... ) \
    fw_macro_concat(fw_macro_make_, fw_macro_count(__VA_ARGS__))(__VA_ARGS__)
#define fw_macro_make_0( ... )
#define fw_macro_make_1( A ) \
    A
#define fw_macro_make_2( A, B ) \
    A.B
#define fw_macro_make_3( A, B, C ) \
    A.B.C
#define fw_macro_make_4( A, B, C, D ) \
    A.B.C.D
#define fw_macro_make_5( A, B, C, D, E ) \
    A.B.C.D.E
#define fw_macro_make_6( A, B, C, D, E, F ) \
    A.B.C.D.E.F
#define fw_macro_make_7( A, B, C, D, E, F, G ) \
    A.B.C.D.E.F.G
#define fw_macro_make_8( A, B, C, D, E, F, G, H ) \
    A.B.C.D.E.F.G.H

/*!
 @brief 参数默认值设置，需传入##__VA_ARGS__
 @discussion 调用示例：fw_macro_default(default, ##__VA_ARGS__)。##__VA_ARGS__前面的##作用在于，当可变参数的个数为0时，把前面多余的","去掉，否则会编译出错
 
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

/*!
 @brief 指定位置参数默认值设置，从1开始计数，需传入##__VA_ARGS__
 @discussion 调用示例：fw_macro_default_at(1, default, ##__VA_ARGS__)
 
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

#pragma mark - Block

#ifndef weakify

/*!
 @brief 解决block循环引用，@weakify，和@strongify配对使用
 
 @param x 变量名，如self
 */
#define weakify( x ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    autoreleasepool{} __weak __typeof__(x) x##_weak_ = x; \
    _Pragma("clang diagnostic pop")

#endif /* weakify */

#ifndef strongify

/*!
 @brief 解决block循环引用，@strongify，和@weakify配对使用
 
 @param x 变量名，如self
 */
#define strongify( x ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    try{} @finally{} __typeof__(x) x = x##_weak_; \
    _Pragma("clang diagnostic pop")

#endif /* strongify */

/*!
 @brief 解决block循环引用，和FWStrongify配对使用
 
 @param x 变量名，如self
 */
#define FWWeakify( x ) \
    @_Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    autoreleasepool{} __weak __typeof__(x) x##_weak_ = x; \
    _Pragma("clang diagnostic pop")

/*!
 @brief 解决block循环引用，和FWWeakify配对使用
 
 @param x 变量名，如self
 */
#define FWStrongify( x ) \
    @_Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    try{} @finally{} __typeof__(x) x = x##_weak_; \
    _Pragma("clang diagnostic pop")

/*!
 @brief 解决self循环引用。等价于：typeof(self) __weak self_weak_ = self;
 */
#define FWWeakifySelf( ) \
    FWWeakify( self )

/*!
 @brief 解决self循环引用。等价于：typeof(self_weak_) __strong self = self_weak_;
 */
#define FWStrongifySelf( ) \
    FWStrongify( self )

#pragma mark - Foundation

#ifdef DEBUG

// 调试模式打开日志
#define NSLog(format, ...) \
    NSLog((@"(%@ #%d %s) " format), [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__)

#else

// 正式环境关闭日志
#define NSLog(...)

#endif

// 标记废弃方法或属性
#define	FWDeprecated( msg ) \
    __attribute__((deprecated(msg)))

// 标记未使用的变量
#define	FWUnused( x ) \
    { id __unused_var__ __attribute__((unused)) = (id)(x); }

// 标记未完成的功能
#define FWTodo( msg ) \
    _Pragma(fw_macro_cstring(message("✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖ TODO: " msg)))

// 声明dealloc方法，可不传参数，也可传code，或者{code}
#define FWDealloc( x ) \
    - (void)dealloc \
    { \
        [[NSNotificationCenter defaultCenter] removeObserver:self]; \
        NSLog(@"%@ did dealloc", NSStringFromClass(self.class)); \
        x \
    }

// 标记忽略调用方法警告开始
#define FWIgnoredBegin( ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
    _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"") \
    _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")

// 标记忽略警告结束
#define FWIgnoredEnd( ) \
    _Pragma("clang diagnostic pop")

#endif /* FWMacro_h */
