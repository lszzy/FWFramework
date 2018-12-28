/*!
 @header     FWViewController.h
 @indexgroup FWFramework
 @brief      FWViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import <UIKit/UIKit.h>

/*!
 @brief 视图控制器挂钩协议
 */
@protocol FWViewController <NSObject>

@optional

// 渲染初始化方法，init自动调用
- (void)fwRenderInit;

// 渲染视图方法，loadView自动调用
- (void)fwRenderView;

// 渲染模型方法，viewDidLoad自动调用
- (void)fwRenderModel;

// 渲染数据模型，viewDidLoad自动调用
- (void)fwRenderData;

@end

/*!
 @brief 视图控制器拦截器
 */
@interface FWViewControllerIntercepter : NSObject

@end
