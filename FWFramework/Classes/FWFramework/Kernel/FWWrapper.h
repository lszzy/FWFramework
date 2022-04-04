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
///
/// 备注：因Swift无法扩展OC泛型，未使用OC泛型实现，子类需覆盖base属性声明
@interface FWObjectWrapper : NSObject

/// 原始对象
@property (nonatomic, unsafe_unretained, readonly) id base;

/// 禁用属性
@property (nonatomic, strong, readonly) FWObjectWrapper *fw NS_UNAVAILABLE;

/// 快速创建包装器，自动缓存
+ (instancetype)wrapper:(id)base;

@end

/// 框架包装器协议
@protocol FWObjectWrapper <NSObject>

/// 对象包装器，有缓存
@property (nonatomic, strong, readonly) FWObjectWrapper *fw;

@end

/// NSObject实现包装器协议
@interface NSObject (FWObjectWrapper) <FWObjectWrapper>

/// 对象包装器，有缓存
@property (nonatomic, strong, readonly) FWObjectWrapper *fw;

@end

#pragma mark - FWClassWrapper

/// 框架类包装器
@interface FWClassWrapper : NSObject

/// 原始类
@property (nonatomic, unsafe_unretained, readonly) Class base;

/// 禁用属性
@property (nonatomic, strong, readonly) FWClassWrapper *fw NS_UNAVAILABLE;

/// 快速创建包装器，无缓存
+ (instancetype)wrapper:(Class)base;

@end

/// 框架类包装器协议
@protocol FWClassWrapper <NSObject>

/// 类包装器，无缓存
@property (class, nonatomic, strong, readonly) FWClassWrapper *fw;

@end

/// NSObject实现类包装器协议
@interface NSObject (FWClassWrapper) <FWClassWrapper>

/// 类包装器，无缓存
@property (class, nonatomic, strong, readonly) FWClassWrapper *fw;

@end

#pragma mark - FWObjectWrapper

@interface FWStringWrapper : FWObjectWrapper

@property (nonatomic, unsafe_unretained, readonly) NSString *base;

@end

@interface NSString (FWStringWrapper)

@property (nonatomic, strong, readonly) FWStringWrapper *fw;

@end

@interface FWDataWrapper : FWObjectWrapper

@property (nonatomic, unsafe_unretained, readonly) NSData *base;

@end

@interface NSData (FWDataWrapper)

@property (nonatomic, strong, readonly) FWDataWrapper *fw;

@end

@interface FWURLWrapper : FWObjectWrapper

@property (nonatomic, unsafe_unretained, readonly) NSURL *base;

@end

@interface NSURL (FWURLWrapper)

@property (nonatomic, strong, readonly) FWURLWrapper *fw;

@end

@interface FWBundleWrapper : FWObjectWrapper

@property (nonatomic, unsafe_unretained, readonly) NSBundle *base;

@end

@interface NSBundle (FWBundleWrapper)

@property (nonatomic, strong, readonly) FWBundleWrapper *fw;

@end

@interface FWViewWrapper : FWObjectWrapper

@property (nonatomic, unsafe_unretained, readonly) UIView *base;

@end

@interface UIView (FWViewWrapper)

@property (nonatomic, strong, readonly) FWViewWrapper *fw;

@end

@interface FWNavigationBarWrapper : FWViewWrapper

@property (nonatomic, unsafe_unretained, readonly) UINavigationBar *base;

@end

@interface UINavigationBar (FWNavigationBarWrapper)

@property (nonatomic, strong, readonly) FWNavigationBarWrapper *fw;

@end

@interface FWTabBarWrapper : FWViewWrapper

@property (nonatomic, unsafe_unretained, readonly) UITabBar *base;

@end

@interface UITabBar (FWTabBarWrapper)

@property (nonatomic, strong, readonly) FWTabBarWrapper *fw;

@end

@interface FWToolbarWrapper : FWViewWrapper

@property (nonatomic, unsafe_unretained, readonly) UIToolbar *base;

@end

@interface UIToolbar (FWToolbarWrapper)

@property (nonatomic, strong, readonly) FWToolbarWrapper *fw;

@end

@interface FWWindowWrapper : FWViewWrapper

@property (nonatomic, unsafe_unretained, readonly) UIWindow *base;

@end

@interface UIWindow (FWWindowWrapper)

@property (nonatomic, strong, readonly) FWWindowWrapper *fw;

@end

@interface FWViewControllerWrapper : FWObjectWrapper

@property (nonatomic, unsafe_unretained, readonly) UIViewController *base;

@end

@interface UIViewController (FWViewControllerWrapper)

@property (nonatomic, strong, readonly) FWViewControllerWrapper *fw;

@end

@interface FWNavigationControllerWrapper : FWViewControllerWrapper

@property (nonatomic, unsafe_unretained, readonly) UINavigationController *base;

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

@interface FWApplicationClassWrapper : FWClassWrapper

@end

@interface UIApplication (FWApplicationClassWrapper)

@property (class, nonatomic, strong, readonly) FWApplicationClassWrapper *fw;

@end

@interface FWDeviceClassWrapper : FWClassWrapper

@end

@interface UIDevice (FWDeviceClassWrapper)

@property (class, nonatomic, strong, readonly) FWDeviceClassWrapper *fw;

@end

@interface FWScreenClassWrapper : FWClassWrapper

@end

@interface UIScreen (FWScreenClassWrapper)

@property (class, nonatomic, strong, readonly) FWScreenClassWrapper *fw;

@end

@interface FWViewClassWrapper : FWClassWrapper

@end

@interface UIView (FWViewClassWrapper)

@property (class, nonatomic, strong, readonly) FWViewClassWrapper *fw;

@end

@interface FWWindowClassWrapper : FWViewClassWrapper

@end

@interface UIWindow (FWWindowClassWrapper)

@property (class, nonatomic, strong, readonly) FWWindowClassWrapper *fw;

@end

NS_ASSUME_NONNULL_END
