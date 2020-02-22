/*!
 @header     TestViewController.m
 @indexgroup Example
 @brief      TestViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "TestViewController.h"

@interface TestViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation TestViewController

- (UISearchBar *)searchBar
{
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, FWNavigationBarHeight)];
        _searchBar.placeholder = @"我是很长很长";
        _searchBar.delegate = self;
        _searchBar.showsCancelButton = YES;
        [_searchBar fwForceCancelButtonEnabled:YES];
        [_searchBar fwSetBackgroundColor:[UIColor whiteColor]];
        [_searchBar fwSetTextFieldBackgroundColor:[UIColor fwColorWithHex:0xEEEEEE]];
        _searchBar.fwContentInset = UIEdgeInsetsMake(6, 15, 6, 65);
        [_searchBar fwSetSearchIconCenter:YES];
        [_searchBar fwSetSearchIconPosition:0];
        
        UITextField *textField = [_searchBar fwTextField];
        textField.font = [UIFont systemFontOfSize:12];
        [textField fwSetCornerRadius:16];
        textField.fwTouchResign = YES;
    }
    return _searchBar;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [searchBar fwSetSearchIconCenter:NO];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [searchBar fwSetSearchIconCenter:YES];
    return YES;
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                       @[@"FWFramework", @[
                                             @[@"UIButton(FWFramework)", @"TestButtonViewController"],
                                             @[@"UIView(FWAnimation)", @"TestAnimationViewController"],
                                             @[@"UIView(FWBadge)", @"TestBadgeViewController"],
                                             @[@"UIView(FWIndicator)", @"TestIndicatorViewController"],
                                             @[@"UIView(FWBorder)", @"TestBorderViewController"],
                                             @[@"UIView(FWChain)", @"TestChainViewController"],
                                             @[@"UIView(FWLayer)", @"TestLayerViewController"],
                                             @[@"UIView(FWStatistical)", @"TestStatisticalViewController"],
                                             @[@"UIImageView(FWFace)", @"TestFaceViewController"],
                                             @[@"UITableView(FWTemplateLayout)", @"TestTableLayoutViewController"],
                                             @[@"FWScroll", @"TestTableScrollViewController"],
                                             @[@"NSObject(FWModel)", @"TestModelViewController"],
                                             @[@"NSObject(FWThread)", @"TestThreadViewController"],
                                             @[@"NSAttributedString(FWOption)", @"TestAttributedStringViewController"],
                                             @[@"UIWindow(FWFramework)", @"TestWindowViewController"],
                                             @[@"UIScrollView(FWFramework)", @"TestScrollViewController"],
                                             @[@"UIScrollView(FWEmptyView)", @"TestEmptyViewController"],
                                             @[@"UICollection(FWFramework)", @"TestCollectionViewController"],
                                             @[@"UIWebView(FWFramework)", @"TestWebViewController"],
                                             @[@"UINavigationController(FWFramework)", @"TestNavigationViewController"],
                                             @[@"UIViewController(FWAlert)", @"TestAlertViewController"],
                                             @[@"UIViewController(FWBar)", @"TestBarViewController"],
                                             @[@"UIViewController(FWTransition)", @"TestTransitionViewController"],
                                             @[@"UIViewController(FWWorkflow)", @"TestWorkflowViewController"],
                                             @[@"UITextField(FWKeyboard)", @"TestKeyboardViewController"],
                                             @[@"UILabel(FWFramework)", @"TestLabelViewController"],
                                             @[@"UIView+FWGradient", @"TestGradientViewController"],
                                             @[@"NSURL(FWVendor)", @"TestUrlViewController"],
                                             @[@"FWAsyncSocket", @"TestSocketViewController"],
                                             ]],
                                       @[@"FWApplication", @[
                                             @[@"FWIndicatorControl", @"TestIndicatorControlViewController"],
                                             @[@"TableBackground", @"TestTableBackgroundViewController"],
                                             @[@"NestScrollView", @"TestNestScrollViewController"],
                                             @[@"MapView", @"TestMapViewController"],
                                             @[@"DrawerView", @"TestDrawerViewController"],
                                             @[@"MenuView", @"TestMenuViewController"],
                                             @[@"FWRouter", @"TestRouterViewController"],
                                             @[@"FWState", @"TestStateViewController"],
                                             @[@"FWSegmentedControl", @"TestSegmentViewController"],
                                             @[@"FWBannerView", @"TestBannerViewController"],
                                             @[@"FWViewController", @"TestControllerViewController"],
                                             @[@"FWQrcodeScanView", @"TestQrcodeViewController"],
                                             @[@"FWExceptionManager", @"TestCrashViewController"],
                                             @[@"FWAuthorizeManager", @"TestAuthorizeViewController"],
                                             @[@"FWStorekitManager", @"TestStorekitViewController"],
                                             @[@"FWNotificationManager", @"TestNotificationViewController"],
                                             @[@"FWCache", @"TestCacheViewController"],
                                             @[@"FWVersionManager", @"TestVersionViewController"],
                                             @[@"TableReloadData", @"TestTableReloadViewController"],
                                             ]],
                                       ]];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.searchBar fwAddToNavigationItem:self.navigationItem];
}

#pragma mark - TableView

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderTableView
{
    self.tableView.fwKeyboardDismissOnDrag = YES;
}

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionData = [self.tableData objectAtIndex:indexPath.section];
    NSArray *sectionList = [sectionData objectAtIndex:1];
    NSArray *rowData = [sectionList objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *sectionData = [self.tableData objectAtIndex:indexPath.section];
    NSArray *sectionList = [sectionData objectAtIndex:1];
    NSArray *rowData = [sectionList objectAtIndex:indexPath.row];
    
    NSString *vcStr = [rowData objectAtIndex:1];
    Class vcClass = NSClassFromString(vcStr);
    UIViewController *vc = [[vcClass alloc] init];
    vc.title = [rowData objectAtIndex:0];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = [self.tableData objectAtIndex:section];
    NSArray *sectionList = [sectionData objectAtIndex:1];
    return sectionList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *sectionData = [self.tableData objectAtIndex:section];
    NSString *sectionName = [sectionData objectAtIndex:0];
    return sectionName;
}

@end
