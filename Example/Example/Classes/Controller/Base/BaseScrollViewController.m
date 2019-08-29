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

- (void)loadView
{
    [super loadView];
    
    // 默认背景色
    self.scrollView.backgroundColor = [UIColor appColorBg];
}

@end
