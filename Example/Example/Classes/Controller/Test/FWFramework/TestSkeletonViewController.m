//
//  TestSkeletonViewController.m
//  Example
//
//  Created by wuyong on 2020/7/29.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestSkeletonViewController.h"

@interface TestSkeletonViewController () <FWSkeletonViewDelegate>

@property (nonatomic, strong) UIView *testView;
@property (nonatomic, strong) UIView *childView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation TestSkeletonViewController

- (void)renderView
{
    UIView *testView = [UIView new];
    _testView = testView;
    testView.backgroundColor = [UIColor redColor];
    [testView fwSetCornerRadius:5];
    [self.view addSubview:testView];
    testView.fwLayoutChain.leftWithInset(20).topWithInset(20).size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
    
    UIView *rightView = [UIView new];
    rightView.backgroundColor = [UIColor redColor];
    [rightView fwSetCornerRadius:5];
    [self.view addSubview:rightView];
    rightView.fwLayoutChain.rightWithInset(20).topWithInset(20).size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
    
    UIView *childView = [UIView new];
    _childView = childView;
    childView.backgroundColor = [UIColor blueColor];
    [rightView addSubview:childView];
    childView.fwLayoutChain.edgesWithInsets(UIEdgeInsetsMake(10, 10, 10, 10));
    
    UIImageView *imageView = [UIImageView new];
    _imageView = imageView;
    imageView.image = [UIImage fwImageWithAppIcon];
    [imageView fwSetCornerRadius:5];
    [self.view addSubview:imageView];
    imageView.fwLayoutChain.centerXToView(testView).topToBottomOfViewWithOffset(testView, 20).size(CGSizeMake(50, 50));
}

- (void)renderData
{
    [self fwShowSkeletonWithDelegate:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fwHideSkeleton];
    });
}

#pragma mark - FWSkeletonViewDelegate

- (void)skeletonViewLayout:(FWSkeletonView *)containerView
{
    [containerView copySubview:self.testView];
    [containerView copySubview:self.childView];
    [containerView copySubview:self.imageView block:^(FWSkeletonView *skeletonView) {
        skeletonView.image = [[UIImage imageNamed:@"tabbar_home"] fwImageWithTintColor:FWSkeletonConfig.sharedInstance.skeletonColor];
    }];
}

@end
