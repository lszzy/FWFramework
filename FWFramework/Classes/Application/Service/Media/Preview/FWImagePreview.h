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

#pragma mark - FWImagePreviewView

@class FWImagePreviewView;

typedef NS_ENUM (NSUInteger, FWImagePreviewMediaType) {
    FWImagePreviewMediaTypeImage,
    FWImagePreviewMediaTypeLivePhoto,
    FWImagePreviewMediaTypeVideo,
    FWImagePreviewMediaTypeOthers
};

@protocol FWImagePreviewViewDelegate <FWZoomImageViewDelegate>

@optional
- (NSUInteger)numberOfImagesInImagePreviewView:(FWImagePreviewView *)imagePreviewView;

- (void)imagePreviewView:(FWImagePreviewView *)imagePreviewView renderZoomImageView:(FWZoomImageView *)zoomImageView atIndex:(NSUInteger)index;

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

@class FWCollectionViewPagingLayout;

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

@property(nonatomic, assign, readonly) NSUInteger imageCount;
/// 获取当前正在查看的图片 index，也可强制将图片滚动到指定的 index
@property(nonatomic, assign) NSUInteger currentImageIndex;
- (void)setCurrentImageIndex:(NSUInteger)currentImageIndex animated:(BOOL)animated;

/// 图片数组，delegate不存在时调用，支持UIImage|PHLivePhoto|AVPlayerItem|NSURL|NSString等
@property(nonatomic, copy, nullable) NSArray *imageURLs;
/// 占位图片句柄，仅imageURLs生效，默认nil
@property(nonatomic, copy, nullable) UIImage * _Nullable (^placeholderImage)(NSUInteger index);

/// 自定义zoomImageView句柄，cellForItem方法自动调用
@property(nonatomic, copy, nullable) void (^zoomImageView)(FWZoomImageView *zoomImageView, NSUInteger index);
/// 获取某个 FWZoomImageView 所对应的 index，若当前的 zoomImageView 不可见，会返回NSNotFound
- (NSInteger)indexForZoomImageView:(FWZoomImageView *)zoomImageView;
/// 获取某个 index 对应的 zoomImageView，若该 index 对应的图片当前不可见（不处于可视区域），则返回 nil
- (nullable FWZoomImageView *)zoomImageViewAtIndex:(NSUInteger)index;

@end

#pragma mark - FWImagePreviewViewController

@class FWImagePreviewTransitionAnimator;

typedef NS_ENUM(NSUInteger, FWImagePreviewTransitioningStyle) {
    /// present 时整个界面渐现，dismiss 时整个界面渐隐，默认。
    FWImagePreviewTransitioningStyleFade,
    
    /// present 时从某个指定的位置缩放到屏幕中央，dismiss 时缩放到指定位置，必须实现 sourceImageView 并返回一个非空的值
    FWImagePreviewTransitioningStyleZoom
};

extern const CGFloat FWImagePreviewCornerRadiusAutomaticDimension;

/**
 *  图片预览控件，主要功能由内部自带的 FWImagePreviewView 提供，由于以 viewController 的形式存在，所以适用于那种在单独界面里展示图片，或者需要从某张目标图片的位置以动画的形式放大进入预览界面的场景。
 *
 *  使用方式：
 *
 *  1. 使用 init 方法初始化
 *  2. 添加 self.imagePreviewView 的 delegate
 *  3. 以 push 或 present 的方式打开界面。如果是 present，则支持 FWImagePreviewTransitioningStyle 里定义的动画。特别地，如果使用 zoom 方式，则需要通过 sourceImageView() 返回一个原界面上的 view 以作为 present 动画的起点和 dismiss 动画的终点。
 */
@interface FWImagePreviewViewController : UIViewController<UIViewControllerTransitioningDelegate>

/// 图片背后的黑色背景，默认为配置表里的 UIColorBlack
@property(nullable, nonatomic, strong) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;

@property(null_resettable, nonatomic, strong, readonly) FWImagePreviewView *imagePreviewView;

/// 以 present 方式进入大图预览的时候使用的转场动画 animator，可通过 FWImagePreviewTransitionAnimator 提供的若干个 block 属性自定义动画，也可以完全重写一个自己的 animator。
@property(nullable, nonatomic, strong) __kindof FWImagePreviewTransitionAnimator *transitioningAnimator;

/// present 时的动画，默认为 fade，当修改了 presentingStyle 时会自动把 dismissingStyle 也修改为相同的值。
@property(nonatomic, assign) FWImagePreviewTransitioningStyle presentingStyle;

/// dismiss 时的动画，默认为 fade，默认与 presentingStyle 的值相同，若需要与之不同，请在设置完 presentingStyle 之后再设置 dismissingStyle。
@property(nonatomic, assign) FWImagePreviewTransitioningStyle dismissingStyle;

/// 当以 zoom 动画进入/退出大图预览时，会通过这个 block 获取到原本界面上的图片所在的 view，从而进行动画的位置计算，如果返回的值为 nil，则会强制使用 fade 动画。当同时存在 sourceImageView 和 sourceImageRect 时，只有 sourceImageRect 会被调用。
@property(nullable, nonatomic, copy) UIView * _Nullable (^sourceImageView)(void);

/// 当以 zoom 动画进入/退出大图预览时，会通过这个 block 获取到原本界面上的图片所在的 view，从而进行动画的位置计算，如果返回的值为 CGRectZero，则会强制使用 fade 动画。注意返回值要进行坐标系转换。当同时存在 sourceImageView 和 sourceImageRect 时，只有 sourceImageRect 会被调用。
@property(nullable, nonatomic, copy) CGRect (^sourceImageRect)(void);

/// 当以 zoom 动画进入/退出大图预览时，可以指定一个圆角值，默认为 FWImagePreviewCornerRadiusAutomaticDimension，也即自动从 sourceImageView.layer.cornerRadius 获取，如果使用的是 sourceImageRect 或希望自定义圆角值，则直接给 sourceImageCornerRadius 赋值即可。
@property(nonatomic, assign) CGFloat sourceImageCornerRadius;

/// 是否支持手势拖拽退出预览模式，默认为 YES。仅对以 present 方式进入大图预览的场景有效。
@property(nonatomic, assign) BOOL dismissingGestureEnabled;

/// 手势单击时是否退出预览模式，默认NO。如果正在播放视频，单击会先暂停，再点击一次才会退出。
@property(nonatomic, assign) BOOL dismissingWhenTapped;

/// 是否显示页数标签，默认NO
@property(nonatomic, assign) BOOL showsPageLabel;
/// 页数标签中心垂直偏移，默认0，位于底部20+安全距离
@property(nonatomic, assign) CGFloat pageLabelOffset;
/// 页数标签，默认字号16、白色
@property(nonatomic, strong, readonly) UILabel *pageLabel;

@end

#pragma mark - FWImagePreviewTransitionAnimator

/**
 负责处理 FWImagePreviewViewController 被 present/dismiss 时的动画，如果需要自定义动画效果，可按需修改 animationEnteringBlock、animationBlock、animationCompletionBlock。
 */
@interface FWImagePreviewTransitionAnimator : NSObject<UIViewControllerAnimatedTransitioning>

/// 当前图片预览控件的引用，在为 FWImagePreviewViewController.transitioningAnimator 赋值时会自动建立这个引用关系
@property(nonatomic, weak, nullable) FWImagePreviewViewController *imagePreviewViewController;

/// 转场动画的持续时长，默认为 0.25
@property(nonatomic, assign) NSTimeInterval duration;

/// 当 sourceImageView 本身带圆角时，动画过程中会通过这个 layer 来处理圆角的动画
@property(nonatomic, strong, readonly) CALayer *cornerRadiusMaskLayer;

/**
 动画开始前的准备工作可以在这里做
 
 @param animator 当前的动画器 animator
 @param isPresenting YES 表示当前正在 present，NO 表示正在 dismiss
 @param style 当前动画的样式
 @param sourceImageRect 原界面上显示图片的 view 在 imagePreviewViewController.view 坐标系里的 rect，仅在 style 为 zoom 时有值，style 为 fade 时为 CGRectZero
 @param zoomImageView 当前图片
 @param transitionContext 转场动画的上下文，可通过它获取前后界面、动画容器等信息
 */
@property(nonatomic, copy, nullable) void (^animationEnteringBlock)(__kindof FWImagePreviewTransitionAnimator *animator, BOOL isPresenting, FWImagePreviewTransitioningStyle style, CGRect sourceImageRect, FWZoomImageView *zoomImageView, id<UIViewControllerContextTransitioning> _Nullable transitionContext);

/**
 转场时的实际动画内容，整个 block 会在一个 UIView animation block 里被调用，因此直接写动画内容即可，无需包裹一个 animation block
 
 @param animator 当前的动画器 animator
 @param isPresenting YES 表示当前正在 present，NO 表示正在 dismiss
 @param style 当前动画的样式
 @param sourceImageRect 原界面上显示图片的 view 在 imagePreviewViewController.view 坐标系里的 rect，仅在 style 为 zoom 时有值，style 为 fade 时为 CGRectZero
 @param zoomImageView 当前图片
 @param transitionContext 转场动画的上下文，可通过它获取前后界面、动画容器等信息
 */
@property(nonatomic, copy, nullable) void (^animationBlock)(__kindof FWImagePreviewTransitionAnimator *animator, BOOL isPresenting, FWImagePreviewTransitioningStyle style, CGRect sourceImageRect, FWZoomImageView *zoomImageView, id<UIViewControllerContextTransitioning> _Nullable transitionContext);

/**
 动画结束后的事情，在执行完这个 block 后才会调用 [transitionContext completeTransition:]
 
 @param animator 当前的动画器 animator
 @param isPresenting YES 表示当前正在 present，NO 表示正在 dismiss
 @param style 当前动画的样式
 @param sourceImageRect 原界面上显示图片的 view 在 imagePreviewViewController.view 坐标系里的 rect，仅在 style 为 zoom 时有值，style 为 fade 时为 CGRectZero
 @param zoomImageView 当前图片
 @param transitionContext 转场动画的上下文，可通过它获取前后界面、动画容器等信息
 */
@property(nonatomic, copy, nullable) void (^animationCompletionBlock)(__kindof FWImagePreviewTransitionAnimator *animator, BOOL isPresenting, FWImagePreviewTransitioningStyle style, CGRect sourceImageRect, FWZoomImageView *zoomImageView, id<UIViewControllerContextTransitioning> _Nullable transitionContext);

@end

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