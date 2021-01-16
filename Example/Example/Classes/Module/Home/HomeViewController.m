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

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // FIXME: hotfix
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // TODO: feature
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton = loginButton;
    [loginButton addTarget:self action:@selector(onLogin) forControlEvents:UIControlEventTouchUpInside];
    loginButton.frame = CGRectMake(0, 20, FWScreenWidth, 30);
    [self.view addSubview:loginButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self renderData];
}

- (void)renderData {
    self.navigationItem.title = FWLocalizedString(@"homeTitle");
    if ([Mediator.userModule isLogin]) {
        [self.loginButton setTitle:FWLocalizedString(@"backTitle") forState:UIControlStateNormal];
    } else {
        [self.loginButton setTitle:FWLocalizedString(@"welcomeTitle") forState:UIControlStateNormal];
    }
}

#pragma mark - Action

- (void)onLogin {
    if ([Mediator.userModule isLogin]) return;
    
    FWWeakifySelf();
    [Mediator.userModule login:^{
        FWStrongifySelf();
        [self renderData];
    }];
}

@end
