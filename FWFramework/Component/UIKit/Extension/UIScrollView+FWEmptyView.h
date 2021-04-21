/*!
 @header     UIScrollView+FWEmptyView.h
 @indexgroup FWFramework
 @brief      UIScrollView+FWEmptyView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FWEmptyViewDataSource;
@protocol FWEmptyViewDelegate;

/**
 A drop-in UITableView/UICollectionView superclass category for showing empty datasets whenever the view has no content to display.
 @discussion It will work automatically, by just conforming to FWEmptyViewDataSource, and returning the data you want to show.
 
 @see https://github.com/dzenbot/DZNEmptyView
 */
@interface UIScrollView (FWEmptyView)

/** The empty datasets data source. */
@property (nonatomic, weak, nullable) IBOutlet id <FWEmptyViewDataSource> fwEmptyViewDataSource;
/** The empty datasets delegate. */
@property (nonatomic, weak, nullable) IBOutlet id <FWEmptyViewDelegate> fwEmptyViewDelegate;
/** YES if any empty dataset is visible. */
@property (nonatomic, readonly) BOOL fwEmptyViewVisible;

/**
 Reloads the empty dataset content receiver.
 @discussion Call this method to force all the data to refresh. Calling -reloadData is similar, but this forces only the empty dataset to reload, not the entire table view or collection view.
 */
- (void)fwReloadEmptyView;

@end


/**
 The object that acts as the data source of the empty datasets.
 @discussion The data source must adopt the FWEmptyViewDataSource protocol. The data source is not retained. All data source methods are optional.
 */
@protocol FWEmptyViewDataSource <NSObject>
@optional

- (void)fwShowEmptyView:(UIView *)contentView scrollView:(UIScrollView *)scrollView;

- (void)fwHideEmptyView:(UIView *)contentView scrollView:(UIScrollView *)scrollView;

@end


/**
 The object that acts as the delegate of the empty datasets.
 @discussion The delegate can adopt the FWEmptyViewDelegate protocol. The delegate is not retained. All delegate methods are optional.
 
 @discussion All delegate methods are optional. Use this delegate for receiving action callbacks.
 */
@protocol FWEmptyViewDelegate <NSObject>
@optional

/**
 Asks the delegate to know if the empty dataset should still be displayed when the amount of items is more than 0. Default is NO
 
 @param scrollView A scrollView subclass object informing the delegate.
 @return YES if empty dataset should be forced to display
 */
- (BOOL)fwEmptyViewShouldBeForcedToDisplay:(UIScrollView *)scrollView;

/**
 Asks the delegate to know if the empty dataset should be rendered and displayed. Default is YES.
 
 @param scrollView A scrollView subclass object informing the delegate.
 @return YES if the empty dataset should show.
 */
- (BOOL)fwEmptyViewShouldDisplay:(UIScrollView *)scrollView;

/**
 Asks the delegate for scroll permission. Default is NO.
 
 @param scrollView A scrollView subclass object informing the delegate.
 @return YES if the empty dataset is allowed to be scrollable.
 */
- (BOOL)fwEmptyViewShouldAllowScroll:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
