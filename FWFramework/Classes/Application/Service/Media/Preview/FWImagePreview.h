/*!
 @header     FWImagePreview.h
 @indexgroup FWFramework
 @brief      FWImagePreview
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <UIKit/UIKit.h>
#import "FWZoomImageView.h"

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

#pragma mark - FWImagePreviewView

@class FWImagePreviewView;

typedef NS_ENUM (NSUInteger, FWImagePreviewMediaType) {
    FWImagePreviewMediaTypeImage,
    FWImagePreviewMediaTypeLivePhoto,
    FWImagePreviewMediaTypeVideo,
    FWImagePreviewMediaTypeOthers
};

@protocol FWImagePreviewViewDelegate <FWZoomImageViewDelegate>

@required
- (NSUInteger)numberOfImagesInImagePreviewView:(FWImagePreviewView *)imagePreviewView;
- (void)imagePreviewView:(FWImagePreviewView *)imagePreviewView renderZoomImageView:(FWZoomImageView *)zoomImageView atIndex:(NSUInteger)index;

@optional
// 返回要展示的媒体资源的类型（图片、live photo、视频），如果不实现此方法，则 FWImagePreviewView 将无法选择最合适的 cell 来复用从而略微增大系统开销
- (FWImagePreviewMediaType)imagePreviewView:(FWImagePreviewView *)imagePreviewView assetTypeAtIndex:(NSUInteger)index;

/**
 *  当左右的滚动停止时会触发这个方法
 *  @param  imagePreviewView 当前预览的 FWImagePreviewView
 *  @param  index 当前滚动到的图片所在的索引
 */
- (void)imagePreviewView:(FWImagePreviewView *)imagePreviewView didScrollToIndex:(NSUInteger)index;

/**
 *  在滚动过程中，如果某一张图片的边缘（左/右）经过预览控件的中心点时，就会触发这个方法
 *  @param  imagePreviewView 当前预览的 FWImagePreviewView
 *  @param  index 当前滚动到的图片所在的索引
 */
- (void)imagePreviewView:(FWImagePreviewView *)imagePreviewView willScrollHalfToIndex:(NSUInteger)index;

@end

/**
 *  查看图片的控件，支持横向滚动、放大缩小、loading 及错误语展示，内部使用 UICollectionView 实现横向滚动及 cell 复用，因此与其他普通的 UICollectionView 一样，也可使用 reloadData、collectionViewLayout 等常用方法。
 *
 *  使用方式：
 *
 *  1. 使用 initWithFrame: 或 init 方法初始化。
 *  2. 设置 delegate。
 *  3. 在 delegate 的 numberOfImagesInImagePreviewView: 方法里返回图片总数。
 *  4. 在 delegate 的 imagePreviewView:renderZoomImageView:atIndex: 方法里为 zoomImageView.image 设置图片，如果需要，也可调用 [zoomImageView showLoading] 等方法来显示 loading。
 *  5. 由于 FWImagePreviewViewDelegate 继承自 FWZoomImageViewDelegate，所以若需要响应单击、双击、长按事件，请实现 FWZoomImageViewDelegate 里的对应方法。
 *  6. 若需要从指定的某一张图片开始查看，可使用 currentImageIndex 属性。
 *
 *  @see https://github.com/Tencent/QMUI_iOS
 */
@interface FWImagePreviewView : UIView<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, FWZoomImageViewDelegate>

@property(nonatomic, weak, nullable) id<FWImagePreviewViewDelegate> delegate;
@property(nonatomic, strong, readonly) UICollectionView *collectionView;
@property(nonatomic, strong, readonly) FWCollectionViewPagingLayout *collectionViewLayout;

/// 获取当前正在查看的图片 index，也可强制将图片滚动到指定的 index
@property(nonatomic, assign) NSUInteger currentImageIndex;
- (void)setCurrentImageIndex:(NSUInteger)currentImageIndex animated:(BOOL)animated;

/// 每一页里的 loading 的颜色，默认为 UIColorWhite
@property(nonatomic, strong) UIColor *loadingColor;

/**
 *  获取某个 FWZoomImageView 所对应的 index
 *  @return zoomImageView 对应的 index，若当前的 zoomImageView 不可见，会返回 0
 */
- (NSInteger)indexForZoomImageView:(FWZoomImageView *)zoomImageView;

/**
 *  获取某个 index 对应的 zoomImageView
 *  @return 指定的 index 所在的 zoomImageView，若该 index 对应的图片当前不可见（不处于可视区域），则返回 nil
 */
- (FWZoomImageView *)zoomImageViewAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
