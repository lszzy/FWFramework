/**
 @header     FWWrapper.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/// 快速声明包装器宏
#define FWObjectWrapperCompatible(baseClass, wrapperClass, parentWrapper) \
    @interface wrapperClass : parentWrapper \
    @property (nonatomic, strong, readonly) baseClass *base; \
    @end \
    @interface baseClass (wrapperClass) \
    @property (nonatomic, strong, readonly) wrapperClass *fw; \
    @end

/// 快速实现包装器宏
#define FWDefObjectWrapper(baseClass, wrapperClass) \
    @implementation wrapperClass \
    @dynamic base; \
    @end \
    @implementation baseClass (wrapperClass) \
    - (wrapperClass *)fw { \
        return [[wrapperClass alloc] init:self]; \
    } \
    @end

/// 快速声明类包装器宏
#define FWClassWrapperCompatible(baseClass, wrapperClass, parentWrapper) \
    @interface wrapperClass : parentWrapper \
    @end \
    @interface baseClass (wrapperClass) \
    @property (class, nonatomic, strong, readonly) wrapperClass *fw; \
    @end

/// 快速实现类包装器宏
#define FWDefClassWrapper(baseClass, wrapperClass) \
    @implementation wrapperClass \
    @end \
    @implementation baseClass (wrapperClass) \
    + (wrapperClass *)fw { \
        return [[wrapperClass alloc] init:self]; \
    } \
    @end

#pragma mark - FWObjectWrapper

/// 框架包装器
///
/// 备注：因Swift无法扩展OC泛型，未使用OC泛型实现，子类需覆盖base属性声明
@interface FWObjectWrapper : NSObject

/// 原始对象
@property (nonatomic, strong, readonly) id base;

/// 禁用属性
@property (nonatomic, strong, readonly) FWObjectWrapper *fw NS_UNAVAILABLE;

/// 快速创建包装器
- (instancetype)init:(id)base;

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
- (instancetype)init:(Class)base;

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

#pragma mark - FWObjectWrapperCompatible

FWObjectWrapperCompatible(NSString, FWStringWrapper, FWObjectWrapper);
FWObjectWrapperCompatible(NSData, FWDataWrapper, FWObjectWrapper);
FWObjectWrapperCompatible(NSURL, FWURLWrapper, FWObjectWrapper);
FWObjectWrapperCompatible(NSBundle, FWBundleWrapper, FWObjectWrapper);
FWObjectWrapperCompatible(UIView, FWViewWrapper, FWObjectWrapper);
FWObjectWrapperCompatible(UINavigationBar, FWNavigationBarWrapper, FWViewWrapper);
FWObjectWrapperCompatible(UITabBar, FWTabBarWrapper, FWViewWrapper);
FWObjectWrapperCompatible(UIToolbar, FWToolbarWrapper, FWViewWrapper);
FWObjectWrapperCompatible(UIWindow, FWWindowWrapper, FWViewWrapper);
FWObjectWrapperCompatible(UIViewController, FWViewControllerWrapper, FWObjectWrapper);
FWObjectWrapperCompatible(UINavigationController, FWNavigationControllerWrapper, FWViewControllerWrapper);

#pragma mark - FWClassWrapperCompatible

FWClassWrapperCompatible(NSString, FWStringClassWrapper, FWClassWrapper);
FWClassWrapperCompatible(NSData, FWDataClassWrapper, FWClassWrapper);
FWClassWrapperCompatible(NSURL, FWURLClassWrapper, FWClassWrapper);
FWClassWrapperCompatible(NSBundle, FWBundleClassWrapper, FWClassWrapper);
FWClassWrapperCompatible(UIApplication, FWApplicationClassWrapper, FWClassWrapper);
FWClassWrapperCompatible(UIDevice, FWDeviceClassWrapper, FWClassWrapper);
FWClassWrapperCompatible(UIScreen, FWScreenClassWrapper, FWClassWrapper);
FWClassWrapperCompatible(UIView, FWViewClassWrapper, FWClassWrapper);
FWClassWrapperCompatible(UIWindow, FWWindowClassWrapper, FWViewClassWrapper);

NS_ASSUME_NONNULL_END
