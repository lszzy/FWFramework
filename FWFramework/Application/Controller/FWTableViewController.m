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
    UITableView *tableView = objc_getAssociatedObject(self, @selector(tableView));
    if (!tableView) {
        UITableViewStyle tableStyle = [(id<FWTableViewController>)self renderTableStyle];
        tableView = [[UITableView alloc] initWithFrame:CGRectZero style:tableStyle];
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        objc_setAssociatedObject(self, @selector(tableView), tableView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tableView;
}

- (NSMutableArray *)fwInnerTableData
{
    NSMutableArray *tableData = objc_getAssociatedObject(self, @selector(tableData));
    if (!tableData) {
        tableData = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, @selector(tableData), tableData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tableData;
}

- (UITableViewStyle)fwInnerRenderTableStyle
{
    return UITableViewStylePlain;
}

- (void)fwInnerRenderTableView
{
    UITableView *tableView = [(id<FWTableViewController>)self tableView];
    [tableView fwPinEdgesToSuperview];
}

@end

#pragma mark - FWViewControllerManager+FWTableViewController

@implementation FWViewControllerManager (FWTableViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.loadViewIntercepter = @selector(tableViewControllerLoadView:);
    intercepter.forwardSelectors = @{@"tableView" : @"fwInnerTableView",
                                     @"tableData" : @"fwInnerTableData",
                                     @"renderTableStyle" : @"fwInnerRenderTableStyle",
                                     @"renderTableView" : @"fwInnerRenderTableView"};
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWTableViewController) withIntercepter:intercepter];
}

- (void)tableViewControllerLoadView:(UIViewController<FWTableViewController> *)viewController
{
    UITableView *tableView = [viewController tableView];
    tableView.dataSource = viewController;
    tableView.delegate = viewController;
    [viewController.view addSubview:tableView];
    
    [viewController renderTableView];
    [tableView setNeedsLayout];
    [tableView layoutIfNeeded];
}

@end
