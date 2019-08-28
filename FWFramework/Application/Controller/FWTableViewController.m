/*!
 @header     FWTableViewController.m
 @indexgroup FWFramework
 @brief      FWTableViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/28
 */

#import "FWTableViewController.h"
#import "UIView+FWAutoLayout.h"
#import <objc/runtime.h>

#pragma mark - UIViewController+FWTableViewController

@interface UIViewController (FWTableViewController)

@end

@implementation UIViewController (FWTableViewController)

- (UITableView *)fwInnerTableView
{
    UITableView *tableView = objc_getAssociatedObject(self, @selector(fwInnerTableView));
    if (!tableView) {
        tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        objc_setAssociatedObject(self, @selector(fwInnerTableView), tableView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tableView;
}

- (NSMutableArray *)fwInnerTableData
{
    NSMutableArray *tableData = objc_getAssociatedObject(self, @selector(fwInnerTableData));
    if (!tableData) {
        tableData = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, @selector(fwInnerTableData), tableData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tableData;
}

@end

#pragma mark - FWViewControllerManager+FWTableViewController

@implementation FWViewControllerManager (FWTableViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.loadViewIntercepter = @selector(tableViewControllerLoadView:);
    intercepter.forwardSelectors = @{@"tableView" : @"fwInnerTableView", @"tableData" : @"fwInnerTableData"};
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWTableViewController) withIntercepter:intercepter];
}

- (void)tableViewControllerLoadView:(UIViewController<FWTableViewController> *)viewController
{
    UITableView *tableView = [viewController tableView];
    tableView.dataSource = viewController;
    tableView.delegate = viewController;
    [viewController.view addSubview:tableView];
    
    if ([viewController respondsToSelector:@selector(renderTableView)]) {
        [viewController renderTableView];
    } else {
        [tableView fwPinEdgesToSuperview];
    }
    
    [tableView setNeedsLayout];
    [tableView layoutIfNeeded];
}

@end
