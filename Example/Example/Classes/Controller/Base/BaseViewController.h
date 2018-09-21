/*!
 @header     BaseViewController.h
 @indexgroup Example
 @brief      BaseViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import <UIKit/UIKit.h>

/*!
 @brief BaseViewController
 */
@interface BaseViewController : UIViewController

#pragma mark - Protect

// 初始化内部视图，仅子类重写，外部不可见
- (void)setupView;

#pragma mark - Render

// 渲染初始化方法，init自动调用
- (void)renderInit;

// 渲染视图方法，loadView自动调用
- (void)renderView;

// 渲染模型方法，viewDidLoad自动调用
- (void)renderModel;

// 渲染数据模型，viewDidLoad自动调用
- (void)renderData;

@end
