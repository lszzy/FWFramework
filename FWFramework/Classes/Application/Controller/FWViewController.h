/*!
 @header     FWViewController.h
 @indexgroup FWFramework
 @brief      FWViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 视图控制器页面状态可扩展枚举
typedef NSInteger FWViewControllerState NS_TYPED_EXTENSIBLE_ENUM;
static const FWViewControllerState FWViewControllerStateReady   = 0;
static const FWViewControllerState FWViewControllerStateLoading = 1;
static const FWViewControllerState FWViewControllerStateSuccess = 2;
static const FWViewControllerState FWViewControllerStateFailure = 3;

/*!
 @brief 视图控制器挂钩协议，可覆写
 */
@protocol FWViewController <NSObject>

@optional

/// 渲染初始化方法，init自动调用，默认未实现
- (void)renderInit;

/// 渲染视图方法，loadView自动调用，默认未实现
- (void)renderView;

/// 渲染模型方法，viewDidLoad自动调用，默认未实现
- (void)renderModel;

/// 渲染数据模型，viewDidLoad自动调用，默认未实现
- (void)renderData;

/// 渲染页面状态，viewDidLoad自动调用，默认未实现。初始状态为ready，其它需手工触发
- (void)renderState:(FWViewControllerState)state withObject:(nullable id)object;

@end

/*!
 @brief 视图控制器拦截器
 */
@interface FWViewControllerIntercepter : NSObject

@property (nonatomic, assign, nullable) SEL initIntercepter;
@property (nonatomic, assign, nullable) SEL loadViewIntercepter;
@property (nonatomic, assign, nullable) SEL viewDidLoadIntercepter;

@property (nonatomic, copy, nullable) NSDictionary *forwardSelectors;

@end

/*!
 @brief 视图控制器管理器
 @discussion 框架默认未注册FWViewController协议拦截器，如需全局配置控制器，使用全局自定义block即可
 */
@interface FWViewControllerManager : NSObject

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWViewControllerManager *sharedInstance;

/// 默认全局控制器init句柄
@property (nonatomic, copy, nullable) void (^renderInit)(UIViewController *viewController);
/// 默认全局控制器loadView句柄
@property (nonatomic, copy, nullable) void (^renderLoadView)(UIViewController *viewController);
/// 默认全局控制器viewDidLoad句柄
@property (nonatomic, copy, nullable) void (^renderViewDidLoad)(UIViewController *viewController);

/// 注册协议拦截器，提供拦截和跳转方法
- (void)registerProtocol:(Protocol *)protocol withIntercepter:(FWViewControllerIntercepter *)intercepter;

/// 调用控制器拦截方法默认实现并返回(如tableView等)，由于实现机制无法通过super调用原始方法，提供此替代方案。如果未实现该协议或方法，返回nil
- (nullable id)performIntercepter:(SEL)intercepter withObject:(UIViewController *)object;

/// 调用控制器拦截方法默认实现并返回，可携带参数(如setWebRequest:等)，由于实现机制无法通过super调用原始方法，提供此替代方案。如果未实现该协议或方法，返回nil
- (nullable id)performIntercepter:(SEL)intercepter withObject:(UIViewController *)object parameter:(nullable id)parameter;

@end

NS_ASSUME_NONNULL_END
