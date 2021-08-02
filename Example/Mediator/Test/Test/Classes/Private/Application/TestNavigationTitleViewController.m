//
//  TestNavigationTitleViewController.m
//  Example
//
//  Created by wuyong on 2020/2/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestNavigationTitleViewController.h"

@interface TestNavigationTitleViewController () <FWTableViewController, FWNavigationTitleViewDelegate, FWPopupMenuDelegate>

@property(nullable, nonatomic, strong) FWNavigationTitleView *titleView;
@property(nonatomic, assign) UIControlContentHorizontalAlignment horizontalAlignment;

@end

@implementation TestNavigationTitleViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStylePlain;
}

- (void)renderView
{
    self.titleView = [[FWNavigationTitleView alloc] init];
    self.titleView.showsLoadingView = YES;
    self.titleView.title = self.title;
    self.fwNavigationItem.titleView = self.titleView;
    self.horizontalAlignment = self.titleView.contentHorizontalAlignment;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 300)];
    
    self.fwLeftBarItem = [[FWNavigationButton alloc] initWithImage:[CoreBundle imageNamed:@"back"]];
    [self fwAddRightBarItem:[[FWNavigationButton alloc] initWithImage:[CoreBundle imageNamed:@"close"]] block:^(id  _Nonnull sender) {
        [FWRouter closeViewControllerAnimated:YES];
    }];
    [self fwAddRightBarItem:[[FWNavigationButton alloc] initWithImage:[CoreBundle imageNamed:@"back"]] block:^(id  _Nonnull sender) {
        [FWRouter closeViewControllerAnimated:YES];
    }];
    
    FWNavigationView *navigationView = self.fwNavigationView;
    navigationView.bottomView.backgroundColor = UIColor.brownColor;
    navigationView.bottomHidden = YES;
    UILabel *titleLabel = [UILabel fwLabelWithFont:FWFontBold(18) textColor:UIColor.whiteColor text:@"FWNavigationView"];
    [navigationView.bottomView addSubview:titleLabel];
    titleLabel.fwLayoutChain.leftWithInset(15).bottomWithInset(15);
    
    FWNavigationContentView *contentView = navigationView.contentView;
    FWNavigationButton *leftButton = [[FWNavigationButton alloc] initWithImage:[CoreBundle imageNamed:@"back"]];
    [leftButton fwAddTouchBlock:^(id  _Nonnull sender) {
        [FWRouter closeViewControllerAnimated:YES];
    }];
    contentView.leftButton = leftButton;
    FWNavigationButton *rightMoreButton = [[FWNavigationButton alloc] initWithImage:[CoreBundle imageNamed:@"back"]];
    [rightMoreButton fwAddTouchBlock:^(id  _Nonnull sender) {
        [FWRouter closeViewControllerAnimated:YES];
    }];
    contentView.rightMoreButton = rightMoreButton;
    FWNavigationButton *rightButton = [[FWNavigationButton alloc] initWithImage:[CoreBundle imageNamed:@"close"]];
    [rightButton fwAddTouchBlock:^(id  _Nonnull sender) {
        [FWRouter closeViewControllerAnimated:YES];
    }];
    contentView.rightButton = rightButton;
}

- (void)renderData
{
    self.tableView.backgroundColor = Theme.tableColor;
    [self.tableData addObjectsFromArray:@[
        @"显示左边的loading",
        @"显示右边的accessoryView",
        @"显示副标题",
        @"切换为上下两行显示",
        @"水平方向的对齐方式",
        @"模拟标题的loading状态切换",
        @"标题点击效果",
    ]];
    if (self.fwNavigationViewEnabled) {
        [self.tableData addObjectsFromArray:@[
            @"导航栏顶部视图切换",
            @"导航栏自定义视图切换",
            @"导航栏底部视图切换",
            @"导航栏绑定控制器切换",
            @"导航栏固定高度切换",
            @"导航栏滚动效果切换",
        ]];
    }
}

- (void)dealloc
{
    self.titleView.delegate = nil;
}

- (UIImage *)accessoryImage
{
    UIBezierPath *bezierPath = [UIBezierPath fwShapeTriangle:CGRectMake(0, 0, 8, 5) direction:UISwipeGestureRecognizerDirectionDown];
    UIImage *accessoryImage = [[bezierPath fwShapeImage:CGSizeMake(8, 5) strokeWidth:0 strokeColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1] fillColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    return accessoryImage;
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.titleView.userInteractionEnabled = NO;
    self.titleView.delegate = nil;
    
    switch (indexPath.row) {
        case 0:
            self.titleView.loadingViewHidden = !self.titleView.loadingViewHidden;
            break;
        case 1: {
            self.titleView.accessoryImage = self.titleView.accessoryImage ? nil : [self accessoryImage];
            break;
        }
        case 2:
            self.titleView.subtitle = self.titleView.subtitle ? nil : @"(副标题)";
            break;
        case 3:
            self.titleView.style = self.titleView.style == FWNavigationTitleViewStyleHorizontal ? FWNavigationTitleViewStyleVertical : FWNavigationTitleViewStyleHorizontal;
            self.titleView.subtitle = self.titleView.style == FWNavigationTitleViewStyleVertical ? @"(副标题)" : self.titleView.subtitle;
            break;
        case 4:
        {
            FWWeakifySelf();
            [self fwShowSheetWithTitle:@"水平对齐方式" message:nil cancel:@"取消" actions:@[@"左对齐", @"居中对齐", @"右对齐"] actionBlock:^(NSInteger index) {
                FWStrongifySelf();
                if (index == 0) {
                    self.titleView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                    self.horizontalAlignment = self.titleView.contentHorizontalAlignment;
                    [self.tableView reloadData];
                } else if (index == 1) {
                    self.titleView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                    self.horizontalAlignment = self.titleView.contentHorizontalAlignment;
                    [self.tableView reloadData];
                } else {
                    self.titleView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                    self.horizontalAlignment = self.titleView.contentHorizontalAlignment;
                    [self.tableView reloadData];
                }
            }];
        }
            break;
        case 5:
        {
            self.titleView.loadingViewHidden = NO;
            self.titleView.showsLoadingPlaceholder = NO;
            self.titleView.title = @"加载中...";
            self.titleView.subtitle = nil;
            self.titleView.style = FWNavigationTitleViewStyleHorizontal;
            self.titleView.accessoryImage = nil;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.titleView.showsLoadingPlaceholder = YES;
                self.titleView.loadingViewHidden = YES;
                self.titleView.title = @"主标题";
            });
        }
            break;
        case 6:
        {
            self.titleView.userInteractionEnabled = YES;
            self.titleView.title = @"点我展开分类";
            self.titleView.accessoryImage = [self accessoryImage];
            self.titleView.delegate = self;
        }
            break;
        case 7:
        {
            if (self.fwNavigationView.topView.backgroundColor != UIColor.greenColor) {
                self.fwNavigationView.topView.backgroundColor = UIColor.greenColor;
            } else {
                self.fwNavigationView.topHidden = !self.fwNavigationView.topHidden;
            }
        }
            break;
        case 8:
        {
            if (self.fwNavigationView.style == FWNavigationViewStyleDefault) {
                self.fwNavigationView.style = FWNavigationViewStyleCustom;
                self.fwNavigationView.contentView.backgroundColor = UIColor.yellowColor;
            } else {
                self.fwNavigationView.style = FWNavigationViewStyleDefault;
            }
        }
            break;
        case 9:
        {
            self.fwNavigationView.bottomHidden = !self.fwNavigationView.bottomHidden;
            self.fwNavigationView.bottomHeight = UINavigationBar.fwLargeTitleHeight;
        }
            break;
        case 10:
        {
            self.fwNavigationView.viewController = self.fwNavigationView.viewController ? nil : self;
        }
            break;
        case 11:
        {
            if (self.fwNavigationView.middleHeight == 100) {
                self.fwNavigationView.middleHeight = 0;
                self.fwNavigationView.middleView.backgroundColor = nil;
            } else {
                self.fwNavigationView.middleHeight = 100;
                self.fwNavigationView.middleView.backgroundColor = [UIColor orangeColor];
            }
        }
        case 12:
        {
            self.fwNavigationView.scrollView = self.fwNavigationView.scrollView ? nil : tableView;
        }
            break;
    }
    
    [tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView style:UITableViewCellStyleValue1];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailTextLabel.text = nil;
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = self.titleView.loadingViewHidden ? @"显示左边的loading" : @"隐藏左边的loading";
            break;
        case 1:
            cell.textLabel.text = self.titleView.accessoryImage == nil ? @"显示右边的accessoryView" : @"去掉右边的accessoryView";
            break;
        case 2:
            cell.textLabel.text = self.titleView.subtitle ? @"去掉副标题" : @"显示副标题";
            break;
        case 3:
            cell.textLabel.text = self.titleView.style == FWNavigationTitleViewStyleHorizontal ? @"切换为上下两行显示" : @"切换为水平一行显示";
            break;
        case 4:
            cell.textLabel.text = [self.tableData fwObjectAtIndex:indexPath.row];
            cell.detailTextLabel.text = (self.horizontalAlignment == UIControlContentHorizontalAlignmentLeft ? @"左对齐" : (self.horizontalAlignment == UIControlContentHorizontalAlignmentRight ? @"右对齐" : @"居中对齐"));
            break;
        default:
            cell.textLabel.text = [self.tableData fwObjectAtIndex:indexPath.row];
            break;
    }
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.fwNavigationViewEnabled) return;
    
    CGFloat progress = 1.0 - (self.fwNavigationView.bottomHeight / UINavigationBar.fwLargeTitleHeight);
    self.titleView.tintColor = [Theme.textColor colorWithAlphaComponent:progress];
}

#pragma mark - FWNavigationTitleViewDelegate

- (void)didChangedActive:(BOOL)active forTitleView:(FWNavigationTitleView *)titleView {
    if (!active) return;
    
    [FWPopupMenu showRelyOnView:titleView titles:@[@"菜单1", @"菜单2"] icons:nil menuWidth:120 otherSettings:^(FWPopupMenu *popupMenu) {
        popupMenu.delegate = self;
    }];
}

#pragma mark - FWPopupMenuDelegate

- (void)popupMenuDidDismiss:(FWPopupMenu *)popupMenu {
    self.titleView.active = NO;
}

@end
