//
//  TestSkeletonViewController.m
//  Example
//
//  Created by wuyong on 2020/7/29.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestSkeletonViewController.h"

@interface TestSkeletonViewController ()

@property (nonatomic, strong) UIView *testView;

@end

@implementation TestSkeletonViewController

- (void)renderView
{
    UIView *testView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 200, 200)];
    _testView = testView;
    testView.backgroundColor = [UIColor redColor];
    [self.view addSubview:testView];
}

- (void)renderData
{
    [self.testView.layer fwStartSkeletonAnimation:[FWSkeletonAnimationShimmer new]];
}

@end
