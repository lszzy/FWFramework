/*!
 @header     FWPhotoBrowser.m
 @indexgroup FWFramework
 @brief      FWPhotoBrowser
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/24
 */

#import "FWPhotoBrowser.h"
#import "FWAutoLayout.h"
#import "FWProgressView.h"
#import "FWNavigation.h"
#import "FWMessage.h"
#import "FWToolkit.h"
#import "FWImage.h"

#pragma mark - FWPhotoView

@interface FWPhotoPlayerView : UIView

@end

@implementation FWPhotoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end

@interface FWPhotoView() <UIScrollViewDelegate>

@property (nonatomic, assign) CGSize showPictureSize;

@property (nonatomic, assign) BOOL doubleClicks;

@property (nonatomic, assign) CGPoint lastContentOffset;

@property (nonatomic, assign) CGFloat scale;

@property (nonatomic, assign) CGFloat offsetY;

@property (nonatomic, weak) FWProgressView *progressView;

@property (nonatomic, assign) BOOL showAnimation;

@property (nonatomic, strong) PHLivePhotoView *livePhotoView;

@property (nonatomic, strong) UIView *videoPlayerView;

@property (nonatomic, strong) AVPlayer *videoPlayer;

@property (nonatomic, strong) UIButton *videoPlayButton;

@property (nonatomic, assign) NSInteger showType;

@end

@implementation FWPhotoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.delegate = self;
    scrollView.alwaysBounceVertical = true;
    scrollView.backgroundColor = [UIColor clearColor];
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    scrollView.showsHorizontalScrollIndicator = false;
    scrollView.showsVerticalScrollIndicator = false;
    scrollView.maximumZoomScale = 2;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView = scrollView;
    [self addSubview:scrollView];
    
    // 添加 imageView
    Class imageClass = [UIImageView fwImageViewAnimatedClass];
    UIImageView *imageView = [[imageClass alloc] init];
    imageView.clipsToBounds = true;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.frame = self.bounds;
    imageView.userInteractionEnabled = true;
    _imageView = imageView;
    [scrollView addSubview:imageView];
    
    // 添加进度view
    FWProgressView *progressView = [[FWProgressView alloc] init];
    _progressView = progressView;
    [scrollView addSubview:progressView];
    
    // 添加监听事件
    UITapGestureRecognizer *doubleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleClick:)];
    doubleTapGes.numberOfTapsRequired = 2;
    [imageView addGestureRecognizer:doubleTapGes];
}

#pragma mark - 外部方法

- (void)animationShowWithFromRect:(CGRect)rect animationBlock:(void (^)(void))animationBlock completionBlock:(void (^)(void))completionBlock {
    _imageView.frame = rect;
    self.showAnimation = true;
    [UIView animateWithDuration:0.25 animations:^{
        if (animationBlock != nil) {
            animationBlock();
        }
        self.imageView.frame = [self getImageActualFrame:self.showPictureSize];
    } completion:^(BOOL finished) {
        if (finished) {
            if (completionBlock) {
                completionBlock();
            }
        }
        self.showAnimation = false;
    }];
}

- (void)animationDismissWithToRect:(CGRect)rect animationBlock:(void (^)(void))animationBlock completionBlock:(void (^)(void))completionBlock {
    
    // 隐藏进度视图
    self.progressView.hidden = true;
    _videoPlayButton.hidden = true;
    [UIView animateWithDuration:0.25 animations:^{
        if (animationBlock) {
            animationBlock();
        }
        CGRect toRect = rect;
        toRect.origin.y += self.offsetY;
        // 这一句话用于在放大的时候去关闭
        toRect.origin.x += self.scrollView.contentOffset.x;
        self.imageView.frame = toRect;
    } completion:^(BOOL finished) {
        if (finished) {
            if (completionBlock) {
                completionBlock();
            }
        }
    }];
}

#pragma mark - 私有方法

- (void)pauseAll {
    if (_videoPlayer) {
        [_videoPlayer pause];
        [_videoPlayer seekToTime:CMTimeMake(0, 1)];
        _videoPlayButton.hidden = NO;
    }
}

- (void)clearAll {
    [self.imageView fwCancelImageRequest];
    self.imageView.image = nil;
    _livePhotoView.livePhoto = nil;
    [self playClear];
    _urlString = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.progressView.center = CGPointMake(self.scrollView.frame.size.width * 0.5, self.scrollView.frame.size.height * 0.5);
}

- (PHLivePhotoView *)livePhotoView {
    if (!_livePhotoView) {
        _livePhotoView = [[PHLivePhotoView alloc] initWithFrame:self.imageView.bounds];
        _livePhotoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _livePhotoView.hidden = YES;
        [self.imageView addSubview:_livePhotoView];
    }
    return _livePhotoView;
}

- (UIView *)videoPlayerView {
    if (!_videoPlayerView) {
        _videoPlayerView = [[FWPhotoPlayerView alloc] initWithFrame:self.imageView.bounds];
        _videoPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _videoPlayerView.hidden = YES;
        [self.imageView addSubview:_videoPlayerView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playToggle)];
        [_videoPlayerView addGestureRecognizer:tapGesture];
    }
    return _videoPlayerView;
}

- (AVPlayerLayer *)videoPlayerLayer {
    return (AVPlayerLayer *)self.videoPlayerView.layer;
}

- (UIButton *)videoPlayButton {
    if (!_videoPlayButton) {
        _videoPlayButton = [[UIButton alloc] init];
        [_videoPlayButton setImage:[self videoPlayImage] forState:UIControlStateNormal];
        [_videoPlayButton addTarget:self action:@selector(playStart) forControlEvents:UIControlEventTouchUpInside];
        _videoPlayButton.hidden = YES;
        [self.imageView addSubview:_videoPlayButton];
        [_videoPlayButton fwAlignCenterToSuperview];
    }
    return _videoPlayButton;
}

- (UIImage *)videoPlayImage {
    CGFloat width = 60;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width), NO, 0);
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    if (!contextRef) return nil;
    
    UIColor *color = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.75];
    CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
    CGContextSetFillColorWithColor(contextRef, [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor);
    CGFloat circleLineWidth = 1;
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(circleLineWidth / 2, circleLineWidth / 2, width - circleLineWidth, width - circleLineWidth)];
    [circle setLineWidth:circleLineWidth];
    [circle stroke];
    [circle fill];
    
    CGContextSetFillColorWithColor(contextRef, color.CGColor);
    CGFloat triangleLength = width / 2.5;
    UIBezierPath *triangle = [UIBezierPath bezierPath];
    [triangle moveToPoint:CGPointZero];
    [triangle addLineToPoint:CGPointMake(triangleLength * cos(M_PI / 6), triangleLength / 2)];
    [triangle addLineToPoint:CGPointMake(0, triangleLength)];
    [triangle closePath];
    
    UIOffset offset = UIOffsetMake(width / 2 - triangleLength * tan(M_PI / 6) / 2, width / 2 - triangleLength / 2);
    [triangle applyTransform:CGAffineTransformMakeTranslation(offset.horizontal, offset.vertical)];
    [triangle fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)showImage:(UIImage *)image {
    self.showType = 0;
    if (image) {
        self.imageView.image = image;
        [self setPictureSize:image.size];
    } else {
        self.imageView.image = self.placeholderImage;
    }
    _livePhotoView.hidden = YES;
    _livePhotoView.livePhoto = nil;
    [self playClear];
}

- (void)showLivePhoto:(PHLivePhoto *)livePhoto {
    self.showType = 1;
    self.imageView.image = nil;
    self.livePhotoView.hidden = NO;
    self.livePhotoView.livePhoto = livePhoto;
    [self setPictureSize:livePhoto.size];
    [self playClear];
}

- (void)showPlayerItem:(AVPlayerItem *)playerItem {
    self.showType = 2;
    self.imageView.image = nil;
    _livePhotoView.hidden = YES;
    _livePhotoView.livePhoto = nil;
    [self playClear];
    
    NSArray<AVAssetTrack *> *tracksArray = playerItem.asset.tracks;
    CGSize videoSize = CGSizeZero;
    for (AVAssetTrack *track in tracksArray) {
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            CGSize size = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
            videoSize = CGSizeMake(fabs(size.width), fabs(size.height));
            break;
        }
    }
    
    self.videoPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    self.videoPlayerLayer.player = self.videoPlayer;
    [self setPictureSize:videoSize];
    
    // 添加监听
    [self fwObserveNotification:AVPlayerItemDidPlayToEndTimeNotification object:playerItem target:self action:@selector(playEnd)];
    [self fwObserveNotification:UIApplicationDidEnterBackgroundNotification target:self action:@selector(playPause)];
    
    self.videoPlayerView.hidden = NO;
    self.videoPlayButton.hidden = NO;
}

- (void)setShowAnimation:(BOOL)showAnimation {
    _showAnimation = showAnimation;
    if (showAnimation == true) {
        self.progressView.hidden = true;
    }else {
        self.progressView.hidden = self.progressView.progress == 1;
    }
}

- (void)setUrlString:(id)urlString {
    _urlString = urlString;
    [self.imageView fwCancelImageRequest];
    self.imageLoaded = NO;
    if ([urlString isKindOfClass:[NSString class]] && [[urlString lowercaseString] hasPrefix:@"http"]) {
        self.progress = 0.01;
        // 优先使用插件，否则使用默认
        __weak __typeof__(self) self_weak_ = self;
        [self.imageView fwSetImageWithURL:urlString placeholderImage:self.placeholderImage options:0 completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
            __typeof__(self) self = self_weak_;
            [self showImage:image];
            self.progress = 1;
            self.imageLoaded = image ? YES : NO;
            
            [self.pictureDelegate photoViewLoaded:self];
        } progress:^(double progress) {
            __typeof__(self) self = self_weak_;
            self.progressView.progress = progress;
        }];
    } else if ([urlString isKindOfClass:[PHLivePhoto class]]) {
        [self showLivePhoto:(PHLivePhoto *)urlString];
        self.progress = 1;
        self.imageLoaded = YES;
        
        [_pictureDelegate photoViewLoaded:self];
    } else if ([urlString isKindOfClass:[AVPlayerItem class]]) {
        [self showPlayerItem:(AVPlayerItem *)urlString];
        self.progress = 1;
        self.imageLoaded = YES;
        
        [_pictureDelegate photoViewLoaded:self];
    } else {
        UIImage *image = nil;
        if ([urlString isKindOfClass:[NSString class]]) {
            image = [UIImage fwImageNamed:urlString];
        } else if ([urlString isKindOfClass:[UIImage class]]) {
            image = (UIImage *)urlString;
        }
        [self showImage:image];
        self.progress = 1;
        self.imageLoaded = image ? YES : NO;
        
        [_pictureDelegate photoViewLoaded:self];
    }
}

- (CGFloat)progress
{
    return self.progressView.progress;
}

- (void)setProgress:(CGFloat)progress
{
    self.progressView.progress = progress;
    if (progress >= 1) {
        if (!self.userInteractionEnabled) self.userInteractionEnabled = true;
        if (!self.progressView.hidden) self.progressView.hidden = true;
    } else {
        if (self.userInteractionEnabled) self.userInteractionEnabled = false;
        if (self.showAnimation == false) self.progressView.hidden = false;
    }
}

- (void)setContentSize:(CGSize)contentSize {
    self.scrollView.contentSize = contentSize;
    if (self.scrollView.zoomScale == 1) {
        [UIView animateWithDuration:0.25 animations:^{
            CGPoint center = self.imageView.center;
            center.x = self.scrollView.contentSize.width * 0.5;
            self.imageView.center = center;
        }];
    }
}

- (void)setLastContentOffset:(CGPoint)lastContentOffset {
    // 如果用户没有在拖动，并且绽放比 > 0.15
    if (!(self.scrollView.dragging == false && _scale > 0.15)) {
        _lastContentOffset = lastContentOffset;
    }
}

- (void)setPictureSize:(CGSize)pictureSize {
    _pictureSize = pictureSize;
    if (CGSizeEqualToSize(pictureSize, CGSizeZero)) {
        return;
    }
    // 计算实际的大小
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat scale = screenW / pictureSize.width;
    CGFloat height = scale * pictureSize.height;
    self.showPictureSize = CGSizeMake(screenW, height);
}

- (void)setShowPictureSize:(CGSize)showPictureSize {
    _showPictureSize = showPictureSize;
    self.imageView.frame = [self getImageActualFrame:_showPictureSize];
    [self setContentSize:self.imageView.frame.size];
}

- (CGRect)getImageActualFrame:(CGSize)imageSize {
    CGFloat x = 0;
    CGFloat y = 0;
    
    if (imageSize.height < [UIScreen mainScreen].bounds.size.height) {
        y = ([UIScreen mainScreen].bounds.size.height - imageSize.height) / 2;
    }
    return CGRectMake(x, y, imageSize.width, imageSize.height);
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center{
    CGRect zoomRect;
    zoomRect.size.height =self.scrollView.frame.size.height / scale;
    zoomRect.size.width  =self.scrollView.frame.size.width  / scale;
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    return zoomRect;
}

#pragma mark - 监听方法

- (void)playToggle {
    if (self.videoPlayButton.hidden) {
        [self playPause];
    } else {
        [self playStart];
    }
}

- (void)playStart {
    [self.videoPlayer play];
    self.videoPlayButton.hidden = YES;
}

- (void)playPause {
    [self.videoPlayer pause];
    self.videoPlayButton.hidden = NO;
}

- (void)playEnd {
    [self.videoPlayer seekToTime:CMTimeMake(0, 1)];
    self.videoPlayButton.hidden = NO;
}

- (void)playClear {
    _videoPlayerView.hidden = YES;
    _videoPlayButton.hidden = YES;
    [self fwUnobserveNotification:AVPlayerItemDidPlayToEndTimeNotification];
    [self fwUnobserveNotification:UIApplicationDidEnterBackgroundNotification];
    _videoPlayer = nil;
    ((AVPlayerLayer *)_videoPlayerView.layer).player = nil;
}

- (void)doubleClick:(UITapGestureRecognizer *)ges {
    CGFloat newScale = 2;
    if (_doubleClicks) {
        newScale = 1;
    }
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[ges locationInView:ges.view]];
    [self.scrollView zoomToRect:zoomRect animated:YES];
    _doubleClicks = !_doubleClicks;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.lastContentOffset = scrollView.contentOffset;
    // 保存 offsetY
    _offsetY = scrollView.contentOffset.y;
    
    // 正在动画
    if ([self.imageView.layer animationForKey:@"transform"] != nil) {
        return;
    }
    // 用户正在缩放
    if (self.scrollView.zoomBouncing || self.scrollView.zooming) {
        return;
    }
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    // 滑动到中间
    if (scrollView.contentSize.height > screenH) {
        // 代表没有滑动到底部
        if (_lastContentOffset.y > 0 && _lastContentOffset.y <= scrollView.contentSize.height - screenH) {
            return;
        }
    }
    _scale = fabs(_lastContentOffset.y) / screenH;
    
    // 如果内容高度 > 屏幕高度
    // 并且偏移量 > 内容高度 - 屏幕高度
    // 那么就代表滑动到最底部了
    if (scrollView.contentSize.height > screenH &&
        _lastContentOffset.y > scrollView.contentSize.height - screenH) {
        _scale = (_lastContentOffset.y - (scrollView.contentSize.height - screenH)) / screenH;
    }
    
    // 条件1：拖动到顶部再继续往下拖
    // 条件2：拖动到顶部再继续往上拖
    // 两个条件都满足才去设置 scale -> 针对于长图
    if (scrollView.contentSize.height > screenH) {
        // 长图
        if (scrollView.contentOffset.y < 0 || _lastContentOffset.y > scrollView.contentSize.height - screenH) {
            [_pictureDelegate photoView:self scale:_scale];
        }
    }else {
        [_pictureDelegate photoView:self scale:_scale];
    }
    
    // 如果用户松手
    if (scrollView.dragging == false) {
        if (_scale > 0.15 && _scale <= 1) {
            // 关闭
            [_pictureDelegate photoViewClicked:self];
            // 设置 contentOffset
            [scrollView setContentOffset:_lastContentOffset animated:false];
        }
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGPoint center = _imageView.center;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    center.y = scrollView.contentSize.height * 0.5 + offsetY;
    _imageView.center = center;
    
    // 如果是缩小，保证在屏幕中间
    if (scrollView.zoomScale < scrollView.minimumZoomScale) {
        CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
        center.x = scrollView.contentSize.width * 0.5 + offsetX;
        _imageView.center = center;
    }
}

@end

#pragma mark - FWPhotoBrowser

@interface FWPhotoBrowser() <UIScrollViewDelegate, FWPhotoViewDelegate>

/// 图片数组
@property (nonatomic, strong) NSMutableArray<FWPhotoView *> *photoViews;
/// 当前页数
@property (nonatomic, assign) NSInteger currentPage;
/// 界面子控件
@property (nonatomic, weak) UIScrollView *scrollView;
/// 页码文字控件
@property (nonatomic, strong) UILabel *pageTextLabel;
/// 消失的 tap 手势
@property (nonatomic, weak) UITapGestureRecognizer *dismissTapGes;
/// 来源视图，默认dismiss位置，delegate可覆盖
@property (nonatomic, weak) UIView *fromView;

@end

@implementation FWPhotoBrowser

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.frame = [UIScreen mainScreen].bounds;
    self.backgroundColor = [UIColor clearColor];
    
    // 设置默认属性
    self.statusBarHidden = YES;
    self.imagesSpacing = 20;
    self.pageTextFont = [UIFont systemFontOfSize:16];
    self.pageTextCenter = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height - (20 + UIScreen.fwSafeAreaInsets.bottom));
    self.pageTextColor = [UIColor whiteColor];
    // 初始化数组
    self.photoViews = [NSMutableArray array];
    
    // 初始化 scrollView
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(-_imagesSpacing * 0.5, 0, self.frame.size.width + _imagesSpacing, self.frame.size.height)];
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    scrollView.showsVerticalScrollIndicator = false;
    scrollView.showsHorizontalScrollIndicator = false;
    scrollView.pagingEnabled = true;
    scrollView.delegate = self;
    [self addSubview:scrollView];
    self.scrollView = scrollView;
    
    // 初始化label
    UILabel *label = [[UILabel alloc] init];
    label.alpha = 0;
    label.textColor = self.pageTextColor;
    label.center = self.pageTextCenter;
    label.font = self.pageTextFont;
    [self addSubview:label];
    self.pageTextLabel = label;
    
    // 添加手势事件
    UILongPressGestureRecognizer *longGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:longGes];
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGes:)];
    [self addGestureRecognizer:tapGes];
    self.dismissTapGes = tapGes;
}

- (void)setPictureUrls:(NSArray *)pictureUrls {
    _pictureUrls = pictureUrls;
    self.picturesCount = pictureUrls.count;
}

- (NSInteger)currentIndex {
    return _currentPage;
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentPage = currentIndex;
}

- (void)showFromView:(UIView *)fromView {
    // 记录值并设置位置
    _fromView = fromView;
    [self setPageText:_currentPage];
    // 添加到 window 上
    UIWindow *window = UIWindow.fwMainWindow;
    // 隐藏状态栏
    if (self.statusBarHidden) {
        window.windowLevel = UIWindowLevelStatusBar + 10.f;
    }
    [window addSubview:self];
    // 计算 scrollView 的 contentSize
    self.scrollView.contentSize = CGSizeMake(_picturesCount * _scrollView.frame.size.width, _scrollView.frame.size.height);
    // 滚动到指定位置
    [self.scrollView setContentOffset:CGPointMake(_currentPage * _scrollView.frame.size.width, 0) animated:false];
    // 设置第1个 view 的位置以及大小
    FWPhotoView *photoView = nil;
    // 获取来源图片在屏幕上的位置
    CGRect rect = CGRectZero;
    if (fromView) {
        photoView = [self setPictureViewForIndex:_currentPage defaultSize:fromView.bounds.size];
        rect = [fromView convertRect:fromView.bounds toView:nil];
    } else {
        photoView = [self setPictureViewForIndex:_currentPage defaultSize:CGSizeMake(0.01, 0.01)];
        rect = CGRectMake([UIScreen mainScreen].bounds.size.width * 0.5, [UIScreen mainScreen].bounds.size.height * 0.5, 0, 0);
    }
    
    [photoView animationShowWithFromRect:rect animationBlock:^{
        self.backgroundColor = [UIColor blackColor];
        self.pageTextLabel.alpha = 1;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoBrowser:willShowPhotoView:)]) {
            [self.delegate photoBrowser:self willShowPhotoView:photoView];
        }
    } completionBlock:^{
        // 设置左边与右边的 photoView
        if (self.currentPage != 0 && self.picturesCount > 1) {
            // 设置左边
            [self setPictureViewForIndex:self.currentPage - 1 defaultSize:CGSizeZero];
        }
        
        if (self.currentPage < self.picturesCount - 1) {
            // 设置右边
            [self setPictureViewForIndex:self.currentPage + 1 defaultSize:CGSizeZero];
        }
    }];
}

- (void)show {
    [self showFromView:nil];
}

- (void)dismiss {
    CGFloat x = [UIScreen mainScreen].bounds.size.width * 0.5;
    CGFloat y = [UIScreen mainScreen].bounds.size.height * 0.5;
    CGRect rect = CGRectMake(x - 0.5, y - 0.5, 1, 1);
    UIView *endView = _fromView;
    if ([_delegate respondsToSelector:@selector(photoBrowser:viewForIndex:)]) {
        id v = [_delegate photoBrowser:self viewForIndex:_currentPage];
        endView = [v isKindOfClass:[UIView class]] ? (UIView *)v : nil;
        if ([v isKindOfClass:[NSValue class]]) {
            rect = [((NSValue *)v) CGRectValue];
        }
    }
    if (endView.superview != nil) {
        rect = [endView convertRect:endView.bounds toView:nil];
    } else if (endView != nil) {
        rect = endView.frame;
    }
    
    // 取到当前显示的 photoView
    FWPhotoView *photoView = [[_photoViews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"index == %d", _currentPage]] firstObject];
    
    // 显示状态栏
    if (self.statusBarHidden) {
        UIWindow.fwMainWindow.windowLevel = UIWindowLevelNormal;
    }
    
    // 执行关闭动画
    [photoView animationDismissWithToRect:rect animationBlock:^{
        self.backgroundColor = [UIColor clearColor];
        self.pageTextLabel.alpha = 0;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoBrowser:willDismissPhotoView:)]) {
            [self.delegate photoBrowser:self willDismissPhotoView:photoView];
        }
    } completionBlock:^{
        [self.photoViews enumerateObjectsUsingBlock:^(FWPhotoView *obj, NSUInteger idx, BOOL *stop) {
            [obj clearAll];
            [obj removeFromSuperview];
        }];
        [self.photoViews removeAllObjects];
        [self removeFromSuperview];
    }];
}

#pragma mark - 监听事件

- (void)tapGes:(UITapGestureRecognizer *)ges {
    [self dismiss];
}

- (void)longPress:(UILongPressGestureRecognizer *)ges {
    if (ges.state == UIGestureRecognizerStateBegan) {
        if (self.longPressBlock) {
            self.longPressBlock(_currentPage);
        }
    }
}

#pragma mark - 私有方法

- (void)setPageTextFont:(UIFont *)pageTextFont {
    _pageTextFont = pageTextFont;
    self.pageTextLabel.font = pageTextFont;
}

- (void)setPageTextColor:(UIColor *)pageTextColor {
    _pageTextColor = pageTextColor;
    self.pageTextLabel.textColor = pageTextColor;
}

- (void)setPageTextCenter:(CGPoint)pageTextCenter {
    _pageTextCenter = pageTextCenter;
    [self.pageTextLabel sizeToFit];
    self.pageTextLabel.center = pageTextCenter;
}

- (void)setImagesSpacing:(CGFloat)imagesSpacing {
    _imagesSpacing = imagesSpacing;
    self.scrollView.frame = CGRectMake(-_imagesSpacing * 0.5, 0, self.frame.size.width + _imagesSpacing, self.frame.size.height);
}

- (void)setCurrentPage:(NSInteger)currentPage {
    if (_currentPage == currentPage) {
        return;
    }
    
    NSUInteger oldValue = _currentPage;
    _currentPage = currentPage;
    [self setPageText:currentPage];
    // 如果新值大于旧值
    if (currentPage > oldValue) {
        // 往右滑，设置右边的视图
        if (currentPage + 1 < _picturesCount) {
            [self setPictureViewForIndex:currentPage + 1 defaultSize:CGSizeZero];
        }
    }else {
        // 往左滑，设置左边的视图
        if (currentPage > 0) {
            [self setPictureViewForIndex:currentPage - 1 defaultSize:CGSizeZero];
        }
    }
    
    // 清理未显示的photoView内存
    [self clearPhotoView:currentPage previousIndex:oldValue];
}

/**
 设置pitureView到指定位置
 
 @param index 索引
 @param defaultSize 默认图片大小，在下载完毕之后会根据下载的图片计算大小
 
 @return 当前设置的控件
 */
- (FWPhotoView *)setPictureViewForIndex:(NSInteger)index defaultSize:(CGSize)defaultSize {
    FWPhotoView *view = [self getPhotoView:index];
    CGRect frame = view.frame;
    frame.size = self.frame.size;
    view.frame = frame;
    CGPoint center = view.center;
    center.x = index * _scrollView.frame.size.width + _scrollView.frame.size.width * 0.5;
    view.center = center;
    
    // 加载自定义视图
    if ([_delegate respondsToSelector:@selector(photoBrowser:startLoadPhotoView:)]) {
        [_delegate photoBrowser:self startLoadPhotoView:view];
    }
    
    // 1. 判断是否实现图片大小的方法
    if ([_delegate respondsToSelector:@selector(photoBrowser:imageSizeForIndex:)]) {
        view.pictureSize = [_delegate photoBrowser:self imageSizeForIndex:index];
    }else if ([_delegate respondsToSelector:@selector(photoBrowser:placeholderImageForIndex:)]) {
        UIImage *image = [_delegate photoBrowser:self placeholderImageForIndex:index];
        // 2. 如果没有实现，判断是否有默认图片，获取默认图片大小
        view.pictureSize = image != nil ? image.size : defaultSize;
    } else if ([_delegate respondsToSelector:@selector(photoBrowser:viewForIndex:)]) {
        id v = [_delegate photoBrowser:self viewForIndex:index];
        if (v && [v isKindOfClass:[UIImageView class]]) {
            UIImage *image = ((UIImageView *)v).image;
            view.pictureSize = image != nil ? image.size : defaultSize;
            // 并且设置占位图片
            view.placeholderImage = image;
        }else {
            view.pictureSize = defaultSize;
        }
    }else {
        // 3. 如果都没有就设置为屏幕宽度，待下载完成之后再次计算
        view.pictureSize = defaultSize;
    }
    
    // 设置占位图
    if ([_delegate respondsToSelector:@selector(photoBrowser:placeholderImageForIndex:)]) {
        view.placeholderImage = [_delegate photoBrowser:self placeholderImageForIndex:index];
    }
    
    if ([_delegate respondsToSelector:@selector(photoBrowser:photoUrlForIndex:)]) {
        view.urlString = [_delegate photoBrowser:self photoUrlForIndex:index];
    } else if ([_delegate respondsToSelector:@selector(photoBrowser:loadPhotoForIndex:photoView:)]) {
        [_delegate photoBrowser:self loadPhotoForIndex:index photoView:view];
    } else {
        view.urlString = index < self.pictureUrls.count ? self.pictureUrls[index] : nil;
    }
    return view;
}

/**
 获取图片控件：如果缓存里面有，那就从缓存里面取，没有就创建
 
 @return 图片控件
 */
- (FWPhotoView *)getPhotoView:(NSInteger)index {
    for (FWPhotoView *photoView in self.photoViews) {
        if (photoView.index == index) return photoView;
    }
    
    FWPhotoView *view = [FWPhotoView new];
    view.index = index;
    // 手势事件冲突处理
    [self.dismissTapGes requireGestureRecognizerToFail:view.imageView.gestureRecognizers.firstObject];
    view.pictureDelegate = self;
    [_scrollView addSubview:view];
    [_photoViews addObject:view];
    return view;
}

/**
 清理未显示的photoView，最多7个
 */
- (void)clearPhotoView:(NSInteger)index previousIndex:(NSInteger)previousIndex {
    [self.photoViews enumerateObjectsUsingBlock:^(FWPhotoView *photoView, NSUInteger idx, BOOL *stop) {
        if (photoView.index == previousIndex) [photoView pauseAll];
        if (photoView.index >= index - 3 && photoView.index <= index + 3) return;
        
        [photoView clearAll];
        [photoView removeFromSuperview];
        [self.photoViews removeObject:photoView];
    }];
}

/**
 设置文字，并设置位置
 */
- (void)setPageText:(NSUInteger)index {
    _pageTextLabel.text = [NSString stringWithFormat:@"%@ / %@", @(index + 1), @(self.picturesCount)];
    [_pageTextLabel sizeToFit];
    _pageTextLabel.center = self.pageTextCenter;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSUInteger page = (scrollView.contentOffset.x / scrollView.frame.size.width + 0.5);
    if (self.currentPage != page) {
        if ([_delegate respondsToSelector:@selector(photoBrowser:scrollToIndex:)]) {
            [_delegate photoBrowser:self scrollToIndex: page];
        }
        self.currentPage = page;
    }
}

#pragma mark - FWPhotoViewDelegate

- (void)photoViewClicked:(FWPhotoView *)photoView {
    [self dismiss];
}

- (void)photoView:(FWPhotoView *)photoView scale:(CGFloat)scale {
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1 - scale];
}

- (void)photoViewLoaded:(FWPhotoView *)photoView {
    if ([_delegate respondsToSelector:@selector(photoBrowser:finishLoadPhotoView:)]) {
        [_delegate photoBrowser:self finishLoadPhotoView:photoView];
    }
}

@end
