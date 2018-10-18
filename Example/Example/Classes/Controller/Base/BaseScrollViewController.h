//
//  BaseScrollViewController.h
//  EasiCustomer
//
//  Created by wuyong on 2018/9/21.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "BaseViewController.h"

/*!
 @brief 滚动视图控制器基类
 */
@interface BaseScrollViewController : BaseViewController

// 滚动视图，默认不显示滚动条
@property (nonatomic, readonly) UIScrollView *scrollView;

// 内容容器视图，自动撑开，子视图需要添加到此视图上
@property (nonatomic, readonly) UIView *contentView;

// 渲染滚动视图，loadView自动调用
- (UIScrollView *)renderScrollView;

// 渲染滚动视图布局，默认铺满，loadView自动调用
- (void)renderScrollLayout;

@end
