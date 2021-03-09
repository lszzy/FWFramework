//
//  TestNavigationViewController.m
//  Example
//
//  Created by wuyong on 2019/1/15.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestNavigationViewController.h"

@interface TestNavigationViewController () <FWScrollViewController>

@property (nonatomic, assign) BOOL fullscreenPop;

@end

@implementation TestNavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FWWeakifySelf();
    [self fwSetRightBarItem:@"Push" block:^(id sender) {
        FWStrongifySelf();
        TestNavigationViewController *viewController = [TestNavigationViewController new];
        viewController.fullscreenPop = YES;
        [self.navigationController pushViewController:viewController animated:YES];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.fullscreenPop) {
        if (!self.fwTempObject) {
            self.fwTempObject = [UIColor fwRandomColor];
        }
        self.navigationController.navigationBar.fwBackgroundColor = self.fwTempObject;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.fullscreenPop) {
        self.navigationController.fwFullscreenPopGestureEnabled = YES;
    } else {
        self.navigationController.fwFullscreenPopGestureEnabled = NO;
    }
}

- (void)renderView
{
    // 允许同时识别手势处理
    if (self.fullscreenPop) {
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
    }
    
    // 添加内容
    UIImageView *imageView = [UIImageView fwAutoLayoutView];
    imageView.image = [TestBundle imageNamed:@"public_picture"];
    [self.contentView addSubview:imageView]; {
        [imageView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
        [imageView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero];
        [imageView fwSetDimension:NSLayoutAttributeHeight toSize:FWScreenHeight];
    }
}

@end
