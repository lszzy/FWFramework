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

/*!
 @brief 视图控制器挂钩协议
 */
@protocol FWViewController <NSObject>

@optional

// 渲染初始化方法，init自动调用
- (void)renderInit;

// 渲染视图方法，loadView自动调用
- (void)renderView;

// 渲染模型方法，viewDidLoad自动调用
- (void)renderModel;

// 渲染数据模型，viewDidLoad自动调用
- (void)renderData;

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
 */
@interface FWViewControllerManager : NSObject

// 单例对象
+ (FWViewControllerManager *)sharedInstance;

// 注册协议拦截器，提供拦截和跳转方法
- (void)registerProtocol:(Protocol *)protocol withIntercepter:(FWViewControllerIntercepter *)intercepter;

@end

NS_ASSUME_NONNULL_END
