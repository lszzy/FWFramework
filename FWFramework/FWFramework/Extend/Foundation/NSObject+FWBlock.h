/*!
 @header     NSObject+FWBlock.h
 @indexgroup FWFramework
 @brief      NSObject+FWBlock
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import <Foundation/Foundation.h>

#pragma mark - Block

#ifndef	weakify

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

#ifndef	strongify

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

/*!
 @brief 通用不带参数block
 */
typedef void (^FWBlockVoid)(void);

/*!
 @brief 通用id参数block
 
 @param param id参数
 */
typedef void (^FWBlockParam)(id param);

/*!
 @brief 通用bool参数block
 
 @param isTrue bool参数
 */
typedef void (^FWBlockBool)(BOOL isTrue);

/*!
 @brief 通用int参数block
 
 @param index int参数
 */
typedef void (^FWBlockInt)(int index);

/*!
 @brief NSObject+FWBlock
 */
@interface NSObject (FWBlock)

@end
