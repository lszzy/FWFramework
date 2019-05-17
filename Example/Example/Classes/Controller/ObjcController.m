//
//  ViewController.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "ObjcController.h"

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
    // swiftButton.hidden = YES;
    swiftButton.hidden = YES;
    [swiftButton setTitle:@"SwiftController" forState:UIControlStateNormal];
    [swiftButton addTarget:self action:@selector(onSwift) forControlEvents:UIControlEventTouchUpInside];
    swiftButton.frame = CGRectMake(self.view.frame.size.width / 2 - 75, 20, 150, 30);
    [self.view addSubview:swiftButton];
    [self.view fwAddTapGestureWithTarget:self action:@selector(onClose)];
}

#pragma mark - Action

- (void)onSwift {
    // SwiftController *viewController = [[SwiftController alloc] init];
    // [self.navigationController pushViewController:viewController animated:YES];
}

- (void)onClose {
    [self fwCloseViewControllerAnimated:YES];
}

@end
