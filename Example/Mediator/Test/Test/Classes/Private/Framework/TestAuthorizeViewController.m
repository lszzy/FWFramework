//
//  TestAuthorizeViewController.m
//  Example
//
//  Created by wuyong on 2019/3/19.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestAuthorizeViewController.h"

@interface TestAuthorizeViewController () <FWTableViewController>

@end

@implementation TestAuthorizeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self fwSetRightBarItem:@"设置" block:^(id sender) {
        [UIApplication fwOpenAppSettings];
    }];
    
    // 手工修改设置返回页面自动刷新权限，释放时自动移除监听
    FWWeakifySelf();
    [self fwObserveNotification:UIApplicationDidBecomeActiveNotification block:^(NSNotification *notification) {
        FWStrongifySelf();
        
        [self.tableView reloadData];
    }];
}

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                         @[@"定位", @(FWAuthorizeTypeLocationWhenInUse)],
                                         @[@"后台定位", @(FWAuthorizeTypeLocationAlways)],
                                         @[@"麦克风", @(FWAuthorizeTypeMicrophone)],
                                         @[@"相册", @(FWAuthorizeTypePhotoLibrary)],
                                         @[@"照相机", @(FWAuthorizeTypeCamera)],
                                         @[@"联系人", @(FWAuthorizeTypeContacts)],
                                         @[@"日历", @(FWAuthorizeTypeCalendars)],
                                         @[@"提醒", @(FWAuthorizeTypeReminders)],
                                         @[@"音乐", @(FWAuthorizeTypeAppleMusic)],
                                         @[@"通知", @(FWAuthorizeTypeNotifications)],
                                         @[@"广告追踪", @(FWAuthorizeTypeTracking)],
                                         ]];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    FWAuthorizeType type = [[rowData objectAtIndex:1] integerValue];
    
    FWAuthorizeManager *manager = [FWAuthorizeManager managerWithType:type];
    FWAuthorizeStatus status = manager.authorizeStatus;
    NSString *typeText = [rowData objectAtIndex:0];
    BOOL canSelect = NO;
    if (status == FWAuthorizeStatusRestricted) {
        typeText = [typeText stringByAppendingString:@"受限制"];
    } else if (status == FWAuthorizeStatusAuthorized) {
        typeText = [typeText stringByAppendingString:@"已开启"];
    } else if (status == FWAuthorizeStatusDenied) {
        typeText = [typeText stringByAppendingString:@"已拒绝"];
    } else {
        typeText = [typeText stringByAppendingString:@"未授权"];
        canSelect = YES;
    }
    cell.textLabel.text = typeText;
    cell.accessoryType = canSelect ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    FWAuthorizeType type = [[rowData objectAtIndex:1] integerValue];
    
    FWAuthorizeManager *manager = [FWAuthorizeManager managerWithType:type];
    if (manager.authorizeStatus == FWAuthorizeStatusNotDetermined) {
        FWWeakifySelf();
        [manager authorize:^(FWAuthorizeStatus status) {
            FWStrongifySelf();
            
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }];
    }
}

@end
