//
//  TestNavigationTitleViewController.m
//  Example
//
//  Created by wuyong on 2020/2/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestNavigationTitleViewController.h"

@interface TestNavigationTitleViewController () <FWTableViewController, FWNavigationTitleViewDelegate, FWPopupMenuDelegate>

@property(nonatomic, strong) UIToolbar *toolbar;
@property(nonatomic, strong) FWNavigationTitleView *titleView;
@property(nonatomic, assign) UIControlContentHorizontalAlignment horizontalAlignment;

@end

@implementation TestNavigationTitleViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStylePlain;
}

- (void)renderView
{
    UIToolbar *toolbar = [UIToolbar new];
    toolbar.fwBarPosition = UIBarPositionBottom;
    _toolbar = toolbar;
    toolbar.fwForegroundColor = Theme.textColor;
    toolbar.fwBackgroundColor = Theme.barColor;
    [self.fwView addSubview:toolbar];
    toolbar.fwLayoutChain.edgesToSafeAreaWithInsetsExcludingEdge(UIEdgeInsetsZero, NSLayoutAttributeTop);
    
    UIBarButtonItem *leftItem = [UIBarButtonItem fwBarItemWithObject:@"取消" block:nil];
    UIBarButtonItem *flexibleItem = [UIBarButtonItem fwBarItemWithObject:@(UIBarButtonSystemItemFlexibleSpace) block:nil];
    UIBarButtonItem *rightItem = [UIBarButtonItem fwBarItemWithObject:@"确定" block:nil];
    toolbar.items = @[leftItem, flexibleItem, rightItem];
    [toolbar sizeToFit];
    
    FWNavigationTitleView *titleView = [[FWNavigationTitleView alloc] init];
    self.titleView = titleView;
    titleView.showsLoadingView = YES;
    self.fwBarTitle = titleView;
    self.fwNavigationItem.title = @"我是很长很长要多长有多长长得不得了的按钮";
    self.horizontalAlignment = self.titleView.contentHorizontalAlignment;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 300)];
    
    self.fwLeftBarItem = [[FWNavigationButton alloc] initWithImage:FWIcon.backImage];
    [self fwAddRightBarItem:[[FWNavigationButton alloc] initWithImage:FWIcon.closeImage] block:^(id  _Nonnull sender) {
        [FWRouter closeViewControllerAnimated:YES];
    }];
    [self fwAddRightBarItem:[[FWNavigationButton alloc] initWithImage:FWIcon.backImage] block:^(id  _Nonnull sender) {
        [FWRouter closeViewControllerAnimated:YES];
    }];
    
    FWNavigationView *navigationView = self.fwNavigationView;
    navigationView.bottomView.backgroundColor = UIColor.brownColor;
    navigationView.bottomHidden = YES;
    UILabel *titleLabel = [UILabel fwLabelWithFont:FWFontBold(18) textColor:UIColor.whiteColor text:@"FWNavigationView"];
    [navigationView.bottomView addSubview:titleLabel];
    titleLabel.fwLayoutChain.leftWithInset(15).bottomWithInset(15);
}

- (void)renderModel
{
    FWWeakifySelf();
    self.fwBackBarBlock = ^BOOL{
        FWStrongifySelf();
        [self fwShowConfirmWithTitle:nil message:@"是否关闭" cancel:nil confirm:nil confirmBlock:^{
            FWStrongifySelf();
            [self fwCloseViewControllerAnimated:YES];
        }];
        return NO;
    };
}

- (void)renderData
{
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
            @"导航栏中间视图切换",
            @"导航栏底部视图切换",
            @"导航栏绑定控制器切换",
            @"导航栏固定高度切换",
            @"导航栏内间距切换",
            @"导航栏滚动效果切换",
        ]];
    }
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
            if (self.fwNavigationView.contentView.backgroundColor != UIColor.yellowColor) {
                self.fwNavigationView.contentView.backgroundColor = UIColor.yellowColor;
                self.fwNavigationView.style = FWNavigationViewStyleCustom;
            } else {
                self.fwNavigationView.style = self.fwNavigationView.style == FWNavigationViewStyleDefault ? FWNavigationViewStyleCustom : FWNavigationViewStyleDefault;
            }
        }
            break;
        case 9:
        {
            self.fwNavigationView.middleHidden = !self.fwNavigationView.middleHidden;
        }
            break;
        case 10:
        {
            self.fwNavigationView.bottomHidden = !self.fwNavigationView.bottomHidden;
            self.fwNavigationView.bottomHeight = 100;
        }
            break;
        case 11:
        {
            self.fwNavigationView.viewController = self.fwNavigationView.viewController ? nil : self;
        }
            break;
        case 12:
        {
            if (self.fwNavigationView.middleHeight == 100) {
                self.fwNavigationView.middleHeight = 0;
                self.fwNavigationView.contentInsets = UIEdgeInsetsZero;
                self.fwNavigationView.middleView.backgroundColor = nil;
            } else {
                self.fwNavigationView.middleHeight = 100;
                self.fwNavigationView.contentInsets = UIEdgeInsetsMake(0, 0, 100 - self.fwNavigationView.contentHeight, 0);
                self.fwNavigationView.middleView.backgroundColor = [UIColor orangeColor];
            }
        }
            break;
        case 13:
        {
            self.fwNavigationView.contentInsets = UIEdgeInsetsEqualToEdgeInsets(self.fwNavigationView.contentInsets, UIEdgeInsetsZero) ? UIEdgeInsetsMake(0, 0, 100 - self.fwNavigationView.contentHeight, 0) : UIEdgeInsetsZero;
        }
            break;
        case 14:
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
    
    CGFloat progress = 1.0 - (self.fwNavigationView.bottomHeight / 100);
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
