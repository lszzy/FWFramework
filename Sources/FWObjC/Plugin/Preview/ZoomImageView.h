//
//  ZoomImageView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

@class __FWZoomImageView;

/// __FWZoomImageView事件代理
NS_SWIFT_NAME(ZoomImageViewDelegate)
@protocol __FWZoomImageViewDelegate <NSObject>

@optional

/// 单击事件代理方法
- (void)singleTouchInZoomingImageView:(__FWZoomImageView *)zoomImageView location:(CGPoint)location;
/// 双击事件代理方法
- (void)doubleTouchInZoomingImageView:(__FWZoomImageView *)zoomImageView location:(CGPoint)location;
/// 长按事件代理方法
- (void)longPressInZoomingImageView:(__FWZoomImageView *)zoomImageView;

/// 在视频预览界面里，由于用户点击了空白区域或播放视频等导致了底部的视频工具栏被显示或隐藏
- (void)zoomImageView:(__FWZoomImageView *)imageView didHideVideoToolbar:(BOOL)didHide;

/// 自定义内容视图代理方法，contentView根据显示内容不同而不同
- (void)zoomImageView:(__FWZoomImageView *)imageView customContentView:(__kindof UIView *)contentView;

/// 是否支持缩放，默认为 YES
- (BOOL)enabledZoomViewInZoomImageView:(__FWZoomImageView *)zoomImageView;

@end

@class __FWZoomImageVideoToolbar;
@protocol __FWProgressViewPlugin;

/**
 *  支持缩放查看静态图片、live photo、视频的控件
 *  默认显示完整图片或视频，可双击查看放大后的大小，再次双击恢复到初始大小。
 *
 *  支持通过修改 contentMode 来控制静态图片和 live photo 默认的显示模式，目前仅支持 UIViewContentModeCenter、UIViewContentModeScaleAspectFill、UIViewContentModeScaleAspectFit、UIViewContentModeScaleToFill(仅宽度拉伸)，默认为 UIViewContentModeScaleAspectFit。注意这里的显示模式是基于 viewportRect 而言的而非整个 zoomImageView
 *  __FWZoomImageView 提供最基础的图片预览和缩放功能，其他功能请通过继承来实现。
 *
 *  @see https://github.com/Tencent/QMUI_iOS
 */
NS_SWIFT_NAME(ZoomImageView)
@interface __FWZoomImageView : UIView <UIScrollViewDelegate>

@property(nonatomic, weak, nullable) id<__FWZoomImageViewDelegate> delegate;

@property(nonatomic, strong, readonly) UIScrollView *scrollView;

/**
 * 比如常见的上传头像预览界面中间有一个用于裁剪的方框，则 viewportRect 必须被设置为这个方框在 zoomImageView 坐标系内的 frame，否则拖拽图片或视频时无法正确限制它们的显示范围
 * @note 图片或视频的初始位置会位于 viewportRect 正中间
 * @note 如果想要图片覆盖整个 viewportRect，将 contentMode 设置为 UIViewContentModeScaleAspectFill 即可
 * 如果设置为 CGRectZero 则表示使用默认值，默认值为和整个 zoomImageView 一样大
 */
@property(nonatomic, assign) CGRect viewportRect;

/// 最大缩放比率，默认0根据contentMode自动计算
@property(nonatomic, assign) CGFloat maximumZoomScale;

/// 最小缩率比率，默认0根据contentMode自动计算
@property(nonatomic, assign) CGFloat minimumZoomScale;

/// 自定义最大缩放比率句柄，默认nil时根据contentMode自动计算
@property(nonatomic, copy, nullable) CGFloat (^maximumZoomScaleBlock)(CGFloat scaleX, CGFloat scaleY);

/// 最定义最小缩放比率句柄，默认nil时根据contentMode自动计算
@property(nonatomic, copy, nullable) CGFloat (^minimumZoomScaleBlock)(CGFloat scaleX, CGFloat scaleY);

/// 自定义双击放大比率句柄，默认nil时直接放大到最大比率
@property(nonatomic, copy, nullable) CGFloat (^zoomInScaleBlock)(UIScrollView *scrollView);

@property(nonatomic, copy, nullable) NSObject<NSCopying> *reusedIdentifier;

/// 设置当前要显示的图片，会把 livePhoto/video 相关内容清空，因此注意不要直接通过 imageView.image 来设置图片。
@property(nonatomic, weak, nullable) UIImage *image;

/// 用于显示图片的 UIImageView，注意不要通过 imageView.image 来设置图片，请使用 image 属性。
@property(nonatomic, strong, readonly) UIImageView *imageView;

/// 设置当前要显示的 Live Photo，会把 image/video 相关内容清空，因此注意不要直接通过 livePhotoView.livePhoto 来设置
@property(nonatomic, weak, nullable) PHLivePhoto *livePhoto;

/// 用于显示 Live Photo 的 view，仅在 iOS 9.1 及以后才有效
@property(nonatomic, strong, readonly) PHLivePhotoView *livePhotoView;

/// 设置当前要显示的 video ，会把 image/livePhoto 相关内容清空，因此注意不要直接通过 videoPlayerLayer 来设置
@property(nonatomic, weak, nullable) AVPlayerItem *videoPlayerItem;

/// 用于显示 video 的 layer
@property(nonatomic, strong, readonly) AVPlayerLayer *videoPlayerLayer;

/// 获取当前正在显示的图片/视频的容器
@property(nonatomic, weak, nullable, readonly) __kindof UIView *contentView;

/// 是否播放video时显示底部的工具栏，默认NO
@property(nonatomic, assign) BOOL showsVideoToolbar;

// 播放 video 时底部的工具栏，你可通过此属性来拿到并修改上面的播放/暂停按钮、进度条、Label 等的样式，默认paddings为{10, 10, 10, 10}
@property(nonatomic, strong, readonly) __FWZoomImageVideoToolbar *videoToolbar;

// 视频底部控制条的 margins，会在此基础上自动叠加安全区域，默认值为 {0, 16, 16, 8}
@property(nonatomic, assign) UIEdgeInsets videoToolbarMargins UI_APPEARANCE_SELECTOR;

// 播放 video 时屏幕中央的播放按钮
@property(nonatomic, strong, readonly) UIButton *videoPlayButton;

// 可通过此属性修改 video 播放时屏幕中央的播放按钮图片
@property(nonatomic, strong) UIImage *videoPlayButtonImage UI_APPEARANCE_SELECTOR;

// 是否显示播放 video 时屏幕左上角的关闭按钮，默认NO，仅播放视频时生效
@property(nonatomic, assign) BOOL showsVideoCloseButton;

// 播放 video 时屏幕左上角的关闭按钮，默认自动关闭所在present控制器
@property(nonatomic, strong, readonly) UIButton *videoCloseButton;

// 可通过此属性修改 video 播放时屏幕左上角的关闭按钮图片
@property(nonatomic, strong) UIImage *videoCloseButtonImage UI_APPEARANCE_SELECTOR;

// 播放 video 时屏幕左上角的关闭按钮中心句柄，默认同导航栏关闭按钮
@property(nonatomic, copy, nullable) CGPoint (^videoCloseButtonCenter)(void);

// 是否隐藏进度视图，默认NO
@property(nonatomic, assign) BOOL hidesProgressView;

// 进度视图，居中显示
@property(nonatomic, strong) UIView<__FWProgressViewPlugin> *progressView;

// 设置当前进度，自动显示或隐藏进度视图
@property(nonatomic, assign) CGFloat progress;

/// 是否正在播放视频
@property(nonatomic, assign, readonly) BOOL isPlayingVideo;

/// 是否忽略本地图片缓存，默认NO
@property(nonatomic, assign) BOOL ignoreImageCache;

/// 开始视频播放
- (void)playVideo;

/// 暂停视频播放
- (void)pauseVideo;

/// 停止视频播放，将播放状态重置到初始状态
- (void)endPlayingVideo;

/// 获取当前正在显示的图片/视频在整个 __FWZoomImageView 坐标系里的 rect（会按照当前的缩放状态来计算）
- (CGRect)contentViewRect;

/// 重置图片或视频的大小，使用的场景例如：相册控件里放大当前图片、划到下一张、再回来，当前的图片或视频应该恢复到原来大小。注意子类重写需要调一下super
- (void)revertZooming;

/// 快速设置图片URL，参数支持UIImage|PHLivePhoto|AVPlayerItem|NSURL|NSString类型
- (void)setImageURL:(nullable id)imageURL;

/// 快速设置图片URL，支持占位图和完成回调，参数支持UIImage|PHLivePhoto|AVPlayerItem|NSURL|NSString类型
- (void)setImageURL:(nullable id)imageURL placeholderImage:(nullable UIImage *)placeholderImage completion:(nullable void (^)(UIImage * _Nullable image))completion;

@end

#pragma mark - __FWZoomImageVideoToolbar

NS_SWIFT_NAME(ZoomImageVideoToolbar)
@interface __FWZoomImageVideoToolbar : UIView

@property(nonatomic, strong, readonly) UIButton *playButton;
@property(nonatomic, strong, readonly) UIButton *pauseButton;
@property(nonatomic, strong, readonly) UISlider *slider;
@property(nonatomic, strong, readonly) UILabel *sliderLeftLabel;
@property(nonatomic, strong, readonly) UILabel *sliderRightLabel;

// 可通过调整此属性来调整 toolbar 内部的间距，默认为 {0, 0, 0, 0}
@property(nonatomic, assign) UIEdgeInsets paddings UI_APPEARANCE_SELECTOR;

// 可通过这些属性修改 video 播放时屏幕底部工具栏的播放/暂停图标
@property(nonatomic, strong) UIImage *playButtonImage UI_APPEARANCE_SELECTOR;
@property(nonatomic, strong) UIImage *pauseButtonImage UI_APPEARANCE_SELECTOR;

@end

NS_ASSUME_NONNULL_END
