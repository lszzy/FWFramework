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
        @[@"Framework", @[
              @[@"FWRouter", @"TestRouterViewController"],
              @[@"FWRouter+Navigation", @"TestWindowViewController"],
              @[@"FWEncode", @"TestCrashViewController"],
              @[@"FWLayoutChain", @"TestChainViewController"],
              @[@"FWTheme", @"TestThemeViewController"],
              @[@"FWTheme+Extension", @"TestThemeExtensionViewController"],
              @[@"FWDynamicLayout+UITableView", @"TestTableDynamicLayoutViewController"],
              @[@"FWDynamicLayout+UICollectionView", @"TestCollectionDynamicLayoutViewController"],
              @[@"FWAdaptive", @"TestBarViewController"],
              @[@"FWImage", @"TestImageViewController"],
              @[@"FWState", @"TestStateViewController"],
              @[@"FWAnnotation", [TestAnnotationViewController new]],
              @[@"FWAuthorize", @"TestAuthorizeViewController"],
              @[@"FWLocation", [TestLocationViewController new]],
              @[@"FWNotification", @"TestNotificationViewController"],
              @[@"FWVersion", @"TestVersionViewController"],
              ]],
        @[@"Application", @[
              @[@"FWWebViewBridge", @"TestJavascriptBridgeViewController"],
              @[@"FWAlertPlugin", @"TestAlertViewController"],
              @[@"FWAlertController", @"TestCustomerAlertController"],
              @[@"FWToastPlugin", @"TestIndicatorViewController"],
              @[@"FWRefreshPlugin", @"TestTableScrollViewController"],
              @[@"FWRefreshPlugin+Reload", @"TestTableReloadViewController"],
              @[@"FWEmptyPlugin", @"TestEmptyViewController"],
              @[@"FWModel", @"TestModelViewController"],
              @[@"FWAsyncSocket", @"TestSocketViewController"],
              @[@"FWViewController", [TestSwiftViewController new]],
              @[@"FWScrollViewController", @"TestControllerViewController"],
              @[@"FWTabBarController", @"TestTabBarViewController"],
              @[@"FWCache", @"TestCacheViewController"],
              ]],
        @[@"Component", @[
              @[@"UIButton+FWFramework", @"TestButtonViewController"],
              @[@"UICollectionView+FWFramework", @"TestCollectionViewController"],
              @[@"UIView+FWAnimation", @"TestAnimationViewController"],
              @[@"UIView+FWBadge", @"TestBadgeViewController"],
              @[@"UIView+FWBorder", @"TestBorderViewController"],
              @[@"UIView+FWLayer", @"TestLayerViewController"],
              @[@"UIView+FWStatistical", @"TestStatisticalViewController"],
              @[@"UIImageView+FWFace", @"TestFacesViewController"],
              @[@"UITableView+FWTemplateLayout", @"TestTableLayoutViewController"],
              @[@"UITableView+FWEmptyView", @"TestEmptyScrollViewController"],
              @[@"NSObject+FWThread", @"TestThreadViewController"],
              @[@"NSAttributedString+FWOption", @"TestAttributedStringViewController"],
              @[@"UITableView+Hover", @"TestScrollViewController"],
              @[@"WKWebView+FWFramework", @"TestWebViewController"],
              @[@"UIViewController+FWTransition", @"TestTransitionViewController"],
              @[@"UIViewController+FWWorkflow", @"TestWorkflowViewController"],
              @[@"UITextField+FWKeyboard", @"TestKeyboardViewController"],
              @[@"UILabel+FWFramework", @"TestLabelViewController"],
              @[@"UIView+FWGradient", @"TestGradientViewController"],
              @[@"NSURL+FWVendor", @"TestUrlViewController"],
              @[@"FWIndicatorControl", @"TestIndicatorControlViewController"],
              @[@"FWSkeletonView", @"TestSkeletonViewController"],
              @[@"UITableView+Background", @"TestTableBackgroundViewController"],
              @[@"FWPagingView", @"TestNestScrollViewController"],
              @[@"FWCropViewController", @"TestCropViewController"],
              @[@"MKMapView", @"TestMapViewController"],
              @[@"FWDrawerView", @"TestDrawerViewController"],
              @[@"FWDrawerView+Menu", @"TestMenuViewController"],
              @[@"FWSegmentedControl", @"TestSegmentViewController"],
              @[@"FWTableView", @"TestTableCreateViewController"],
              @[@"FWCollectionView", @"TestCollectionCreateViewController"],
              @[@"FWBannerView", @"TestBannerViewController"],
              @[@"FWBarrageView", @"TestBarrageViewController"],
              @[@"FWGridView", @"TestGridViewController"],
              @[@"FWFloatLayoutView", @"TestFloatLayoutViewController"],
              @[@"FWPopupMenu", @"TestPopupMenuViewController"],
              @[@"FWQrcodeScanView", @"TestQrcodeViewController"],
              @[@"UIView+Draw", @"TestDrawViewController"],
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
    
    id vc = [rowData objectAtIndex:1];
    if ([vc isKindOfClass:[NSString class]]) {
        Class vcClass = NSClassFromString(vc);
        vc = [[vcClass alloc] init];
        ((UIViewController *)vc).title = [rowData objectAtIndex:0];
    } else if ([vc isKindOfClass:[UIViewController class]]) {
        ((UIViewController *)vc).title = [rowData objectAtIndex:0];
    }
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
