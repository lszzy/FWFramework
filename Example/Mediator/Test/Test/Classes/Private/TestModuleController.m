//
//  TestModuleController.m
//  Pods
//
//  Created by wuyong on 2021/1/2.
//

#import "TestModuleController.h"
@import FWFramework;
@import Core;

@interface TestModuleController () <FWTableViewController, UISearchBarDelegate>

@property (nonatomic, assign) BOOL isSearch;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *searchResult;

@end

@implementation TestModuleController

#pragma mark - Accessor

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:selectedIndex] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [self fwShowMessageWithText:[NSString stringWithFormat:@"跳转到测试section: %@", @(selectedIndex)]];
}

- (UISearchBar *)searchBar
{
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, FWNavigationBarHeight)];
        _searchBar.placeholder = @"Search";
        _searchBar.delegate = self;
        _searchBar.showsCancelButton = YES;
        [_searchBar.fwCancelButton setTitle:[FWFrameworkBundle localizedString:@"取消"] forState:UIControlStateNormal];
        _searchBar.fwForceCancelButtonEnabled = YES;
        _searchBar.fwBackgroundColor = [Theme barColor];
        _searchBar.fwTextFieldBackgroundColor = [Theme tableColor];
        _searchBar.fwContentInset = UIEdgeInsetsMake(6, 16, 6, 0);
        _searchBar.fwCancelButtonInset = UIEdgeInsetsMake(0, 16, 0, 16);
        _searchBar.fwSearchIconCenter = YES;
        _searchBar.fwSearchIconOffset = 10;
        _searchBar.fwSearchTextOffset = 4;
        
        UITextField *textField = [_searchBar fwTextField];
        textField.font = [UIFont systemFontOfSize:12];
        [textField fwSetCornerRadius:16];
        textField.fwTouchResign = YES;
    }
    return _searchBar;
}

- (UIView *)titleView
{
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, FWNavigationBarHeight)];
    [titleView fwSetDimension:NSLayoutAttributeHeight toSize:FWNavigationBarHeight];
    titleView.fwIntrinsicContentSize = UILayoutFittingExpandedSize;
    titleView.backgroundColor = [UIColor clearColor];
    [titleView addSubview:self.searchBar];
    [self.searchBar fwPinEdgesToSuperview];
    return titleView;
}

- (NSArray *)displayData
{
    return self.isSearch ? self.searchResult : self.tableData;
}

#pragma mark - Lifecycle

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderTableView
{
    self.tableView.backgroundColor = [Theme tableColor];
    self.tableView.fwKeyboardDismissOnDrag = YES;
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
        @[@"Framework", @[
              @[@"FWRouter", @"TestRouterViewController"],
              @[@"FWNavigation", @"TestWindowViewController"],
              @[@"FWWorkflow", @"TestWorkflowViewController"],
              @[@"FWEncode", @"TestCrashViewController"],
              @[@"FWLayoutChain", @"TestChainViewController"],
              @[@"FWTheme", @"TestThemeViewController"],
              @[@"FWTheme+Extension", @"TestThemeExtensionViewController"],
              @[@"FWIcon", @"Test.TestIconViewController"],
              @[@"FWDynamicLayout+UITableView", @"TestTableDynamicLayoutViewController"],
              @[@"FWDynamicLayout+UICollectionView", @"TestCollectionDynamicLayoutViewController"],
              @[@"FWAdaptive", @"TestBarViewController"],
              @[@"FWPromise", @"Test.TestPromiseViewController"],
              @[@"FWImage", @"TestImageViewController"],
              @[@"FWState", @"TestStateViewController"],
              @[@"FWAnnotation", @"Test.TestAnnotationViewController"],
              @[@"FWAuthorize", @"TestAuthorizeViewController"],
              @[@"FWLocation", @"Test.TestLocationViewController"],
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
              @[@"FWEmptyPlugin+Scroll", @"TestEmptyScrollViewController"],
              @[@"FWViewPlugin", @"TestViewPluginViewController"],
              @[@"FWModel", @"TestModelViewController"],
              @[@"FWAsyncSocket", @"TestSocketViewController"],
              @[@"FWViewController", @"Test.TestSwiftViewController"],
              @[@"FWScrollViewController", @"TestControllerViewController"],
              @[@"FWNavigationView", @"TestNavigationTitleViewController"],
              @[@"FWNavigationView+Scroll", @"Test.TestNavigationScrollViewController"],
              @[@"FWTabBarController", @"TestTabBarViewController"],
              @[@"FWCache", @"TestCacheViewController"],
              @[@"FWAssetManager", @"Test.TestAssetViewController"],
              @[@"FWAudioPlayer", @"Test.TestAudioViewController"],
              @[@"FWVideoPlayer", @"Test.TestVideoViewController"],
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
              @[@"NSObject+FWThread", @"TestThreadViewController"],
              @[@"NSAttributedString+FWOption", @"TestAttributedStringViewController"],
              @[@"UITableView+Hover", @"TestScrollViewController"],
              @[@"UITableView+Background", @"TestTableBackgroundViewController"],
              @[@"UIViewController+FWTransition", @"TestTransitionViewController"],
              @[@"UIViewController+FWFramework", @"Test.TestChildViewController"],
              @[@"UITextField+FWKeyboard", @"TestKeyboardViewController"],
              @[@"UITextView+FWPlaceholder", @"Test.TestTextViewViewController"],
              @[@"UILabel+FWFramework", @"TestLabelViewController"],
              @[@"UIView+FWGradient", @"TestGradientViewController"],
              @[@"NSURL+FWVendor", @"TestUrlViewController"],
              @[@"FWSkeletonView", @"TestSkeletonViewController"],
              @[@"FWPagingView", @"TestNestScrollViewController"],
              @[@"FWPasscodeView", @"TestPasscodeViewController"],
              @[@"FWPhotoBrowser", @"Test.TestPhotoBrowserViewController"],
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
              @[@"FWSignatureView", @"Test.TestSignatureViewController"],
              ]],
    ]];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (@available(iOS 11.0, *)) {
        self.fwNavigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    self.fwNavigationView.scrollView = self.tableView;
    self.fwBarTitle = [self titleView];
}

#pragma mark - UISearchBar

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    searchBar.fwSearchIconCenter = NO;
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    searchBar.fwSearchIconCenter = YES;
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.isSearch = searchText.fwTrimString.length > 0;
    if (!self.isSearch) {
        self.searchResult = [NSMutableArray array];
        [self.tableView reloadData];
        return;
    }
    
    NSMutableArray *searchResult = [NSMutableArray array];
    NSString *searchString = searchText.fwTrimString.lowercaseString;
    for (NSArray *sectionData in self.tableData) {
        NSMutableArray *sectionResult = [NSMutableArray array];
        for (NSArray *rowData in sectionData[1]) {
            if ([[rowData[0] lowercaseString] containsString:searchString]) {
                [sectionResult addObject:rowData];
            }
        }
        if (sectionResult.count > 0) {
            [searchResult addObject:@[sectionData[0], sectionResult]];
        }
    }
    self.searchResult = searchResult;
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.displayData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = [self.displayData objectAtIndex:section];
    NSArray *sectionList = [sectionData objectAtIndex:1];
    return sectionList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSArray *sectionData = [self.displayData objectAtIndex:indexPath.section];
    NSArray *sectionList = [sectionData objectAtIndex:1];
    NSArray *rowData = [sectionList objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *sectionData = [self.displayData objectAtIndex:section];
    NSString *sectionName = [sectionData objectAtIndex:0];
    return sectionName;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *sectionData = [self.displayData objectAtIndex:indexPath.section];
    NSArray *sectionList = [sectionData objectAtIndex:1];
    NSArray *rowData = [sectionList objectAtIndex:indexPath.row];
    
    Class controllerClass = NSClassFromString([rowData objectAtIndex:1]);
    UIViewController *viewController = [[controllerClass alloc] init];
    viewController.fwNavigationItem.title = [rowData objectAtIndex:0];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
