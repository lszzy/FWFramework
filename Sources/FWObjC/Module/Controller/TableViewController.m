//
//  TableViewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "TableViewController.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIView ()

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperview:(UIEdgeInsets)insets;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWViewControllerManager+__FWTableViewController

@implementation __FWViewControllerManager (__FWTableViewController)

+ (void)load
{
    __FWViewControllerIntercepter *intercepter = [[__FWViewControllerIntercepter alloc] init];
    intercepter.viewDidLoadIntercepter = @selector(tableViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{
        @"tableView" : @"fw_innerTableView",
        @"tableData" : @"fw_innerTableData",
        @"setupTableStyle" : @"fw_innerSetupTableStyle",
        @"setupTableLayout" : @"fw_innerSetupTableLayout",
    };
    [[__FWViewControllerManager sharedInstance] registerProtocol:@protocol(__FWTableViewController) withIntercepter:intercepter];
}

- (void)tableViewControllerViewDidLoad:(UIViewController<__FWTableViewController> *)viewController
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

#pragma mark - UIViewController+__FWTableViewController

@interface UIViewController (__FWTableViewController)

@end

@implementation UIViewController (__FWTableViewController)

- (UITableView *)fw_innerTableView
{
    UITableView *tableView = objc_getAssociatedObject(self, _cmd);
    if (!tableView) {
        UITableViewStyle tableStyle = [(id<__FWTableViewController>)self setupTableStyle];
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
    UITableView *tableView = [(id<__FWTableViewController>)self tableView];
    [tableView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
}

@end
