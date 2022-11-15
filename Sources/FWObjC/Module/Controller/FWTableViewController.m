//
//  FWTableViewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWTableViewController.h"
#import <objc/runtime.h>
#if FWMacroSPM
@import FWFramework;
#else
#import <FWFramework/FWFramework-Swift.h>
#endif

#pragma mark - FWViewControllerManager+FWTableViewController

@implementation FWViewControllerManager (FWTableViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.viewDidLoadIntercepter = @selector(tableViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{
        @"tableView" : @"fw_innerTableView",
        @"tableData" : @"fw_innerTableData",
        @"setupTableStyle" : @"fw_innerSetupTableStyle",
        @"setupTableLayout" : @"fw_innerSetupTableLayout",
    };
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWTableViewController) withIntercepter:intercepter];
}

- (void)tableViewControllerViewDidLoad:(UIViewController<FWTableViewController> *)viewController
{
    UITableView *tableView = [viewController tableView];
    tableView.dataSource = viewController;
    tableView.delegate = viewController;
    [viewController.view addSubview:tableView];
    
    if (self.hookTableViewController) {
        self.hookTableViewController(viewController);
    }
    
    if ([viewController respondsToSelector:@selector(setupTableView)]) {
        [viewController setupTableView];
    }
    
    [viewController setupTableLayout];
    [tableView setNeedsLayout];
    [tableView layoutIfNeeded];
}

@end

#pragma mark - UIViewController+FWTableViewController

@interface UIViewController (FWTableViewController)

@end

@implementation UIViewController (FWTableViewController)

- (UITableView *)fw_innerTableView
{
    UITableView *tableView = objc_getAssociatedObject(self, _cmd);
    if (!tableView) {
        UITableViewStyle tableStyle = [(id<FWTableViewController>)self setupTableStyle];
        tableView = [[UITableView alloc] initWithFrame:CGRectZero style:tableStyle];
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        if (@available(iOS 15.0, *)) {
            tableView.sectionHeaderTopPadding = 0;
        }
        objc_setAssociatedObject(self, _cmd, tableView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tableView;
}

- (NSMutableArray *)fw_innerTableData
{
    NSMutableArray *tableData = objc_getAssociatedObject(self, _cmd);
    if (!tableData) {
        tableData = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, _cmd, tableData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tableData;
}

- (UITableViewStyle)fw_innerSetupTableStyle
{
    return UITableViewStylePlain;
}

- (void)fw_innerSetupTableLayout
{
    UITableView *tableView = [(id<FWTableViewController>)self tableView];
    [tableView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
}

@end
