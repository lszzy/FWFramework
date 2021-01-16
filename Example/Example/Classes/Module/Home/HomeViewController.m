//
//  ViewController.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "HomeViewController.h"

#pragma mark - HomeViewController

@interface HomeViewController ()

@property (nonatomic, strong) UIButton *loginButton;

@end

@implementation HomeViewController

#pragma mark - Accessor

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    
    [self.view fwShowMessageWithText:[NSString stringWithFormat:@"切换到tab: %@", @(selectedIndex)]];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // FIXME: hotfix
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // TODO: feature
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton = loginButton;
    [loginButton addTarget:self action:@selector(onMediator) forControlEvents:UIControlEventTouchUpInside];
    loginButton.frame = CGRectMake(self.view.frame.size.width / 2 - 75, 20, 150, 30);
    [self.view addSubview:loginButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self renderData];
}

- (void)renderData {
    self.navigationItem.title = FWLocalizedString(@"homeTitle");
    if ([Mediator.userModule isLogin]) {
        [self.loginButton setTitle:FWLocalizedString(@"loginInvalid") forState:UIControlStateNormal];
    } else {
        [self.loginButton setTitle:FWLocalizedString(@"mediatorLogin") forState:UIControlStateNormal];
    }
}

#pragma mark - Action

- (void)onMediator {
    if ([Mediator.userModule isLogin]) {
        [self onInvalid];
    } else {
        [self onLogin];
    }
}

- (void)onLogin {
    FWWeakifySelf();
    [Mediator.userModule login:^{
        FWStrongifySelf();
        [self renderData];
    }];
}

- (void)onInvalid {
    FWWeakifySelf();
    [UIWindow.fwMainWindow.fwTopPresentedController fwShowConfirmWithTitle:FWLocalizedString(@"loginInvalid") message:nil cancel:FWLocalizedString(@"取消") confirm:FWLocalizedString(@"确定") confirmBlock:^{
        FWStrongifySelf();
        [UIWindow.fwMainWindow fwDismissViewControllers:^{
            FWStrongifySelf();
            [Mediator.userModule logout:^{
                FWStrongifySelf();
                [self renderData];
                [self onLogin];
            }];
        }];
    }];
}

@end
