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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *deviceText = [NSString stringWithFormat:@"Device UUID: \n%@", [UIDevice fwDeviceUUID]];
    UILabel *textLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:deviceText];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.numberOfLines = 0;
    [self.fwView addSubview:textLabel];
    [textLabel fwAlignCenterToSuperview];
    [textLabel fwPinEdgesToSuperviewHorizontal];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 数据更新
    FWWeakifySelf();
    [[FWVersionManager sharedInstance] checkDataVersion:@"1.2.1" migrator:^{
        FWStrongifySelf();
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fwShowAlertWithTitle:nil message:@"数据更新至1.2.1版本" cancel:nil cancelBlock:nil];
        });
    }];
    [[FWVersionManager sharedInstance] checkDataVersion:@"1.0.0" migrator:^{
        FWStrongifySelf();
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fwShowAlertWithTitle:nil message:@"数据更新至1.0.0版本" cancel:nil cancelBlock:nil];
        });
    }];
    [[FWVersionManager sharedInstance] migrateData:^{
        FWStrongifySelf();
        [self fwShowAlertWithTitle:nil message:@"数据更新完毕" cancel:nil cancelBlock:nil];
    }];
    
    // 版本更新
    [FWVersionManager sharedInstance].appId = @"1439986536";
    [FWVersionManager sharedInstance].countryCode = @"cn";
    [[FWVersionManager sharedInstance] checkVersion:0 completion:^() {
        FWStrongifySelf();
        NSLog(@"version status: %@", @([FWVersionManager sharedInstance].status));
        
        if ([FWVersionManager sharedInstance].status == FWVersionStatusAudit) {
            [self fwShowAlertWithTitle:nil message:@"当前版本正在审核中" cancel:nil actions:nil actionBlock:nil cancelBlock:nil priority:FWAlertPriorityHigh];
        } else if ([FWVersionManager sharedInstance].status == FWVersionStatusUpdate) {
            BOOL isForce = NO;
            if (isForce) {
                // 强制更新
                NSString *title = [NSString stringWithFormat:@"%@的新版本可用。请立即更新到%@版本。", @"EASI", [FWVersionManager sharedInstance].latestVersion];
                [self fwShowAlertWithTitle:title message:[FWVersionManager sharedInstance].releaseNotes cancel:@"更新" actions:nil actionBlock:nil cancelBlock:^{
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@", [FWVersionManager sharedInstance].appId]];
                    [UIApplication fwOpenURL:url completionHandler:^(BOOL success) {
                        if (success) {
                            exit(EXIT_SUCCESS);
                        }
                    }];
                } priority:FWAlertPrioritySuper];
            } else {
                // 非强制更新
                NSString *title = [NSString stringWithFormat:@"%@的新版本可用。请立即更新到%@版本。", @"EASI", [FWVersionManager sharedInstance].latestVersion];
                [self fwShowConfirmWithTitle:title message:[FWVersionManager sharedInstance].releaseNotes cancel:@"取消" confirm:@"更新" confirmBlock:^{
                    [[FWVersionManager sharedInstance] openAppStore];
                } cancelBlock:nil priority:FWAlertPriorityHigh];
            }
        }
    }];
}

@end
