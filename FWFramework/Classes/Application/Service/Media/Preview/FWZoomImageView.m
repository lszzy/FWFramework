/*!
 @header     FWZoomImageView.h
 @indexgroup FWFramework
 @brief      FWZoomImageView
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import "FWZoomImageView.h"
#import "FWAutoLayout.h"
#import "FWAdaptive.h"
#import "FWToolkit.h"
#import "FWImage.h"
#import "FWViewPlugin.h"

@interface FWZoomImageViewImageGenerator : NSObject

+ (UIImage *)largePlayImage;
+ (UIImage *)smallPlayImage;
+ (UIImage *)pauseImage;

@end

@interface QMUIZoomImageVideoPlayerView : UIView

@end

static NSUInteger const kTagForCenteredPlayButton = 1;

@interface FWZoomImageView () <UIGestureRecognizerDelegate>

// video play
@property(nonatomic, strong) QMUIZoomImageVideoPlayerView *videoPlayerView;
@property(nonatomic, strong) AVPlayer *videoPlayer;
@property(nonatomic, strong) id videoTimeObserver;
@property(nonatomic, assign) BOOL isSeekingVideo;
@property(nonatomic, assign) CGSize videoSize;

@end

@implementation FWZoomImageView

@synthesize imageView = _imageView;
@synthesize livePhotoView = _livePhotoView;
@synthesize videoPlayerLayer = _videoPlayerLayer;
@synthesize videoToolbar = _videoToolbar;
@synthesize videoCenteredPlayButton = _videoCenteredPlayButton;
@synthesize progressView = _progressView;

- (void)didMoveToWindow {
    [super didMoveToWindow];
    // 当 self.window 为 nil 时说明此 view 被移出了可视区域（比如所在的 controller 被 pop 了），此时应该停止视频播放
    if (!self.window) {
        [self endPlayingVideo];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.maximumZoomScale = 2.0;
        
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.minimumZoomScale = 0;
        self.scrollView.maximumZoomScale = self.maximumZoomScale;
        self.scrollView.delegate = self;
        if (@available(iOS 11, *)) {
            self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [self addSubview:self.scrollView];
        
        UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGestureWithPoint:)];
        singleTapGesture.delegate = self;
        singleTapGesture.numberOfTapsRequired = 1;
        singleTapGesture.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:singleTapGesture];
        
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGestureWithPoint:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        doubleTapGesture.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:doubleTapGesture];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [self addGestureRecognizer:longPressGesture];
        
        // 双击失败后才出发单击
        [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
        
        self.contentMode = UIViewContentModeCenter;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    
    self.scrollView.frame = self.bounds;
    
    CGRect viewportRect = [self finalViewportRect];
    
    if (_videoCenteredPlayButton) {
        [_videoCenteredPlayButton sizeToFit];
        _videoCenteredPlayButton.center = CGPointMake(CGRectGetMidX(viewportRect), CGRectGetMidY(viewportRect));
    }
    
    if (_videoToolbar) {
        _videoToolbar.frame = ({
            UIEdgeInsets margins = UIEdgeInsetsMake(self.videoToolbarMargins.top + self.fwSafeAreaInsets.top, self.videoToolbarMargins.left + self.fwSafeAreaInsets.left, self.videoToolbarMargins.bottom + self.fwSafeAreaInsets.bottom, self.videoToolbarMargins.right + self.fwSafeAreaInsets.right);
            CGFloat width = CGRectGetWidth(self.bounds) - (margins.left + margins.right);
            CGFloat height = [_videoToolbar sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
            CGRectMake(margins.left, CGRectGetHeight(self.bounds) - margins.bottom - height, width, height);
        });
    }
}

- (void)setFrame:(CGRect)frame {
    BOOL isBoundsChanged = !CGSizeEqualToSize(frame.size, self.frame.size);
    [super setFrame:frame];
    if (isBoundsChanged) {
        [self revertZooming];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Normal Image

- (UIImageView *)imageView {
    [self initImageViewIfNeeded];
    return _imageView;
}

- (void)initImageViewIfNeeded {
    if (_imageView) {
        return;
    }
    Class imageClass = [UIImageView fwImageViewAnimatedClass];
    _imageView = [[imageClass alloc] init];
    [self.scrollView addSubview:_imageView];
}

- (void)setImage:(UIImage *)image {
    _image = image;
    
    if (image) {
        self.livePhoto = nil;
        self.videoPlayerItem = nil;
    }
    
    if (!image) {
        _imageView.image = nil;
        [_imageView removeFromSuperview];
        _imageView = nil;
        return;
    }
    self.imageView.image = image;
    
    // 更新 imageView 的大小时，imageView 可能已经被缩放过，所以要应用当前的缩放
    self.imageView.fwFrameApplyTransform = CGRectMake(0, 0, image.size.width, image.size.height);
    
    [self hideViews];
    self.imageView.hidden = NO;
    
    [self revertZooming];
}

#pragma mark - Live Photo

- (PHLivePhotoView *)livePhotoView {
    [self initLivePhotoViewIfNeeded];
    return _livePhotoView;
}

- (void)setLivePhoto:(PHLivePhoto *)livePhoto {
    _livePhoto = livePhoto;
    
    if (livePhoto) {
        self.image = nil;
        self.videoPlayerItem = nil;
    }
    
    if (!livePhoto) {
        _livePhotoView.livePhoto = nil;
        [_livePhotoView removeFromSuperview];
        _livePhotoView = nil;
        return;
    }
    
    [self initLivePhotoViewIfNeeded];
    _livePhotoView.livePhoto = livePhoto;
    _livePhotoView.hidden = NO;
    
    // 更新 livePhotoView 的大小时，livePhotoView 可能已经被缩放过，所以要应用当前的缩放
    _livePhotoView.fwFrameApplyTransform = CGRectMake(0, 0, livePhoto.size.width, livePhoto.size.height);
    
    [self revertZooming];
}

- (void)initLivePhotoViewIfNeeded {
    if (_livePhotoView) {
        return;
    }
    _livePhotoView = [[PHLivePhotoView alloc] init];
    [self.scrollView addSubview:_livePhotoView];
}

#pragma mark - Image Scale

- (void)setContentMode:(UIViewContentMode)contentMode {
    BOOL isContentModeChanged = self.contentMode != contentMode;
    [super setContentMode:contentMode];
    if (isContentModeChanged) {
        [self revertZooming];
    }
}

- (void)setMaximumZoomScale:(CGFloat)maximumZoomScale {
    _maximumZoomScale = maximumZoomScale;
    self.scrollView.maximumZoomScale = maximumZoomScale;
}

- (CGFloat)minimumZoomScale {
    BOOL isLivePhoto = !!self.livePhoto;

    if (!self.image && !isLivePhoto && !self.videoPlayerItem) {
        return 1;
    }
    
    CGRect viewport = [self finalViewportRect];
    CGSize mediaSize = CGSizeZero;
    if (self.image) {
        mediaSize = self.image.size;
    } else if (isLivePhoto) {
        mediaSize = self.livePhoto.size;
    } else if (self.videoPlayerItem) {
        mediaSize = self.videoSize;
    }
    
    CGFloat minScale = 1;
    CGFloat scaleX = CGRectGetWidth(viewport) / mediaSize.width;
    CGFloat scaleY = CGRectGetHeight(viewport) / mediaSize.height;
    if (self.contentMode == UIViewContentModeScaleAspectFit) {
        minScale = MIN(scaleX, scaleY);
    } else if (self.contentMode == UIViewContentModeScaleAspectFill) {
        minScale = MAX(scaleX, scaleY);
    } else if (self.contentMode == UIViewContentModeCenter) {
        if (scaleX >= 1 && scaleY >= 1) {
            minScale = 1;
        } else {
            minScale = MIN(scaleX, scaleY);
        }
    }
    return minScale;
}

- (void)revertZooming {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    
    BOOL enabledZoomImageView = [self enabledZoomImageView];
    CGFloat minimumZoomScale = [self minimumZoomScale];
    CGFloat maximumZoomScale = enabledZoomImageView ? self.maximumZoomScale : minimumZoomScale;
    maximumZoomScale = MAX(minimumZoomScale, maximumZoomScale);// 可能外部通过 contentMode = UIViewContentModeScaleAspectFit 的方式来让小图片撑满当前的 zoomImageView，所以算出来 minimumZoomScale 会很大（至少比 maximumZoomScale 大），所以这里要做一个保护
    CGFloat zoomScale = minimumZoomScale;
    BOOL shouldFireDidZoomingManual = zoomScale == self.scrollView.zoomScale;
    self.scrollView.panGestureRecognizer.enabled = enabledZoomImageView;
    self.scrollView.pinchGestureRecognizer.enabled = enabledZoomImageView;
    self.scrollView.minimumZoomScale = minimumZoomScale;
    self.scrollView.maximumZoomScale = maximumZoomScale;
    self.contentView.fwOrigin = CGPointMake(0, 0);
    [self setZoomScale:zoomScale animated:NO];
    
    // 只有前后的 zoomScale 不相等，才会触发 UIScrollViewDelegate scrollViewDidZoom:，因此对于相等的情况要自己手动触发
    if (shouldFireDidZoomingManual) {
        [self handleDidEndZooming];
    }
    
    // 当内容比 viewport 的区域更大时，要把内容放在 viewport 正中间
    self.scrollView.contentOffset = ({
        CGFloat x = self.scrollView.contentOffset.x;
        CGFloat y = self.scrollView.contentOffset.y;
        CGRect viewport = [self finalViewportRect];
        if (!CGRectIsEmpty(viewport)) {
            UIView *contentView = [self contentView];
            if (CGRectGetWidth(viewport) < CGRectGetWidth(contentView.frame)) {
                x = (CGRectGetWidth(contentView.frame) / 2 - CGRectGetWidth(viewport) / 2) - CGRectGetMinX(viewport);
            }
            if (CGRectGetHeight(viewport) < CGRectGetHeight(contentView.frame)) {
                y = (CGRectGetHeight(contentView.frame) / 2 - CGRectGetHeight(viewport) / 2) - CGRectGetMinY(viewport);
            }
        }
        CGPointMake(x, y);
    });
}

- (void)setZoomScale:(CGFloat)zoomScale animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:.25 delay:0.0 options:(7<<16) animations:^{
            self.scrollView.zoomScale = zoomScale;
        } completion:nil];
    } else {
        self.scrollView.zoomScale = zoomScale;
    }
}

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:.25 delay:0.0 options:(7<<16) animations:^{
            [self.scrollView zoomToRect:rect animated:NO];
        } completion:nil];
    } else {
        [self.scrollView zoomToRect:rect animated:NO];
    }
}

- (CGRect)contentViewRectInZoomImageView {
    UIView *contentView = [self contentView];
    if (!contentView) {
        return CGRectZero;
    }
    return [self convertRect:contentView.frame fromView:contentView.superview];
}

- (void)handleDidEndZooming {
    CGRect viewport = [self finalViewportRect];
    
    UIView *contentView = [self contentView];
    // 强制 layout 以确保下面的一堆计算依赖的都是最新的 frame 的值
    [self layoutIfNeeded];
    CGRect contentViewFrame = contentView ? [self convertRect:contentView.frame fromView:contentView.superview] : CGRectZero;
    UIEdgeInsets contentInset = UIEdgeInsetsZero;
    
    contentInset.top = CGRectGetMinY(viewport);
    contentInset.left = CGRectGetMinX(viewport);
    contentInset.right = CGRectGetWidth(self.bounds) - CGRectGetMaxX(viewport);
    contentInset.bottom = CGRectGetHeight(self.bounds) - CGRectGetMaxY(viewport);
    
    // 图片 height 比选图框(viewport)的 height 小，这时应该把图片纵向摆放在选图框中间，且不允许上下移动
    if (CGRectGetHeight(viewport) > CGRectGetHeight(contentViewFrame)) {
        // 用 floor 而不是 flat，是因为 flat 本质上是向上取整，会导致 top + bottom 比实际的大，然后 scrollView 就认为可滚动了
        contentInset.top = floor(CGRectGetMidY(viewport) - CGRectGetHeight(contentViewFrame) / 2.0);
        contentInset.bottom = floor(CGRectGetHeight(self.bounds) - CGRectGetMidY(viewport) - CGRectGetHeight(contentViewFrame) / 2.0);
    }
    
    // 图片 width 比选图框的 width 小，这时应该把图片横向摆放在选图框中间，且不允许左右移动
    if (CGRectGetWidth(viewport) > CGRectGetWidth(contentViewFrame)) {
        contentInset.left = floor(CGRectGetMidX(viewport) - CGRectGetWidth(contentViewFrame) / 2.0);
        contentInset.right = floor(CGRectGetWidth(self.bounds) - CGRectGetMidX(viewport) - CGRectGetWidth(contentViewFrame) / 2.0);
    }
    
    self.scrollView.contentInset = contentInset;
    self.scrollView.contentSize = contentView.frame.size;
}

- (BOOL)enabledZoomImageView {
    BOOL enabledZoom = YES;
    BOOL isLivePhoto = isLivePhoto = !!self.livePhoto;
    if ([self.delegate respondsToSelector:@selector(enabledZoomViewInZoomImageView:)]) {
        enabledZoom = [self.delegate enabledZoomViewInZoomImageView:self];
    } else if (!self.image && !isLivePhoto && !self.videoPlayerItem) {
        enabledZoom = NO;
    }
    return enabledZoom;
}

#pragma mark - Video

- (void)setVideoPlayerItem:(AVPlayerItem *)videoPlayerItem {
    _videoPlayerItem = videoPlayerItem;
    
    if (videoPlayerItem) {
        self.livePhoto = nil;
        self.image = nil;
        [self hideViews];
    }
    
    // 移除旧的 videoPlayer 时，同时移除相应的 timeObserver
    if (self.videoPlayer) {
        [self removePlayerTimeObserver];
    }
    
    if (!videoPlayerItem) {
        [self destroyVideoRelatedObjectsIfNeeded];
        return;
    }
    
    // 获取视频尺寸
    NSArray<AVAssetTrack *> *tracksArray = videoPlayerItem.asset.tracks;
    self.videoSize = CGSizeZero;
    for (AVAssetTrack *track in tracksArray) {
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            CGSize size = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
            self.videoSize = CGSizeMake(fabs(size.width), fabs(size.height));
            break;
        }
    }
    
    self.videoPlayer = [AVPlayer playerWithPlayerItem:videoPlayerItem];
    [self initVideoRelatedViewsIfNeeded];
    _videoPlayerLayer.player = self.videoPlayer;
    // 更新 videoPlayerView 的大小时，videoView 可能已经被缩放过，所以要应用当前的缩放
    self.videoPlayerView.fwFrameApplyTransform = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleVideoPlayToEndEvent) name:AVPlayerItemDidPlayToEndTimeNotification object:videoPlayerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [self configVideoProgressSlider];
    
    self.videoPlayerLayer.hidden = NO;
    self.videoCenteredPlayButton.hidden = NO;
    self.videoToolbar.playButton.hidden = NO;
    
    [self revertZooming];
}

- (void)handlePlayButton:(UIButton *)button {
    [self addPlayerTimeObserver];
    [self.videoPlayer play];
    self.videoCenteredPlayButton.hidden = YES;
    self.videoToolbar.playButton.hidden = YES;
    self.videoToolbar.pauseButton.hidden = NO;
    if (button.tag == kTagForCenteredPlayButton) {
        self.videoToolbar.hidden = YES;
        if ([self.delegate respondsToSelector:@selector(zoomImageView:didHideVideoToolbar:)]) {
            [self.delegate zoomImageView:self didHideVideoToolbar:YES];
        }
    }
}
- (void)handlePauseButton {
    [self.videoPlayer pause];
    self.videoToolbar.playButton.hidden = NO;
    self.videoToolbar.pauseButton.hidden = YES;
}

- (void)handleVideoPlayToEndEvent {
    [self.videoPlayer seekToTime:CMTimeMake(0, 1)];
    self.videoCenteredPlayButton.hidden = NO;
    self.videoToolbar.playButton.hidden = NO;
    self.videoToolbar.pauseButton.hidden = YES;
}

- (void)handleStartDragVideoSlider:(UISlider *)slider {
    [self.videoPlayer pause];
    [self removePlayerTimeObserver];
}

- (void)handleDraggingVideoSlider:(UISlider *)slider {
    if (!self.isSeekingVideo) {
        self.isSeekingVideo = YES;
        [self updateVideoSliderLeftLabel];
        
        CGFloat currentValue = slider.value;
        [self.videoPlayer seekToTime:CMTimeMakeWithSeconds(currentValue, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isSeekingVideo = NO;
            });
        }];
    }
}

- (void)handleFinishDragVideoSlider:(UISlider *)slider {
    [self.videoPlayer play];
    self.videoCenteredPlayButton.hidden = YES;
    self.videoToolbar.playButton.hidden = YES;
    self.videoToolbar.pauseButton.hidden = NO;
    
    [self addPlayerTimeObserver];
}

- (void)syncVideoProgressSlider {
    double currentSeconds = CMTimeGetSeconds(self.videoPlayer.currentTime);
    [self.videoToolbar.slider setValue:currentSeconds];
    [self updateVideoSliderLeftLabel];
}

- (void)configVideoProgressSlider {
    self.videoToolbar.sliderLeftLabel.text = [self timeStringFromSeconds:0];
    double duration = CMTimeGetSeconds(self.videoPlayerItem.asset.duration);
    self.videoToolbar.sliderRightLabel.text = [self timeStringFromSeconds:duration];
    
    self.videoToolbar.slider.minimumValue = 0.0;
    self.videoToolbar.slider.maximumValue = duration;
    self.videoToolbar.slider.value = 0;
    [self.videoToolbar.slider addTarget:self action:@selector(handleStartDragVideoSlider:) forControlEvents:UIControlEventTouchDown];
    [self.videoToolbar.slider addTarget:self action:@selector(handleDraggingVideoSlider:) forControlEvents:UIControlEventValueChanged];
    [self.videoToolbar.slider addTarget:self action:@selector(handleFinishDragVideoSlider:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addPlayerTimeObserver];
}

- (void)addPlayerTimeObserver {
    if (self.videoTimeObserver) {
        return;
    }
    double interval = .1f;
    __weak FWZoomImageView *weakSelf = self;
    self.videoTimeObserver = [self.videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf syncVideoProgressSlider];
    }];
}

- (void)removePlayerTimeObserver {
    if (!self.videoTimeObserver) {
        return;
    }
    [self.videoPlayer removeTimeObserver:self.videoTimeObserver];
    self.videoTimeObserver = nil;
}

- (void)updateVideoSliderLeftLabel {
    double currentSeconds = CMTimeGetSeconds(self.videoPlayer.currentTime);
    self.videoToolbar.sliderLeftLabel.text = [self timeStringFromSeconds:currentSeconds];
}

- (NSString *)timeStringFromSeconds:(NSUInteger)seconds {
    NSUInteger min = floor(seconds / 60);
    NSUInteger sec = floor(seconds - min * 60);
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)sec];
}

- (void)pauseVideo {
    if (!self.videoPlayer) {
        return;
    }
    [self handlePauseButton];
    [self removePlayerTimeObserver];
}

- (void)endPlayingVideo {
    if (!self.videoPlayer) {
        return;
    }
    [self.videoPlayer seekToTime:CMTimeMake(0, 1)];
    [self pauseVideo];
    [self syncVideoProgressSlider];
    self.videoToolbar.hidden = YES;
    self.videoCenteredPlayButton.hidden = NO;
    
}

- (AVPlayerLayer *)videoPlayerLayer {
    [self initVideoPlayerLayerIfNeeded];
    return _videoPlayerLayer;
}

- (FWZoomImageViewVideoToolbar *)videoToolbar {
    [self initVideoToolbarIfNeeded];
    return _videoToolbar;
}

- (UIButton *)videoCenteredPlayButton {
    [self initVideoCenteredPlayButtonIfNeeded];
    return _videoCenteredPlayButton;
}

- (void)initVideoPlayerLayerIfNeeded {
    if (self.videoPlayerView) {
        return;
    }
    self.videoPlayerView = [[QMUIZoomImageVideoPlayerView alloc] init];
    _videoPlayerLayer = (AVPlayerLayer *)self.videoPlayerView.layer;
    self.videoPlayerView.hidden = YES;
    [self.scrollView addSubview:self.videoPlayerView];
}

- (void)initVideoToolbarIfNeeded {
    if (_videoToolbar) {
        return;
    }
    _videoToolbar = ({
        FWZoomImageViewVideoToolbar * b = [[FWZoomImageViewVideoToolbar alloc] init];
        [b.playButton addTarget:self action:@selector(handlePlayButton:) forControlEvents:UIControlEventTouchUpInside];
        [b.pauseButton addTarget:self action:@selector(handlePauseButton) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:b];
        b.hidden = YES;
        b;
    });
}

- (void)initVideoCenteredPlayButtonIfNeeded {
    if (_videoCenteredPlayButton) {
        return;
    }
    
    _videoCenteredPlayButton = ({
        UIButton *b = [[UIButton alloc] init];
        b.fwTouchInsets = UIEdgeInsetsMake(60, 60, 60, 60);
        b.tag = kTagForCenteredPlayButton;
        [b setImage:self.videoCenteredPlayButtonImage forState:UIControlStateNormal];
        [b addTarget:self action:@selector(handlePlayButton:) forControlEvents:UIControlEventTouchUpInside];
        b.hidden = YES;
        [self addSubview:b];
        b;
    });
}

- (void)initVideoRelatedViewsIfNeeded {
    [self initVideoPlayerLayerIfNeeded];
    [self initVideoToolbarIfNeeded];
    [self initVideoCenteredPlayButtonIfNeeded];
    [self setNeedsLayout];
}

- (void)destroyVideoRelatedObjectsIfNeeded {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self removePlayerTimeObserver];
    
    [self.videoPlayerView removeFromSuperview];
    self.videoPlayerView = nil;
    
    [self.videoToolbar removeFromSuperview];
    _videoToolbar = nil;
    
    [self.videoCenteredPlayButton removeFromSuperview];
    _videoCenteredPlayButton = nil;
    
    self.videoPlayer = nil;
    _videoPlayerLayer.player = nil;
}

- (void)setVideoToolbarMargins:(UIEdgeInsets)videoToolbarMargins {
    _videoToolbarMargins = videoToolbarMargins;
    [self setNeedsLayout];
}

- (void)setVideoCenteredPlayButtonImage:(UIImage *)videoCenteredPlayButtonImage {
    _videoCenteredPlayButtonImage = videoCenteredPlayButtonImage;
    if (!self.videoCenteredPlayButton) {
        return;
    }
    [self.videoCenteredPlayButton setImage:videoCenteredPlayButtonImage forState:UIControlStateNormal];
    [self setNeedsLayout];
}

- (void)applicationDidEnterBackground {
    [self pauseVideo];
}

#pragma mark - Progress

- (UIView<FWProgressViewPlugin> *)progressView {
    if (!_progressView) {
        _progressView = [UIView fwProgressViewWithStyle:FWProgressViewStyleDefault];
        _progressView.hidden = YES;
        [self addSubview:_progressView];
        [_progressView fwAlignCenterToSuperview];
    }
    return _progressView;
}

- (void)setProgressView:(UIView<FWProgressViewPlugin> *)progressView {
    [_progressView removeFromSuperview];
    _progressView = progressView;
    _progressView.hidden = YES;
    [self addSubview:_progressView];
    [_progressView fwAlignCenterToSuperview];
}

- (CGFloat)progress {
    return self.progressView.progress;
}

- (void)setProgress:(CGFloat)progress {
    self.progressView.progress = progress;
    if (progress >= 1 || progress <= 0) {
        if (!self.progressView.hidden) self.progressView.hidden = YES;
    } else {
        if (self.progressView.hidden) self.progressView.hidden = NO;
    }
}

#pragma mark - GestureRecognizers

- (void)handleSingleTapGestureWithPoint:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint gesturePoint = [gestureRecognizer locationInView:gestureRecognizer.view];
    if ([self.delegate respondsToSelector:@selector(singleTouchInZoomingImageView:location:)]) {
        [self.delegate singleTouchInZoomingImageView:self location:gesturePoint];
    }
    if (self.videoPlayerItem) {
        self.videoToolbar.hidden = !self.videoToolbar.hidden;
        if ([self.delegate respondsToSelector:@selector(zoomImageView:didHideVideoToolbar:)]) {
            [self.delegate zoomImageView:self didHideVideoToolbar:self.videoToolbar.hidden];
        }
    }
}

- (void)handleDoubleTapGestureWithPoint:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint gesturePoint = [gestureRecognizer locationInView:gestureRecognizer.view];
    if ([self.delegate respondsToSelector:@selector(doubleTouchInZoomingImageView:location:)]) {
        [self.delegate doubleTouchInZoomingImageView:self location:gesturePoint];
    }
    
    if ([self enabledZoomImageView]) {
        // 如果图片被压缩了，则第一次放大到原图大小，第二次放大到最大倍数
        if (self.scrollView.zoomScale >= self.scrollView.maximumZoomScale) {
            [self setZoomScale:self.scrollView.minimumZoomScale animated:YES];
        } else {
            CGFloat newZoomScale = 0;
            if (self.scrollView.zoomScale < 1) {
                // 如果目前显示的大小比原图小，则放大到原图
                newZoomScale = 1;
            } else {
                // 如果当前显示原图，则放大到最大的大小
                newZoomScale = self.scrollView.maximumZoomScale;
            }
            
            CGRect zoomRect = CGRectZero;
            CGPoint tapPoint = [[self contentView] convertPoint:gesturePoint fromView:gestureRecognizer.view];
            zoomRect.size.width = CGRectGetWidth(self.bounds) / newZoomScale;
            zoomRect.size.height = CGRectGetHeight(self.bounds) / newZoomScale;
            zoomRect.origin.x = tapPoint.x - CGRectGetWidth(zoomRect) / 2;
            zoomRect.origin.y = tapPoint.y - CGRectGetHeight(zoomRect) / 2;
            [self zoomToRect:zoomRect animated:YES];
        }
    }
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if ([self enabledZoomImageView] && longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(longPressInZoomingImageView:)]) {
            [self.delegate longPressInZoomingImageView:self];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - <UIScrollViewDelegate>

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [self contentView];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self handleDidEndZooming];
}

#pragma mark - 工具方法

- (CGRect)finalViewportRect {
    CGRect rect = self.viewportRect;
    if (CGRectIsEmpty(rect) && !CGRectIsEmpty(self.bounds)) {
        // 有可能此时还没有走到过 layoutSubviews 因此拿不到正确的 scrollView 的 size，因此这里要强制 layout 一下
        if (!CGSizeEqualToSize(self.scrollView.bounds.size, self.bounds.size)) {
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }
        rect = CGRectMake(0, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    }
    return rect;
}

- (void)hideViews {
    _livePhotoView.hidden = YES;
    _imageView.hidden = YES;
    _videoCenteredPlayButton.hidden = YES;
    _videoPlayerLayer.hidden = YES;
    _videoToolbar.hidden = YES;
    _videoToolbar.pauseButton.hidden = YES;
    _videoToolbar.playButton.hidden = YES;
    _videoCenteredPlayButton.hidden = YES;
}


- (UIView *)contentView {
    if (_imageView) {
        return _imageView;
    }
    if (_livePhotoView) {
        return _livePhotoView;
    }
    if (self.videoPlayerView) {
        return self.videoPlayerView;
    }
    return nil;
}

@end

@interface FWZoomImageView (UIAppearance)

@end

@implementation FWZoomImageView (UIAppearance)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    FWZoomImageView *appearance = [FWZoomImageView appearance];
    appearance.videoToolbarMargins = UIEdgeInsetsMake(0, 25, 25, 18);
    appearance.videoCenteredPlayButtonImage = [FWZoomImageViewImageGenerator largePlayImage];
}

@end

@implementation QMUIZoomImageVideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end

@implementation FWZoomImageViewImageGenerator

+ (UIImage *)largePlayImage {
    CGFloat width = 60;
    return [UIImage fwImageWithBlock:^(CGContextRef contextRef) {
        UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:.75];
        CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
        
        // circle outside
        CGContextSetFillColorWithColor(contextRef, [UIColor colorWithRed:0 green:0 blue:0 alpha:.25].CGColor);
        CGFloat circleLineWidth = 1;
        // consider line width to avoid edge clip
        UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(circleLineWidth / 2, circleLineWidth / 2, width - circleLineWidth, width - circleLineWidth)];
        [circle setLineWidth:circleLineWidth];
        [circle stroke];
        [circle fill];
        
        // triangle inside
        CGContextSetFillColorWithColor(contextRef, color.CGColor);
        CGFloat triangleLength = width / 2.5;
        UIBezierPath *triangle = [self trianglePathWithLength:triangleLength];
        UIOffset offset = UIOffsetMake(width / 2 - triangleLength * tan(M_PI / 6) / 2, width / 2 - triangleLength / 2);
        [triangle applyTransform:CGAffineTransformMakeTranslation(offset.horizontal, offset.vertical)];
        [triangle fill];
    } size:CGSizeMake(width, width)];
}

+ (UIImage *)smallPlayImage {
    CGFloat width = 17;
    return [UIImage fwImageWithBlock:^(CGContextRef contextRef) {
        UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:.75];
        CGContextSetFillColorWithColor(contextRef, color.CGColor);
        UIBezierPath *path = [self trianglePathWithLength:width];
        [path fill];
    } size:CGSizeMake(width, width)];
}

+ (UIImage *)pauseImage {
    CGSize size = CGSizeMake(12, 18);
    return [UIImage fwImageWithBlock:^(CGContextRef contextRef) {
        UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:.75];
        CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
        CGFloat lineWidth = 2;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(lineWidth / 2, 0)];
        [path addLineToPoint:CGPointMake(lineWidth / 2, size.height)];
        [path moveToPoint:CGPointMake(size.width - lineWidth / 2, 0)];
        [path addLineToPoint:CGPointMake(size.width - lineWidth / 2, size.height)];
        [path setLineWidth:lineWidth];
        [path stroke];
    } size:size];
}

// @param length of the triangle side
+ (UIBezierPath *)trianglePathWithLength:(CGFloat)length {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointZero];
    [path addLineToPoint:CGPointMake(length * cos(M_PI / 6), length / 2)];
    [path addLineToPoint:CGPointMake(0, length)];
    [path closePath];
    return path;
}

@end

@implementation FWZoomImageViewVideoToolbar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        _playButton = [[UIButton alloc] init];
        self.playButton.fwTouchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [self.playButton setImage:self.playButtonImage forState:UIControlStateNormal];
        [self addSubview:self.playButton];
        
        _pauseButton = [[UIButton alloc] init];
        self.pauseButton.fwTouchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [self.pauseButton setImage:self.pauseButtonImage forState:UIControlStateNormal];
        [self addSubview:self.pauseButton];
        
        _slider = [[UISlider alloc] init];
        self.slider.minimumTrackTintColor = [UIColor colorWithRed:195/255.f green:195/255.f blue:195/255.f alpha:1];
        self.slider.maximumTrackTintColor = [UIColor colorWithRed:95/255.f green:95/255.f blue:95/255.f alpha:1];
        //self.slider.thumbSize = CGSizeMake(12, 12);
        //self.slider.thumbColor = UIColor.whiteColor;
        [self addSubview:self.slider];
        
        _sliderLeftLabel = [[UILabel alloc] init];
        self.sliderLeftLabel.font = [UIFont systemFontOfSize:12];
        self.sliderLeftLabel.textColor = [UIColor whiteColor];
        self.sliderLeftLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.sliderLeftLabel];
        
        _sliderRightLabel = [[UILabel alloc] init];
        self.sliderRightLabel.font = [UIFont systemFontOfSize:12];
        self.sliderRightLabel.textColor = [UIColor whiteColor];
        self.sliderRightLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.sliderRightLabel];
        
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = .5;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 10;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentHeight = CGRectGetHeight(self.bounds) - (self.paddings.top + self.paddings.bottom);
    
    self.playButton.frame = ({
        CGSize size = [self.playButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        CGRectMake(self.paddings.left, (contentHeight - size.height) / 2.0 + self.paddings.top, size.width, size.height);
    });
    
    self.pauseButton.frame = ({
        CGSize size = [self.pauseButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        CGRectMake(CGRectGetMidX(self.playButton.frame) - size.width / 2, CGRectGetMidY(self.playButton.frame) - size.height / 2, size.width, size.height);
    });
    
    CGFloat timeLabelWidth = 55;
    self.sliderLeftLabel.frame = ({
        CGFloat marginLeft = 19;
        CGRectMake(CGRectGetMaxX(self.playButton.frame) + marginLeft, self.paddings.top, timeLabelWidth, contentHeight);
    });
    self.sliderRightLabel.frame = ({
        CGRectMake(CGRectGetWidth(self.bounds) - self.paddings.right - timeLabelWidth, self.paddings.top, timeLabelWidth, contentHeight);
    });
    self.slider.frame = ({
        CGFloat marginToLabel = 4;
        CGFloat x = CGRectGetMaxX(self.sliderLeftLabel.frame) + marginToLabel;
        CGRectMake(x, self.paddings.top, CGRectGetMinX(self.sliderRightLabel.frame) - marginToLabel - x, contentHeight);
    });
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat contentHeight = [self maxHeightAmongViews:@[self.playButton, self.pauseButton, self.sliderLeftLabel, self.sliderRightLabel, self.slider]];
    size.height = contentHeight + (self.paddings.top + self.paddings.bottom);
    return size;
}

- (void)setPaddings:(UIEdgeInsets)paddings {
    _paddings = paddings;
    [self setNeedsLayout];
}

- (void)setPlayButtonImage:(UIImage *)playButtonImage {
    _playButtonImage = playButtonImage;
    [self.playButton setImage:playButtonImage forState:UIControlStateNormal];
    [self setNeedsLayout];
}

- (void)setPauseButtonImage:(UIImage *)pauseButtonImage {
    _pauseButtonImage = pauseButtonImage;
    [self.pauseButton setImage:pauseButtonImage forState:UIControlStateNormal];
    [self setNeedsLayout];
}

// 返回一堆 view 中高度最大的那个的高度
- (CGFloat)maxHeightAmongViews:(NSArray<UIView *> *)views {
    __block CGFloat maxValue = 0;
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat height = [obj sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height;
        maxValue = MAX(height, maxValue);
    }];
    return maxValue;
}

@end

@interface FWZoomImageViewVideoToolbar (UIAppearance)

@end

@implementation FWZoomImageViewVideoToolbar (UIAppearance)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    FWZoomImageViewVideoToolbar *appearance = [FWZoomImageViewVideoToolbar appearance];
    appearance.playButtonImage = [FWZoomImageViewImageGenerator smallPlayImage];
    appearance.pauseButtonImage = [FWZoomImageViewImageGenerator pauseImage];
}

@end
