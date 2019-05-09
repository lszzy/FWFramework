//
//  TestMenuViewController.m
//  Example
//
//  Created by wuyong on 2019/5/9.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestMenuViewController.h"

@interface TestMenuViewController ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@end

@implementation TestMenuViewController

- (void)renderInit
{
    [self fwSetBarExtendEdge:UIRectEdgeTop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FWWeakifySelf();
    [self fwSetLeftBarItem:@"Menu" block:^(id sender) {
        FWStrongifySelf();
        [self.panGesture fwDrawerViewTogglePosition];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar fwSetBackgroundClear];
}

- (void)renderView
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(-FWScreenWidth / 2.0, 0, FWScreenWidth / 2.0, self.view.fwHeight)];
    _contentView = contentView;
    contentView.backgroundColor = [UIColor brownColor];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 200, 100, 30)];
    topLabel.text = @"Menu 1";
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 250, 100, 30)];
    middleLabel.text = @"Menu 2";
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 300, 100, 30)];
    bottomLabel.text = @"Menu 3";
    [contentView addSubview:bottomLabel];
    UILabel *closeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 400, 100, 30)];
    closeLabel.text = @"Back";
    FWWeakifySelf();
    closeLabel.userInteractionEnabled = YES;
    [closeLabel fwAddTapGestureWithBlock:^(id sender) {
        FWStrongifySelf();
        [self fwCloseViewControllerAnimated:YES];
    }];
    [contentView addSubview:closeLabel];
    [self.view addSubview:contentView];
    
    self.panGesture = [[UIPanGestureRecognizer alloc] init];
    [self.panGesture fwDrawerView:contentView direction:UISwipeGestureRecognizerDirectionRight fromPosition:-FWScreenWidth / 2.0 toPosition:0 kickbackHeight:25 callback:nil];
    [contentView addGestureRecognizer:self.panGesture];
}

@end
