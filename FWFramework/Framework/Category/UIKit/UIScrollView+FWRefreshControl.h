/*!
 @header     UIScrollView+FWRefreshControl.h
 @indexgroup FWFramework
 @brief      UIScrollView+FWRefreshControl
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/13
 */

#import <UIKit/UIKit.h>

/*!
 @brief UIScrollView+FWRefreshControl
 @discussion 滚动视图上下刷新，下拉加载系统分类。备注：iOS10原生支持，iOS10之前对UITableView更友好
 */
@interface UIScrollView (FWRefreshControl)

#pragma mark - UIRefreshControl

// 设置上拉刷新控件，上拉时发送UIControlEventValueChanged事件。注意：一般后台线程异步请求数据，再主线程刷新界面，否则会卡界面
@property (nonatomic, strong) UIRefreshControl *fwRefreshControl;

#pragma mark - PullRefresh

// 是否启用系统下拉刷新组件，添加Block后自动设为YES；设为NO禁用下拉刷新
@property (nonatomic, assign) BOOL fwCanPullRefresh;

// 是否正在下拉刷新
@property (nonatomic, readonly) BOOL fwIsPullRefresh;

// 设置下拉刷新代码块
- (void)fwSetPullRefreshBlock:(void (^)(void))block;

// 开始下拉刷新动画，触发Block，仅当Show为YES生效
- (void)fwBeginPullRefresh;

// 结束下拉刷新动画
- (void)fwEndPullRefresh;

#pragma mark - InfiniteScroll

// 是否启用系统上拉无限加载，添加Block后自动设为YES；设为NO禁用上拉加载
@property (nonatomic, assign) BOOL fwCanInfiniteScroll;

// 是否正在上拉加载
@property (nonatomic, readonly) BOOL fwIsInfiniteScroll;

// 设置上拉加载代码块
- (void)fwSetInfiniteScrollBlock:(void (^)(void))block;

// 开始上拉加载(无动画)，触发Block，仅当Show为YES生效
- (void)fwBeginInfiniteScroll;

// 结束上拉加载(无动画)
- (void)fwEndInfiniteScroll;

@end
