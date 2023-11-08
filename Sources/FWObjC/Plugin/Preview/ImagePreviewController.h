//
//  ImagePreviewController.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWImagePreviewView

/**
 *  查看图片的控件，支持横向滚动、放大缩小、loading 及错误语展示，内部使用 UICollectionView 实现横向滚动及 cell 复用，因此与其他普通的 UICollectionView 一样，也可使用 reloadData、collectionViewLayout 等常用方法。
 *
 *  使用方式：
 *
 *  1. 使用 initWithFrame: 或 init 方法初始化。
 *  2. 设置 delegate。
 *  3. 在 delegate 的 numberOfImagesInImagePreviewView: 方法里返回图片总数。
 *  4. 在 delegate 的 imagePreviewView:renderZoomImageView:atIndex: 方法里为 zoomImageView.image 设置图片，如果需要，也可调用 [zoomImageView showLoading] 等方法来显示 loading。
 *  5. 由于 __FWImagePreviewViewDelegate 继承自 __FWZoomImageViewDelegate，所以若需要响应单击、双击、长按事件，请实现 __FWZoomImageViewDelegate 里的对应方法。
 *  6. 若需要从指定的某一张图片开始查看，可使用 currentImageIndex 属性。
 *
 *  @see https://github.com/Tencent/QMUI_iOS
 */
NS_SWIFT_NAME(ImagePreviewView)
@interface __FWImagePreviewView : UIView<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, __FWZoomImageViewDelegate>

@property(nonatomic, weak, nullable) id<__FWImagePreviewViewDelegate> delegate;
@property(nonatomic, strong, readonly) UICollectionView *collectionView;
@property(nonatomic, strong, readonly) __FWCollectionViewPagingLayout *collectionViewLayout;

@property(nonatomic, assign, readonly) NSInteger imageCount;
/// 获取当前正在查看的图片 index，也可强制将图片滚动到指定的 index
@property(nonatomic, assign) NSInteger currentImageIndex;
- (void)setCurrentImageIndex:(NSInteger)currentImageIndex animated:(BOOL)animated;

/// 图片数组，delegate不存在时调用，支持UIImage|PHLivePhoto|AVPlayerItem|NSURL|NSString等
@property(nonatomic, copy, nullable) NSArray *imageURLs;
/// 自定义图片信息数组，默认未使用，可用于自定义内容展示，默认nil
@property(nonatomic, copy, nullable) NSArray *imageInfos;
/// 占位图片句柄，仅imageURLs生效，默认nil
@property(nonatomic, copy, nullable) UIImage * _Nullable (^placeholderImage)(NSInteger index);
/// 是否自动播放video，默认NO
@property(nonatomic, assign) BOOL autoplayVideo;

/// 自定义zoomImageView样式句柄，cellForItem方法自动调用，先于renderZoomImageView
@property(nonatomic, copy, nullable) void (^customZoomImageView)(__FWZoomImageView *zoomImageView, NSInteger index);
/// 自定义渲染zoomImageView句柄，cellForItem方法自动调用，优先级低于delegate
@property(nonatomic, copy, nullable) void (^renderZoomImageView)(__FWZoomImageView *zoomImageView, NSInteger index);
/// 自定义内容视图句柄，内容显示完成自动调用，优先级低于delegate
@property(nonatomic, copy, nullable) void (^customZoomContentView)(__FWZoomImageView *zoomImageView, __kindof UIView *contentView);
/// 获取当前正在查看的zoomImageView，若当前 index 对应的图片不可见（不处于可视区域），则返回 nil
@property(nonatomic, weak, nullable, readonly) __FWZoomImageView *currentZoomImageView;
/// 获取某个 __FWZoomImageView 所对应的 index，若当前的 zoomImageView 不可见，会返回NSNotFound
- (NSInteger)indexForZoomImageView:(__FWZoomImageView *)zoomImageView;
/// 获取某个 index 对应的 zoomImageView，若该 index 对应的图片当前不可见（不处于可视区域），则返回 nil
- (nullable __FWZoomImageView *)zoomImageViewAtIndex:(NSInteger)index;

@end

#pragma mark - __FWImagePreviewController

@class __FWImagePreviewTransitionAnimator;

typedef NS_ENUM(NSUInteger, __FWImagePreviewTransitioningStyle) {
    /// present 时整个界面渐现，dismiss 时整个界面渐隐，默认。
    __FWImagePreviewTransitioningStyleFade,
    
    /// present 时从某个指定的位置缩放到屏幕中央，dismiss 时缩放到指定位置，必须实现 sourceImageView 并返回一个非空的值
    __FWImagePreviewTransitioningStyleZoom
} NS_SWIFT_NAME(ImagePreviewTransitioningStyle);

extern const CGFloat __FWImagePreviewCornerRadiusAutomaticDimension NS_SWIFT_NAME(ImagePreviewCornerRadiusAutomaticDimension);

/**
 *  图片预览控件，主要功能由内部自带的 __FWImagePreviewView 提供，由于以 viewController 的形式存在，所以适用于那种在单独界面里展示图片，或者需要从某张目标图片的位置以动画的形式放大进入预览界面的场景。
 *
 *  使用方式：
 *
 *  1. 使用 init 方法初始化
 *  2. 添加 self.imagePreviewView 的 delegate
 *  3. 以 push 或 present 的方式打开界面。如果是 present，则支持 __FWImagePreviewTransitioningStyle 里定义的动画。特别地，如果使用 zoom 方式，则需要通过 sourceImageView() 返回一个原界面上的 view 以作为 present 动画的起点和 dismiss 动画的终点。
 */
NS_SWIFT_NAME(ImagePreviewController)
@interface __FWImagePreviewController : UIViewController<UIViewControllerTransitioningDelegate>

/// 图片背后的黑色背景，默认为配置表里的 UIColorBlack
@property(nullable, nonatomic, strong) UIColor *backgroundColor;

@property(null_resettable, nonatomic, strong, readonly) __FWImagePreviewView *imagePreviewView;

/// 以 present 方式进入大图预览的时候使用的转场动画 animator，可通过 __FWImagePreviewTransitionAnimator 提供的若干个 block 属性自定义动画，也可以完全重写一个自己的 animator。
@property(nullable, nonatomic, strong) __kindof __FWImagePreviewTransitionAnimator *transitioningAnimator;

/// present 时的动画，默认为 fade，当修改了 presentingStyle 时会自动把 dismissingStyle 也修改为相同的值。
@property(nonatomic, assign) __FWImagePreviewTransitioningStyle presentingStyle;

/// dismiss 时的动画，默认为 fade，默认与 presentingStyle 的值相同，若需要与之不同，请在设置完 presentingStyle 之后再设置 dismissingStyle。
@property(nonatomic, assign) __FWImagePreviewTransitioningStyle dismissingStyle;

/// 当以 zoom 动画进入/退出大图预览时，会通过这个 block 获取到原本界面上的图片所在的 view，从而进行动画的位置计算，如果返回的值为 nil，则会强制使用 fade 动画。当同时存在 sourceImageView 和 sourceImageRect 时，只有 sourceImageRect 会被调用。支持UIView|NSValue.CGRect类型
@property(nullable, nonatomic, copy) id _Nullable (^sourceImageView)(NSInteger index);

/// 当以 zoom 动画进入/退出大图预览时，会通过这个 block 获取到原本界面上的图片所在的 view，从而进行动画的位置计算，如果返回的值为 CGRectZero，则会强制使用 fade 动画。注意返回值要进行坐标系转换。当同时存在 sourceImageView 和 sourceImageRect 时，只有 sourceImageRect 会被调用。
@property(nullable, nonatomic, copy) CGRect (^sourceImageRect)(NSInteger index);

/// 当以 zoom 动画进入/退出大图预览时，可以指定一个圆角值，默认为 __FWImagePreviewCornerRadiusAutomaticDimension，也即自动从 sourceImageView.layer.cornerRadius 获取，如果使用的是 sourceImageRect 或希望自定义圆角值，则直接给 sourceImageCornerRadius 赋值即可。
@property(nonatomic, assign) CGFloat sourceImageCornerRadius;

/// 手势拖拽退出预览模式时是否启用缩放效果，默认YES。仅对以 present 方式进入大图预览的场景有效。
@property(nonatomic, assign) BOOL dismissingScaleEnabled;

/// 是否支持手势拖拽退出预览模式，默认为 YES。仅对以 present 方式进入大图预览的场景有效。
@property(nonatomic, assign) BOOL dismissingGestureEnabled;

/// 手势单击图片时是否退出预览模式，默认NO。仅对以 present 方式进入大图预览的场景有效。
@property(nonatomic, assign) BOOL dismissingWhenTappedImage;

/// 手势单击视频时是否退出预览模式，默认NO。仅对以 present 方式进入大图预览的场景有效。
@property(nonatomic, assign) BOOL dismissingWhenTappedVideo;

/// 当前页数发生变化回调，默认nil
@property(nonatomic, copy, nullable) void (^pageIndexChanged)(NSInteger index);
/// 是否显示页数标签，默认NO
@property(nonatomic, assign) BOOL showsPageLabel;
/// 页数标签，默认字号16、白色
@property(nonatomic, strong, readonly) UILabel *pageLabel;
/// 页数标签中心句柄，默认nil时离底部安全距离+18
@property(nonatomic, copy, nullable) CGPoint (^pageLabelCenter)(void);
/// 页数文本句柄，默认nil时为index / count
@property(nonatomic, copy, nullable) NSString * (^pageLabelText)(NSInteger index, NSInteger count);

/// 页数标签需要更新，子类可重写
- (void)updatePageLabel;

/// 处理单击关闭事件，子类可重写
- (void)dismissingWhenTapped:(__FWZoomImageView *)zoomImageView;
/// 触发拖动手势或dismiss时切换子视图显示或隐藏，子类可重写
- (void)dismissingGestureChanged:(BOOL)isHidden;

@end

NS_ASSUME_NONNULL_END
