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

/// 框架对象包装器
@interface FWWrapper<__covariant ObjectType> : NSObject

/// 原始对象，weak引用
@property (nullable, nonatomic, weak, readonly) ObjectType base;

/// 禁用属性，防止嵌套
@property (nonatomic, strong, readonly) FWWrapper *fw NS_UNAVAILABLE;

/// 快速创建包装器对象
+ (instancetype)wrapperWithBase:(ObjectType)base;

@end

/// 框架对象包装器关联协议
@protocol FWWrapperProtocol <NSObject>

/// 对象包装器属性
@property (nonatomic, strong, readonly) FWWrapper *fw;

@end

#pragma mark - FWClassWrapper

/// 框架类包装器
@interface FWClassWrapper : NSObject

/// 原始类
@property (nonatomic, unsafe_unretained, readonly) Class base;

/// 禁用属性，防止嵌套
@property (nonatomic, strong, readonly) FWWrapper *fw NS_UNAVAILABLE;

/// 快速创建类包装器对象
+ (instancetype)wrapperWithBase:(Class)base;

@end

/// 框架类包装器关联协议
@protocol FWClassWrapperProtocol <NSObject>

/// 类包装器属性
@property (class, nonatomic, strong, readonly) FWClassWrapper *fw;

@end

NS_ASSUME_NONNULL_END