/*!
 @header     FWImagePreview.h
 @indexgroup FWFramework
 @brief      FWImagePreview
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWCollectionViewPagingLayout

/// 分页横向滚动布局样式枚举
typedef NS_ENUM(NSInteger, FWCollectionViewPagingLayoutStyle) {
    /// 普通模式，水平滑动
    FWCollectionViewPagingLayoutStyleDefault,
    /// 缩放模式，两边的item会小一点，逐渐向中间放大
    FWCollectionViewPagingLayoutStyleScale,
};

/**
 *  支持按页横向滚动的 UICollectionViewLayout，可切换不同类型的滚动动画。
 *
 *  @warning item 的大小和布局仅支持通过 UICollectionViewFlowLayout 的 property 系列属性修改，也即每个 item 都应相等。对于通过 delegate 方式返回各不相同的 itemSize、sectionInset 的场景是不支持的。
 */
@interface FWCollectionViewPagingLayout : UICollectionViewFlowLayout

- (instancetype)initWithStyle:(FWCollectionViewPagingLayoutStyle)style NS_DESIGNATED_INITIALIZER;

@property(nonatomic, assign, readonly) FWCollectionViewPagingLayoutStyle style;

/**
 *  规定超过这个滚动速度就强制翻页，从而使翻页更容易触发。默认为 0.4
 */
@property(nonatomic, assign) CGFloat velocityForEnsurePageDown;

/**
 *  是否支持一次滑动可以滚动多个 item，默认为 YES
 */
@property(nonatomic, assign) BOOL allowsMultipleItemScroll;

/**
 *  规定了当支持一次滑动允许滚动多个 item 的时候，滑动速度要达到多少才会滚动多个 item，默认为 2.5
 *
 *  仅当 allowsMultipleItemScroll 为 YES 时生效
 */
@property(nonatomic, assign) CGFloat multipleItemScrollVelocityLimit;

/// 当前 cell 的百分之多少滚过临界点时就会触发滚到下一张的动作，默认为 .666，也即超过 2/3 即会滚到下一张。
/// 对应地，触发滚到上一张的临界点将会被设置为 (1 - pagingThreshold)
@property(nonatomic, assign) CGFloat pagingThreshold;

/**
 *  中间那张卡片基于初始大小的缩放倍数，默认为 1.0
 */
@property(nonatomic, assign) CGFloat maximumScale;

/**
 *  除了中间之外的其他卡片基于初始大小的缩放倍数，默认为 0.9
 */
@property(nonatomic, assign) CGFloat minimumScale;

@end

NS_ASSUME_NONNULL_END
