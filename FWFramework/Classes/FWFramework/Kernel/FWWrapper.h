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
#define FWWrapperCompatible(baseClass, objectWrapper, objectParent, classWrapper, classParent) \
    @interface objectWrapper : objectParent \
    @property (nonatomic, strong, readonly) baseClass *base; \
    @end \
    @interface baseClass (objectWrapper) \
    @property (nonatomic, strong, readonly) objectWrapper *fw; \
    @end \
    @interface classWrapper : classParent \
    @end \
    @interface baseClass (classWrapper) \
    @property (class, nonatomic, strong, readonly) classWrapper *fw; \
    @end

/// 快速实现包装器宏
#define FWDefWrapper(baseClass, objectWrapper, classWrapper) \
    @implementation objectWrapper \
    @dynamic base; \
    @end \
    @implementation baseClass (objectWrapper) \
    - (objectWrapper *)fw { \
        return [[objectWrapper alloc] init:self]; \
    } \
    @end \
    @implementation classWrapper \
    @end \
    @implementation baseClass (classWrapper) \
    + (classWrapper *)fw { \
        return [[classWrapper alloc] init:self]; \
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

#pragma mark - FWWrapperCompatible

FWWrapperCompatible(NSString, FWStringWrapper, FWObjectWrapper, FWStringClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSData, FWDataWrapper, FWObjectWrapper, FWDataClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSURL, FWURLWrapper, FWObjectWrapper, FWURLClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSBundle, FWBundleWrapper, FWObjectWrapper, FWBundleClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIApplication, FWApplicationWrapper, FWObjectWrapper, FWApplicationClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIDevice, FWDeviceWrapper, FWObjectWrapper, FWDeviceClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIScreen, FWScreenWrapper, FWObjectWrapper, FWScreenClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIView, FWViewWrapper, FWObjectWrapper, FWViewClassWrapper, FWClassWrapper);
FWWrapperCompatible(UINavigationBar, FWNavigationBarWrapper, FWViewWrapper, FWNavigationBarClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UITabBar, FWTabBarWrapper, FWViewWrapper, FWTabBarClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UIToolbar, FWToolbarWrapper, FWViewWrapper, FWToolbarClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UIWindow, FWWindowWrapper, FWViewWrapper, FWWindowClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UIViewController, FWViewControllerWrapper, FWObjectWrapper, FWViewControllerClassWrapper, FWClassWrapper);
FWWrapperCompatible(UINavigationController, FWNavigationControllerWrapper, FWViewControllerWrapper, FWNavigationControllerClassWrapper, FWViewControllerClassWrapper);

NS_ASSUME_NONNULL_END
