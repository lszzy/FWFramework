//
//  UIScrollView+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollView+FWContentView.h"
#import "UIScrollView+FWEmptyView.h"

NS_ASSUME_NONNULL_BEGIN

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

// 总页数，自动识别翻页方向
@property (nonatomic, assign, readonly) NSInteger fwTotalPage;

// 当前页数，不支持动画，自动识别翻页方向
@property (nonatomic, assign) NSInteger fwCurrentPage;

// 设置当前页数，支持动画，自动识别翻页方向
- (void)fwSetCurrentPage:(NSInteger)page animated:(BOOL)animated;

// 是否是最后一页，自动识别翻页方向
@property (nonatomic, assign, readonly) BOOL fwIsLastPage;

#pragma mark - Scroll

// 判断当前的scrollView内容是否足够水平滚动
@property (nonatomic, assign, readonly) BOOL fwCanScrollHorizontal;

// 判断当前的scrollView内容是否足够纵向滚动
@property (nonatomic, assign, readonly) BOOL fwCanScrollVertical;

// 是否已滚动到指定边
- (BOOL)fwIsScrollToEdge:(UIRectEdge)edge;

// 滚动到指定边
- (void)fwScrollToEdge:(UIRectEdge)edge animated:(BOOL)animated;

// 获取当前的scrollView滚动到指定边时的contentOffset(包含contentInset)
- (CGPoint)fwContentOffsetOfEdge:(UIRectEdge)edge;

// 当前滚动方向，如果多个方向滚动，取绝对值较大的一方，失败返回0
@property (nonatomic, assign, readonly) UISwipeGestureRecognizerDirection fwScrollDirection;

// 当前滚动进度，滚动绝对值相对于当前视图的宽或高
@property (nonatomic, assign, readonly) CGFloat fwScrollPercent;

// 计算指定方向的滚动进度
- (CGFloat)fwScrollPercentOfDirection:(UISwipeGestureRecognizerDirection)direction;

#pragma mark - Content

// 单独禁用内边距适应，同上。如果iOS7-10的ScrollView占不满导航栏，需设置viewController.automaticallyAdjustsScrollViewInsets为NO即可。另外appearance设置时会影响到系统控制器如UIImagePickerController等
- (void)fwContentInsetAdjustmentNever UI_APPEARANCE_SELECTOR;

#pragma mark - Keyboard

// 是否滚动时收起键盘，默认NO
@property (nonatomic, assign) BOOL fwKeyboardDismissOnDrag UI_APPEARANCE_SELECTOR;

#pragma mark - Gesture

// 是否开始识别pan手势
@property (nullable, nonatomic, copy) BOOL (^fwShouldBegin)(UIGestureRecognizer *gestureRecognizer);

// 是否允许同时识别多个手势
@property (nullable, nonatomic, copy) BOOL (^fwShouldRecognizeSimultaneously)(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer);

// 是否另一个手势识别失败后，才能识别pan手势
@property (nullable, nonatomic, copy) BOOL (^fwShouldRequireFailure)(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer);

// 是否pan手势识别失败后，才能识别另一个手势
@property (nullable, nonatomic, copy) BOOL (^fwShouldBeRequiredToFail)(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer);

#pragma mark - Hover

/*!
 @brief 设置自动布局视图悬停到指定父视图固定位置，在scrollViewDidScroll:中调用即可
 
 @param view 需要悬停的视图，须占满fromSuperview
 @param fromSuperview 起始的父视图，须是scrollView的子视图
 @param toSuperview 悬停的目标视图，须是scrollView的父级视图，一般控制器self.view
 @param toPosition 需要悬停的目标位置，相对于toSuperview的originY位置
 @return 相对于悬浮位置的距离，可用来设置导航栏透明度等
 */
- (CGFloat)fwHoverView:(UIView *)view
         fromSuperview:(UIView *)fromSuperview
           toSuperview:(UIView *)toSuperview
            toPosition:(CGFloat)toPosition;

@end

NS_ASSUME_NONNULL_END
