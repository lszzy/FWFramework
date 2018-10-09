//
//  UIScrollView+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief UIScrollView分类
 @discussion 添加顶部下拉图片时，只需将该子view添加到scrollView最底层(如frame方式添加inset视图)，再实现效果即可。
 */
@interface UIScrollView (FWFramework)

#pragma mark - Frame

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

// 滚动到指定边
- (void)fwScrollToEdge:(UIRectEdge)edge animated:(BOOL)animated;

// 当前滚动方向
- (UIRectEdge)fwScrollEdge;

#pragma mark - Content

// 全体禁用内边距适应(iOS11默认启用后，会导致显示不正常)
+ (void)fwContentInsetNever;

// 单独禁用内边距适应，同上。如果iOS7-10的ScrollView占不满导航栏，需设置viewController.automaticallyAdjustsScrollViewInsets为NO即可
- (void)fwContentInsetNever;

@end
