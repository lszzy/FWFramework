/**
 @header     FWWrapper.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWWrapper

/// 框架包装器
@interface FWWrapper<__covariant ObjectType> : NSObject

/// 原始对象，内部访问
@property (nonatomic, unsafe_unretained, readonly) ObjectType base;

/// 禁用属性，防止嵌套
@property (nonatomic, strong, readonly) FWWrapper *fw NS_UNAVAILABLE;

/// 快速创建包装器
+ (instancetype)wrapperWithBase:(ObjectType)base;

@end

#pragma mark - FWWrapperObject

/// 框架包装器对象协议
@protocol FWWrapperObject <NSObject>

/// 对象包装器
@property (nonatomic, strong, readonly) FWWrapper *fw;

@end

#pragma mark - FWWrapperClass

/// 框架包装器类协议
@protocol FWWrapperClass <NSObject>

/// 类包装器
@property (class, nonatomic, strong, readonly) FWWrapper<Class> *fw;

@end

NS_ASSUME_NONNULL_END
