//
//  BaseScrollViewController.m
//  EasiCustomer
//
//  Created by wuyong on 2018/9/21.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "BaseScrollViewController.h"

@interface BaseScrollViewController ()

@end

@implementation BaseScrollViewController

- (void)setupView
{
    // 创建滚动视图
    _scrollView = [self renderScrollView];
    [self.view addSubview:_scrollView];
    
    // 创建容器视图，占满滚动视图
    _contentView = [UIView fwAutoLayoutView];
    [_scrollView addSubview:_contentView];
    [_contentView fwPinEdgesToSuperview];
    
    // 渲染滚动视图布局
    [self renderScrollLayout];
    
    // 初始化视图frame
    [_scrollView setNeedsLayout];
    [_scrollView layoutIfNeeded];
}

- (UIScrollView *)renderScrollView
{
    UIScrollView *scrollView = [UIScrollView fwAutoLayoutView];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    // 默认背景色
    scrollView.backgroundColor = [UIColor appColorBg];
    // 禁用内边距适应
    [scrollView fwContentInsetNever];
    return scrollView;
}

- (void)renderScrollLayout
{
    [self.scrollView fwPinEdgesToSuperview];
}

@end
