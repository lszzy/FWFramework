//
//  TestVersionViewController.m
//  Example
//
//  Created by wuyong on 2019/4/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestVersionViewController.h"

@interface TestVersionViewController ()

@end

@implementation TestVersionViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 数据更新
    FWWeakifySelf();
    [[FWVersionManager sharedInstance] checkDataVersion:@"1.2.1" migrator:^{
        FWStrongifySelf();
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fwShowAlertWithTitle:nil message:@"数据更新至1.2.1版本" cancel:@"确定" cancelBlock:nil];
        });
    }];
    [[FWVersionManager sharedInstance] checkDataVersion:@"1.0.0" migrator:^{
        FWStrongifySelf();
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fwShowAlertWithTitle:nil message:@"数据更新至1.0.0版本" cancel:@"确定" cancelBlock:nil];
        });
    }];
    [[FWVersionManager sharedInstance] migrateData:^{
        FWStrongifySelf();
        [self fwShowAlertWithTitle:nil message:@"数据更新完毕" cancel:@"确定" cancelBlock:nil];
    }];
    
    // 版本更新
    [FWVersionManager sharedInstance].appId = @"1439986536";
    [[FWVersionManager sharedInstance] checkVersion:0 completion:^() {
        FWStrongifySelf();
        NSLog(@"version status: %@", @([FWVersionManager sharedInstance].status));
        
        if ([FWVersionManager sharedInstance].status == FWVersionStatusAudit) {
            [self fwShowAlertWithTitle:nil message:@"当前版本正在审核中" cancel:@"确定" actions:nil actionBlock:nil cancelBlock:nil priority:FWAlertPriorityHigh];
        } else if ([FWVersionManager sharedInstance].status == FWVersionStatusUpdate) {
            BOOL isForce = NO;
            if (isForce) {
                // 强制更新
                NSString *message = [NSString stringWithFormat:@"%@的新版本可用。请立即更新到%@版本。", @"EASI", [FWVersionManager sharedInstance].latestVersion];
                [self fwShowAlertWithTitle:nil message:message cancel:@"更新" actions:nil actionBlock:nil cancelBlock:^{
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/app/id%@", [FWVersionManager sharedInstance].appId]];
                    [UIApplication fwOpenURL:url completionHandler:^(BOOL success) {
                        if (success) {
                            exit(EXIT_SUCCESS);
                        }
                    }];
                } priority:FWAlertPrioritySuper];
            } else {
                // 非强制更新
                NSString *message = [NSString stringWithFormat:@"%@的新版本可用。请立即更新到%@版本。", @"EASI", [FWVersionManager sharedInstance].latestVersion];
                [self fwShowConfirmWithTitle:nil message:message cancel:@"取消" confirm:@"更新" confirmBlock:^{
                    [[FWVersionManager sharedInstance] openAppStore];
                } cancelBlock:nil priority:FWAlertPriorityHigh];
            }
        }
    }];
}

@end
