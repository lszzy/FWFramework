/*!
 @header     FWPagerView.m
 @indexgroup FWFramework
 @brief      FWPagerView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/21
 */

#import "FWPagerView.h"

#pragma mark - FWPagerMainTableView

@interface FWPagerMainTableView ()<UIGestureRecognizerDelegate>

@end

@implementation FWPagerMainTableView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.gestureDelegate && [self.gestureDelegate respondsToSelector:@selector(mainTableViewGestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [self.gestureDelegate mainTableViewGestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }else {
        return [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
    }
}

@end

#pragma mark - FWPagerListContainerView

@interface FWPagerListContainerView() <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, weak) id<FWPagerListContainerViewDelegate> delegate;
@property (nonatomic, strong) FWPagerListContainerCollectionView *collectionView;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, assign) BOOL isFirstLayoutSubviews;
@end

@implementation FWPagerListContainerView

- (instancetype)initWithDelegate:(id<FWPagerListContainerViewDelegate>)delegate {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _delegate = delegate;
        _isFirstLayoutSubviews = YES;
        [self initializeViews];
    }
    return self;
}

- (void)initializeViews {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    _collectionView = [[FWPagerListContainerCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.scrollsToTop = NO;
    self.collectionView.bounces = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    if (@available(iOS 10.0, *)) {
        self.collectionView.prefetchingEnabled = NO;
    }
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self addSubview:self.collectionView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.collectionView.frame = self.bounds;
    if (self.selectedIndexPath != nil && [self.delegate numberOfRowsInListContainerView:self] >= self.selectedIndexPath.item + 1) {
        [self.collectionView scrollToItemAtIndexPath:self.selectedIndexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
    if (self.isFirstLayoutSubviews) {
        self.isFirstLayoutSubviews = NO;
        [self.collectionView setContentOffset:CGPointMake(self.collectionView.bounds.size.width*self.defaultSelectedIndex, 0) animated:NO];
        
        self.selectedIndex = self.defaultSelectedIndex;
        if (self.delegate && [self.delegate respondsToSelector:@selector(listContainerView:didScrollToRow:)]) {
            [self.delegate listContainerView:self didScrollToRow:self.selectedIndex];
        }
    }
}

- (void)reloadData {
    [self.collectionView reloadData];
}

- (void)deviceOrientationDidChanged {
    if (self.bounds.size.width > 0) {
        self.selectedIndexPath = [NSIndexPath indexPathForItem:self.collectionView.contentOffset.x/self.bounds.size.width inSection:0];
    }
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.delegate numberOfRowsInListContainerView:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    UIView *listView = [self.delegate listContainerView:self listViewInRow:indexPath.item];
    listView.frame = cell.bounds;
    [cell.contentView addSubview:listView];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate listContainerView:self willDisplayCellAtRow:indexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate listContainerView:self didEndDisplayingCellAtRow:indexPath.item];
    
    CGFloat pageWidth = self.collectionView.bounds.size.width;
    if (pageWidth > 0) {
        NSInteger selectedIndex = (NSInteger)floor((self.collectionView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        if (self.selectedIndex != selectedIndex) {
            self.selectedIndex = selectedIndex;
            if (self.delegate && [self.delegate respondsToSelector:@selector(listContainerView:didScrollToRow:)]) {
                [self.delegate listContainerView:self didScrollToRow:self.selectedIndex];
            }
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return false;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.mainTableView.scrollEnabled = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.mainTableView.scrollEnabled = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.mainTableView.scrollEnabled = YES;
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.mainTableView.scrollEnabled = YES;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.bounds.size;
}

@end


@interface FWPagerListContainerCollectionView ()

@end

@implementation FWPagerListContainerCollectionView

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.gestureDelegate && [self.gestureDelegate respondsToSelector:@selector(pagerListContainerCollectionView:gestureRecognizerShouldBegin:)]) {
        return [self.gestureDelegate pagerListContainerCollectionView:self gestureRecognizerShouldBegin:gestureRecognizer];
    }else {
        if (self.isNestEnabled) {
            if ([gestureRecognizer isMemberOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")]) {
                CGFloat velocityX = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:gestureRecognizer.view].x;
                //x大于0就是往右滑
                if (velocityX > 0) {
                    if (self.contentOffset.x == 0) {
                        return NO;
                    }
                }else if (velocityX < 0) {
                    //x小于0就是往左滑
                    if (self.contentOffset.x + self.bounds.size.width == self.contentSize.width) {
                        return NO;
                    }
                }
            }
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.gestureDelegate && [self.gestureDelegate respondsToSelector:@selector(pagerListContainerCollectionView:gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [self.gestureDelegate pagerListContainerCollectionView:self gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}

@end

#pragma mark - FWPagerView

@interface FWPagerView () <UITableViewDataSource, UITableViewDelegate, FWPagerListContainerViewDelegate>
@property (nonatomic, weak) id<FWPagerViewDelegate> delegate;
@property (nonatomic, strong) FWPagerMainTableView *mainTableView;
@property (nonatomic, strong) FWPagerListContainerView *listContainerView;
@property (nonatomic, strong) UIScrollView *currentScrollingListView;
@property (nonatomic, strong) id<FWPagerViewListViewDelegate> currentList;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, id<FWPagerViewListViewDelegate>> *validListDict;
@property (nonatomic, assign) UIDeviceOrientation currentDeviceOrientation;
@property (nonatomic, assign) BOOL willRemoveFromWindow;
@property (nonatomic, assign) BOOL isFirstMoveToWindow;
@property (nonatomic, strong) FWPagerView *retainedSelf;
@property (nonatomic, strong) UIView *tableHeaderContainerView;
@end

@implementation FWPagerView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (instancetype)initWithDelegate:(id<FWPagerViewDelegate>)delegate {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _delegate = delegate;
        _validListDict = [NSMutableDictionary dictionary];
        _automaticallyDisplayListVerticalScrollIndicator = NO;
        _deviceOrientationChangeEnabled = NO;
        [self initializeViews];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    if (self.isFirstMoveToWindow) {
        //第一次调用过滤，因为第一次列表显示通知会从willDisplayCell方法通知
        self.isFirstMoveToWindow = NO;
        return;
    }
    //当前页面push到一个新的页面时，willMoveToWindow会调用三次。第一次调用的newWindow为nil，第二次调用间隔1ms左右newWindow有值，第三次调用间隔400ms左右newWindow为nil。
    //根据上述事实，第一次和第二次为无效调用，可以根据其间隔1ms左右过滤掉
    if (newWindow == nil) {
        self.willRemoveFromWindow = YES;
        //当前页面被pop的时候，willMoveToWindow只会调用一次，而且整个页面会被销毁掉，所以需要循环引用自己，确保能延迟执行currentListDidDisappear方法，触发列表消失事件。由此可见，循环引用也不一定是个坏事。是天使还是魔鬼，就看你如何对待它了。
        self.retainedSelf = self;
        [self performSelector:@selector(currentListDidDisappear) withObject:nil afterDelay:0.02];
    }else {
        if (self.willRemoveFromWindow) {
            self.willRemoveFromWindow = NO;
            self.retainedSelf = nil;
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(currentListDidDisappear) object:nil];
        }else {
            [self currentListDidAppear];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.mainTableView.frame = self.bounds;
}

- (void)setDefaultSelectedIndex:(NSInteger)defaultSelectedIndex {
    _defaultSelectedIndex = defaultSelectedIndex;
    
    self.listContainerView.defaultSelectedIndex = defaultSelectedIndex;
}

- (void)setListHorizontalScrollEnabled:(BOOL)listHorizontalScrollEnabled {
    _listHorizontalScrollEnabled = listHorizontalScrollEnabled;
    
    self.listContainerView.collectionView.scrollEnabled = listHorizontalScrollEnabled;
}

- (void)reloadData {
    self.currentList = nil;
    self.currentScrollingListView = nil;
    
    for (id<FWPagerViewListViewDelegate> list in self.validListDict.allValues) {
        [list.pagerListView removeFromSuperview];
    }
    [_validListDict removeAllObjects];
    
    [self refreshTableHeaderView];
    [self.mainTableView reloadData];
    [self.listContainerView reloadData];
}

- (void)resizeTableHeaderViewHeightWithAnimatable:(BOOL)animatable duration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve {
    if (animatable) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:curve];
        CGRect frame = self.tableHeaderContainerView.bounds;
        frame.size.height = [self.delegate tableHeaderViewHeightInPagerView:self];
        self.tableHeaderContainerView.frame = frame;
        self.mainTableView.tableHeaderView = self.tableHeaderContainerView;
        [UIView commitAnimations];
    }else {
        CGRect frame = self.tableHeaderContainerView.bounds;
        frame.size.height = [self.delegate tableHeaderViewHeightInPagerView:self];
        self.tableHeaderContainerView.frame = frame;
        self.mainTableView.tableHeaderView = self.tableHeaderContainerView;
    }
}

- (void)scrollToIndex:(NSInteger)index
{
    NSInteger diffIndex = labs(self.listContainerView.selectedIndex - index);
    if (diffIndex > 1) {
        [self.listContainerView.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }else {
        [self.listContainerView.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

#pragma mark - Private

- (void)refreshTableHeaderView {
    if (self.delegate == nil) {
        return;
    }
    UIView *tableHeaderView = [self.delegate tableHeaderViewInPagerView:self];
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, [self.delegate tableHeaderViewHeightInPagerView:self])];
    [containerView addSubview:tableHeaderView];
    tableHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:tableHeaderView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:tableHeaderView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:tableHeaderView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    NSLayoutConstraint *trailing = [NSLayoutConstraint constraintWithItem:tableHeaderView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
    [containerView addConstraints:@[top, leading, bottom, trailing]];
    self.tableHeaderContainerView = containerView;
    self.mainTableView.tableHeaderView = containerView;
}

- (void)adjustMainScrollViewToTargetContentInsetIfNeeded:(UIEdgeInsets)insets {
    if (UIEdgeInsetsEqualToEdgeInsets(insets, self.mainTableView.contentInset) == NO) {
        self.mainTableView.contentInset = insets;
    }
}

- (void)listViewDidScroll:(UIScrollView *)scrollView {
    self.currentScrollingListView = scrollView;
    
    [self preferredProcessListViewDidScroll:scrollView];
}

- (void)deviceOrientationDidChangeNotification:(NSNotification *)notification {
    if (self.isDeviceOrientationChangeEnabled && self.currentDeviceOrientation != [UIDevice currentDevice].orientation) {
        self.currentDeviceOrientation = [UIDevice currentDevice].orientation;
        //前后台切换也会触发该通知，所以不相同的时候才处理
        [self.mainTableView reloadData];
        [self.listContainerView deviceOrientationDidChanged];
        [self.listContainerView reloadData];
    }
}

- (void)currentListDidAppear {
    [self listDidAppear:self.listContainerView.selectedIndex];
}

- (void)currentListDidDisappear {
    id<FWPagerViewListViewDelegate> list = _validListDict[@(self.listContainerView.selectedIndex)];
    if (list && [list respondsToSelector:@selector(pagerListDidDisappear)]) {
        [list pagerListDidDisappear];
    }
    self.willRemoveFromWindow = NO;
    self.retainedSelf = nil;
}

- (void)listDidAppear:(NSInteger)index {
    if (self.delegate == nil) {
        return;
    }
    NSUInteger count = [self.delegate numberOfListViewsInPagerView:self];
    if (count <= 0 || index >= count) {
        return;
    }
    id<FWPagerViewListViewDelegate> list = _validListDict[@(index)];
    if (list && [list respondsToSelector:@selector(pagerListDidAppear)]) {
        [list pagerListDidAppear];
    }
}

- (void)listDidDisappear:(NSInteger)index {
    if (self.delegate == nil) {
        return;
    }
    NSUInteger count = [self.delegate numberOfListViewsInPagerView:self];
    if (count <= 0 || index >= count) {
        return;
    }
    id<FWPagerViewListViewDelegate> list = _validListDict[@(index)];
    if (list && [list respondsToSelector:@selector(pagerListDidDisappear)]) {
        [list pagerListDidDisappear];
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate == nil) {
        return 0;
    }
    return self.bounds.size.height - [self.delegate pinSectionHeaderHeightInPagerView:self] - self.pinSectionHeaderVerticalOffset;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    self.listContainerView.frame = cell.bounds;
    [cell.contentView addSubview:self.listContainerView];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.delegate == nil) {
        return 0;
    }
    return [self.delegate pinSectionHeaderHeightInPagerView:self];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.delegate == nil) {
        return [[UIView alloc] init];
    }
    return [self.delegate pinSectionHeaderInPagerView:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
    footer.backgroundColor = [UIColor clearColor];
    return footer;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.pinSectionHeaderVerticalOffset != 0) {
        if (scrollView.contentOffset.y < self.pinSectionHeaderVerticalOffset) {
            //因为设置了contentInset.top，所以顶部会有对应高度的空白区间，所以需要设置负数抵消掉
            if (scrollView.contentOffset.y >= 0) {
                [self adjustMainScrollViewToTargetContentInsetIfNeeded:UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0)];
            }
        }else if (scrollView.contentOffset.y > self.pinSectionHeaderVerticalOffset){
            //固定的位置就是contentInset.top
            [self adjustMainScrollViewToTargetContentInsetIfNeeded:UIEdgeInsetsMake(self.pinSectionHeaderVerticalOffset, 0, 0, 0)];
        }
    }
    
    [self preferredProcessMainTableViewDidScroll:scrollView];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagerView:mainTableViewDidScroll:)]) {
        [self.delegate pagerView:self mainTableViewDidScroll:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.listContainerView.collectionView.scrollEnabled = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.isListHorizontalScrollEnabled && !decelerate) {
        self.listContainerView.collectionView.scrollEnabled = YES;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.isListHorizontalScrollEnabled) {
        self.listContainerView.collectionView.scrollEnabled = YES;
    }
    if (self.mainTableView.contentInset.top != 0 && self.pinSectionHeaderVerticalOffset != 0) {
        [self adjustMainScrollViewToTargetContentInsetIfNeeded:UIEdgeInsetsZero];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.isListHorizontalScrollEnabled) {
        self.listContainerView.collectionView.scrollEnabled = YES;
    }
}

#pragma mark - FWPagerListContainerViewDelegate

- (NSInteger)numberOfRowsInListContainerView:(FWPagerListContainerView *)listContainerView {
    if (self.delegate == nil) {
        return 0;
    }
    return [self.delegate numberOfListViewsInPagerView:self];
}

- (UIView *)listContainerView:(FWPagerListContainerView *)listContainerView listViewInRow:(NSInteger)row {
    if (self.delegate == nil) {
        return [[UIView alloc] init];
    }
    id<FWPagerViewListViewDelegate> list = self.validListDict[@(row)];
    if (list == nil) {
        list = [self.delegate pagerView:self listViewAtIndex:row];
        __weak typeof(self)weakSelf = self;
        __weak typeof(id<FWPagerViewListViewDelegate>) weakList = list;
        [list pagerListViewDidScrollCallback:^(UIScrollView *scrollView) {
            weakSelf.currentList = weakList;
            [weakSelf listViewDidScroll:scrollView];
        }];
        _validListDict[@(row)] = list;
    }
    for (id<FWPagerViewListViewDelegate> listItem in self.validListDict.allValues) {
        if (listItem == list) {
            [listItem pagerListScrollView].scrollsToTop = YES;
        }else {
            [listItem pagerListScrollView].scrollsToTop = NO;
        }
    }
    
    return [list pagerListView];
}

- (void)listContainerView:(FWPagerListContainerView *)listContainerView willDisplayCellAtRow:(NSInteger)row {
    [self listDidAppear:row];
    self.currentScrollingListView = [self.validListDict[@(row)] pagerListScrollView];
}

- (void)listContainerView:(FWPagerListContainerView *)listContainerView didEndDisplayingCellAtRow:(NSInteger)row {
    [self listDidDisappear:row];
}

- (void)listContainerView:(FWPagerListContainerView *)listContainerView didScrollToRow:(NSInteger)row {
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagerView:didScrollToIndex:)]) {
        [self.delegate pagerView:self didScrollToIndex:row];
    }
}

@end

@implementation FWPagerView (UISubclassingGet)

- (CGFloat)mainTableViewMaxContentOffsetY {
    if (self.delegate == nil) {
        return 0;
    }
    return [self.delegate tableHeaderViewHeightInPagerView:self] - self.pinSectionHeaderVerticalOffset;
}

@end

@implementation FWPagerView (UISubclassingHooks)

- (void)initializeViews {
    _mainTableView = [[FWPagerMainTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.mainTableView.showsVerticalScrollIndicator = NO;
    self.mainTableView.showsHorizontalScrollIndicator = NO;
    self.mainTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.mainTableView.scrollsToTop = NO;
    self.mainTableView.dataSource = self;
    self.mainTableView.delegate = self;
    [self refreshTableHeaderView];
    [self.mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    if (@available(iOS 11.0, *)) {
        self.mainTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self addSubview:self.mainTableView];
    
    _listContainerView = [[FWPagerListContainerView alloc] initWithDelegate:self];
    self.listContainerView.mainTableView = self.mainTableView;
    
    self.listHorizontalScrollEnabled = YES;
    
    self.currentDeviceOrientation = [UIDevice currentDevice].orientation;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)preferredProcessListViewDidScroll:(UIScrollView *)scrollView {
    if (self.mainTableView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
        //mainTableView的header还没有消失，让listScrollView一直为0
        if (self.currentList && [self.currentList respondsToSelector:@selector(pagerListScrollViewWillResetContentOffset)]) {
            [self.currentList pagerListScrollViewWillResetContentOffset];
        }
        [self setListScrollViewToMinContentOffsetY:scrollView];
        if (self.automaticallyDisplayListVerticalScrollIndicator) {
            scrollView.showsVerticalScrollIndicator = NO;
        }
    }else {
        //mainTableView的header刚好消失，固定mainTableView的位置，显示listScrollView的滚动条
        self.mainTableView.contentOffset = CGPointMake(0, self.mainTableViewMaxContentOffsetY);
        if (self.automaticallyDisplayListVerticalScrollIndicator) {
            scrollView.showsVerticalScrollIndicator = YES;
        }
    }
}

- (void)preferredProcessMainTableViewDidScroll:(UIScrollView *)scrollView {
    if (self.currentScrollingListView != nil && self.currentScrollingListView.contentOffset.y > [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
        //mainTableView的header已经滚动不见，开始滚动某一个listView，那么固定mainTableView的contentOffset，让其不动
        [self setMainTableViewToMaxContentOffsetY];
    }
    
    if (scrollView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
        //mainTableView已经显示了header，listView的contentOffset需要重置
        for (id<FWPagerViewListViewDelegate> list in self.validListDict.allValues) {
            if ([list respondsToSelector:@selector(pagerListScrollViewWillResetContentOffset)]) {
                [list pagerListScrollViewWillResetContentOffset];
            }
            [self setListScrollViewToMinContentOffsetY:[list pagerListScrollView]];
        }
    }
    
    if (scrollView.contentOffset.y > self.mainTableViewMaxContentOffsetY && self.currentScrollingListView.contentOffset.y == [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
        //当往上滚动mainTableView的headerView时，滚动到底时，修复listView往上小幅度滚动
        [self setMainTableViewToMaxContentOffsetY];
    }
}

- (void)setMainTableViewToMaxContentOffsetY {
    self.mainTableView.contentOffset = CGPointMake(0, self.mainTableViewMaxContentOffsetY);
}

- (void)setListScrollViewToMinContentOffsetY:(UIScrollView *)scrollView {
    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, [self minContentOffsetYInListScrollView:scrollView]);
}

- (CGFloat)minContentOffsetYInListScrollView:(UIScrollView *)scrollView {
    if (@available(iOS 11.0, *)) {
        return -scrollView.adjustedContentInset.top;
    }
    return -scrollView.contentInset.top;
}

@end

#pragma mark - FWPagerRefreshView

@interface FWPagerRefreshView()
@property (nonatomic, assign) CGFloat lastScrollingListViewContentOffsetY;
@end

@implementation FWPagerRefreshView

- (void)initializeViews {
    [super initializeViews];
    
    self.mainTableView.bounces = NO;
}

- (void)preferredProcessListViewDidScroll:(UIScrollView *)scrollView {
    BOOL shouldProcess = YES;
    if (self.currentScrollingListView.contentOffset.y > self.lastScrollingListViewContentOffsetY) {
        //往上滚动
    }else {
        //往下滚动
        if (self.mainTableView.contentOffset.y == 0) {
            shouldProcess = NO;
        }else {
            if (self.mainTableView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
                //mainTableView的header还没有消失，让listScrollView一直为0
                if (self.currentList && [self.currentList respondsToSelector:@selector(pagerListScrollViewWillResetContentOffset)]) {
                    [self.currentList pagerListScrollViewWillResetContentOffset];
                }
                [self setListScrollViewToMinContentOffsetY:self.currentScrollingListView];
                if (self.automaticallyDisplayListVerticalScrollIndicator) {
                    self.currentScrollingListView.showsVerticalScrollIndicator = NO;
                }
            }
        }
    }
    if (shouldProcess) {
        if (self.mainTableView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
            //处于下拉刷新的状态，scrollView.contentOffset.y为负数，就重置为0
            if (self.currentScrollingListView.contentOffset.y > [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
                //mainTableView的header还没有消失，让listScrollView一直为0
                if (self.currentList && [self.currentList respondsToSelector:@selector(pagerListScrollViewWillResetContentOffset)]) {
                    [self.currentList pagerListScrollViewWillResetContentOffset];
                }
                [self setListScrollViewToMinContentOffsetY:self.currentScrollingListView];
                if (self.automaticallyDisplayListVerticalScrollIndicator) {
                    self.currentScrollingListView.showsVerticalScrollIndicator = NO;
                }
            }
        } else {
            //mainTableView的header刚好消失，固定mainTableView的位置，显示listScrollView的滚动条
            self.mainTableView.contentOffset = CGPointMake(0, self.mainTableViewMaxContentOffsetY);
            if (self.automaticallyDisplayListVerticalScrollIndicator) {
                self.currentScrollingListView.showsVerticalScrollIndicator = YES;
            }
        }
    }
    self.lastScrollingListViewContentOffsetY = self.currentScrollingListView.contentOffset.y;
}

- (void)preferredProcessMainTableViewDidScroll:(UIScrollView *)scrollView {
    if (self.pinSectionHeaderVerticalOffset != 0) {
        if (scrollView.contentOffset.y == 0) {
            self.mainTableView.bounces = NO;
        }else {
            self.mainTableView.bounces = YES;
        }
    }
    if (self.currentScrollingListView != nil && self.currentScrollingListView.contentOffset.y > [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
        //mainTableView的header已经滚动不见，开始滚动某一个listView，那么固定mainTableView的contentOffset，让其不动
        [self setMainTableViewToMaxContentOffsetY];
    }
    
    if (scrollView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
        //mainTableView已经显示了header，listView的contentOffset需要重置
        for (id<FWPagerViewListViewDelegate> list in self.validListDict.allValues) {
            //正在下拉刷新时，不需要重置
            UIScrollView *listScrollView = [list pagerListScrollView];
            if (listScrollView.contentOffset.y > 0) {
                if ([list respondsToSelector:@selector(pagerListScrollViewWillResetContentOffset)]) {
                    [list pagerListScrollViewWillResetContentOffset];
                }
                [self setListScrollViewToMinContentOffsetY:listScrollView];
            }
        }
    }
    
    if (scrollView.contentOffset.y > self.mainTableViewMaxContentOffsetY && self.currentScrollingListView.contentOffset.y == [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
        //当往上滚动mainTableView的headerView时，滚动到底时，修复listView往上小幅度滚动
        [self setMainTableViewToMaxContentOffsetY];
    }
}

@end
