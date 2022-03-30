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

#pragma mark - FWStringWrapper

/// 框架NSString对象包装器
@interface FWStringWrapper : FWObjectWrapper<NSString *>

@end

/// 框架NSString类包装器
@interface FWStringClassWrapper : FWClassWrapper

@end

@interface NSString (FWStringWrapper)

/// 对象包装器
@property (nonatomic, strong, readonly) FWStringWrapper *fw;

/// 类包装器
@property (class, nonatomic, strong, readonly) FWStringClassWrapper *fw;

@end

#pragma mark - FWDataWrapper

/// 框架NSData对象包装器
@interface FWDataWrapper : FWObjectWrapper<NSData *>

@end

/// 框架NSData类包装器
@interface FWDataClassWrapper : FWClassWrapper

@end

@interface NSData (FWDataWrapper)

/// 对象包装器
@property (nonatomic, strong, readonly) FWDataWrapper *fw;

/// 类包装器
@property (class, nonatomic, strong, readonly) FWDataClassWrapper *fw;

@end

#pragma mark - FWURLWrapper

/// 框架NSURL对象包装器
@interface FWURLWrapper : FWObjectWrapper<NSURL *>

@end

/// 框架NSURL类包装器
@interface FWURLClassWrapper : FWClassWrapper

@end

@interface NSURL (FWURLWrapper)

/// 对象包装器
@property (nonatomic, strong, readonly) FWURLWrapper *fw;

/// 类包装器
@property (class, nonatomic, strong, readonly) FWURLClassWrapper *fw;

@end

#pragma mark - FWBundleWrapper

/// 框架NSBundle对象包装器
@interface FWBundleWrapper : FWObjectWrapper<NSBundle *>

@end

/// 框架NSBundle类包装器
@interface FWBundleClassWrapper : FWClassWrapper

@end

@interface NSBundle (FWBundleWrapper)

/// 对象包装器
@property (nonatomic, strong, readonly) FWBundleWrapper *fw;

/// 类包装器
@property (class, nonatomic, strong, readonly) FWBundleClassWrapper *fw;

@end

#pragma mark - FWViewWrapper

/// 框架视图对象包装器
@interface FWViewWrapper<__covariant ObjectType: UIView *> : FWObjectWrapper<ObjectType>

/// 原始对象
@property (nonatomic, unsafe_unretained, readonly) ObjectType base;

@end

@interface UIView (FWViewWrapper)

/// 对象包装器
@property (nonatomic, strong, readonly) FWViewWrapper *fw;

@end

#pragma mark - FWWindowWrapper

/// 框架窗口对象包装器
@interface FWWindowWrapper : FWViewWrapper<UIWindow *>

@end

/// 框架窗口类包装器
@interface FWWindowClassWrapper : FWClassWrapper

@end

@interface UIWindow (FWWindowWrapper)

/// 对象包装器
@property (nonatomic, strong, readonly) FWWindowWrapper *fw;

/// 类包装器
@property (class, nonatomic, strong, readonly) FWWindowClassWrapper *fw;

@end

#pragma mark - FWViewControllerWrapper

/// 框架视图控制器对象包装器
@interface FWViewControllerWrapper<__covariant ObjectType: UIViewController *> : FWObjectWrapper<ObjectType>

/// 原始对象
@property (nonatomic, unsafe_unretained, readonly) ObjectType base;

@end

@interface UIViewController (FWViewControllerWrapper)

/// 对象包装器
@property (nonatomic, strong, readonly) FWViewControllerWrapper *fw;

@end

#pragma mark - FWNavigationControllerWrapper

/// 框架导航控制器对象包装器
@interface FWNavigationControllerWrapper : FWViewControllerWrapper<UINavigationController *>

@end

@interface UINavigationController (FWNavigationControllerWrapper)

/// 对象包装器
@property (nonatomic, strong, readonly) FWNavigationControllerWrapper *fw;

@end

NS_ASSUME_NONNULL_END
