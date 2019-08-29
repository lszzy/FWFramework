/*!
 @header     BaseViewController.m
 @indexgroup Example
 @brief      BaseViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "BaseViewController.h"

@implementation BaseViewController

- (void)loadView
{
    [super loadView];
    
    // 统一设置背景色
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 通用导航栏样式
    [self fwSetBackBarImage:[UIImage imageNamed:@"public_back"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 通用导航栏样式
    [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
    [self.navigationController.navigationBar fwSetLineHidden:YES];
}

- (void)dealloc
{
    // 自动移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 打印被释放日志，防止内存泄露
    NSLog(@"%@ did dealloc", NSStringFromClass(self.class));
}

@end
