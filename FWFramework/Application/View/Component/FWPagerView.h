/*!
 @header     FWPagerView.h
 @indexgroup FWFramework
 @brief      FWPagerView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/21
 */

#import <UIKit/UIKit.h>

#pragma mark - FWPagerListContainerView

@class FWPagerListContainerView;

@protocol FWPagerListContainerViewDelegate <NSObject>

- (NSInteger)numberOfRowsInListContainerView:(FWPagerListContainerView *)listContainerView;

- (UIView *)listContainerView:(FWPagerListContainerView *)listContainerView listViewInRow:(NSInteger)row;

- (void)listContainerView:(FWPagerListContainerView *)listContainerView willDisplayCellAtRow:(NSInteger)row;

- (void)listContainerView:(FWPagerListContainerView *)listContainerView didEndDisplayingCellAtRow:(NSInteger)row;

- (void)listContainerView:(FWPagerListContainerView *)listContainerView didScrollToRow:(NSInteger)row;

@end

@interface FWPagerListContainerView : UIView

/**
 需要和self.categoryView.defaultSelectedIndex保持一致
 */
@property (nonatomic, assign) NSInteger defaultSelectedIndex;

@property (nonatomic, assign) BOOL isNestEnabled;
// 可自定义shouldBegin和shouldRecognizeSimultaneously解决手势冲突
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, weak) UITableView *mainTableView;

- (instancetype)initWithDelegate:(id<FWPagerListContainerViewDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (void)reloadData;

- (void)deviceOrientationDidChanged;

@end

#pragma mark - FWPagerView

@class FWPagerView;

/**
 该协议主要用于mainTableView已经显示了header，listView的contentOffset需要重置时，内部需要访问到外部传入进来的listView内的scrollView
 */
@protocol FWPagerViewListViewDelegate <NSObject>

/**
 返回listView。如果是vc包裹的就是vc.view；如果是自定义view包裹的，就是自定义view自己。
 
 @return UIView
 */
- (UIView *)pagerListView;

/**
 返回listView内部持有的UIScrollView或UITableView或UICollectionView
 主要用于mainTableView已经显示了header，listView的contentOffset需要重置时，内部需要访问到外部传入进来的listView内的scrollView
 
 @return listView内部持有的UIScrollView或UITableView或UICollectionView
 */
- (UIScrollView *)pagerListScrollView;


/**
 当listView内部持有的UIScrollView或UITableView或UICollectionView的代理方法`scrollViewDidScroll`回调时，需要调用该代理方法传入的callback
 
 @param callback `scrollViewDidScroll`回调时调用的callback
 */
- (void)pagerListViewDidScrollCallback:(void (^)(UIScrollView *scrollView))callback;

@optional

/**
 将要重置listScrollView的contentOffset
 */
- (void)pagerListScrollViewWillResetContentOffset;

/**
 可选实现，列表显示的时候调用
 */
- (void)pagerListDidAppear;

/**
 可选实现，列表消失的时候调用
 */
- (void)pagerListDidDisappear;

@end

@protocol FWPagerViewDelegate <NSObject>

/**
 返回tableHeaderView的高度，因为内部需要比对判断，只能是整型数
 
 @param pagerView pagerView description
 @return return tableHeaderView的高度
 */
- (NSUInteger)tableHeaderViewHeightInPagerView:(FWPagerView *)pagerView;

/**
 返回tableHeaderView
 
 @param pagerView pagerView description
 @return tableHeaderView
 */
- (UIView *)tableHeaderViewInPagerView:(FWPagerView *)pagerView;

/**
 返回悬浮HeaderView的高度，因为内部需要比对判断，只能是整型数
 
 @param pagerView pagerView description
 @return 悬浮HeaderView的高度
 */
- (NSUInteger)pinSectionHeaderHeightInPagerView:(FWPagerView *)pagerView;

/**
 返回悬浮HeaderView。可以选择其他的三方库或者自己写
 
 @param pagerView pagerView description
 @return 悬浮HeaderView
 */
- (UIView *)pinSectionHeaderInPagerView:(FWPagerView *)pagerView;

/**
 返回列表的数量
 
 @param pagerView pagerView description
 @return 列表的数量
 */
- (NSInteger)numberOfListViewsInPagerView:(FWPagerView *)pagerView;

/**
 根据index初始化一个对应列表实例，需要是遵从`FWPagerViewListViewDelegate`协议的对象。
 如果列表是用自定义UIView封装的，就让自定义UIView遵从`FWPagerViewListViewDelegate`协议，该方法返回自定义UIView即可。
 如果列表是用自定义UIViewController封装的，就让自定义UIViewController遵从`FWPagerViewListViewDelegate`协议，该方法返回自定义UIViewController即可。
 注意：一定要是新生成的实例！！！
 
 @param pagerView pagerView description
 @param index index description
 @return 新生成的列表实例
 */
- (id<FWPagerViewListViewDelegate>)pagerView:(FWPagerView *)pagerView listViewAtIndex:(NSInteger)index;

@optional

/**
 mainTableView的滚动回调，用于实现头图跟随缩放
 
 @param scrollView mainTableView
 */
- (void)pagerView:(FWPagerView *)pagerView mainTableViewDidScroll:(UIScrollView *)scrollView;

/**
 滚动到指定index
 
 @param pagerView pagerView description
 @param index index description
 */
- (void)pagerView:(FWPagerView *)pagerView didScrollToIndex:(NSInteger)index;

@end

/*!
 @brief FWPagerView
 @see https://github.com/pujiaxin33/JXPagingView
 */
@interface FWPagerView : UIView
/**
 需要和self.categoryView.defaultSelectedIndex保持一致
 */
@property (nonatomic, assign) NSInteger defaultSelectedIndex;
// 可自定义shouldRecognizeSimultaneously解决手势冲突
@property (nonatomic, strong, readonly) UITableView *mainTableView;
@property (nonatomic, strong, readonly) FWPagerListContainerView *listContainerView;
/**
 当前已经加载过可用的列表字典，key就是index值，value是对应的列表。
 */
@property (nonatomic, strong, readonly) NSDictionary <NSNumber *, id<FWPagerViewListViewDelegate>> *validListDict;
/**
 顶部固定sectionHeader的垂直偏移量。数值越大越往下沉。
 */
@property (nonatomic, assign) NSInteger pinSectionHeaderVerticalOffset;
/**
 是否支持设备旋转，默认为NO
 */
@property (nonatomic, assign, getter=isDeviceOrientationChangeEnabled) BOOL deviceOrientationChangeEnabled;
/**
 是否允许列表左右滑动。默认：YES
 */
@property (nonatomic, assign, getter=isListHorizontalScrollEnabled) BOOL listHorizontalScrollEnabled;
/**
 是否允许当前列表自动显示或隐藏列表是垂直滚动指示器。YES：悬浮的headerView滚动到顶部开始滚动列表时，就会显示，反之隐藏。NO：内部不会处理列表的垂直滚动指示器。默认为：NO。
 */
@property (nonatomic, assign) BOOL automaticallyDisplayListVerticalScrollIndicator;
/**
 是否适应主tableView到目标contentInset。默认为：NO。
 */
@property (nonatomic, assign) BOOL adjustMainScrollViewToTargetContentInset;

- (instancetype)initWithDelegate:(id<FWPagerViewDelegate>)delegate NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (void)reloadData;
- (void)resizeTableHeaderViewHeightWithAnimatable:(BOOL)animatable duration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve;
// 为了不丧失延迟加载功能，请调用本方法。相邻的两个item切换时有动画，未相邻的两个item直接切换
- (void)scrollToIndex:(NSInteger)index;

@end

@interface FWPagerView (UISubclassingGet)
/**
 暴露给子类使用，请勿直接使用该属性！
 */
@property (nonatomic, strong, readonly) UIScrollView *currentScrollingListView;
/**
 暴露给子类使用，请勿直接使用该属性！
 */
@property (nonatomic, strong, readonly) id<FWPagerViewListViewDelegate> currentList;
@property (nonatomic, assign, readonly) CGFloat mainTableViewMaxContentOffsetY;
@end

@interface FWPagerView (UISubclassingHooks)
- (void)initializeViews NS_REQUIRES_SUPER;
- (void)preferredProcessListViewDidScroll:(UIScrollView *)scrollView;
- (void)preferredProcessMainTableViewDidScroll:(UIScrollView *)scrollView;
- (void)setMainTableViewToMaxContentOffsetY;
- (void)setListScrollViewToMinContentOffsetY:(UIScrollView *)scrollView;
- (CGFloat)minContentOffsetYInListScrollView:(UIScrollView *)scrollView;
@end

#pragma mark - FWPagerRefreshView

@interface FWPagerRefreshView : FWPagerView

@end
