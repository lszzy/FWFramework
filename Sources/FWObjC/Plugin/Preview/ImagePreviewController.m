//
//  ImagePreviewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ImagePreviewController.h"
#import <FWFramework/FWFramework-Swift.h>

#pragma mark - __FWImagePreviewView

@interface __FWImagePreviewCell : UICollectionViewCell

@property(nonatomic, strong) __FWZoomImageView *zoomImageView;
@property(nonatomic, assign) CGRect contentViewBounds;

@end

@implementation __FWImagePreviewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;

        self.zoomImageView = [[__FWZoomImageView alloc] init];
        [self.contentView addSubview:self.zoomImageView];
        self.contentViewBounds = self.contentView.bounds;
        self.zoomImageView.__fw_frameApplyTransform = self.contentView.bounds;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.contentView.bounds, self.contentViewBounds)) {
        self.contentViewBounds = self.contentView.bounds;
        self.zoomImageView.__fw_frameApplyTransform = self.contentView.bounds;
    }
}

@end

static NSString * const kLivePhotoCellIdentifier = @"livephoto";
static NSString * const kVideoCellIdentifier = @"video";
static NSString * const kImageOrUnknownCellIdentifier = @"imageorunknown";

@interface __FWImagePreviewView ()

@property(nonatomic, assign) BOOL isChangingCollectionViewBounds;
@property(nonatomic, assign) BOOL isChangingIndexWhenScrolling;
@property(nonatomic, assign) CGFloat previousIndexWhenScrolling;
@property(nonatomic, weak) __FWImagePreviewController *previewController;

@end

@implementation __FWImagePreviewView

@synthesize currentImageIndex = _currentImageIndex;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self didInitializedWithFrame:frame];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitializedWithFrame:self.frame];
    }
    return self;
}

- (void)didInitializedWithFrame:(CGRect)frame {
    _collectionViewLayout = [[__FWCollectionViewPagingLayout alloc] initWithStyle:__FWCollectionViewPagingLayoutStyleDefault];
    self.collectionViewLayout.allowsMultipleItemScroll = NO;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) collectionViewLayout:self.collectionViewLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.scrollsToTop = NO;
    self.collectionView.delaysContentTouches = NO;
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.collectionView registerClass:[__FWImagePreviewCell class] forCellWithReuseIdentifier:kImageOrUnknownCellIdentifier];
    [self.collectionView registerClass:[__FWImagePreviewCell class] forCellWithReuseIdentifier:kVideoCellIdentifier];
    [self.collectionView registerClass:[__FWImagePreviewCell class] forCellWithReuseIdentifier:kLivePhotoCellIdentifier];
    [self addSubview:self.collectionView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isCollectionViewSizeChanged = !CGSizeEqualToSize(self.collectionView.bounds.size, self.bounds.size);
    if (isCollectionViewSizeChanged) {
        self.isChangingCollectionViewBounds = YES;
        
        // 必须先 invalidateLayout，再更新 collectionView.frame，否则横竖屏旋转前后的图片不一致（因为 scrollViewDidScroll: 时 contentSize、contentOffset 那些是错的）
        [self.collectionViewLayout invalidateLayout];
        self.collectionView.frame = self.bounds;
        if (self.currentImageIndex < [self.collectionView numberOfItemsInSection:0]) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentImageIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
        
        self.isChangingCollectionViewBounds = NO;
    }
}

- (void)setCurrentImageIndex:(NSInteger)currentImageIndex {
    [self setCurrentImageIndex:currentImageIndex animated:NO];
}

- (void)setCurrentImageIndex:(NSInteger)currentImageIndex animated:(BOOL)animated {
    _currentImageIndex = currentImageIndex;
    _isChangingIndexWhenScrolling = NO;
    [self.previewController updatePageLabel];
    
    [self.collectionView reloadData];
    if (currentImageIndex < [self.collectionView numberOfItemsInSection:0]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentImageIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
        // [self.collectionView layoutIfNeeded];// scroll immediately
    }
}

- (NSInteger)imageCount {
    return [self.collectionView numberOfItemsInSection:0];
}

#pragma mark - <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(numberOfImagesInImagePreviewView:)]) {
        return [self.delegate numberOfImagesInImagePreviewView:self];
    }
    return self.imageURLs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = kImageOrUnknownCellIdentifier;
    id imageURL = nil;
    if ([self.delegate respondsToSelector:@selector(imagePreviewView:assetTypeAtIndex:)]) {
        __FWImagePreviewMediaType type = [self.delegate imagePreviewView:self assetTypeAtIndex:indexPath.item];
        if (type == __FWImagePreviewMediaTypeLivePhoto) {
            identifier = kLivePhotoCellIdentifier;
        } else if (type == __FWImagePreviewMediaTypeVideo) {
            identifier = kVideoCellIdentifier;
        }
    } else if (self.imageURLs.count > indexPath.item) {
        imageURL = self.imageURLs[indexPath.item];
        if ([imageURL isKindOfClass:[PHLivePhoto class]]) {
            identifier = kLivePhotoCellIdentifier;
        } else if ([imageURL isKindOfClass:[AVPlayerItem class]]) {
            identifier = kVideoCellIdentifier;
        }
    }
    __FWImagePreviewCell *cell = (__FWImagePreviewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    __FWZoomImageView *zoomView = cell.zoomImageView;
    zoomView.delegate = self;
    
    // 因为 cell 复用的问题，很可能此时会显示一张错误的图片，因此这里要清空所有图片的显示
    BOOL shouldReset = YES;
    if ([self.delegate respondsToSelector:@selector(imagePreviewView:shouldResetZoomImageView:atIndex:)]) {
        shouldReset = [self.delegate imagePreviewView:self shouldResetZoomImageView:zoomView atIndex:indexPath.item];
    }
    if (shouldReset) {
        zoomView.image = nil;
        zoomView.videoPlayerItem = nil;
        zoomView.livePhoto = nil;
    }
    
    if (self.customZoomImageView) {
        self.customZoomImageView(zoomView, indexPath.item);
    }
    
    if ([self.delegate respondsToSelector:@selector(imagePreviewView:renderZoomImageView:atIndex:)]) {
        [self.delegate imagePreviewView:self renderZoomImageView:zoomView atIndex:indexPath.item];
    } else if (self.renderZoomImageView) {
        self.renderZoomImageView(zoomView, indexPath.item);
    } else if (self.imageURLs.count > indexPath.item) {
        UIImage *placeholderImage = self.placeholderImage ? self.placeholderImage(indexPath.item) : nil;
        [zoomView setImageURL:imageURL placeholderImage:placeholderImage completion:nil];
    }
    
    // 自动播放视频
    if (self.autoplayVideo && !self.isChangingIndexWhenScrolling) {
        if (zoomView && zoomView.videoPlayerItem) {
            [zoomView playVideo];
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    __FWImagePreviewCell *previewCell = (__FWImagePreviewCell *)cell;
    [previewCell.zoomImageView revertZooming];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    __FWImagePreviewCell *previewCell = (__FWImagePreviewCell *)cell;
    [previewCell.zoomImageView endPlayingVideo];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.bounds.size;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.collectionView) {
        return;
    }
    
    // 当前滚动到的页数
    if ([self.delegate respondsToSelector:@selector(imagePreviewView:didScrollToIndex:)]) {
        [self.delegate imagePreviewView:self didScrollToIndex:self.currentImageIndex];
    }
    
    // 自动播放视频
    if (self.autoplayVideo && self.isChangingIndexWhenScrolling) {
        __FWZoomImageView *zoomImageView = [self zoomImageViewAtIndex:self.currentImageIndex];
        if (zoomImageView && zoomImageView.videoPlayerItem) {
            [zoomImageView playVideo];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.collectionView) {
        return;
    }
    
    if (self.isChangingCollectionViewBounds) {
        return;
    }
    
    CGFloat pageWidth = [self collectionView:self.collectionView layout:self.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].width;
    CGFloat pageHorizontalMargin = self.collectionViewLayout.minimumLineSpacing;
    CGFloat contentOffsetX = self.collectionView.contentOffset.x;
    CGFloat index = contentOffsetX / (pageWidth + pageHorizontalMargin);
    
    // 在滑动过临界点的那一次才去调用 delegate，避免过于频繁的调用
    BOOL isFirstDidScroll = self.previousIndexWhenScrolling == 0;

    // fastToRight example : self.previousIndexWhenScrolling 1.49, index = 2.0
    BOOL fastToRight = (floor(index) - floor(self.previousIndexWhenScrolling) >= 1.0) && (floor(index) - self.previousIndexWhenScrolling > 0.5);
    BOOL turnPageToRight = fastToRight || (self.previousIndexWhenScrolling <= floor(index) + 0.5 && floor(index) + 0.5 <= index);

    // fastToLeft example : self.previousIndexWhenScrolling 2.51, index = 1.99
    BOOL fastToLeft = (floor(self.previousIndexWhenScrolling) - floor(index) >= 1.0) && (self.previousIndexWhenScrolling - ceil(index) > 0.5);
    BOOL turnPageToLeft = fastToLeft || (index <= floor(index) + 0.5 && floor(index) + 0.5 <= self.previousIndexWhenScrolling);
    
    if (!isFirstDidScroll && (turnPageToRight || turnPageToLeft)) {
        index = round(index);
        if (0 <= index && index < [self.collectionView numberOfItemsInSection:0]) {
            
            // 不调用 setter，避免又走一次 scrollToItem
            _currentImageIndex = index;
            _isChangingIndexWhenScrolling = YES;
            [self.previewController updatePageLabel];
            
            if ([self.delegate respondsToSelector:@selector(imagePreviewView:willScrollHalfToIndex:)]) {
                [self.delegate imagePreviewView:self willScrollHalfToIndex:index];
            }
        }
    }
    self.previousIndexWhenScrolling = index;
}

- (NSInteger)indexForZoomImageView:(__FWZoomImageView *)zoomImageView {
    if ([zoomImageView.superview.superview isKindOfClass:[__FWImagePreviewCell class]]) {
        return [self.collectionView indexPathForCell:(__FWImagePreviewCell *)zoomImageView.superview.superview].item;
    }
    return NSNotFound;
}

- (__FWZoomImageView *)zoomImageViewAtIndex:(NSInteger)index {
    __FWImagePreviewCell *cell = (__FWImagePreviewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return cell.zoomImageView;
}

- (__FWZoomImageView *)currentZoomImageView {
    return [self zoomImageViewAtIndex:self.currentImageIndex];
}

#pragma mark - <__FWZoomImageViewDelegate>

- (void)singleTouchInZoomingImageView:(__FWZoomImageView *)imageView location:(CGPoint)location {
    [self.previewController dismissingWhenTapped:imageView];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate singleTouchInZoomingImageView:imageView location:location];
    }
}

- (void)doubleTouchInZoomingImageView:(__FWZoomImageView *)imageView location:(CGPoint)location {
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate doubleTouchInZoomingImageView:imageView location:location];
    }
}

- (void)longPressInZoomingImageView:(__FWZoomImageView *)imageView {
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate longPressInZoomingImageView:imageView];
    }
}

- (void)zoomImageView:(__FWZoomImageView *)imageView didHideVideoToolbar:(BOOL)didHide {
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate zoomImageView:imageView didHideVideoToolbar:didHide];
    }
}

- (void)zoomImageView:(__FWZoomImageView *)imageView customContentView:(__kindof UIView *)contentView {
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate zoomImageView:imageView customContentView:contentView];
    } else if (self.customZoomContentView) {
        self.customZoomContentView(imageView, contentView);
    }
}

- (BOOL)enabledZoomViewInZoomImageView:(__FWZoomImageView *)imageView {
    if ([self.delegate respondsToSelector:_cmd]) {
        return [self.delegate enabledZoomViewInZoomImageView:imageView];
    }
    return YES;
}

@end

#pragma mark - __FWImagePreviewController

const CGFloat __FWImagePreviewCornerRadiusAutomaticDimension = -1;

@interface __FWImagePreviewController ()

@property(nonatomic, strong) UIPanGestureRecognizer *dismissingGesture;
@property(nonatomic, assign) CGPoint gestureBeganLocation;
@property(nonatomic, weak) __FWZoomImageView *gestureZoomImageView;
@property(nonatomic, assign) BOOL originalStatusBarHidden;
@property(nonatomic, assign) BOOL statusBarHidden;

@end

@implementation __FWImagePreviewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self didInitialize];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize {
    self.sourceImageCornerRadius = __FWImagePreviewCornerRadiusAutomaticDimension;
    _dismissingScaleEnabled = YES;
    _dismissingGestureEnabled = YES;
    self.backgroundColor = UIColor.blackColor;
    
    // present style
    self.transitioningAnimator = [[__FWImagePreviewTransitionAnimator alloc] init];
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.modalPresentationCapturesStatusBarAppearance = YES;
    self.transitioningDelegate = self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    if ([self isViewLoaded]) {
        self.view.backgroundColor = backgroundColor;
    }
}

@synthesize imagePreviewView = _imagePreviewView;
- (__FWImagePreviewView *)imagePreviewView {
    if (!_imagePreviewView) {
        _imagePreviewView = [[__FWImagePreviewView alloc] initWithFrame:self.isViewLoaded ? self.view.bounds : CGRectZero];
        _imagePreviewView.previewController = self;
    }
    return _imagePreviewView;
}

@synthesize pageLabel = _pageLabel;
- (UILabel *)pageLabel {
    if (!_pageLabel) {
        _pageLabel = [[UILabel alloc] init];
        _pageLabel.font = [UIFont systemFontOfSize:16];
        _pageLabel.textColor = [UIColor whiteColor];
        _pageLabel.textAlignment = NSTextAlignmentCenter;
        _pageLabel.hidden = YES;
    }
    return _pageLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = self.backgroundColor;
    [self.view addSubview:self.imagePreviewView];
    [self.view addSubview:self.pageLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.imagePreviewView.__fw_frameApplyTransform = self.view.bounds;
    
    if (self.pageLabel.text.length < 1 && self.imagePreviewView.imageCount > 0) {
        [self updatePageLabel];
    }
    CGPoint pageLabelCenter = self.pageLabelCenter ? self.pageLabelCenter() : CGPointMake(UIScreen.mainScreen.bounds.size.width / 2, UIScreen.mainScreen.bounds.size.height - (UIScreen.__fw_safeAreaInsets.bottom + 18));
    self.pageLabel.center = pageLabelCenter;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.__fw_isPresented) {
        [self initObjectsForZoomStyleIfNeeded];
    }
    [self.imagePreviewView.collectionView reloadData];
    [self.imagePreviewView.collectionView layoutIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.__fw_isPresented) {
        self.statusBarHidden = YES;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.statusBarHidden = self.originalStatusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self removeObjectsForZoomStyle];
    [self resetDismissingGesture];
}

- (void)setPresentingStyle:(__FWImagePreviewTransitioningStyle)presentingStyle {
    _presentingStyle = presentingStyle;
    self.dismissingStyle = presentingStyle;
}

- (void)setTransitioningAnimator:(__kindof __FWImagePreviewTransitionAnimator *)transitioningAnimator {
    _transitioningAnimator = transitioningAnimator;
    transitioningAnimator.imagePreviewViewController = self;
}

- (BOOL)prefersStatusBarHidden {
    if ([self __fw_isInvisibleState]) {
        // 在 present/dismiss 动画过程中，都使用原界面的状态栏显隐状态
        if (self.presentingViewController) {
            BOOL statusBarHidden = self.presentingViewController.view.window.windowScene.statusBarManager.statusBarHidden;
            self.originalStatusBarHidden = statusBarHidden;
            return self.originalStatusBarHidden;
        }
        return [super prefersStatusBarHidden];
    }
    return self.statusBarHidden;
}

- (BOOL)showsPageLabel {
    return !self.pageLabel.hidden;
}

- (void)setShowsPageLabel:(BOOL)showsPageLabel {
    self.pageLabel.hidden = !showsPageLabel;
}

- (void)updatePageLabel {
    if (self.pageLabelText) {
        self.pageLabel.text = self.pageLabelText(self.imagePreviewView.currentImageIndex, self.imagePreviewView.imageCount);
    } else {
        self.pageLabel.text = [NSString stringWithFormat:@"%@ / %@", @(self.imagePreviewView.currentImageIndex + 1), @(self.imagePreviewView.imageCount)];
    }
    [self.pageLabel sizeToFit];
    
    if (self.pageIndexChanged) {
        self.pageIndexChanged(self.imagePreviewView.currentImageIndex);
    }
}

#pragma mark - 动画

- (void)initObjectsForZoomStyleIfNeeded {
    if (!self.dismissingGesture && self.dismissingGestureEnabled) {
        self.dismissingGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissingPreviewGesture:)];
        [self.view addGestureRecognizer:self.dismissingGesture];
    }
}

- (void)removeObjectsForZoomStyle {
    [self.dismissingGesture removeTarget:self action:@selector(handleDismissingPreviewGesture:)];
    [self.view removeGestureRecognizer:self.dismissingGesture];
    self.dismissingGesture = nil;
}

- (void)handleDismissingPreviewGesture:(UIPanGestureRecognizer *)gesture {
    
    if (!self.dismissingGestureEnabled) return;
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.gestureBeganLocation = [gesture locationInView:self.view];
            self.gestureZoomImageView = self.imagePreviewView.currentZoomImageView;
            self.gestureZoomImageView.scrollView.clipsToBounds = NO;// 当 contentView 被放大后，如果不去掉 clipToBounds，那么手势退出预览时，contentView 溢出的那部分内容就看不到
            if (self.dismissingGestureEnabled) {
                [self dismissingGestureChanged:YES];
            }
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGPoint location = [gesture locationInView:self.view];
            CGFloat horizontalDistance = location.x - self.gestureBeganLocation.x;
            CGFloat verticalDistance = location.y - self.gestureBeganLocation.y;
            CGFloat ratio = 1.0;
            CGFloat alpha = 1.0;
            if (verticalDistance > 0) {
                // 往下拉的话，当启用图片缩小，但图片移动距离与手指移动距离保持一致
                if (self.dismissingScaleEnabled) {
                    ratio = 1.0 - verticalDistance / CGRectGetHeight(self.view.bounds) / 2;
                }
                
                // 如果预览大图支持横竖屏而背后的界面只支持竖屏，则在横屏时手势拖拽不要露出背后的界面
                if (self.dismissingGestureEnabled) {
                    alpha = 1.0 - verticalDistance / CGRectGetHeight(self.view.bounds) * 1.8;
                }
            } else {
                // 往上拉的话，图片不缩小，但手指越往上移动，图片将会越难被拖走
                CGFloat a = self.gestureBeganLocation.y + 100;// 后面这个加数越大，拖动时会越快达到不怎么拖得动的状态
                CGFloat b = 1 - pow((a - fabs(verticalDistance)) / a, 2);
                CGFloat contentViewHeight = CGRectGetHeight(self.gestureZoomImageView.contentViewRect);
                CGFloat c = (CGRectGetHeight(self.view.bounds) - contentViewHeight) / 2;
                verticalDistance = -c * b;
            }
            CGAffineTransform transform = CGAffineTransformMakeTranslation(horizontalDistance, verticalDistance);
            transform = CGAffineTransformScale(transform, ratio, ratio);
            self.gestureZoomImageView.transform = transform;
            self.view.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:alpha];
            BOOL statusBarHidden = alpha >= 1 ? YES : self.originalStatusBarHidden;
            if (statusBarHidden != self.statusBarHidden) {
                self.statusBarHidden = statusBarHidden;
                [self setNeedsStatusBarAppearanceUpdate];
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded: {
            CGPoint location = [gesture locationInView:self.view];
            CGFloat verticalDistance = location.y - self.gestureBeganLocation.y;
            if (verticalDistance > CGRectGetHeight(self.view.bounds) / 2 / 3) {
                
                // 如果背后的界面支持的方向与当前预览大图的界面不一样，则为了避免在 dismiss 后看到背后界面的旋转，这里提前触发背后界面的 viewWillAppear，从而借助 AutomaticallyRotateDeviceOrientation 的功能去提前旋转到正确方向。（备忘，如果不这么处理，标准的触发 viewWillAppear: 的时机是在 animator 的 animateTransition: 时，这里就算重复调用一次也不会导致 viewWillAppear: 多次触发）
                // 这里只能解决手势拖拽的 dismiss，如果是业务代码手动调用 dismiss 则无法兼顾，再看怎么处理。
                if (!self.dismissingGestureEnabled) {
                    [self.presentingViewController beginAppearanceTransition:YES animated:YES];
                }
                
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [self cancelDismissingGesture];
            }
        }
            break;
        default:
            [self cancelDismissingGesture];
            break;
    }
}

// 手势判定失败，恢复到手势前的状态
- (void)cancelDismissingGesture {
    self.statusBarHidden = YES;
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
        [self resetDismissingGesture];
    } completion:NULL];
}

// 清理手势相关的变量
- (void)resetDismissingGesture {
    self.gestureZoomImageView.transform = CGAffineTransformIdentity;
    self.gestureBeganLocation = CGPointZero;
    if (self.dismissingGestureEnabled) {
        [self dismissingGestureChanged:NO];
    }
    self.gestureZoomImageView = nil;
    self.view.backgroundColor = self.backgroundColor;
}

- (void)dismissingWhenTapped:(__FWZoomImageView *)zoomImageView {
    if (!self.__fw_isPresented) return;
    
    BOOL shouldDismiss = NO;
    if (zoomImageView.videoPlayerItem) {
        if (self.dismissingWhenTappedVideo) shouldDismiss = YES;
    } else {
        if (self.dismissingWhenTappedImage) shouldDismiss = YES;
    }
    if (shouldDismiss) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)dismissingGestureChanged:(BOOL)isHidden {
    __FWZoomImageView *zoomImageView = self.imagePreviewView.currentZoomImageView;
    if (zoomImageView.videoPlayerItem) {
        if (zoomImageView.showsVideoToolbar) zoomImageView.videoToolbar.alpha = isHidden ? 0 : 1;
        if (zoomImageView.showsVideoCloseButton) zoomImageView.videoCloseButton.alpha = isHidden ? 0 : 1;
    }
    [self.view.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        if (obj != self.imagePreviewView) {
            obj.alpha = isHidden ? 0 : 1;
        }
    }];
}

- (void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    [self dismissingGestureChanged:YES];
    [super dismissViewControllerAnimated:animated completion:completion];
}

#pragma mark - <UIViewControllerTransitioningDelegate>

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self.transitioningAnimator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self.transitioningAnimator;
}

@end

#pragma mark - __FWImagePreviewTransitionAnimator

@implementation __FWImagePreviewTransitionAnimator

- (instancetype)init {
    if (self = [super init]) {
        self.duration = .25;
        
        _cornerRadiusMaskLayer = [CALayer layer];
        [self.cornerRadiusMaskLayer __fw_removeDefaultAnimations];
        self.cornerRadiusMaskLayer.backgroundColor = [UIColor whiteColor].CGColor;
        
        self.animationEnteringBlock = ^(__kindof __FWImagePreviewTransitionAnimator * _Nonnull animator, BOOL isPresenting, __FWImagePreviewTransitioningStyle style, CGRect sourceImageRect, __FWZoomImageView * _Nonnull zoomImageView, id<UIViewControllerContextTransitioning>  _Nullable transitionContext) {
            
            UIView *previewView = animator.imagePreviewViewController.view;
            
            if (style == __FWImagePreviewTransitioningStyleFade) {
                
                previewView.alpha = isPresenting ? 0 : 1;
                
            } else if (style == __FWImagePreviewTransitioningStyleZoom) {
                
                CGRect contentViewFrame = [previewView convertRect:zoomImageView.contentViewRect fromView:nil];
                CGPoint contentViewCenterInZoomImageView = CGPointMake(CGRectGetMidX(zoomImageView.contentViewRect), CGRectGetMidY(zoomImageView.contentViewRect));
                if (CGRectIsEmpty(contentViewFrame)) {
                    // 有可能 start preview 时图片还在 loading，此时拿到的 content rect 是 zero，所以做个保护
                    contentViewFrame = [previewView convertRect:zoomImageView.frame fromView:zoomImageView.superview];
                    contentViewCenterInZoomImageView = CGPointMake(CGRectGetMidX(contentViewFrame), CGRectGetMidY(contentViewFrame));
                }
                CGPoint centerInZoomImageView = CGPointMake(CGRectGetMidX(zoomImageView.bounds), CGRectGetMidY(zoomImageView.bounds));// 注意不是 zoomImageView 的 center，而是 zoomImageView 这个容器里的中心点
                CGFloat horizontalRatio = CGRectGetWidth(sourceImageRect) / CGRectGetWidth(contentViewFrame);
                CGFloat verticalRatio = CGRectGetHeight(sourceImageRect) / CGRectGetHeight(contentViewFrame);
                CGFloat finalRatio = MAX(horizontalRatio, verticalRatio);
                
                CGAffineTransform fromTransform = CGAffineTransformIdentity;
                CGAffineTransform toTransform = CGAffineTransformIdentity;
                CGAffineTransform transform = CGAffineTransformIdentity;
                
                // 先缩再移
                transform = CGAffineTransformScale(transform, finalRatio, finalRatio);
                CGPoint contentViewCenterAfterScale = CGPointMake(centerInZoomImageView.x + (contentViewCenterInZoomImageView.x - centerInZoomImageView.x) * finalRatio, centerInZoomImageView.y + (contentViewCenterInZoomImageView.y - centerInZoomImageView.y) * finalRatio);
                CGSize translationAfterScale = CGSizeMake(CGRectGetMidX(sourceImageRect) - contentViewCenterAfterScale.x, CGRectGetMidY(sourceImageRect) - contentViewCenterAfterScale.y);
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(translationAfterScale.width, translationAfterScale.height));
                
                if (isPresenting) {
                    fromTransform = transform;
                } else {
                    toTransform = transform;
                }
                
                CGRect maskFromBounds = zoomImageView.contentView.bounds;
                CGRect maskToBounds = zoomImageView.contentView.bounds;
                CGRect maskBounds = maskFromBounds;
                CGFloat maskHorizontalRatio = CGRectGetWidth(sourceImageRect) / CGRectGetWidth(maskBounds);
                CGFloat maskVerticalRatio = CGRectGetHeight(sourceImageRect) / CGRectGetHeight(maskBounds);
                CGFloat maskFinalRatio = MAX(maskHorizontalRatio, maskVerticalRatio);
                maskBounds = CGRectMake(0, 0, CGRectGetWidth(sourceImageRect) / maskFinalRatio, CGRectGetHeight(sourceImageRect) / maskFinalRatio);
                if (isPresenting) {
                    maskFromBounds = maskBounds;
                } else {
                    maskToBounds = maskBounds;
                }
                
                NSInteger sourceImageIndex = animator.imagePreviewViewController.imagePreviewView.currentImageIndex;
                CGFloat cornerRadius = MAX(animator.imagePreviewViewController.sourceImageCornerRadius, 0);
                if (animator.imagePreviewViewController.sourceImageCornerRadius == __FWImagePreviewCornerRadiusAutomaticDimension && animator.imagePreviewViewController.sourceImageView) {
                    UIView *sourceImageView = animator.imagePreviewViewController.sourceImageView(sourceImageIndex);
                    if ([sourceImageView isKindOfClass:[UIView class]]) {
                        cornerRadius = sourceImageView.layer.cornerRadius;
                    }
                }
                cornerRadius = cornerRadius / maskFinalRatio;
                CGFloat fromCornerRadius = isPresenting ? cornerRadius : 0;
                CGFloat toCornerRadius = isPresenting ? 0 : cornerRadius;
                CABasicAnimation *cornerRadiusAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
                cornerRadiusAnimation.fromValue = @(fromCornerRadius);
                cornerRadiusAnimation.toValue = @(toCornerRadius);
                
                CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
                boundsAnimation.fromValue = [NSValue valueWithCGRect:CGRectMake(0, 0, maskFromBounds.size.width, maskFromBounds.size.height)];
                boundsAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, maskToBounds.size.width, maskToBounds.size.height)];
                
                CAAnimationGroup *maskAnimation = [[CAAnimationGroup alloc] init];
                maskAnimation.duration = animator.duration;
                maskAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                maskAnimation.fillMode = kCAFillModeForwards;
                maskAnimation.removedOnCompletion = NO;// remove 都交给 UIView Block 的 completion 里做，这里是为了避免 Core Animation 和 UIView Animation Block 时间不一致导致的值变动
                maskAnimation.animations = @[cornerRadiusAnimation, boundsAnimation];
                animator.cornerRadiusMaskLayer.position = CGPointMake(CGRectGetMidX(zoomImageView.contentView.bounds), CGRectGetMidY(zoomImageView.contentView.bounds));// 不管怎样，mask 都是居中的
                zoomImageView.contentView.layer.mask = animator.cornerRadiusMaskLayer;
                [animator.cornerRadiusMaskLayer addAnimation:maskAnimation forKey:@"maskAnimation"];
                
                // 动画开始
                zoomImageView.scrollView.clipsToBounds = NO;// 当 contentView 被放大后，如果不去掉 clipToBounds，那么退出预览时，contentView 溢出的那部分内容就看不到
                
                if (isPresenting) {
                    zoomImageView.transform = fromTransform;
                    previewView.backgroundColor = UIColor.clearColor;
                }
                
                // 发现 zoomImageView.transform 用 UIView Animation Block 实现的话，手势拖拽 dismissing 的情况下，松手时会瞬间跳动到某个位置，然后才继续做动画，改为 Core Animation 就没这个问题
                CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
                transformAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(toTransform)];
                transformAnimation.duration = animator.duration;
                transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                transformAnimation.fillMode = kCAFillModeForwards;
                transformAnimation.removedOnCompletion = NO;// remove 都交给 UIView Block 的 completion 里做，这里是为了避免 Core Animation 和 UIView Animation Block 时间不一致导致的值变动
                [zoomImageView.layer addAnimation:transformAnimation forKey:@"transformAnimation"];
            };
        };
        
        self.animationBlock = ^(__kindof __FWImagePreviewTransitionAnimator * _Nonnull animator, BOOL isPresenting, __FWImagePreviewTransitioningStyle style, CGRect sourceImageRect, __FWZoomImageView * _Nonnull zoomImageView, id<UIViewControllerContextTransitioning>  _Nullable transitionContext) {
            if (style == __FWImagePreviewTransitioningStyleFade) {
                animator.imagePreviewViewController.view.alpha = isPresenting ? 1 : 0;
            } else if (style == __FWImagePreviewTransitioningStyleZoom) {
                animator.imagePreviewViewController.view.backgroundColor = isPresenting ? animator.imagePreviewViewController.backgroundColor : UIColor.clearColor;
            }
        };
        
        self.animationCompletionBlock = ^(__kindof __FWImagePreviewTransitionAnimator * _Nonnull animator, BOOL isPresenting, __FWImagePreviewTransitioningStyle style, CGRect sourceImageRect, __FWZoomImageView * _Nonnull zoomImageView, id<UIViewControllerContextTransitioning>  _Nullable transitionContext) {
            
            // 由于支持 zoom presenting 和 fade dismissing 搭配使用，所以这里不管是哪种 style 都要做相同的清理工作
            
            // for fade
            animator.imagePreviewViewController.view.alpha = 1;
            
            // for zoom
            [animator.cornerRadiusMaskLayer removeAnimationForKey:@"maskAnimation"];
            zoomImageView.scrollView.clipsToBounds = YES;// UIScrollView.clipsToBounds default is YES
            zoomImageView.contentView.layer.mask = nil;
            zoomImageView.transform = CGAffineTransformIdentity;
            [zoomImageView.layer removeAnimationForKey:@"transformAnimation"];
        };
    }
    return self;
}

#pragma mark - <UIViewControllerAnimatedTransitioning>

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    if (!self.imagePreviewViewController) {
        return;
    }
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    BOOL isPresenting = fromViewController.presentedViewController == toViewController;
    UIViewController *presentingViewController = isPresenting ? fromViewController : toViewController;
    BOOL shouldAppearanceTransitionManually = self.imagePreviewViewController.modalPresentationStyle != UIModalPresentationFullScreen;// 触发背后界面的生命周期，从而配合屏幕旋转那边做一些强制旋转的操作
    
    __FWImagePreviewTransitioningStyle style = isPresenting ? self.imagePreviewViewController.presentingStyle : self.imagePreviewViewController.dismissingStyle;
    CGRect sourceImageRect = CGRectZero;
    NSInteger currentImageIndex = self.imagePreviewViewController.imagePreviewView.currentImageIndex;
    if (style == __FWImagePreviewTransitioningStyleZoom) {
        if (self.imagePreviewViewController.sourceImageRect) {
            sourceImageRect = [self.imagePreviewViewController.view convertRect:self.imagePreviewViewController.sourceImageRect(currentImageIndex) fromView:nil];
        } else if (self.imagePreviewViewController.sourceImageView) {
            id sourceImageView = self.imagePreviewViewController.sourceImageView(currentImageIndex);
            if ([sourceImageView isKindOfClass:[UIView class]]) {
                sourceImageRect = [self.imagePreviewViewController.view convertRect:((UIView *)sourceImageView).frame fromView:((UIView *)sourceImageView).superview];
            } else if ([sourceImageView isKindOfClass:[NSValue class]]) {
                sourceImageRect = [self.imagePreviewViewController.view convertRect:((NSValue *)sourceImageView).CGRectValue fromView:nil];
            }
        }
        /*
        // 限制sourceImageRect在显示区域内。由于支持自定义区域，此限制暂不需要
        if (!CGRectEqualToRect(sourceImageRect, CGRectZero) && !CGRectIntersectsRect(sourceImageRect, self.imagePreviewViewController.view.bounds)) {
            sourceImageRect = CGRectZero;
        }*/
    }
    style = style == __FWImagePreviewTransitioningStyleZoom && CGRectEqualToRect(sourceImageRect, CGRectZero) ? __FWImagePreviewTransitioningStyleFade : style;// zoom 类型一定需要有个非 zero 的 sourceImageRect，否则不知道动画的起点/终点，所以当不存在 sourceImageRect 时强制改为用 fade 动画
    
    UIView *containerView = transitionContext.containerView;
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    [fromView setNeedsLayout];
    [fromView layoutIfNeeded];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    [toView setNeedsLayout];
    [toView layoutIfNeeded];// present 时 toViewController 还没走到 viewDidLayoutSubviews，此时做动画可能得到不正确的布局，所以强制布局一次
    __FWZoomImageView *zoomImageView = [self.imagePreviewViewController.imagePreviewView zoomImageViewAtIndex:currentImageIndex];
    
    toView.frame = containerView.bounds;
    if (isPresenting) {
        [containerView addSubview:toView];
        if (shouldAppearanceTransitionManually) {
            [presentingViewController beginAppearanceTransition:NO animated:YES];
        }
    } else {
        [containerView insertSubview:toView belowSubview:fromView];
        [presentingViewController beginAppearanceTransition:YES animated:YES];
    }
    
    if (self.animationEnteringBlock) {
        self.animationEnteringBlock(self, isPresenting, style, sourceImageRect, zoomImageView, transitionContext);
    }
    if (self.animationCallbackBlock) {
        self.animationCallbackBlock(self, isPresenting, NO);
    }
    
    [UIView animateWithDuration:self.duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (self.animationBlock) {
            self.animationBlock(self, isPresenting, style, sourceImageRect, zoomImageView, transitionContext);
        }
    } completion:^(BOOL finished) {
        [presentingViewController endAppearanceTransition];
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        if (self.animationCompletionBlock) {
            self.animationCompletionBlock(self, isPresenting, style, sourceImageRect, zoomImageView, transitionContext);
        }
        if (self.animationCallbackBlock) {
            self.animationCallbackBlock(self, isPresenting, YES);
        }
    }];
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return self.duration;
}

@end

#pragma mark - __FWCollectionViewPagingLayout

@interface __FWCollectionViewPagingLayout () {
    CGFloat _maximumScale;
    CGFloat _minimumScale;
    CGSize _finalItemSize;
    CGFloat _pagingThreshold;
}

@end

@implementation __FWCollectionViewPagingLayout

- (instancetype)initWithStyle:(__FWCollectionViewPagingLayoutStyle)style {
    if (self = [super init]) {
        _style = style;
        self.velocityForEnsurePageDown = 0.4;
        self.allowsMultipleItemScroll = YES;
        self.multipleItemScrollVelocityLimit = 2.5;
        self.pagingThreshold = 2.0 / 3.0;
        self.maximumScale = 1.0;
        self.minimumScale = 0.94;
        
        self.minimumInteritemSpacing = 0;
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

- (instancetype)init {
    return [self initWithStyle:__FWCollectionViewPagingLayoutStyleDefault];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self init];
}

- (void)prepareLayout {
    [super prepareLayout];
    CGSize itemSize = self.itemSize;
    id<UICollectionViewDelegateFlowLayout> layoutDelegate = (id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate;
    if ([layoutDelegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        itemSize = [layoutDelegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
    _finalItemSize = itemSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    if (self.style == __FWCollectionViewPagingLayoutStyleScale) {
        return YES;
    }
    return !CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size);
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    if (self.style == __FWCollectionViewPagingLayoutStyleDefault) {
        return [super layoutAttributesForElementsInRect:rect];
    }
    
    NSArray<UICollectionViewLayoutAttributes *> *resultAttributes = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
    CGFloat offset = CGRectGetMidX(self.collectionView.bounds);// 当前滚动位置的可视区域的中心点
    CGSize itemSize = _finalItemSize;
    
    if (self.style == __FWCollectionViewPagingLayoutStyleScale) {
        
        CGFloat distanceForMinimumScale = itemSize.width + self.minimumLineSpacing;
        CGFloat distanceForMaximumScale = 0.0;
        
        for (UICollectionViewLayoutAttributes *attributes in resultAttributes) {
            CGFloat scale = 0;
            CGFloat distance = ABS(offset - attributes.center.x);
            if (distance >= distanceForMinimumScale) {
                scale = self.minimumScale;
            } else if (distance == distanceForMaximumScale) {
                scale = self.maximumScale;
            } else {
                scale = self.minimumScale + (distanceForMinimumScale - distance) * (self.maximumScale - self.minimumScale) / (distanceForMinimumScale - distanceForMaximumScale);
            }
            attributes.transform3D = CATransform3DMakeScale(scale, scale, 1);
            attributes.zIndex = 1;
        }
        return resultAttributes;
    }
    
    return resultAttributes;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    
    CGFloat itemSpacing = (self.scrollDirection == UICollectionViewScrollDirectionHorizontal ? _finalItemSize.width : _finalItemSize.height) + self.minimumLineSpacing;
    
    CGSize contentSize = self.collectionViewContentSize;
    CGSize frameSize = self.collectionView.bounds.size;
    UIEdgeInsets contentInset = self.collectionView.adjustedContentInset;
    
    BOOL scrollingToRight = proposedContentOffset.x < self.collectionView.contentOffset.x;// 代表 collectionView 期望的实际滚动方向是向右，但不代表手指拖拽的方向是向右，因为有可能此时已经在左边的尽头，继续往右拖拽，松手的瞬间由于回弹，这里会判断为是想向左滚动，但其实你的手指是向右拖拽
    BOOL scrollingToBottom = proposedContentOffset.y < self.collectionView.contentOffset.y;
    BOOL forcePaging = NO;
    
    CGPoint translation = [self.collectionView.panGestureRecognizer translationInView:self.collectionView];
    
    if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
        if (!self.allowsMultipleItemScroll || ABS(velocity.y) <= ABS(self.multipleItemScrollVelocityLimit)) {
            proposedContentOffset = self.collectionView.contentOffset;// 一次性滚多次的本质是系统根据速度算出来的 proposedContentOffset 可能比当前 contentOffset 大很多，所以这里既然限制了一次只能滚一页，那就直接取瞬时 contentOffset 即可。
            
            // 只支持滚动一页 或者 支持滚动多页但是速度不够滚动多页，时，允许强制滚动
            if (ABS(velocity.y) > self.velocityForEnsurePageDown) {
                forcePaging = YES;
            }
        }
        
        // 最顶/最底
        if (proposedContentOffset.y < -contentInset.top || proposedContentOffset.y >= contentSize.height + contentInset.bottom - frameSize.height) {
            // iOS 10 及以上的版本，直接返回当前的 contentOffset，系统会自动帮你调整到边界状态，而 iOS 9 及以下的版本需要自己计算
            return proposedContentOffset;
        }
        
        CGFloat progress = ((contentInset.top + proposedContentOffset.y) + _finalItemSize.height / 2/*因为第一个 item 初始状态中心点离 contentOffset.y 有半个 item 的距离*/) / itemSpacing;
        NSInteger currentIndex = (NSInteger)progress;
        NSInteger targetIndex = currentIndex;
        // 加上下面这两个额外的 if 判断是为了避免那种“从0滚到1的左边 1/3，松手后反而会滚回0”的 bug
        if (translation.y < 0 && (ABS(translation.y) > _finalItemSize.height / 2 + self.minimumLineSpacing)) {
        } else if (translation.y > 0 && ABS(translation.y > _finalItemSize.height / 2)) {
        } else {
            CGFloat remainder = progress - currentIndex;
            CGFloat offset = remainder * itemSpacing;
            BOOL shouldNext = (forcePaging || (offset / _finalItemSize.height >= self.pagingThreshold)) && !scrollingToBottom && velocity.y > 0;
            BOOL shouldPrev = (forcePaging || (offset / _finalItemSize.height <= 1 - self.pagingThreshold)) && scrollingToBottom && velocity.y < 0;
            targetIndex = currentIndex + (shouldNext ? 1 : (shouldPrev ? -1 : 0));
        }
        proposedContentOffset.y = -contentInset.top + targetIndex * itemSpacing;
    }
    else if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        if (!self.allowsMultipleItemScroll || ABS(velocity.x) <= ABS(self.multipleItemScrollVelocityLimit)) {
            proposedContentOffset = self.collectionView.contentOffset;// 一次性滚多次的本质是系统根据速度算出来的 proposedContentOffset 可能比当前 contentOffset 大很多，所以这里既然限制了一次只能滚一页，那就直接取瞬时 contentOffset 即可。
            
            // 只支持滚动一页 或者 支持滚动多页但是速度不够滚动多页，时，允许强制滚动
            if (ABS(velocity.x) > self.velocityForEnsurePageDown) {
                forcePaging = YES;
            }
        }
        
        // 最左/最右
        if (proposedContentOffset.x < -contentInset.left || proposedContentOffset.x >= contentSize.width + contentInset.right - frameSize.width) {
            // iOS 10 及以上的版本，直接返回当前的 contentOffset，系统会自动帮你调整到边界状态，而 iOS 9 及以下的版本需要自己计算
            return proposedContentOffset;
        }
        
        CGFloat progress = ((contentInset.left + proposedContentOffset.x) + _finalItemSize.width / 2/*因为第一个 item 初始状态中心点离 contentOffset.x 有半个 item 的距离*/) / itemSpacing;
        NSInteger currentIndex = (NSInteger)progress;
        NSInteger targetIndex = currentIndex;
        // 加上下面这两个额外的 if 判断是为了避免那种“从0滚到1的左边 1/3，松手后反而会滚回0”的 bug
        if (translation.x < 0 && (ABS(translation.x) > _finalItemSize.width / 2 + self.minimumLineSpacing)) {
        } else if (translation.x > 0 && ABS(translation.x > _finalItemSize.width / 2)) {
        } else {
            CGFloat remainder = progress - currentIndex;
            CGFloat offset = remainder * itemSpacing;
            // collectionView 关闭了 bounces 后，如果在第一页向左边快速滑动一段距离，并不会触发上一个「最左/最右」的判断（因为 proposedContentOffset 不够），此时的 velocity 为负数，所以要加上 velocity.x > 0 的判断，否则这种情况会命中 forcePaging && !scrollingToRight 这两个条件，当做下一页处理。
            BOOL shouldNext = (forcePaging || (offset / _finalItemSize.width >= self.pagingThreshold)) && !scrollingToRight && velocity.x > 0;
            BOOL shouldPrev = (forcePaging || (offset / _finalItemSize.width <= 1 - self.pagingThreshold)) && scrollingToRight && velocity.x < 0;
            targetIndex = currentIndex + (shouldNext ? 1 : (shouldPrev ? -1 : 0));
        }
        proposedContentOffset.x = -contentInset.left + targetIndex * itemSpacing;
    }
    
    return proposedContentOffset;
}

- (CGFloat)pagingThreshold {
    return _pagingThreshold;
}

- (void)setPagingThreshold:(CGFloat)pagingThreshold {
    _pagingThreshold = pagingThreshold;
}

- (CGFloat)maximumScale {
    return _maximumScale;
}

- (void)setMaximumScale:(CGFloat)maximumScale {
    _maximumScale = maximumScale;
}

- (CGFloat)minimumScale {
    return _minimumScale;
}

- (void)setMinimumScale:(CGFloat)minimumScale {
    _minimumScale = minimumScale;
}

@end
