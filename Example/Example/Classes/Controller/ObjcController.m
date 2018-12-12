//
//  ViewController.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "ObjcController.h"
#import "SDCycleScrollView.h"

#pragma mark - ObjcController

@interface ObjcController ()

@end

@implementation ObjcController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // FIXME: hotfix
    self.navigationItem.title = NSStringFromClass(self.class);
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    
    // TODO: feature
    UIButton *swiftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [swiftButton setTitle:@"SwiftController" forState:UIControlStateNormal];
    [swiftButton addTarget:self action:@selector(onSwift) forControlEvents:UIControlEventTouchUpInside];
    swiftButton.frame = CGRectMake(self.view.frame.size.width / 2 - 75, 20, 150, 30);
    [self.view addSubview:swiftButton];
    [self.view fwAddTapGestureWithTarget:self action:@selector(onClose)];
    
    SDCycleScrollView *cycleView = [SDCycleScrollView new];
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 6;
    cycleView.placeholderImage = [UIImage imageNamed:@"public_picture"];
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.pageControlDotSize = CGSizeMake(6, 6);
    cycleView.pageDotColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    cycleView.currentPageDotColor = [UIColor whiteColor];
    [self.view addSubview:cycleView];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeTop];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fwSetDimension:NSLayoutAttributeHeight toSize:135];
    
    NSMutableArray *imageUrls = [NSMutableArray array];
    [imageUrls addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls addObject:@"ss.png"];
    [imageUrls addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    cycleView.imageURLStringsGroup = [imageUrls copy];
}

#pragma mark - Action

- (void)onSwift {
    SwiftController *viewController = [[SwiftController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)onClose {
    [self fwCloseViewControllerAnimated:YES];
}

@end
