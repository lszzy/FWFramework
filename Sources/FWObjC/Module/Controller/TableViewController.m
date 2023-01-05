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

- (NSArray<NSLayoutConstraint *> *)__fw_pinEdgesToSuperview:(UIEdgeInsets)insets;

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
        @"tableView" : @"__fw_tableView",
        @"tableData" : @"__fw_tableData",
        @"setupTableStyle" : @"__fw_setupTableStyle",
        @"setupTableLayout" : @"__fw_setupTableLayout",
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

- (UITableView *)__fw_tableView
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

- (NSMutableArray *)__fw_tableData
{
    NSMutableArray *tableData = objc_getAssociatedObject(self, _cmd);
    if (!tableData) {
        tableData = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, _cmd, tableData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tableData;
}

- (UITableViewStyle)__fw_setupTableStyle
{
    return UITableViewStylePlain;
}

- (void)__fw_setupTableLayout
{
    UITableView *tableView = [(id<__FWTableViewController>)self tableView];
    [tableView __fw_pinEdgesToSuperview:UIEdgeInsetsZero];
}

@end
