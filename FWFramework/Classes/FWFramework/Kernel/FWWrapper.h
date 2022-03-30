/**
 @header     FWWrapper.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWObjectWrapper

/// 框架包装器
@interface FWObjectWrapper<__covariant ObjectType> : NSObject

/// 原始对象
@property (nonatomic, unsafe_unretained, readonly) ObjectType base;

/// 禁用属性
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
@property (nonatomic, strong, readonly) FWObjectWrapper *fw;

@end

#pragma mark - FWClassWrapper

/// 框架类包装器
@interface FWClassWrapper : NSObject

/// 原始类
@property (nonatomic, unsafe_unretained, readonly) Class base;

/// 禁用属性
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

#pragma mark - FWObjectWrapper

@interface FWStringWrapper : FWObjectWrapper<NSString *>

@end

@interface NSString (FWStringWrapper)

@property (nonatomic, strong, readonly) FWStringWrapper *fw;

@end

@interface FWDataWrapper : FWObjectWrapper<NSData *>

@end

@interface NSData (FWDataWrapper)

@property (nonatomic, strong, readonly) FWDataWrapper *fw;

@end

@interface FWURLWrapper : FWObjectWrapper<NSURL *>

@end

@interface NSURL (FWURLWrapper)

@property (nonatomic, strong, readonly) FWURLWrapper *fw;

@end

@interface FWBundleWrapper : FWObjectWrapper<NSBundle *>

@end

@interface NSBundle (FWBundleWrapper)

@property (nonatomic, strong, readonly) FWBundleWrapper *fw;

@end

@interface FWViewWrapper<__covariant ObjectType: UIView *> : FWObjectWrapper<ObjectType>

@property (nonatomic, unsafe_unretained, readonly) ObjectType base;

@end

@interface UIView (FWViewWrapper)

@property (nonatomic, strong, readonly) FWViewWrapper *fw;

@end

@interface FWWindowWrapper : FWViewWrapper<UIWindow *>

@end

@interface UIWindow (FWWindowWrapper)

@property (nonatomic, strong, readonly) FWWindowWrapper *fw;

@end

@interface FWViewControllerWrapper<__covariant ObjectType: UIViewController *> : FWObjectWrapper<ObjectType>

@property (nonatomic, unsafe_unretained, readonly) ObjectType base;

@end

@interface UIViewController (FWViewControllerWrapper)

@property (nonatomic, strong, readonly) FWViewControllerWrapper *fw;

@end

@interface FWNavigationControllerWrapper : FWViewControllerWrapper<UINavigationController *>

@end

@interface UINavigationController (FWNavigationControllerWrapper)

@property (nonatomic, strong, readonly) FWNavigationControllerWrapper *fw;

@end

#pragma mark - FWClassWrapper

@interface FWStringClassWrapper : FWClassWrapper

@end

@interface NSString (FWStringClassWrapper)

@property (class, nonatomic, strong, readonly) FWStringClassWrapper *fw;

@end

@interface FWDataClassWrapper : FWClassWrapper

@end

@interface NSData (FWDataClassWrapper)

@property (class, nonatomic, strong, readonly) FWDataClassWrapper *fw;

@end

@interface FWURLClassWrapper : FWClassWrapper

@end

@interface NSURL (FWURLClassWrapper)

@property (class, nonatomic, strong, readonly) FWURLClassWrapper *fw;

@end

@interface FWBundleClassWrapper : FWClassWrapper

@end

@interface NSBundle (FWBundleClassWrapper)

@property (class, nonatomic, strong, readonly) FWBundleClassWrapper *fw;

@end

@interface FWWindowClassWrapper : FWClassWrapper

@end

@interface UIWindow (FWWindowClassWrapper)

@property (class, nonatomic, strong, readonly) FWWindowClassWrapper *fw;

@end

NS_ASSUME_NONNULL_END
