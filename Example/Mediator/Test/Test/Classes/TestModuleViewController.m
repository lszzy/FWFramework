//
//  TestModuleViewController.m
//  Pods
//
//  Created by wuyong on 2021/1/2.
//

#import "TestModuleViewController.h"
#import <FWFramework/FWFramework.h>

@interface TestModuleViewController ()

@end

@implementation TestModuleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.title = @"TestModuleViewController";
    FWWeakifySelf();
    [self.view fwAddTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self fwCloseViewControllerAnimated:YES];
    }];
}

@end
