//
//  TestNavigationViewController.m
//  Example
//
//  Created by wuyong on 2019/1/15.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestNavigationViewController.h"

@interface TestNavigationViewController ()

@property (nonatomic, assign) BOOL isPush;

@end

@implementation TestNavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FWWeakifySelf();
    [self fwSetRightBarItem:@"Push" block:^(id sender) {
        FWStrongifySelf();
        TestNavigationViewController *viewController = [TestNavigationViewController new];
        viewController.isPush = YES;
        [self.navigationController pushViewController:viewController animated:YES];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.isPush) {
        [self.navigationController fwAddFullscreenPopGesture];
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController.navigationBar fwResetBackground];
    } else {
        [self.navigationController setNavigationBarHidden:[[@[@0, @1] fwRandomObject] boolValue] animated:animated];
        [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwRandomColor]];
    }
}

- (void)renderView
{
    // 允许同时识别手势处理
    FWWeakifySelf();
    self.scrollView.fwShouldRecognizeSimultaneously = ^BOOL(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer) {
        FWStrongifySelf();
        if (self.scrollView.contentOffset.x <= 0) {
            if ([UINavigationController fwIsFullscreenPopGestureRecognizer:otherGestureRecognizer]) {
                return YES;
            }
        }
        return NO;
    };
    
    // 添加内容
    UIImageView *imageView = [UIImageView fwAutoLayoutView];
    imageView.image = [UIImage imageNamed:@"public_picture"];
    [self.contentView addSubview:imageView]; {
        [imageView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
        [imageView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero];
        [imageView fwSetDimension:NSLayoutAttributeHeight toSize:FWScreenHeight];
    }
}

@end
