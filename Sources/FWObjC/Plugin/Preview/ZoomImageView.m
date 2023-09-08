//
//  ZoomImageView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ZoomImageView.h"
#import "ImagePlugin.h"
#import <FWFramework/FWFramework-Swift.h>

#pragma mark - __FWZoomImageVideoPlayerView

@interface __FWZoomImageVideoPlayerView : UIView

@end

@implementation __FWZoomImageVideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end

#pragma mark - __FWZoomImageView

@interface __FWZoomImageView () <UIGestureRecognizerDelegate>

// video play
@property(nonatomic, strong) __FWZoomImageVideoPlayerView *videoPlayerView;
@property(nonatomic, strong) AVPlayer *videoPlayer;
@property(nonatomic, strong) id videoTimeObserver;
@property(nonatomic, assign) BOOL isSeekingVideo;
@property(nonatomic, assign) CGSize videoSize;

@end

@implementation __FWZoomImageView

@synthesize imageView = _imageView;
@synthesize livePhotoView = _livePhotoView;
@synthesize videoPlayerLayer = _videoPlayerLayer;
@synthesize videoToolbar = _videoToolbar;
@synthesize videoPlayButton = _videoPlayButton;
@synthesize videoCloseButton = _videoCloseButton;
@synthesize progressView = _progressView;
@synthesize maximumZoomScale = _maximumZoomScale;
@synthesize minimumZoomScale = _minimumZoomScale;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    __FWZoomImageView *appearance = [__FWZoomImageView appearance];
    appearance.videoToolbarMargins = UIEdgeInsetsMake(0, 16, 16, 8);
    appearance.videoPlayButtonImage = [NSObject __fw_bundleImage:@"fw.videoPlay"];
    appearance.videoCloseButtonImage = [NSObject __fw_bundleImage:@"fw.navClose"];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.delegate = self;
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
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
        
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    // 当 self.window 为 nil 时说明此 view 被移出了可视区域（比如所在的 controller 被 pop 了），此时应该停止视频播放
    if (!self.window) {
        [self endPlayingVideo];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (CGRectIsEmpty(self.bounds)) return;
    
    self.scrollView.frame = self.bounds;
    
    CGRect viewportRect = [self finalViewportRect];
    
    if (_videoPlayButton) {
        [_videoPlayButton sizeToFit];
        _videoPlayButton.center = CGPointMake(CGRectGetMidX(viewportRect), CGRectGetMidY(viewportRect));
    }
    if (_videoCloseButton) {
        [_videoCloseButton sizeToFit];
        CGPoint videoCloseButtonCenter = self.videoCloseButtonCenter ? self.videoCloseButtonCenter() : CGPointMake(UIScreen.__fw_safeAreaInsets.left + 24, UIScreen.__fw_statusBarHeight + UIScreen.__fw_navigationBarHeight / 2);
        _videoCloseButton.center = videoCloseButtonCenter;
    }
    
    if (_videoToolbar) {
        _videoToolbar.frame = ({
            UIEdgeInsets margins = UIEdgeInsetsMake(self.videoToolbarMargins.top + self.safeAreaInsets.top, self.videoToolbarMargins.left + self.safeAreaInsets.left, self.videoToolbarMargins.bottom + self.safeAreaInsets.bottom, self.videoToolbarMargins.right + self.safeAreaInsets.right);
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
    if (_imageView) return;
    _imageView = [UIImageView __fw_animatedImageView];
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
    self.imageView.__fw_frameApplyTransform = CGRectMake(0, 0, image.size.width, image.size.height);
    
    [self hideViews];
    self.imageView.hidden = NO;
    
    [self revertZooming];
    
    if ([self.delegate respondsToSelector:@selector(zoomImageView:customContentView:)]) {
        [self.delegate zoomImageView:self customContentView:self.imageView];
    }
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
    _livePhotoView.__fw_frameApplyTransform = CGRectMake(0, 0, livePhoto.size.width, livePhoto.size.height);
    
    [self revertZooming];
    
    if ([self.delegate respondsToSelector:@selector(zoomImageView:customContentView:)]) {
        [self.delegate zoomImageView:self customContentView:_livePhotoView];
    }
}

- (void)initLivePhotoViewIfNeeded {
    if (_livePhotoView) return;
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

- (void)setMinimumZoomScale:(CGFloat)minimumZoomScale {
    _minimumZoomScale = minimumZoomScale;
    self.scrollView.minimumZoomScale = minimumZoomScale;
}

- (CGFloat)maximumZoomScale {
    if (_maximumZoomScale > 0) return _maximumZoomScale;
    
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
    CGFloat scaleX = CGRectGetWidth(viewport) / mediaSize.width;
    CGFloat scaleY = CGRectGetHeight(viewport) / mediaSize.height;
    
    if (self.maximumZoomScaleBlock) {
        return self.maximumZoomScaleBlock(scaleX, scaleY);
    }
    
    CGFloat minScale = [self minimumZoomScale];
    return MAX(minScale * 2, 2);
}

- (CGFloat)minimumZoomScale {
    if (_minimumZoomScale > 0) return _minimumZoomScale;
    
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
    CGFloat scaleX = CGRectGetWidth(viewport) / mediaSize.width;
    CGFloat scaleY = CGRectGetHeight(viewport) / mediaSize.height;
    
    if (self.minimumZoomScaleBlock) {
        return self.minimumZoomScaleBlock(scaleX, scaleY);
    }
    
    CGFloat minScale = 1;
    switch (self.contentMode) {
        case UIViewContentModeScaleAspectFit: {
            minScale = MIN(scaleX, scaleY);
            break;
        }
        case UIViewContentModeScaleAspectFill: {
            minScale = MAX(scaleX, scaleY);
            break;
        }
        case UIViewContentModeCenter: {
            if (scaleX >= 1 && scaleY >= 1) {
                minScale = 1;
            } else {
                minScale = MIN(scaleX, scaleY);
            }
            break;
        }
        case UIViewContentModeScaleToFill: {
            minScale = scaleX;
            break;
        }
        default:
            break;
    }
    return minScale;
}

- (void)revertZooming {
    if (CGRectIsEmpty(self.bounds)) return;
    
    BOOL enabledZoomImageView = [self enabledZoomImageView];
    CGFloat minimumZoomScale = [self minimumZoomScale];
    CGFloat maximumZoomScale = enabledZoomImageView ? [self maximumZoomScale] : minimumZoomScale;
    
    CGFloat zoomScale = minimumZoomScale;
    BOOL shouldFireDidZoomingManual = zoomScale == self.scrollView.zoomScale;
    self.scrollView.panGestureRecognizer.enabled = enabledZoomImageView;
    self.scrollView.pinchGestureRecognizer.enabled = enabledZoomImageView;
    self.scrollView.minimumZoomScale = minimumZoomScale;
    self.scrollView.maximumZoomScale = maximumZoomScale;
    self.contentView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
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

- (CGRect)contentViewRect {
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
    self.videoPlayerView.__fw_frameApplyTransform = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleVideoPlayToEndEvent) name:AVPlayerItemDidPlayToEndTimeNotification object:videoPlayerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [self configVideoProgressSlider];
    
    self.videoPlayerLayer.hidden = NO;
    self.videoPlayButton.hidden = NO;
    self.videoToolbar.playButton.hidden = NO;
    if (!self.showsVideoToolbar && self.showsVideoCloseButton) {
        self.videoCloseButton.hidden = NO;
    }
    
    [self revertZooming];
    
    if ([self.delegate respondsToSelector:@selector(zoomImageView:customContentView:)]) {
        [self.delegate zoomImageView:self customContentView:self.videoPlayerView];
    }
}

- (void)handleCloseButton:(UIButton *)button {
    UIViewController *viewController = self.__fw_viewController;
    if (viewController && viewController.__fw_isPresented) {
        [viewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)handlePlayButton:(UIButton *)button {
    [self addPlayerTimeObserver];
    [self.videoPlayer play];
    self.videoPlayButton.hidden = YES;
    self.videoToolbar.playButton.hidden = YES;
    self.videoToolbar.pauseButton.hidden = NO;
    if (button.tag == 1) {
        if (self.showsVideoCloseButton) {
            self.videoCloseButton.hidden = YES;
        }
        if (self.showsVideoToolbar) {
            self.videoToolbar.hidden = YES;
            if ([self.delegate respondsToSelector:@selector(zoomImageView:didHideVideoToolbar:)]) {
                [self.delegate zoomImageView:self didHideVideoToolbar:YES];
            }
        }
    }
}
- (void)handlePauseButton {
    [self.videoPlayer pause];
    self.videoToolbar.playButton.hidden = NO;
    self.videoToolbar.pauseButton.hidden = YES;
    if (!self.showsVideoToolbar) {
        self.videoPlayButton.hidden = NO;
    }
}

- (void)handleVideoPlayToEndEvent {
    [self.videoPlayer seekToTime:CMTimeMake(0, 1)];
    self.videoPlayButton.hidden = NO;
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
    self.videoPlayButton.hidden = YES;
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
    if (self.videoTimeObserver) return;
    
    double interval = .1f;
    __weak __FWZoomImageView *weakSelf = self;
    self.videoTimeObserver = [self.videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf syncVideoProgressSlider];
    }];
}

- (void)removePlayerTimeObserver {
    if (!self.videoTimeObserver) return;
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

- (BOOL)isPlayingVideo {
    if (!self.videoPlayer) return NO;
    return self.videoPlayer.rate != 0.f;
}

- (void)playVideo {
    if (!self.videoPlayer) return;
    [self handlePlayButton:nil];
}

- (void)pauseVideo {
    if (!self.videoPlayer) return;
    [self handlePauseButton];
    [self removePlayerTimeObserver];
}

- (void)endPlayingVideo {
    if (!self.videoPlayer) return;
    [self.videoPlayer seekToTime:CMTimeMake(0, 1)];
    [self pauseVideo];
    [self syncVideoProgressSlider];
    self.videoToolbar.hidden = YES;
    self.videoCloseButton.hidden = YES;
    self.videoPlayButton.hidden = NO;
}

- (AVPlayerLayer *)videoPlayerLayer {
    [self initVideoPlayerLayerIfNeeded];
    return _videoPlayerLayer;
}

- (__FWZoomImageVideoToolbar *)videoToolbar {
    [self initVideoToolbarIfNeeded];
    return _videoToolbar;
}

- (UIButton *)videoPlayButton {
    [self initVideoPlayButtonIfNeeded];
    return _videoPlayButton;
}

- (UIButton *)videoCloseButton {
    [self initVideoCloseButtonIfNeeded];
    return _videoCloseButton;
}

- (void)initVideoPlayerLayerIfNeeded {
    if (self.videoPlayerView) return;
    self.videoPlayerView = [[__FWZoomImageVideoPlayerView alloc] init];
    _videoPlayerLayer = (AVPlayerLayer *)self.videoPlayerView.layer;
    self.videoPlayerView.hidden = YES;
    [self.scrollView addSubview:self.videoPlayerView];
}

- (void)initVideoToolbarIfNeeded {
    if (_videoToolbar) return;
    _videoToolbar = ({
        __FWZoomImageVideoToolbar *videoToolbar = [[__FWZoomImageVideoToolbar alloc] init];
        videoToolbar.paddings = UIEdgeInsetsMake(10, 10, 10, 10);
        [videoToolbar.playButton addTarget:self action:@selector(handlePlayButton:) forControlEvents:UIControlEventTouchUpInside];
        [videoToolbar.pauseButton addTarget:self action:@selector(handlePauseButton) forControlEvents:UIControlEventTouchUpInside];
        videoToolbar.hidden = YES;
        [self addSubview:videoToolbar];
        videoToolbar;
    });
}

- (void)initVideoPlayButtonIfNeeded {
    if (_videoPlayButton) return;
    
    _videoPlayButton = ({
        UIButton *playButton = [[UIButton alloc] init];
        playButton.__fw_touchInsets = UIEdgeInsetsMake(60, 60, 60, 60);
        playButton.tag = 1;
        [playButton setImage:self.videoPlayButtonImage forState:UIControlStateNormal];
        [playButton addTarget:self action:@selector(handlePlayButton:) forControlEvents:UIControlEventTouchUpInside];
        playButton.hidden = YES;
        [self addSubview:playButton];
        playButton;
    });
}

- (void)initVideoCloseButtonIfNeeded {
    if (_videoCloseButton) return;
    
    _videoCloseButton = ({
        UIButton *closeButton = [[UIButton alloc] init];
        closeButton.__fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [closeButton setImage:self.videoCloseButtonImage forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(handleCloseButton:) forControlEvents:UIControlEventTouchUpInside];
        closeButton.hidden = YES;
        [self addSubview:closeButton];
        closeButton;
    });
}

- (void)initVideoRelatedViewsIfNeeded {
    [self initVideoPlayerLayerIfNeeded];
    [self initVideoToolbarIfNeeded];
    [self initVideoPlayButtonIfNeeded];
    [self initVideoCloseButtonIfNeeded];
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
    
    [self.videoPlayButton removeFromSuperview];
    _videoPlayButton = nil;
    
    [self.videoCloseButton removeFromSuperview];
    _videoCloseButton = nil;
    
    self.videoPlayer = nil;
    _videoPlayerLayer.player = nil;
}

- (void)setVideoToolbarMargins:(UIEdgeInsets)videoToolbarMargins {
    _videoToolbarMargins = videoToolbarMargins;
    [self setNeedsLayout];
}

- (void)setVideoPlayButtonImage:(UIImage *)videoPlayButtonImage {
    _videoPlayButtonImage = videoPlayButtonImage;
    if (!self.videoPlayButton) return;
    
    [self.videoPlayButton setImage:videoPlayButtonImage forState:UIControlStateNormal];
    [self setNeedsLayout];
}

- (void)setVideoCloseButtonCenter:(CGPoint (^)(void))videoCloseButtonCenter {
    _videoCloseButtonCenter = videoCloseButtonCenter;
    if (!self.videoCloseButton) return;
    
    [self setNeedsLayout];
}

- (void)setVideoCloseButtonImage:(UIImage *)videoCloseButtonImage {
    _videoCloseButtonImage = videoCloseButtonImage;
    if (!self.videoCloseButton) return;
    
    [self.videoCloseButton setImage:videoCloseButtonImage forState:UIControlStateNormal];
    [self setNeedsLayout];
}

- (void)applicationDidEnterBackground {
    [self pauseVideo];
}

#pragma mark - Progress

- (UIView<__FWProgressViewPlugin> *)progressView {
    if (!_progressView) {
        _progressView = [UIView __fw_progressViewWithDefault];
        _progressView.hidden = YES;
        [self addSubview:_progressView];
        [_progressView __fw_alignCenterToSuperview:CGPointZero];
    }
    return _progressView;
}

- (void)setProgressView:(UIView<__FWProgressViewPlugin> *)progressView {
    [_progressView removeFromSuperview];
    _progressView = progressView;
    _progressView.hidden = YES;
    [self addSubview:_progressView];
    [_progressView __fw_alignCenterToSuperview:CGPointZero];
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

#pragma mark - ImageURL

- (void)setImageURL:(id)imageURL {
    [self setImageURL:imageURL placeholderImage:nil completion:nil];
}

- (void)setImageURL:(id)imageURL placeholderImage:(UIImage *)placeholderImage completion:(void (^)(UIImage * _Nullable))completion {
    if ([imageURL isKindOfClass:[NSString class]]) {
        if ([imageURL isAbsolutePath]) {
            imageURL = [NSURL fileURLWithPath:imageURL];
        } else {
            NSURL *url = [NSURL URLWithString:imageURL];
            if (!url && [imageURL length] > 0) {
                url = [NSURL URLWithString:[imageURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            }
            imageURL = url;
        }
    }
    if ([imageURL isKindOfClass:[NSURL class]]) {
        // 默认只判断几种视频格式，不使用缓存，如果不满足需求，自行生成AVPlayerItem即可
        NSString *pathExt = [imageURL pathExtension];
        BOOL isVideo = pathExt && [@[@"mp4", @"mov", @"m4v", @"3gp", @"avi"] containsObject:pathExt];
        if (isVideo) imageURL = [AVPlayerItem playerItemWithURL:imageURL];
    }

    [self __fw_cancelImageRequest];
    if ([imageURL isKindOfClass:[NSURL class]]) {
        self.progress = 0.01;
        __weak __typeof__(self) self_weak_ = self;
        [self __fw_setImageWithUrl:imageURL placeholderImage:placeholderImage options:__FWWebImageOptionAvoidSetImage setImageBlock:^(UIImage * _Nullable image) {
            __typeof__(self) self = self_weak_;
            self.image = image;
        } completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
            __typeof__(self) self = self_weak_;
            self.progress = 1;
            if (image) self.image = image;
            if (completion) completion(image);
        } progress:^(double progress) {
            __typeof__(self) self = self_weak_;
            self.progress = progress;
        }];
    } else if ([imageURL isKindOfClass:[PHLivePhoto class]]) {
        self.progress = 1;
        self.livePhoto = (PHLivePhoto *)imageURL;
        if (completion) completion(nil);
    } else if ([imageURL isKindOfClass:[AVPlayerItem class]]) {
        self.progress = 1;
        self.videoPlayerItem = (AVPlayerItem *)imageURL;
        if (completion) completion(nil);
    } else if ([imageURL isKindOfClass:[UIImage class]]) {
        self.progress = 1;
        self.image = (UIImage *)imageURL;
        if (completion) completion(self.image);
    } else {
        self.progress = 1;
        self.image = placeholderImage;
        if (completion) completion(nil);
    }
}

#pragma mark - GestureRecognizers

- (void)handleSingleTapGestureWithPoint:(UITapGestureRecognizer *)gestureRecognizer {
    if (self.videoPlayerItem) {
        if (self.showsVideoCloseButton) {
            self.videoCloseButton.hidden = !self.videoCloseButton.hidden;
        }
        if (self.showsVideoToolbar) {
            self.videoToolbar.hidden = !self.videoToolbar.hidden;
            if ([self.delegate respondsToSelector:@selector(zoomImageView:didHideVideoToolbar:)]) {
                [self.delegate zoomImageView:self didHideVideoToolbar:self.videoToolbar.hidden];
            }
        }
    }
    
    CGPoint gesturePoint = [gestureRecognizer locationInView:gestureRecognizer.view];
    if ([self.delegate respondsToSelector:@selector(singleTouchInZoomingImageView:location:)]) {
        [self.delegate singleTouchInZoomingImageView:self location:gesturePoint];
    }
}

- (void)handleDoubleTapGestureWithPoint:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint gesturePoint = [gestureRecognizer locationInView:gestureRecognizer.view];
    if ([self.delegate respondsToSelector:@selector(doubleTouchInZoomingImageView:location:)]) {
        [self.delegate doubleTouchInZoomingImageView:self location:gesturePoint];
    }
    
    if ([self enabledZoomImageView]) {
        // 默认第一次双击放大，再次双击还原，可通过zoomInScaleBlock自定义缩放效果
        if (self.scrollView.zoomScale >= self.scrollView.maximumZoomScale) {
            [self setZoomScale:self.scrollView.minimumZoomScale animated:YES];
        } else {
            CGFloat newZoomScale = self.scrollView.maximumZoomScale;
            if (self.zoomInScaleBlock) {
                newZoomScale = self.zoomInScaleBlock(self.scrollView);
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
    _videoPlayButton.hidden = YES;
    _videoPlayerLayer.hidden = YES;
    _videoToolbar.hidden = YES;
    _videoCloseButton.hidden = YES;
    _videoToolbar.pauseButton.hidden = YES;
    _videoToolbar.playButton.hidden = YES;
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

#pragma mark - __FWZoomImageVideoToolbar

@implementation __FWZoomImageVideoToolbar

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    __FWZoomImageVideoToolbar *appearance = [__FWZoomImageVideoToolbar appearance];
    appearance.playButtonImage = [NSObject __fw_bundleImage:@"fw.videoStart"];
    appearance.pauseButtonImage = [NSObject __fw_bundleImage:@"fw.videoPause"];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        _playButton = [[UIButton alloc] init];
        self.playButton.__fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [self.playButton setImage:self.playButtonImage forState:UIControlStateNormal];
        [self addSubview:self.playButton];
        
        _pauseButton = [[UIButton alloc] init];
        self.pauseButton.hidden = YES;
        self.pauseButton.__fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [self.pauseButton setImage:self.pauseButtonImage forState:UIControlStateNormal];
        [self addSubview:self.pauseButton];
        
        _slider = [[UISlider alloc] init];
        self.slider.minimumTrackTintColor = [UIColor colorWithRed:195/255.f green:195/255.f blue:195/255.f alpha:1];
        self.slider.maximumTrackTintColor = [UIColor colorWithRed:95/255.f green:95/255.f blue:95/255.f alpha:1];
        self.slider.__fw_thumbSize = CGSizeMake(12, 12);
        self.slider.__fw_thumbColor = UIColor.whiteColor;
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

- (CGFloat)maxHeightAmongViews:(NSArray<UIView *> *)views {
    __block CGFloat maxValue = 0;
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat height = [obj sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height;
        maxValue = MAX(height, maxValue);
    }];
    return maxValue;
}

@end
