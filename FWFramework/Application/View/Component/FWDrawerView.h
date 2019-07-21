/*!
 @header     FWDrawerView.h
 @indexgroup FWFramework
 @brief      FWDrawerView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/7/20
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWDrawerView

/*!
 @brief 抽屉视图位置枚举
 */
typedef NS_ENUM(NSInteger, FWDrawerViewPosition) {
    // 不显示
    FWDrawerViewPositionClosed = 0,
    // 折叠，显示很小部分
    FWDrawerViewPositionCollapsed,
    // 部分打开，显示部分
    FWDrawerViewPositionPartiallyOpen,
    // 完全打开，显示全部
    FWDrawerViewPositionOpen,
};

@class FWDrawerView;

/*!
 @brief 抽屉视图事件代理
 */
@protocol FWDrawerViewDelegate <NSObject>

@optional

// 抽屉将要从一个位置到另一个位置
- (void)drawerView:(FWDrawerView *)drawerView willTransitionFrom:(FWDrawerViewPosition)startPosition to:(FWDrawerViewPosition)targetPosition;

// 抽屉转换到另一个位置
- (void)drawerView:(FWDrawerView *)drawerView didTransitionTo:(FWDrawerViewPosition)position;

// 抽屉移动到某个偏移
- (void)drawerView:(FWDrawerView *)drawerView didMoveTo:(CGFloat)drawerOffset;

// 抽屉将要开始拖动
- (void)drawerViewWillBeginDragging:(FWDrawerView *)drawerView;

// 抽屉将要结束拖动
- (void)drawerViewWillEndDragging:(FWDrawerView *)drawerView;

@end

/*!
 @brief 抽屉视图
 
 @see https://github.com/mkko/DrawerView
 */
@interface FWDrawerView : UIView <UIGestureRecognizerDelegate>

// 设置事件代理，支持可视化设置
@property (nonatomic, weak, nullable) IBOutlet id<FWDrawerViewDelegate> delegate;

// 抽屉完整显示时离顶部的距离，默认0
@property (nonatomic, assign) CGFloat topMargin;

// 抽屉折叠时的高度，默认TabBar高度
@property (nonatomic, assign) CGFloat collapsedHeight;

// 抽屉部分打开时的高度，默认屏幕高度的1/3
@property (nonatomic, assign) CGFloat partiallyOpenHeight;

// 抽屉的当前位置，默认Collapsed
@property (nonatomic, assign) FWDrawerViewPosition position;

// 自定义抽屉的折叠位置列表，自动从小到大排序，默认[Collapsed|PartiallyOpen|Open]
@property (nonatomic, copy) NSArray<NSNumber *> *snapPositions;

// 快速设置容器视图，内部会调用attachTo:，支持可视化设置
@property (nonatomic, weak, nullable) IBOutlet UIView *containerView;

// 快速设置嵌入视图，支持可视化设置
@property (nonatomic, weak, nullable) IBOutlet UIView *embedView;

// 抽屉效果是否启用，默认YES
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

// 设置隐蔽状态，默认NO
@property (nonatomic, assign, getter=isConcealed) BOOL concealed;

// 获取抽屉偏移offset，从底部向上计算
@property (nonatomic, assign, readonly) CGFloat drawerOffset;

// 初始化，可设置嵌入视图
- (instancetype)initWithEmbedView:(nullable UIView *)embedView;

// 关联到容器视图
- (void)attachTo:(UIView *)containerView;

// 动画方式指定抽屉位置
- (void)setPosition:(FWDrawerViewPosition)position animated:(BOOL)animated;

// 动画方式设置隐蔽状态
- (void)setConcealed:(BOOL)concealed animated:(BOOL)animated;

// 动画方式从父视图移除
- (void)removeFromSuperviewAnimated:(BOOL)animated;

// 获取当前位置步进后的位置，找不到时返回NSNotFound
- (FWDrawerViewPosition)getPositionWithStep:(NSInteger)step;

// 获取指定位置的偏移offset值
- (CGFloat)drawerOffsetWithPosition:(FWDrawerViewPosition)position;

@end

#pragma mark - UIViewController+FWDrawerView

/*!
 @brief UIViewController+FWDrawerView
 */
@interface UIViewController (FWDrawerView)

// 添加抽屉控制器到self.view
- (FWDrawerView *)fwAddDrawerViewController:(UIViewController *)viewController;

// 添加抽屉控制器到指定视图，nil时为self.view
- (FWDrawerView *)fwAddDrawerViewController:(UIViewController *)viewController toView:(nullable UIView *)parentView;

@end

NS_ASSUME_NONNULL_END
