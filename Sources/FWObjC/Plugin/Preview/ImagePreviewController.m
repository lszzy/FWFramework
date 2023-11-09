//
//  ImagePreviewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ImagePreviewController.h"
#import <FWFramework/FWFramework-Swift.h>

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
