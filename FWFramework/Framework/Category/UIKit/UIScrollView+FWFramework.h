//
//  UIScrollView+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollView+FWEmptyView.h"
#import "UIScrollView+FWInfiniteScroll.h"
#import "UIScrollView+FWPullRefresh.h"

/*!
 @brief UIScrollView分类
 @discussion 添加顶部下拉图片时，只需将该子view添加到scrollView最底层(如frame方式添加inset视图)，再实现效果即可。
 */
@interface UIScrollView (FWFramework)

#pragma mark - Frame

// UIScrollView的真正inset，在iOS11以后需要用到adjustedContentInset而在iOS11以前只需要用contentInset
@property (nonatomic, assign, readonly) UIEdgeInsets fwContentInset;

// contentSize.width
@property (nonatomic, assign) CGFloat fwContentWidth;

// contentSize.height
@property (nonatomic, assign) CGFloat fwContentHeight;

// contentOffset.x
@property (nonatomic, assign) CGFloat fwContentOffsetX;

// contentOffset.y
@property (nonatomic, assign) CGFloat fwContentOffsetY;

#pragma mark - Page

// 总页数
- (NSInteger)fwTotalPage;

// 当前页数
- (NSInteger)fwCurrentPage;

// 设置当前页数
- (void)fwSetCurrentPage:(NSInteger)page;

// 设置当前页数，支持动画
- (void)fwSetCurrentPage:(NSInteger)page animated:(BOOL)animated;

// 是否是最后一页
- (BOOL)fwIsLastPage;

#pragma mark - Scroll

// 判断当前的scrollView内容是否足够滚动
- (BOOL)fwCanScroll;

// 是否已滚动到指定边
- (BOOL)fwIsScrollToEdge:(UIRectEdge)edge;

// 滚动到指定边
- (void)fwScrollToEdge:(UIRectEdge)edge animated:(BOOL)animated;

// 当前滚动方向，失败返回0
- (UISwipeGestureRecognizerDirection)fwScrollDirection;

#pragma mark - Content

// 全体禁用内边距适应(iOS11默认启用后，会导致显示不正常)
+ (void)fwContentInsetNever;

// 单独禁用内边距适应，同上。如果iOS7-10的ScrollView占不满导航栏，需设置viewController.automaticallyAdjustsScrollViewInsets为NO即可
- (void)fwContentInsetNever;

#pragma mark - Keyboard

// 是否滚动时收起键盘，默认NO
@property (nonatomic, assign) BOOL fwDismissKeyboardOnDrag;

#pragma mark - Gesture

// 是否允许同时识别多个手势
@property (nonatomic, copy) BOOL (^fwShouldRecognizeSimultaneously)(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer);

#pragma mark - Hover

/*!
 @brief 设置自动布局视图悬停到指定父视图固定位置，在scrollViewDidScroll:中调用即可
 
 @param view 需要悬停的视图，必须占满fromSuperview
 @param fromSuperview 起始父视图，view铺满的容器
 @param toSuperview 悬停的目标视图，一般控制器self.view
 @param fromPosition 相对于toSuperview的起始originY位置
 @param toPosition 相对于toSuperview的目标originY位置
 @return 悬停进度。1:开始悬停;0:停止悬停;0-1:悬停动画;-1非悬停。可用来设置导航栏透明度等
 */
- (CGFloat)fwHoverView:(UIView *)view
         fromSuperview:(UIView *)fromSuperview
           toSuperview:(UIView *)toSuperview
          fromPosition:(CGFloat)fromPosition
            toPosition:(CGFloat)toPosition;

@end
