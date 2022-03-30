/**
 @header     FWWrapper.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWObjectWrapper

/// 框架包装器
@interface FWObjectWrapper<__covariant ObjectType> : NSObject

/// 原始对象，内部访问
@property (nonatomic, unsafe_unretained, readonly) ObjectType base;

/// 禁用属性，防止嵌套
@property (nonatomic, strong, readonly) FWObjectWrapper *fw NS_UNAVAILABLE;

/// 快速创建包装器
+ (instancetype)wrapper:(ObjectType)base;

@end

/// 框架包装器协议
@protocol FWObjectWrapper <NSObject>

/// 对象包装器
@property (nonatomic, strong, readonly) FWObjectWrapper *fw;

@end

/// NSObject实现包装器协议
@interface NSObject (FWObjectWrapper) <FWObjectWrapper>

/// 对象包装器
@property (nonatomic, strong, readonly) FWObjectWrapper<NSObject *> *fw;

@end

#pragma mark - FWClassWrapper

/// 框架类包装器
@interface FWClassWrapper : NSObject

/// 原始类，内部访问
@property (nonatomic, unsafe_unretained, readonly) Class base;

/// 禁用属性，防止嵌套
@property (nonatomic, strong, readonly) FWClassWrapper *fw NS_UNAVAILABLE;

/// 快速创建包装器
+ (instancetype)wrapper:(Class)base;

@end

/// 框架类包装器协议
@protocol FWClassWrapper <NSObject>

/// 类包装器
@property (class, nonatomic, strong, readonly) FWClassWrapper *fw;

@end

/// NSObject实现类包装器协议
@interface NSObject (FWClassWrapper) <FWClassWrapper>

/// 类包装器
@property (class, nonatomic, strong, readonly) FWClassWrapper *fw;

@end

#pragma mark - FWStringWrapper

/// 框架NSString对象包装器
@interface FWStringWrapper : FWObjectWrapper<NSString *>

@end

/// NSString实现包装器对象协议
@interface NSString (FWStringWrapper) <FWObjectWrapper>

/// 对象包装器
@property (nonatomic, strong, readonly) FWStringWrapper *fw;

@end

#pragma mark - FWViewWrapper

/// 框架视图对象包装器
@interface FWViewWrapper : FWObjectWrapper<UIView *>

@end

/// 视图实现包装器对象协议
@interface UIView (FWViewWrapper) <FWObjectWrapper>

/// 对象包装器
@property (nonatomic, strong, readonly) FWViewWrapper *fw;

@end

#pragma mark - FWViewControllerWrapper

/// 框架视图控制器对象包装器
@interface FWViewControllerWrapper : FWObjectWrapper<UIViewController *>

@end

/// 视图控制器实现包装器对象协议
@interface UIViewController (FWViewControllerWrapper) <FWObjectWrapper>

/// 对象包装器
@property (nonatomic, strong, readonly) FWViewControllerWrapper *fw;

@end

NS_ASSUME_NONNULL_END
