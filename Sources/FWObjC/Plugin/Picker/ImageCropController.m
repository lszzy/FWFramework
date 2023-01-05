//
//  ImageCropController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ImageCropController.h"
#import "AlertPlugin.h"
#import "AppBundle.h"

#if FWMacroSPM

@interface UIScreen ()

@property (class, nonatomic, assign, readonly) CGFloat __fw_toolBarHeight;
@property (class, nonatomic, assign, readonly) UIEdgeInsets __fw_safeAreaInsets;

@end

@interface UIImage ()

- (nullable UIImage *)__fw_croppedImageWithFrame:(CGRect)frame angle:(NSInteger)angle circular:(BOOL)circular;

@end

@interface UIViewController ()

- (void)__fw_showSheetWithTitle:(nullable id)title message:(nullable id)message cancel:(nullable id)cancel actions:(nullable NSArray *)actions currentIndex:(NSInteger)currentIndex actionBlock:(nullable void (^)(NSInteger))actionBlock cancelBlock:(nullable void (^)(void))cancelBlock;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

@interface __FWImageCropController () <__FWImageCropViewDelegate>

/* The target image */
@property (nonatomic, readwrite) UIImage *image;

/* The cropping style of the crop view */
@property (nonatomic, assign, readwrite) __FWImageCropCroppingStyle croppingStyle;

/* Views */
@property (nonatomic, strong) __FWImageCropToolbar *toolbar;
@property (nonatomic, strong, readwrite) __FWImageCropView *cropView;
@property (nonatomic, strong) UIView *toolbarSnapshotView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;

/* If pushed from a navigation controller, the visibility of that controller's bars. */
@property (nonatomic, assign) BOOL navigationBarHidden;
@property (nonatomic, assign) BOOL toolbarHidden;
@property (nonatomic, assign) BOOL inTransition;

/* State for whether content is being laid out vertically or horizontally */
@property (nonatomic, readonly) BOOL verticalLayout;

/* Convenience method for managing status bar state */
@property (nonatomic, readonly) BOOL overrideStatusBar; // Whether the view controller needs to touch the status bar
@property (nonatomic, readonly) BOOL statusBarHidden;   // Whether it should be hidden or visible at this point
@property (nonatomic, readonly) CGFloat statusBarHeight; // The height of the status bar when visible

/* Convenience method for getting the vertical inset for both iPhone X and status bar */
@property (nonatomic, readonly) UIEdgeInsets statusBarSafeInsets;

/* Flag to perform initial setup on the first run */
@property (nonatomic, assign) BOOL firstTime;

@end

@implementation __FWImageCropController

- (instancetype)initWithCroppingStyle:(__FWImageCropCroppingStyle)style image:(UIImage *)image
{
    NSParameterAssert(image);

    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Init parameters
        _image = image;
        _croppingStyle = style;
        
        // Set up base view controller behaviour
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.hidesNavigationBar = true;

        // Default initial behaviour
        _titleTopPadding = 14.0f;
        _aspectRatioPreset = __FWImageCropAspectRatioPresetOriginal;
        _toolbarPosition = __FWImageCropToolbarPositionBottom;
    }
    
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    return [self initWithCroppingStyle:__FWImageCropCroppingStyleDefault image:image];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set up view controller properties
    self.view.backgroundColor = self.cropView.backgroundColor;
    
    BOOL circularMode = (self.croppingStyle == __FWImageCropCroppingStyleCircular);

    // Layout the views initially
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:self.verticalLayout];
    self.toolbar.frame = [self frameForToolbarWithVerticalLayout:self.verticalLayout];

    // Set up toolbar default behaviour
    self.toolbar.clampButtonHidden = self.aspectRatioPickerButtonHidden || circularMode;
    self.toolbar.rotateClockwiseButtonHidden = self.rotateClockwiseButtonHidden;
    
    // Set up the toolbar button actions
    __weak typeof(self) weakSelf = self;
    self.toolbar.doneButtonTapped   = ^{ [weakSelf doneButtonTapped]; };
    self.toolbar.cancelButtonTapped = ^{ [weakSelf cancelButtonTapped]; };
    self.toolbar.resetButtonTapped = ^{ [weakSelf resetCropViewLayout]; };
    self.toolbar.clampButtonTapped = ^{ [weakSelf showAspectRatioDialog]; };
    self.toolbar.rotateCounterclockwiseButtonTapped = ^{ [weakSelf rotateCropViewCounterclockwise]; };
    self.toolbar.rotateClockwiseButtonTapped        = ^{ [weakSelf rotateCropViewClockwise]; };
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // If we're animating onto the screen, set a flag
    // so we can manually control the status bar fade out timing
    if (animated) {
        self.inTransition = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    // If this controller is pushed onto a navigation stack, set flags noting the
    // state of the navigation controller bars before we present, and then hide them
    if (self.navigationController) {
        if (self.hidesNavigationBar) {
            self.navigationBarHidden = self.navigationController.navigationBarHidden;
            self.toolbarHidden = self.navigationController.toolbarHidden;
            [self.navigationController setNavigationBarHidden:YES animated:animated];
            [self.navigationController setToolbarHidden:YES animated:animated];
        }

        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    else {
        // Hide the background content when transitioning for performance
        [self.cropView setBackgroundImageViewHidden:YES animated:NO];
        
        // The title label will fade
        self.titleLabel.alpha = animated ? 0.0f : 1.0f;
    }

    // If an initial aspect ratio was set before presentation, set it now once the rest of
    // the setup will have been done
    if (self.aspectRatioPreset != __FWImageCropAspectRatioPresetOriginal) {
        [self setAspectRatioPreset:self.aspectRatioPreset animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Disable the transition flag for the status bar
    self.inTransition = NO;
    
    // Re-enable translucency now that the animation has completed
    self.cropView.simpleRenderMode = NO;

    // Now that the presentation animation will have finished, animate
    // the status bar fading out, and if present, the title label fading in
    void (^updateContentBlock)(void) = ^{
        [self setNeedsStatusBarAppearanceUpdate];
        self.titleLabel.alpha = 1.0f;
    };

    if (animated) {
        [UIView animateWithDuration:0.3f animations:updateContentBlock];
    }
    else {
        updateContentBlock();
    }
    
    // Make the grid overlay view fade in
    if (self.cropView.gridOverlayHidden) {
        [self.cropView setGridOverlayHidden:NO animated:animated];
    }
    
    // Fade in the background view content
    if (self.navigationController == nil) {
        [self.cropView setBackgroundImageViewHidden:NO animated:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Set the transition flag again so we can defer the status bar
    self.inTransition = YES;
    [UIView animateWithDuration:0.5f animations:^{ [self setNeedsStatusBarAppearanceUpdate]; }];
    
    // Restore the navigation controller to its state before we were presented
    if (self.navigationController && self.hidesNavigationBar) {
        [self.navigationController setNavigationBarHidden:self.navigationBarHidden animated:animated];
        [self.navigationController setToolbarHidden:self.toolbarHidden animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Reset the state once the view has gone offscreen
    self.inTransition = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Status Bar -
- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.navigationController) {
        return UIStatusBarStyleLightContent;
    }

    // Even though we are a dark theme, leave the status bar
    // as black so it's not obvious that it's still visible during the transition
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    // Disregard the transition animation if we're not actively overriding it
    if (!self.overrideStatusBar) {
        return self.statusBarHidden;
    }

    // Work out whether the status bar needs to be visible
    // during a transition animation or not
    BOOL hidden = YES; // Default is yes
    hidden = hidden && !(self.inTransition); // Not currently in a presentation animation (Where removing the status bar would break the layout)
    hidden = hidden && !(self.view.superview == nil); // Not currently waiting to be added to a super view
    return hidden;
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures
{
    return UIRectEdgeAll;
}

- (CGRect)frameForToolbarWithVerticalLayout:(BOOL)verticalLayout
{
    UIEdgeInsets insets = self.statusBarSafeInsets;

    CGRect frame = CGRectZero;
    CGFloat toolbarHeight = self.toolbarHeight;
    if (!verticalLayout) { // In landscape laying out toolbar to the left
        frame.origin.x = insets.left;
        frame.origin.y = 0.0f;
        frame.size.width = toolbarHeight;
        frame.size.height = CGRectGetHeight(self.view.frame);
    }
    else {
        frame.origin.x = 0.0f;
        frame.size.width = CGRectGetWidth(self.view.bounds);
        frame.size.height = toolbarHeight;

        if (self.toolbarPosition == __FWImageCropToolbarPositionBottom) {
            frame.origin.y = CGRectGetHeight(self.view.bounds) - (frame.size.height + insets.bottom);
        } else {
            frame.origin.y = insets.top;
        }
    }
    
    return frame;
}

- (CGRect)frameForCropViewWithVerticalLayout:(BOOL)verticalLayout
{
    //On an iPad, if being presented in a modal view controller by a UINavigationController,
    //at the time we need it, the size of our view will be incorrect.
    //If this is the case, derive our view size from our parent view controller instead
    UIView *view = nil;
    if (self.parentViewController == nil) {
        view = self.view;
    }
    else {
        view = self.parentViewController.view;
    }

    UIEdgeInsets insets = self.statusBarSafeInsets;

    CGRect bounds = view.bounds;
    CGRect frame = CGRectZero;
    CGFloat toolbarHeight = self.toolbarHeight;

    // Horizontal layout (eg landscape)
    if (!verticalLayout) {
        frame.origin.x = toolbarHeight + insets.left;
        frame.size.width = CGRectGetWidth(bounds) - frame.origin.x;
        frame.size.height = CGRectGetHeight(bounds);
    }
    else { // Vertical layout
        frame.size.height = CGRectGetHeight(bounds);
        frame.size.width = CGRectGetWidth(bounds);

        // Set Y and adjust for height
        if (self.toolbarPosition == __FWImageCropToolbarPositionBottom) {
            frame.size.height -= (insets.bottom + toolbarHeight);
        } else if (self.toolbarPosition == __FWImageCropToolbarPositionTop) {
            frame.origin.y = toolbarHeight + insets.top;
            frame.size.height -= frame.origin.y;
        }
    }
    
    return frame;
}

- (CGRect)frameForTitleLabelWithSize:(CGSize)size verticalLayout:(BOOL)verticalLayout
{
    CGRect frame = (CGRect){CGPointZero, size};
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat x = 0.0f; // Additional X offset in landscape mode

    // Adjust for landscape layout
    if (!verticalLayout) {
        x = self.titleTopPadding;
        x += self.view.safeAreaInsets.left;

        viewWidth -= x;
    }

    // Work out horizontal position
    frame.origin.x = ceilf((viewWidth - frame.size.width) * 0.5f);
    if (!verticalLayout) { frame.origin.x += x; }

    // Work out vertical position
    frame.origin.y = self.view.safeAreaInsets.top + self.titleTopPadding;

    return frame;
}

- (void)adjustCropViewInsets
{
    UIEdgeInsets insets = self.statusBarSafeInsets;

    // If there is no title text, inset the top of the content as high as possible
    if (!self.titleLabel.text.length) {
        if (self.verticalLayout) {
          if (self.toolbarPosition == __FWImageCropToolbarPositionTop) {
            self.cropView.cropRegionInsets = UIEdgeInsetsMake(0.0f, 0.0f, insets.bottom, 0.0f);
          }
          else { // Add padding to the top otherwise
            self.cropView.cropRegionInsets = UIEdgeInsetsMake(insets.top, 0.0f, 0.0, 0.0f);
          }
        }
        else {
            self.cropView.cropRegionInsets = UIEdgeInsetsMake(0.0f, 0.0f, insets.bottom, 0.0f);
        }

        return;
    }

    // Work out the size of the title label based on the crop view size
    CGRect frame = self.titleLabel.frame;
    frame.size = [self.titleLabel sizeThatFits:self.cropView.frame.size];
    self.titleLabel.frame = frame;

    // Set out the appropriate inset for that
    CGFloat verticalInset = self.statusBarHeight;
    verticalInset += self.titleTopPadding;
    verticalInset += self.titleLabel.frame.size.height;
    self.cropView.cropRegionInsets = UIEdgeInsetsMake(verticalInset, 0, insets.bottom, 0);
}

- (void)adjustToolbarInsets
{
    UIEdgeInsets insets = UIEdgeInsetsZero;

    // Add padding to the left in landscape mode
    if (!self.verticalLayout) {
        insets.left = self.view.safeAreaInsets.left;
    }
    else {
        // Add padding on top if in vertical and tool bar is at the top
        if (self.toolbarPosition == __FWImageCropToolbarPositionTop) {
            insets.top = self.view.safeAreaInsets.top;
        }
        else { // Add padding to the bottom otherwise
            insets.bottom = self.view.safeAreaInsets.bottom;
        }
    }

    // Update the toolbar with these properties
    self.toolbar.backgroundViewOutsets = insets;
    self.toolbar.statusBarHeightInset = self.statusBarHeight;
    [self.toolbar setNeedsLayout];
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    [self adjustCropViewInsets];
    [self adjustToolbarInsets];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.cropView.frame = [self frameForCropViewWithVerticalLayout:self.verticalLayout];
    [self adjustCropViewInsets];
    [self.cropView moveCroppedContentToCenterAnimated:NO];

    if (self.firstTime == NO) {
        [self.cropView performInitialSetup];
        self.firstTime = YES;
    }
    
    if (self.title.length) {
        self.titleLabel.frame = [self frameForTitleLabelWithSize:self.titleLabel.frame.size verticalLayout:self.verticalLayout];
        [self.cropView moveCroppedContentToCenterAnimated:NO];
    }

    [UIView performWithoutAnimation:^{
        self.toolbar.frame = [self frameForToolbarWithVerticalLayout:self.verticalLayout];
        [self adjustToolbarInsets];
        [self.toolbar setNeedsLayout];
    }];
}

#pragma mark - Rotation Handling -

- (void)_willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.toolbarSnapshotView = [self.toolbar snapshotViewAfterScreenUpdates:NO];
    self.toolbarSnapshotView.frame = self.toolbar.frame;
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        self.toolbarSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    else {
        self.toolbarSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    }
    [self.view addSubview:self.toolbarSnapshotView];

    // Set up the toolbar frame to be just off t
    CGRect frame = [self frameForToolbarWithVerticalLayout:UIInterfaceOrientationIsPortrait(toInterfaceOrientation)];
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        frame.origin.x = -frame.size.width;
    }
    else {
        frame.origin.y = self.view.bounds.size.height;
    }
    self.toolbar.frame = frame;

    [self.toolbar layoutIfNeeded];
    self.toolbar.alpha = 0.0f;
    
    [self.cropView prepareforRotation];
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:!UIInterfaceOrientationIsPortrait(toInterfaceOrientation)];
    self.cropView.simpleRenderMode = YES;
    self.cropView.internalLayoutDisabled = YES;
}

- (void)_willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //Remove all animations in the toolbar
    self.toolbar.frame = [self frameForToolbarWithVerticalLayout:!UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    [self.toolbar.layer removeAllAnimations];
    for (CALayer *sublayer in self.toolbar.layer.sublayers) {
        [sublayer removeAllAnimations];
    }

    // On iOS 11, since these layout calls are done multiple times, if we don't aggregate from the
    // current state, the animation breaks.
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:
    ^{
        self.cropView.frame = [self frameForCropViewWithVerticalLayout:!UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
        self.toolbar.frame = [self frameForToolbarWithVerticalLayout:UIInterfaceOrientationIsPortrait(toInterfaceOrientation)];
        [self.cropView performRelayoutForRotation];
    } completion:nil];

    self.toolbarSnapshotView.alpha = 0.0f;
    self.toolbar.alpha = 1.0f;
}

- (void)_didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.toolbarSnapshotView removeFromSuperview];
    self.toolbarSnapshotView = nil;
    
    [self.cropView setSimpleRenderMode:NO animated:YES];
    self.cropView.internalLayoutDisabled = NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // If the size doesn't change (e.g, we did a 180 degree device rotation), don't bother doing a relayout
    if (CGSizeEqualToSize(size, self.view.bounds.size)) { return; }
    
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    CGSize currentSize = self.view.bounds.size;
    if (currentSize.width < size.width) {
        orientation = UIInterfaceOrientationLandscapeLeft;
    }
    
    [self _willRotateToInterfaceOrientation:orientation duration:coordinator.transitionDuration];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self _willAnimateRotationToInterfaceOrientation:orientation duration:coordinator.transitionDuration];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self _didRotateFromInterfaceOrientation:orientation];
    }];
}

#pragma mark - Reset -
- (void)resetCropViewLayout
{
    BOOL animated = (self.cropView.angle == 0);
    
    if (self.resetAspectRatioEnabled) {
        self.aspectRatioLockEnabled = NO;
    }
    
    [self.cropView resetLayoutToDefaultAnimated:animated];
}

#pragma mark - Aspect Ratio Handling -
- (void)showAspectRatioDialog
{
    if (self.cropView.aspectRatioLockEnabled) {
        self.cropView.aspectRatioLockEnabled = NO;
        self.toolbar.clampButtonGlowing = NO;
        return;
    }
    
    //Depending on the shape of the image, work out if horizontal, or vertical options are required
    BOOL verticalCropBox = self.cropView.cropBoxAspectRatioIsPortrait;
    
    //Prepare the localized options
    NSString *cancelButtonTitle = _cancelButtonTitle ?: __FWAppBundle.cancelButton;
    NSString *originalButtonTitle = self.originalAspectRatioName.length > 0 ? self.originalAspectRatioName : __FWAppBundle.originalButton;
    
    //Prepare the list that will be fed to the alert view/controller
    
    // Ratio titles according to the order of enum __FWImageCropAspectRatioPreset
    NSArray<NSString *> *portraitRatioTitles = @[originalButtonTitle, @"1:1", @"2:3", @"3:5", @"3:4", @"4:5", @"5:7", @"9:16"];
    NSArray<NSString *> *landscapeRatioTitles = @[originalButtonTitle, @"1:1", @"3:2", @"5:3", @"4:3", @"5:4", @"7:5", @"16:9"];

    NSMutableArray *ratioValues = [NSMutableArray array];
    NSMutableArray *itemStrings = [NSMutableArray array];

    if (self.allowedAspectRatios == nil) {
        for (NSInteger i = 0; i < __FWImageCropAspectRatioPresetCustom; i++) {
            NSString *itemTitle = verticalCropBox ? portraitRatioTitles[i] : landscapeRatioTitles[i];
            [itemStrings addObject:itemTitle];
            [ratioValues addObject:@(i)];
        }
    }
    else {
        for (NSNumber *allowedRatio in self.allowedAspectRatios) {
            __FWImageCropAspectRatioPreset ratio = allowedRatio.integerValue;
            NSString *itemTitle = verticalCropBox ? portraitRatioTitles[ratio] : landscapeRatioTitles[ratio];
            [itemStrings addObject:itemTitle];
            [ratioValues addObject:allowedRatio];
        }
    }
    
    // If a custom aspect ratio is provided, and a custom name has been given to it, add it as a visible choice
    if (self.customAspectRatioName.length > 0 && !CGSizeEqualToSize(CGSizeZero, self.customAspectRatio)) {
        [itemStrings addObject:self.customAspectRatioName];
        [ratioValues addObject:@(__FWImageCropAspectRatioPresetCustom)];
    }

    __weak __typeof__(self) self_weak_ = self;
    [self __fw_showSheetWithTitle:nil message:nil cancel:cancelButtonTitle actions:itemStrings currentIndex:-1 actionBlock:^(NSInteger index) {
        __typeof__(self) self = self_weak_;
        [self setAspectRatioPreset:[ratioValues[index] integerValue] animated:YES];
        self.aspectRatioLockEnabled = YES;
    } cancelBlock:nil];
}

- (void)setAspectRatioPreset:(__FWImageCropAspectRatioPreset)aspectRatioPreset animated:(BOOL)animated
{
    CGSize aspectRatio = CGSizeZero;
    
    _aspectRatioPreset = aspectRatioPreset;
    
    switch (aspectRatioPreset) {
        case __FWImageCropAspectRatioPresetOriginal:
            aspectRatio = CGSizeZero;
            break;
        case __FWImageCropAspectRatioPresetSquare:
            aspectRatio = CGSizeMake(1.0f, 1.0f);
            break;
        case __FWImageCropAspectRatioPreset3x2:
            aspectRatio = CGSizeMake(3.0f, 2.0f);
            break;
        case __FWImageCropAspectRatioPreset5x3:
            aspectRatio = CGSizeMake(5.0f, 3.0f);
            break;
        case __FWImageCropAspectRatioPreset4x3:
            aspectRatio = CGSizeMake(4.0f, 3.0f);
            break;
        case __FWImageCropAspectRatioPreset5x4:
            aspectRatio = CGSizeMake(5.0f, 4.0f);
            break;
        case __FWImageCropAspectRatioPreset7x5:
            aspectRatio = CGSizeMake(7.0f, 5.0f);
            break;
        case __FWImageCropAspectRatioPreset16x9:
            aspectRatio = CGSizeMake(16.0f, 9.0f);
            break;
        case __FWImageCropAspectRatioPresetCustom:
            aspectRatio = self.customAspectRatio;
            break;
    }
    
    // If the aspect ratio lock is not enabled, allow a swap
    // If the aspect ratio lock is on, allow a aspect ratio swap
    // only if the allowDimensionSwap option is specified.
    BOOL aspectRatioCanSwapDimensions = !self.aspectRatioLockEnabled ||
                                (self.aspectRatioLockEnabled && self.aspectRatioLockDimensionSwapEnabled);
    
    //If the image is a portrait shape, flip the aspect ratio to match
    if (self.cropView.cropBoxAspectRatioIsPortrait &&
        aspectRatioCanSwapDimensions)
    {
        CGFloat width = aspectRatio.width;
        aspectRatio.width = aspectRatio.height;
        aspectRatio.height = width;
    }
    
    [self.cropView setAspectRatio:aspectRatio animated:animated];
}

- (void)rotateCropViewClockwise
{
    [self.cropView rotateImageNinetyDegreesAnimated:YES clockwise:YES];
}

- (void)rotateCropViewCounterclockwise
{
    [self.cropView rotateImageNinetyDegreesAnimated:YES clockwise:NO];
}

#pragma mark - Crop View Delegates -
- (void)cropViewDidBecomeResettable:(__FWImageCropView *)cropView
{
    self.toolbar.resetButtonEnabled = YES;
}

- (void)cropViewDidBecomeNonResettable:(__FWImageCropView *)cropView
{
    self.toolbar.resetButtonEnabled = NO;
}

#pragma mark - Button Feedback -
- (void)cancelButtonTapped
{
    bool isDelegateOrCallbackHandled = NO;

    // Check if the delegate method was implemented and call if so
    if ([self.delegate respondsToSelector:@selector(cropController:didFinishCancelled:)]) {
        [self.delegate cropController:self didFinishCancelled:YES];
        isDelegateOrCallbackHandled = YES;
    }

    // Check if the block version was implemented and call if so
    if (self.onDidFinishCancelled != nil) {
        self.onDidFinishCancelled(YES);
        isDelegateOrCallbackHandled = YES;
    }

    // If neither callbacks were implemented, perform a default dismissing animation
    if (!isDelegateOrCallbackHandled) {
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)doneButtonTapped
{
    CGRect cropFrame = self.cropView.imageCropFrame;
    NSInteger angle = self.cropView.angle;
    
    BOOL isCallbackOrDelegateHandled = NO;
    
    //If the delegate/block that only supplies crop data is provided, call it
    if ([self.delegate respondsToSelector:@selector(cropController:didCropImageToRect:angle:)]) {
        [self.delegate cropController:self didCropImageToRect:cropFrame angle:angle];
        isCallbackOrDelegateHandled = YES;
    }

    if (self.onDidCropImageToRect != nil) {
        self.onDidCropImageToRect(cropFrame, angle);
        isCallbackOrDelegateHandled = YES;
    }

    // Check if the circular APIs were implemented
    BOOL isCircularImageDelegateAvailable = [self.delegate respondsToSelector:@selector(cropController:didCropToCircularImage:withRect:angle:)];
    BOOL isCircularImageCallbackAvailable = self.onDidCropToCircleImage != nil;

    // Check if non-circular was implemented
    BOOL isDidCropToImageDelegateAvailable = [self.delegate respondsToSelector:@selector(cropController:didCropToImage:withRect:angle:)];
    BOOL isDidCropToImageCallbackAvailable = self.onDidCropToRect != nil;

    //If cropping circular and the circular generation delegate/block is implemented, call it
    if (self.croppingStyle == __FWImageCropCroppingStyleCircular && (isCircularImageDelegateAvailable || isCircularImageCallbackAvailable)) {
        UIImage *image = [self.image __fw_croppedImageWithFrame:cropFrame angle:angle circular:YES];
        
        //Dispatch on the next run-loop so the animation isn't interuppted by the crop operation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.03f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (isCircularImageDelegateAvailable) {
                [self.delegate cropController:self didCropToCircularImage:image withRect:cropFrame angle:angle];
            }
            if (isCircularImageCallbackAvailable) {
                self.onDidCropToCircleImage(image, cropFrame, angle);
            }
        });
        
        isCallbackOrDelegateHandled = YES;
    }
    //If the delegate/block that requires the specific cropped image is provided, call it
    else if (isDidCropToImageDelegateAvailable || isDidCropToImageCallbackAvailable) {
        UIImage *image = nil;
        if (angle == 0 && CGRectEqualToRect(cropFrame, (CGRect){CGPointZero, self.image.size})) {
            image = self.image;
        }
        else {
            image = [self.image __fw_croppedImageWithFrame:cropFrame angle:angle circular:NO];
        }
        
        //Dispatch on the next run-loop so the animation isn't interuppted by the crop operation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.03f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (isDidCropToImageDelegateAvailable) {
                [self.delegate cropController:self didCropToImage:image withRect:cropFrame angle:angle];
            }

            if (isDidCropToImageCallbackAvailable) {
                self.onDidCropToRect(image, cropFrame, angle);
            }
        });
        
        isCallbackOrDelegateHandled = YES;
    }
    
    if (!isCallbackOrDelegateHandled) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Property Methods -

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];

    if (self.title.length == 0) {
        [_titleLabel removeFromSuperview];
        _cropView.cropRegionInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        _titleLabel = nil;
        return;
    }

    self.titleLabel.text = self.title;
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = [self frameForTitleLabelWithSize:self.titleLabel.frame.size verticalLayout:self.verticalLayout];
}

- (void)setDoneButtonTitle:(NSString *)title {
    self.toolbar.doneTextButtonTitle = title;
}

- (void)setCancelButtonTitle:(NSString *)title {
    self.toolbar.cancelTextButtonTitle = title;
}

- (__FWImageCropView *)cropView {
    // Lazily create the crop view in case we try and access it before presentation, but
    // don't add it until our parent view controller view has loaded at the right time
    if (!_cropView) {
        _cropView = [[__FWImageCropView alloc] initWithCroppingStyle:self.croppingStyle image:self.image];
        _cropView.delegate = self;
        _cropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_cropView];
    }
    return _cropView;
}

- (__FWImageCropToolbar *)toolbar {
    if (!_toolbar) {
        _toolbar = [[__FWImageCropToolbar alloc] initWithFrame:CGRectZero];
        [self.view addSubview:_toolbar];
    }
    return _toolbar;
}

- (UILabel *)titleLabel
{
    if (!self.title.length) { return nil; }
    if (_titleLabel) { return _titleLabel; }

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.numberOfLines = 1;
    _titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    _titleLabel.clipsToBounds = YES;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.text = self.title;

    [self.view insertSubview:self.titleLabel aboveSubview:self.cropView];

    return _titleLabel;
}

- (void)setAspectRatioLockEnabled:(BOOL)aspectRatioLockEnabled
{
    self.toolbar.clampButtonGlowing = aspectRatioLockEnabled;
    self.cropView.aspectRatioLockEnabled = aspectRatioLockEnabled;
    if (!self.aspectRatioPickerButtonHidden) {
        self.aspectRatioPickerButtonHidden = (aspectRatioLockEnabled && self.resetAspectRatioEnabled == NO);
    }
}

- (void)setAspectRatioLockDimensionSwapEnabled:(BOOL)aspectRatioLockDimensionSwapEnabled
{
    self.cropView.aspectRatioLockDimensionSwapEnabled = aspectRatioLockDimensionSwapEnabled;
}

- (BOOL)aspectRatioLockEnabled
{
    return self.cropView.aspectRatioLockEnabled;
}

- (void)setRotateButtonsHidden:(BOOL)rotateButtonsHidden
{
    self.toolbar.rotateCounterclockwiseButtonHidden = rotateButtonsHidden;
    self.toolbar.rotateClockwiseButtonHidden = rotateButtonsHidden;
}

- (void)setResetButtonHidden:(BOOL)resetButtonHidden
{
    self.toolbar.resetButtonHidden = resetButtonHidden;
}

- (BOOL)rotateButtonsHidden
{
    return self.toolbar.rotateCounterclockwiseButtonHidden && self.toolbar.rotateClockwiseButtonHidden;
}

- (void)setRotateClockwiseButtonHidden:(BOOL)rotateClockwiseButtonHidden
{
    self.toolbar.rotateClockwiseButtonHidden = rotateClockwiseButtonHidden;
}

- (BOOL)rotateClockwiseButtonHidden {
    return self.toolbar.rotateClockwiseButtonHidden;
}

- (void)setAspectRatioPickerButtonHidden:(BOOL)aspectRatioPickerButtonHidden
{
    self.toolbar.clampButtonHidden = aspectRatioPickerButtonHidden;
}

- (BOOL)aspectRatioPickerButtonHidden
{
    return self.toolbar.clampButtonHidden;
}

- (void)setDoneButtonHidden:(BOOL)doneButtonHidden
{
    self.toolbar.doneButtonHidden = doneButtonHidden;
}

- (BOOL)doneButtonHidden
{
    return self.toolbar.doneButtonHidden;
}

- (void)setCancelButtonHidden:(BOOL)cancelButtonHidden
{
    self.toolbar.cancelButtonHidden = cancelButtonHidden;
}

- (BOOL)cancelButtonHidden
{
    return self.toolbar.cancelButtonHidden;
}

- (void)setResetAspectRatioEnabled:(BOOL)resetAspectRatioEnabled
{
    self.cropView.resetAspectRatioEnabled = resetAspectRatioEnabled;
    if (!self.aspectRatioPickerButtonHidden) {
        self.aspectRatioPickerButtonHidden = (resetAspectRatioEnabled == NO && self.aspectRatioLockEnabled);
    }
}

- (void)setCustomAspectRatio:(CGSize)customAspectRatio
{
    _customAspectRatio = customAspectRatio;
    [self setAspectRatioPreset:__FWImageCropAspectRatioPresetCustom animated:NO];
}

- (BOOL)resetAspectRatioEnabled
{
    return self.cropView.resetAspectRatioEnabled;
}

- (void)setAngle:(NSInteger)angle
{
    self.cropView.angle = angle;
}

- (NSInteger)angle
{
    return self.cropView.angle;
}

- (void)setImageCropFrame:(CGRect)imageCropFrame
{
    self.cropView.imageCropFrame = imageCropFrame;
}

- (CGRect)imageCropFrame
{
    return self.cropView.imageCropFrame;
}

- (CGFloat)toolbarHeight
{
    return _toolbarHeight > 0 ? _toolbarHeight : UIScreen.__fw_toolBarHeight - UIScreen.__fw_safeAreaInsets.bottom;
}

- (BOOL)verticalLayout
{
    return CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds);
}

- (BOOL)overrideStatusBar
{
    // If we're pushed from a navigation controller, we'll defer
    // to its handling of the status bar
    if (self.navigationController) {
        return NO;
    }
    
    // If the view controller presenting us already hid it, we don't need to
    // do anything ourselves
    if (self.presentingViewController.prefersStatusBarHidden) {
        return NO;
    }
    
    // We'll handle the status bar
    return YES;
}

- (BOOL)statusBarHidden
{
    // Defer behaviour to the hosting navigation controller
    if (self.navigationController) {
        return self.navigationController.prefersStatusBarHidden;
    }
    
    //If our presenting controller has already hidden the status bar,
    //hide the status bar by default
    if (self.presentingViewController.prefersStatusBarHidden) {
        return YES;
    }
    
    // Our default behaviour is to always hide the status bar
    return YES;
}

- (CGFloat)statusBarHeight
{
    CGFloat statusBarHeight = 0.0f;
    statusBarHeight = self.view.safeAreaInsets.top;

    // On non-Face ID devices, always disregard the top inset
    // unless we explicitly set the status bar to be visible.
    if (self.statusBarHidden &&
        self.view.safeAreaInsets.bottom <= FLT_EPSILON)
    {
        statusBarHeight = 0.0f;
    }
    
    return statusBarHeight;
}

- (UIEdgeInsets)statusBarSafeInsets
{
    UIEdgeInsets insets = self.view.safeAreaInsets;
    insets.top = self.statusBarHeight;

    return insets;
}

- (void)setMinimumAspectRatio:(CGFloat)minimumAspectRatio
{
    self.cropView.minimumAspectRatio = minimumAspectRatio;
}

- (CGFloat)minimumAspectRatio
{
    return self.cropView.minimumAspectRatio;
}

@end

static const CGFloat k__FWImageCropOverLayerCornerWidth = 20.0f;

@interface __FWImageCropOverlayView ()

@property (nonatomic, strong) NSArray *horizontalGridLines;
@property (nonatomic, strong) NSArray *verticalGridLines;

@property (nonatomic, strong) NSArray *outerLineViews;   //top, right, bottom, left

@property (nonatomic, strong) NSArray *topLeftLineViews; //vertical, horizontal
@property (nonatomic, strong) NSArray *bottomLeftLineViews;
@property (nonatomic, strong) NSArray *bottomRightLineViews;
@property (nonatomic, strong) NSArray *topRightLineViews;

@end

@implementation __FWImageCropOverlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = NO;
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    UIView *(^newLineView)(void) = ^UIView *(void){
        return [self createNewLineView];
    };

    _outerLineViews     = @[newLineView(), newLineView(), newLineView(), newLineView()];
    
    _topLeftLineViews   = @[newLineView(), newLineView()];
    _bottomLeftLineViews = @[newLineView(), newLineView()];
    _topRightLineViews  = @[newLineView(), newLineView()];
    _bottomRightLineViews = @[newLineView(), newLineView()];
    
    self.displayHorizontalGridLines = YES;
    self.displayVerticalGridLines = YES;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (_outerLineViews) {
        [self layoutLines];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    if (_outerLineViews) {
        [self layoutLines];
    }
}

- (void)layoutLines
{
    CGSize boundsSize = self.bounds.size;
    
    //border lines
    for (NSInteger i = 0; i < 4; i++) {
        UIView *lineView = self.outerLineViews[i];
        
        CGRect frame = CGRectZero;
        switch (i) {
            case 0: frame = (CGRect){0,-1.0f,boundsSize.width+2.0f, 1.0f}; break; //top
            case 1: frame = (CGRect){boundsSize.width,0.0f,1.0f,boundsSize.height}; break; //right
            case 2: frame = (CGRect){-1.0f,boundsSize.height,boundsSize.width+2.0f,1.0f}; break; //bottom
            case 3: frame = (CGRect){-1.0f,0,1.0f,boundsSize.height+1.0f}; break; //left
        }
        
        lineView.frame = frame;
    }
    
    //corner liness
    NSArray *cornerLines = @[self.topLeftLineViews, self.topRightLineViews, self.bottomRightLineViews, self.bottomLeftLineViews];
    for (NSInteger i = 0; i < 4; i++) {
        NSArray *cornerLine = cornerLines[i];
        
        CGRect verticalFrame = CGRectZero, horizontalFrame = CGRectZero;
        switch (i) {
            case 0: //top left
                verticalFrame = (CGRect){-3.0f,-3.0f,3.0f,k__FWImageCropOverLayerCornerWidth+3.0f};
                horizontalFrame = (CGRect){0,-3.0f,k__FWImageCropOverLayerCornerWidth,3.0f};
                break;
            case 1: //top right
                verticalFrame = (CGRect){boundsSize.width,-3.0f,3.0f,k__FWImageCropOverLayerCornerWidth+3.0f};
                horizontalFrame = (CGRect){boundsSize.width-k__FWImageCropOverLayerCornerWidth,-3.0f,k__FWImageCropOverLayerCornerWidth,3.0f};
                break;
            case 2: //bottom right
                verticalFrame = (CGRect){boundsSize.width,boundsSize.height-k__FWImageCropOverLayerCornerWidth,3.0f,k__FWImageCropOverLayerCornerWidth+3.0f};
                horizontalFrame = (CGRect){boundsSize.width-k__FWImageCropOverLayerCornerWidth,boundsSize.height,k__FWImageCropOverLayerCornerWidth,3.0f};
                break;
            case 3: //bottom left
                verticalFrame = (CGRect){-3.0f,boundsSize.height-k__FWImageCropOverLayerCornerWidth,3.0f,k__FWImageCropOverLayerCornerWidth};
                horizontalFrame = (CGRect){-3.0f,boundsSize.height,k__FWImageCropOverLayerCornerWidth+3.0f,3.0f};
                break;
        }
        
        [cornerLine[0] setFrame:verticalFrame];
        [cornerLine[1] setFrame:horizontalFrame];
    }
    
    //grid lines - horizontal
    CGFloat thickness = 1.0f / [[UIScreen mainScreen] scale];
    NSInteger numberOfLines = self.horizontalGridLines.count;
    CGFloat padding = (CGRectGetHeight(self.bounds) - (thickness*numberOfLines)) / (numberOfLines + 1);
    for (NSInteger i = 0; i < numberOfLines; i++) {
        UIView *lineView = self.horizontalGridLines[i];
        CGRect frame = CGRectZero;
        frame.size.height = thickness;
        frame.size.width = CGRectGetWidth(self.bounds);
        frame.origin.y = (padding * (i+1)) + (thickness * i);
        lineView.frame = frame;
    }
    
    //grid lines - vertical
    numberOfLines = self.verticalGridLines.count;
    padding = (CGRectGetWidth(self.bounds) - (thickness*numberOfLines)) / (numberOfLines + 1);
    for (NSInteger i = 0; i < numberOfLines; i++) {
        UIView *lineView = self.verticalGridLines[i];
        CGRect frame = CGRectZero;
        frame.size.width = thickness;
        frame.size.height = CGRectGetHeight(self.bounds);
        frame.origin.x = (padding * (i+1)) + (thickness * i);
        lineView.frame = frame;
    }
}

- (void)setGridHidden:(BOOL)hidden animated:(BOOL)animated
{
    _gridHidden = hidden;
    
    if (animated == NO) {
        for (UIView *lineView in self.horizontalGridLines) {
            lineView.alpha = hidden ? 0.0f : 1.0f;
        }
        
        for (UIView *lineView in self.verticalGridLines) {
            lineView.alpha = hidden ? 0.0f : 1.0f;
        }
    
        return;
    }
    
    [UIView animateWithDuration:hidden?0.35f:0.2f animations:^{
        for (UIView *lineView in self.horizontalGridLines)
            lineView.alpha = hidden ? 0.0f : 1.0f;
        
        for (UIView *lineView in self.verticalGridLines)
            lineView.alpha = hidden ? 0.0f : 1.0f;
    }];
}

#pragma mark - Property methods

- (void)setDisplayHorizontalGridLines:(BOOL)displayHorizontalGridLines {
    _displayHorizontalGridLines = displayHorizontalGridLines;
    
    [self.horizontalGridLines enumerateObjectsUsingBlock:^(UIView *__nonnull lineView, NSUInteger idx, BOOL * __nonnull stop) {
        [lineView removeFromSuperview];
    }];
    
    if (_displayHorizontalGridLines) {
        self.horizontalGridLines = @[[self createNewLineView], [self createNewLineView]];
    } else {
        self.horizontalGridLines = @[];
    }
    [self setNeedsDisplay];
}

- (void)setDisplayVerticalGridLines:(BOOL)displayVerticalGridLines {
    _displayVerticalGridLines = displayVerticalGridLines;
    
    [self.verticalGridLines enumerateObjectsUsingBlock:^(UIView *__nonnull lineView, NSUInteger idx, BOOL * __nonnull stop) {
        [lineView removeFromSuperview];
    }];
    
    if (_displayVerticalGridLines) {
        self.verticalGridLines = @[[self createNewLineView], [self createNewLineView]];
    } else {
        self.verticalGridLines = @[];
    }
    [self setNeedsDisplay];
}

- (void)setGridHidden:(BOOL)gridHidden
{
    [self setGridHidden:gridHidden animated:NO];
}

#pragma mark - Private methods

- (nonnull UIView *)createNewLineView {
    UIView *newLine = [[UIView alloc] initWithFrame:CGRectZero];
    newLine.backgroundColor = [UIColor whiteColor];
    [self addSubview:newLine];
    return newLine;
}

@end

@implementation __FWImageCropScrollView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.touchesBegan)
        self.touchesBegan();
        
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.touchesEnded)
        self.touchesEnded();
    
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.touchesCancelled)
        self.touchesCancelled();
    
    [super touchesCancelled:touches withEvent:event];
}

@end

@interface __FWImageCropToolbar()

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong, readwrite) UIButton *doneTextButton;
@property (nonatomic, strong, readwrite) UIButton *doneIconButton;

@property (nonatomic, strong, readwrite) UIButton *cancelTextButton;
@property (nonatomic, strong, readwrite) UIButton *cancelIconButton;

@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *clampButton;

@property (nonatomic, strong) UIButton *rotateButton; // defaults to counterclockwise button for legacy compatibility

@property (nonatomic, assign) BOOL reverseContentLayout; // For languages like Arabic where they natively present content flipped from English

@end

@implementation __FWImageCropToolbar

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    _buttonInsetPadding = 16.f;
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.12f alpha:1.0f];
    [self addSubview:self.backgroundView];
    
    self.reverseContentLayout = ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft);
    
    _doneTextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_doneTextButton setTitle: _doneTextButtonTitle ?
        _doneTextButtonTitle : __FWAppBundle.doneButton
                     forState:UIControlStateNormal];
    [_doneTextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_doneTextButton.titleLabel setFont:[UIFont systemFontOfSize:16.0f]];
    [_doneTextButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_doneTextButton sizeToFit];
    [self addSubview:_doneTextButton];
    
    _doneIconButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_doneIconButton setImage:[__FWImageCropToolbar doneImage] forState:UIControlStateNormal];
    [_doneIconButton setTintColor:[UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f]];
    [_doneIconButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_doneIconButton];
    
    _cancelTextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [_cancelTextButton setTitle: _cancelTextButtonTitle ?
        _cancelTextButtonTitle : __FWAppBundle.cancelButton
                       forState:UIControlStateNormal];
    [_cancelTextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_cancelTextButton.titleLabel setFont:[UIFont systemFontOfSize:16.0f]];
    [_cancelTextButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_cancelTextButton sizeToFit];
    [self addSubview:_cancelTextButton];
    
    _cancelIconButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cancelIconButton setImage:[__FWImageCropToolbar cancelImage] forState:UIControlStateNormal];
    [_cancelIconButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_cancelIconButton];
    
    _clampButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _clampButton.contentMode = UIViewContentModeCenter;
    _clampButton.tintColor = [UIColor whiteColor];
    [_clampButton setImage:[__FWImageCropToolbar clampImage] forState:UIControlStateNormal];
    [_clampButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_clampButton];
    
    _rotateCounterclockwiseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _rotateCounterclockwiseButton.contentMode = UIViewContentModeCenter;
    _rotateCounterclockwiseButton.tintColor = [UIColor whiteColor];
    [_rotateCounterclockwiseButton setImage:[__FWImageCropToolbar rotateCCWImage] forState:UIControlStateNormal];
    [_rotateCounterclockwiseButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_rotateCounterclockwiseButton];
    
    _rotateClockwiseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _rotateClockwiseButton.contentMode = UIViewContentModeCenter;
    _rotateClockwiseButton.tintColor = [UIColor whiteColor];
    [_rotateClockwiseButton setImage:[__FWImageCropToolbar rotateCWImage] forState:UIControlStateNormal];
    [_rotateClockwiseButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_rotateClockwiseButton];
    
    _resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _resetButton.contentMode = UIViewContentModeCenter;
    _resetButton.tintColor = [UIColor whiteColor];
    _resetButton.enabled = NO;
    [_resetButton setImage:[__FWImageCropToolbar resetImage] forState:UIControlStateNormal];
    [_resetButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_resetButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL verticalLayout = (CGRectGetWidth(self.bounds) < CGRectGetHeight(self.bounds));
    CGSize boundsSize = self.bounds.size;
    
    self.cancelIconButton.hidden = self.cancelButtonHidden || (!verticalLayout);
    self.cancelTextButton.hidden = self.cancelButtonHidden || (verticalLayout);
    self.doneIconButton.hidden   = self.doneButtonHidden || (!verticalLayout);
    self.doneTextButton.hidden   = self.doneButtonHidden || (verticalLayout);

    CGRect frame = self.bounds;
    frame.origin.x -= self.backgroundViewOutsets.left;
    frame.size.width += self.backgroundViewOutsets.left;
    frame.size.width += self.backgroundViewOutsets.right;
    frame.origin.y -= self.backgroundViewOutsets.top;
    frame.size.height += self.backgroundViewOutsets.top;
    frame.size.height += self.backgroundViewOutsets.bottom;
    self.backgroundView.frame = frame;
    
    if (verticalLayout == NO) {
        CGFloat insetPadding = self.buttonInsetPadding;
        
        // Work out the cancel button frame
        CGRect frame = CGRectZero;
        frame.origin.y = (CGRectGetHeight(self.bounds) - 44.0f) / 2.0;
        frame.size.height = 44.0f;
        frame.size.width = MIN(self.frame.size.width / 3.0, self.cancelTextButton.frame.size.width);

        //If normal layout, place on the left side, else place on the right
        if (self.reverseContentLayout == NO) {
            frame.origin.x = insetPadding;
        }
        else {
            frame.origin.x = boundsSize.width - (frame.size.width + insetPadding);
        }
        self.cancelTextButton.frame = frame;
        
        // Work out the Done button frame
        frame.size.width = MIN(self.frame.size.width / 3.0, self.doneTextButton.frame.size.width);
        
        if (self.reverseContentLayout == NO) {
            frame.origin.x = boundsSize.width - (frame.size.width + insetPadding);
        }
        else {
            frame.origin.x = insetPadding;
        }
        self.doneTextButton.frame = frame;
        
        // Work out the frame between the two buttons where we can layout our action buttons
        CGFloat x = self.reverseContentLayout ? CGRectGetMaxX(self.doneTextButton.frame) : CGRectGetMaxX(self.cancelTextButton.frame);
        CGFloat width = 0.0f;
        
        if (self.reverseContentLayout == NO) {
            width = CGRectGetMinX(self.doneTextButton.frame) - CGRectGetMaxX(self.cancelTextButton.frame);
        }
        else {
            width = CGRectGetMinX(self.cancelTextButton.frame) - CGRectGetMaxX(self.doneTextButton.frame);
        }
        
        CGRect containerRect = CGRectIntegral((CGRect){x,frame.origin.y,width,CGRectGetHeight(self.bounds) - frame.origin.y});
        
        CGSize buttonSize = (CGSize){44.0f,44.0f};
        
        NSMutableArray *buttonsInOrderHorizontally = [NSMutableArray new];
        if (!self.rotateCounterclockwiseButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.rotateCounterclockwiseButton];
        }
        
        if (!self.resetButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.resetButton];
        }
        
        if (!self.clampButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.clampButton];
        }
        
        if (!self.rotateClockwiseButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.rotateClockwiseButton];
        }
        [self layoutToolbarButtons:buttonsInOrderHorizontally withSameButtonSize:buttonSize inContainerRect:containerRect horizontally:YES];
    }
    else {
        CGRect frame = CGRectZero;
        frame.origin.x = (CGRectGetWidth(self.bounds) - 44.f) / 2.0;
        frame.size.height = 44.0f;
        frame.size.width = 44.0f;
        frame.origin.y = CGRectGetHeight(self.bounds) - 44.0f;
        self.cancelIconButton.frame = frame;
        
        frame.origin.y = self.statusBarHeightInset;
        frame.size.width = 44.0f;
        frame.size.height = 44.0f;
        self.doneIconButton.frame = frame;
        
        CGRect containerRect = (CGRect){frame.origin.x,CGRectGetMaxY(self.doneIconButton.frame),CGRectGetWidth(self.bounds) - frame.origin.x,CGRectGetMinY(self.cancelIconButton.frame)-CGRectGetMaxY(self.doneIconButton.frame)};
        
        CGSize buttonSize = (CGSize){44.0f,44.0f};
        
        NSMutableArray *buttonsInOrderVertically = [NSMutableArray new];
        if (!self.rotateCounterclockwiseButtonHidden) {
            [buttonsInOrderVertically addObject:self.rotateCounterclockwiseButton];
        }
        
        if (!self.resetButtonHidden) {
            [buttonsInOrderVertically addObject:self.resetButton];
        }
        
        if (!self.clampButtonHidden) {
            [buttonsInOrderVertically addObject:self.clampButton];
        }
        
        if (!self.rotateClockwiseButtonHidden) {
            [buttonsInOrderVertically addObject:self.rotateClockwiseButton];
        }
        
        [self layoutToolbarButtons:buttonsInOrderVertically withSameButtonSize:buttonSize inContainerRect:containerRect horizontally:NO];
    }
}

// The convenience method for calculating button's frame inside of the container rect
- (void)layoutToolbarButtons:(NSArray *)buttons withSameButtonSize:(CGSize)size inContainerRect:(CGRect)containerRect horizontally:(BOOL)horizontally
{
    if (buttons.count > 0){
        NSInteger count = buttons.count;
        CGFloat fixedSize = horizontally ? size.width : size.height;
        CGFloat maxLength = horizontally ? CGRectGetWidth(containerRect) : CGRectGetHeight(containerRect);
        CGFloat padding = (maxLength - fixedSize * count) / (count + 1);
        
        for (NSInteger i = 0; i < count; i++) {
            UIView *button = buttons[i];
            CGFloat sameOffset = horizontally ? CGRectGetHeight(containerRect)-CGRectGetHeight(button.bounds) : CGRectGetWidth(containerRect)-CGRectGetWidth(button.bounds);
            CGFloat diffOffset = padding + i * (fixedSize + padding);
            CGPoint origin = horizontally ? CGPointMake(diffOffset, sameOffset) : CGPointMake(sameOffset, diffOffset);
            if (horizontally) {
                origin.x += CGRectGetMinX(containerRect);
            } else {
                origin.y += CGRectGetMinY(containerRect);
            }
            button.frame = (CGRect){origin, size};
        }
    }
}

- (void)buttonTapped:(id)button
{
    if (button == self.cancelTextButton || button == self.cancelIconButton) {
        if (self.cancelButtonTapped)
            self.cancelButtonTapped();
    }
    else if (button == self.doneTextButton || button == self.doneIconButton) {
        if (self.doneButtonTapped)
            self.doneButtonTapped();
    }
    else if (button == self.resetButton && self.resetButtonTapped) {
        self.resetButtonTapped();
    }
    else if (button == self.rotateCounterclockwiseButton && self.rotateCounterclockwiseButtonTapped) {
        self.rotateCounterclockwiseButtonTapped();
    }
    else if (button == self.rotateClockwiseButton && self.rotateClockwiseButtonTapped) {
        self.rotateClockwiseButtonTapped();
    }
    else if (button == self.clampButton && self.clampButtonTapped) {
        self.clampButtonTapped();
        return;
    }
}

- (CGRect)clampButtonFrame
{
    return self.clampButton.frame;
}

- (void)setClampButtonHidden:(BOOL)clampButtonHidden {
    if (_clampButtonHidden == clampButtonHidden)
        return;
    
    _clampButtonHidden = clampButtonHidden;
    [self setNeedsLayout];
}

- (void)setClampButtonGlowing:(BOOL)clampButtonGlowing
{
    if (_clampButtonGlowing == clampButtonGlowing)
        return;
    
    _clampButtonGlowing = clampButtonGlowing;
    
    if (_clampButtonGlowing)
        self.clampButton.tintColor = nil;
    else
        self.clampButton.tintColor = [UIColor whiteColor];
}

- (void)setRotateCounterClockwiseButtonHidden:(BOOL)rotateButtonHidden
{
    if (_rotateCounterclockwiseButtonHidden == rotateButtonHidden)
        return;
    
    _rotateCounterclockwiseButtonHidden = rotateButtonHidden;
    [self setNeedsLayout];
}

- (BOOL)resetButtonEnabled
{
    return self.resetButton.enabled;
}

- (void)setResetButtonEnabled:(BOOL)resetButtonEnabled
{
    self.resetButton.enabled = resetButtonEnabled;
}

- (void)setDoneButtonHidden:(BOOL)doneButtonHidden {
    if (_doneButtonHidden == doneButtonHidden)
        return;
    
    _doneButtonHidden = doneButtonHidden;
    [self setNeedsLayout];
}

- (void)setCancelButtonHidden:(BOOL)cancelButtonHidden {
    if (_cancelButtonHidden == cancelButtonHidden)
        return;
    
    _cancelButtonHidden = cancelButtonHidden;
    [self setNeedsLayout];
}

- (CGRect)doneButtonFrame
{
    if (self.doneIconButton.hidden == NO)
        return self.doneIconButton.frame;
    
    return self.doneTextButton.frame;
}

- (void)setCancelTextButtonTitle:(NSString *)cancelTextButtonTitle {
    _cancelTextButtonTitle = cancelTextButtonTitle;
    [_cancelTextButton setTitle:_cancelTextButtonTitle forState:UIControlStateNormal];
    [_cancelTextButton sizeToFit];
}

- (void)setDoneTextButtonTitle:(NSString *)doneTextButtonTitle {
    _doneTextButtonTitle = doneTextButtonTitle;
    [_doneTextButton setTitle:_doneTextButtonTitle forState:UIControlStateNormal];
    [_doneTextButton sizeToFit];
}

#pragma mark - Image Generation -
+ (UIImage *)doneImage
{
    UIImage *doneImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){17,14}, NO, 0.0f);
    {
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = UIBezierPath.bezierPath;
        [rectanglePath moveToPoint: CGPointMake(1, 7)];
        [rectanglePath addLineToPoint: CGPointMake(6, 12)];
        [rectanglePath addLineToPoint: CGPointMake(16, 1)];
        [UIColor.whiteColor setStroke];
        rectanglePath.lineWidth = 2;
        [rectanglePath stroke];
        
        
        doneImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return doneImage;
}

+ (UIImage *)cancelImage
{
    UIImage *cancelImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){16,16}, NO, 0.0f);
    {
        UIBezierPath* bezierPath = UIBezierPath.bezierPath;
        [bezierPath moveToPoint: CGPointMake(15, 15)];
        [bezierPath addLineToPoint: CGPointMake(1, 1)];
        [UIColor.whiteColor setStroke];
        bezierPath.lineWidth = 2;
        [bezierPath stroke];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = UIBezierPath.bezierPath;
        [bezier2Path moveToPoint: CGPointMake(1, 15)];
        [bezier2Path addLineToPoint: CGPointMake(15, 1)];
        [UIColor.whiteColor setStroke];
        bezier2Path.lineWidth = 2;
        [bezier2Path stroke];
        
        cancelImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return cancelImage;
}

+ (UIImage *)rotateCCWImage
{
    UIImage *rotateImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){18,21}, NO, 0.0f);
    {
        //// Rectangle 2 Drawing
        UIBezierPath* rectangle2Path = [UIBezierPath bezierPathWithRect: CGRectMake(0, 9, 12, 12)];
        [UIColor.whiteColor setFill];
        [rectangle2Path fill];
        
        
        //// Rectangle 3 Drawing
        UIBezierPath* rectangle3Path = UIBezierPath.bezierPath;
        [rectangle3Path moveToPoint: CGPointMake(5, 3)];
        [rectangle3Path addLineToPoint: CGPointMake(10, 6)];
        [rectangle3Path addLineToPoint: CGPointMake(10, 0)];
        [rectangle3Path addLineToPoint: CGPointMake(5, 3)];
        [rectangle3Path closePath];
        [UIColor.whiteColor setFill];
        [rectangle3Path fill];
        
        
        //// Bezier Drawing
        UIBezierPath* bezierPath = UIBezierPath.bezierPath;
        [bezierPath moveToPoint: CGPointMake(10, 3)];
        [bezierPath addCurveToPoint: CGPointMake(17.5, 11) controlPoint1: CGPointMake(15, 3) controlPoint2: CGPointMake(17.5, 5.91)];
        [UIColor.whiteColor setStroke];
        bezierPath.lineWidth = 1;
        [bezierPath stroke];
        rotateImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return rotateImage;
}

+ (UIImage *)rotateCWImage
{
    UIImage *rotateCCWImage = [self.class rotateCCWImage];
    UIGraphicsBeginImageContextWithOptions(rotateCCWImage.size, NO, rotateCCWImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotateCCWImage.size.width, rotateCCWImage.size.height);
    CGContextRotateCTM(context, M_PI);
    CGContextDrawImage(context,CGRectMake(0,0,rotateCCWImage.size.width,rotateCCWImage.size.height),rotateCCWImage.CGImage);
    UIImage *rotateCWImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotateCWImage;
}

+ (UIImage *)resetImage
{
    UIImage *resetImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){22,18}, NO, 0.0f);
    {
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = UIBezierPath.bezierPath;
        [bezier2Path moveToPoint: CGPointMake(22, 9)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 18) controlPoint1: CGPointMake(22, 13.97) controlPoint2: CGPointMake(17.97, 18)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 16) controlPoint1: CGPointMake(13, 17.35) controlPoint2: CGPointMake(13, 16.68)];
        [bezier2Path addCurveToPoint: CGPointMake(20, 9) controlPoint1: CGPointMake(16.87, 16) controlPoint2: CGPointMake(20, 12.87)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 2) controlPoint1: CGPointMake(20, 5.13) controlPoint2: CGPointMake(16.87, 2)];
        [bezier2Path addCurveToPoint: CGPointMake(6.55, 6.27) controlPoint1: CGPointMake(10.1, 2) controlPoint2: CGPointMake(7.62, 3.76)];
        [bezier2Path addCurveToPoint: CGPointMake(6, 9) controlPoint1: CGPointMake(6.2, 7.11) controlPoint2: CGPointMake(6, 8.03)];
        [bezier2Path addLineToPoint: CGPointMake(4, 9)];
        [bezier2Path addCurveToPoint: CGPointMake(4.65, 5.63) controlPoint1: CGPointMake(4, 7.81) controlPoint2: CGPointMake(4.23, 6.67)];
        [bezier2Path addCurveToPoint: CGPointMake(7.65, 1.76) controlPoint1: CGPointMake(5.28, 4.08) controlPoint2: CGPointMake(6.32, 2.74)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 0) controlPoint1: CGPointMake(9.15, 0.65) controlPoint2: CGPointMake(11, 0)];
        [bezier2Path addCurveToPoint: CGPointMake(22, 9) controlPoint1: CGPointMake(17.97, 0) controlPoint2: CGPointMake(22, 4.03)];
        [bezier2Path closePath];
        [UIColor.whiteColor setFill];
        [bezier2Path fill];
        
        
        //// Polygon Drawing
        UIBezierPath* polygonPath = UIBezierPath.bezierPath;
        [polygonPath moveToPoint: CGPointMake(5, 15)];
        [polygonPath addLineToPoint: CGPointMake(10, 9)];
        [polygonPath addLineToPoint: CGPointMake(0, 9)];
        [polygonPath addLineToPoint: CGPointMake(5, 15)];
        [polygonPath closePath];
        [UIColor.whiteColor setFill];
        [polygonPath fill];


        resetImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return resetImage;
}

+ (UIImage *)clampImage
{
    UIImage *clampImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){22,16}, NO, 0.0f);
    {
        //// Color Declarations
        UIColor* outerBox = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.553];
        UIColor* innerBox = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.773];
        
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 3, 13, 13)];
        [UIColor.whiteColor setFill];
        [rectanglePath fill];
        
        
        //// Outer
        {
            //// Top Drawing
            UIBezierPath* topPath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 22, 2)];
            [outerBox setFill];
            [topPath fill];
            
            
            //// Side Drawing
            UIBezierPath* sidePath = [UIBezierPath bezierPathWithRect: CGRectMake(19, 2, 3, 14)];
            [outerBox setFill];
            [sidePath fill];
        }
        
        
        //// Rectangle 2 Drawing
        UIBezierPath* rectangle2Path = [UIBezierPath bezierPathWithRect: CGRectMake(14, 3, 4, 13)];
        [innerBox setFill];
        [rectangle2Path fill];
        
        
        clampImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return clampImage;
}

#pragma mark - Accessors -

- (void)setRotateClockwiseButtonHidden:(BOOL)rotateClockwiseButtonHidden
{
    if (_rotateClockwiseButtonHidden == rotateClockwiseButtonHidden) {
        return;
    }
    
    _rotateClockwiseButtonHidden = rotateClockwiseButtonHidden;
    
    [self setNeedsLayout];
}

- (void)setResetButtonHidden:(BOOL)resetButtonHidden
{
    if (_resetButtonHidden == resetButtonHidden) {
        return;
    }
    
    _resetButtonHidden = resetButtonHidden;
    
    [self setNeedsLayout];
}
- (UIButton *)rotateButton
{
    return self.rotateCounterclockwiseButton;
}

- (void)setStatusBarHeightInset:(CGFloat)statusBarHeightInset
{
    _statusBarHeightInset = statusBarHeightInset;
    [self setNeedsLayout];
}

- (void)setButtonInsetPadding:(CGFloat)buttonInsetPadding
{
    _buttonInsetPadding = buttonInsetPadding;
    [self setNeedsLayout];
}

- (UIView *)visibleCancelButton
{
    if (self.cancelIconButton.hidden == NO) {
        return self.cancelIconButton;
    }

    return self.cancelTextButton;
}

@end

static const CGFloat k__FWImageCropViewPadding = 14.0f;
static const NSTimeInterval k__FWImageCropTimerDuration = 0.8f;
static const CGFloat k__FWImageCropViewMinimumBoxSize = 42.0f;
static const CGFloat k__FWImageCropViewCircularPathRadius = 300.0f;
static const CGFloat k__FWImageCropMaximumZoomScale = 15.0f;

/* When the user taps down to resize the box, this state is used
 to determine where they tapped and how to manipulate the box */
typedef NS_ENUM(NSInteger, __FWImageCropViewOverlayEdge) {
    __FWImageCropViewOverlayEdgeNone,
    __FWImageCropViewOverlayEdgeTopLeft,
    __FWImageCropViewOverlayEdgeTop,
    __FWImageCropViewOverlayEdgeTopRight,
    __FWImageCropViewOverlayEdgeRight,
    __FWImageCropViewOverlayEdgeBottomRight,
    __FWImageCropViewOverlayEdgeBottom,
    __FWImageCropViewOverlayEdgeBottomLeft,
    __FWImageCropViewOverlayEdgeLeft
};

@interface __FWImageCropView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, assign, readwrite) __FWImageCropCroppingStyle croppingStyle;

/* Views */
@property (nonatomic, strong) UIImageView *backgroundImageView;     /* The main image view, placed within the scroll view */
@property (nonatomic, strong) UIView *backgroundContainerView;      /* A view which contains the background image view, to separate its transforms from the scroll view. */
@property (nonatomic, strong, readwrite) UIView *foregroundContainerView;
@property (nonatomic, strong) UIImageView *foregroundImageView;     /* A copy of the background image view, placed over the dimming views */
@property (nonatomic, strong) __FWImageCropScrollView *scrollView;         /* The scroll view in charge of panning/zooming the image. */
@property (nonatomic, strong) UIView *overlayView;                  /* A semi-transparent grey view, overlaid on top of the background image */
@property (nonatomic, strong) UIView *translucencyView;             /* A blur view that is made visible when the user isn't interacting with the crop view */
@property (nonatomic, strong) id translucencyEffect;                /* The dark blur visual effect applied to the visual effect view. */
@property (nonatomic, strong, readwrite) __FWImageCropOverlayView *gridOverlayView;   /* A grid view overlaid on top of the foreground image view's container. */
@property (nonatomic, strong) CAShapeLayer *circularMaskLayer;      /* Managing the clipping of the foreground container into a circle */

/* Gesture Recognizers */
@property (nonatomic, strong) UIPanGestureRecognizer *gridPanGestureRecognizer; /* The gesture recognizer in charge of controlling the resizing of the crop view */

/* Crop box handling */
@property (nonatomic, assign) BOOL applyInitialCroppedImageFrame; /* No by default, when setting initialCroppedImageFrame this will be set to YES, and set back to NO after first application - so it's only done once */
@property (nonatomic, assign) __FWImageCropViewOverlayEdge tappedEdge; /* The edge region that the user tapped on, to resize the cropping region */
@property (nonatomic, assign) CGRect cropOriginFrame;     /* When resizing, this is the original frame of the crop box. */
@property (nonatomic, assign) CGPoint panOriginPoint;     /* The initial touch point of the pan gesture recognizer */
@property (nonatomic, assign, readwrite) CGRect cropBoxFrame;  /* The frame, in relation to to this view where the grid, and crop container view are aligned */
@property (nonatomic, strong) NSTimer *resetTimer;  /* The timer used to reset the view after the user stops interacting with it */
@property (nonatomic, assign) BOOL editing;         /* Used to denote the active state of the user manipulating the content */
@property (nonatomic, assign) BOOL disableForgroundMatching; /* At times during animation, disable matching the forground image view to the background */

/* Pre-screen-rotation state information */
@property (nonatomic, assign) CGPoint rotationContentOffset;
@property (nonatomic, assign) CGSize  rotationContentSize;
@property (nonatomic, assign) CGRect  rotationBoundFrame;

/* View State information */
@property (nonatomic, readonly) CGRect contentBounds; /* Give the current screen real-estate, the frame that the scroll view is allowed to use */
@property (nonatomic, readonly) CGSize imageSize;     /* Given the current rotation of the image, the size of the image */
@property (nonatomic, readonly) BOOL hasAspectRatio;  /* True if an aspect ratio was explicitly applied to this crop view */

/* 90-degree rotation state data */
@property (nonatomic, assign) CGSize cropBoxLastEditedSize; /* When performing 90-degree rotations, remember what our last manual size was to use that as a base */
@property (nonatomic, assign) NSInteger cropBoxLastEditedAngle; /* Remember which angle we were at when we saved the editing size */
@property (nonatomic, assign) CGFloat cropBoxLastEditedZoomScale; /* Remember the zoom size when we last edited */
@property (nonatomic, assign) CGFloat cropBoxLastEditedMinZoomScale; /* Remember the minimum size when we last edited. */
@property (nonatomic, assign) BOOL rotateAnimationInProgress;   /* Disallow any input while the rotation animation is playing */

/* Reset state data */
@property (nonatomic, assign) CGSize originalCropBoxSize; /* Save the original crop box size so we can tell when the content has been edited */
@property (nonatomic, assign) CGPoint originalContentOffset; /* Save the original content offset so we can tell if it's been scrolled. */
@property (nonatomic, assign, readwrite) BOOL canBeReset;

/* If restoring to a previous crop setting, these properties hang onto the
 values until the view is configured for the first time. */
@property (nonatomic, assign) NSInteger restoreAngle;
@property (nonatomic, assign) CGRect    restoreImageCropFrame;

/* Set to YES once `performInitialLayout` is called. This lets pending properties get queued until the view
 has been properly set up in its parent. */
@property (nonatomic, assign) BOOL initialSetupPerformed;

@end

@implementation __FWImageCropView

- (instancetype)initWithImage:(UIImage *)image
{
    return [self initWithCroppingStyle:__FWImageCropCroppingStyleDefault image:image];
}

- (instancetype)initWithCroppingStyle:(__FWImageCropCroppingStyle)style image:(UIImage *)image
{
    if (self = [super init]) {
        _image = image;
        _croppingStyle = style;
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    __weak typeof(self) weakSelf = self;
    
    BOOL circularMode = (self.croppingStyle == __FWImageCropCroppingStyleCircular);
    
    //View properties
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor colorWithWhite:0.12f alpha:1.0f];
    self.cropBoxFrame = CGRectZero;
    self.applyInitialCroppedImageFrame = NO;
    self.editing = NO;
    self.cropBoxResizeEnabled = !circularMode;
    self.aspectRatio = circularMode ? (CGSize){1.0f, 1.0f} : CGSizeZero;
    self.resetAspectRatioEnabled = !circularMode;
    self.restoreImageCropFrame = CGRectZero;
    self.restoreAngle = 0;
    self.cropAdjustingDelay = k__FWImageCropTimerDuration;
    self.cropViewPadding = k__FWImageCropViewPadding;
    self.maximumZoomScale = k__FWImageCropMaximumZoomScale;
    
    //Scroll View properties
    self.scrollView = [[__FWImageCropScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];

    // Disable smart inset behavior in iOS 11
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    self.scrollView.touchesBegan = ^{ [weakSelf startEditing]; };
    self.scrollView.touchesEnded = ^{ [weakSelf startResetTimer]; };
    
    //Background Image View
    self.backgroundImageView = [[UIImageView alloc] initWithImage:self.image];
    self.backgroundImageView.layer.minificationFilter = kCAFilterTrilinear;
    
    //Background container view
    self.backgroundContainerView = [[UIView alloc] initWithFrame:self.backgroundImageView.frame];
    [self.backgroundContainerView addSubview:self.backgroundImageView];
    [self.scrollView addSubview:self.backgroundContainerView];
    
    //Grey transparent overlay view
    self.overlayView = [[UIView alloc] initWithFrame:self.bounds];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.overlayView.backgroundColor = [self.backgroundColor colorWithAlphaComponent:0.35f];
    self.overlayView.hidden = NO;
    self.overlayView.userInteractionEnabled = NO;
    [self addSubview:self.overlayView];
    
    self.translucencyEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.translucencyView = [[UIVisualEffectView alloc] initWithEffect:self.translucencyEffect];
    self.translucencyView.frame = self.bounds;
    self.translucencyView.hidden = self.translucencyAlwaysHidden;
    self.translucencyView.userInteractionEnabled = NO;
    self.translucencyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.translucencyView];
    
    // The forground container that holds the foreground image view
    self.foregroundContainerView = [[UIView alloc] initWithFrame:(CGRect){0,0,200,200}];
    self.foregroundContainerView.clipsToBounds = YES;
    self.foregroundContainerView.userInteractionEnabled = NO;
    [self addSubview:self.foregroundContainerView];
    
    self.foregroundImageView = [[UIImageView alloc] initWithImage:self.image];
    self.foregroundImageView.layer.minificationFilter = kCAFilterTrilinear;
    [self.foregroundContainerView addSubview:self.foregroundImageView];
    
    // Disable colour inversion for the image views
    self.foregroundImageView.accessibilityIgnoresInvertColors = YES;
    self.backgroundImageView.accessibilityIgnoresInvertColors = YES;
    
    // The following setup isn't needed during circular cropping
    if (circularMode) {
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:(CGRect){0,0,k__FWImageCropViewCircularPathRadius, k__FWImageCropViewCircularPathRadius}];
        self.circularMaskLayer = [[CAShapeLayer alloc] init];
        self.circularMaskLayer.path = circlePath.CGPath;
        self.foregroundContainerView.layer.mask = self.circularMaskLayer;
        
        return;
    }
    
    // The white grid overlay view
    self.gridOverlayView = [[__FWImageCropOverlayView alloc] initWithFrame:self.foregroundContainerView.frame];
    self.gridOverlayView.userInteractionEnabled = NO;
    self.gridOverlayView.gridHidden = YES;
    [self addSubview:self.gridOverlayView];
    
    // The pan controller to recognize gestures meant to resize the grid view
    self.gridPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gridPanGestureRecognized:)];
    self.gridPanGestureRecognizer.delegate = self;
    [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.gridPanGestureRecognizer];
    [self addGestureRecognizer:self.gridPanGestureRecognizer];
}

#pragma mark - View Layout -
- (void)performInitialSetup
{
    // Calling this more than once is potentially destructive
    if (self.initialSetupPerformed) {
        return;
    }
    
    // Disable from calling again
    self.initialSetupPerformed = YES;
    
    //Perform the initial layout of the image
    [self layoutInitialImage];
    
    // -- State Restoration --
    
    //If the angle value was previously set before this point, apply it now
    if (self.restoreAngle != 0) {
        self.angle = self.restoreAngle;
        self.restoreAngle = 0;
        self.cropBoxLastEditedAngle = self.angle;
    }
    
    //If an image crop frame was also specified before creation, apply it now
    if (!CGRectIsEmpty(self.restoreImageCropFrame)) {
        self.imageCropFrame = self.restoreImageCropFrame;
        self.restoreImageCropFrame = CGRectZero;
    }

    // Save the current layout state for later
    [self captureStateForImageRotation];
    
    //Check if we performed any resetabble modifications
    [self checkForCanReset];
}

- (void)layoutInitialImage
{
    CGSize imageSize = self.imageSize;
    self.scrollView.contentSize = imageSize;
    
    CGRect bounds = self.contentBounds;
    CGSize boundsSize = bounds.size;

    //work out the minimum scale of the object
    CGFloat scale = 0.0f;
    
    // Work out the size of the image to fit into the content bounds
    scale = MIN(CGRectGetWidth(bounds)/imageSize.width, CGRectGetHeight(bounds)/imageSize.height);
    CGSize scaledImageSize = (CGSize){floorf(imageSize.width * scale), floorf(imageSize.height * scale)};
    
    // If an aspect ratio was pre-applied to the crop view, use that to work out the minimum scale the image needs to be to fit
    CGSize cropBoxSize = CGSizeZero;
    if (self.hasAspectRatio) {
        CGFloat ratioScale = (self.aspectRatio.width / self.aspectRatio.height); //Work out the size of the width in relation to height
        CGSize fullSizeRatio = (CGSize){boundsSize.height * ratioScale, boundsSize.height};
        CGFloat fitScale = MIN(boundsSize.width/fullSizeRatio.width, boundsSize.height/fullSizeRatio.height);
        cropBoxSize = (CGSize){fullSizeRatio.width * fitScale, fullSizeRatio.height * fitScale};
        
        scale = MAX(cropBoxSize.width/imageSize.width, cropBoxSize.height/imageSize.height);
    }

    //Whether aspect ratio, or original, the final image size we'll base the rest of the calculations off
    CGSize scaledSize = (CGSize){floorf(imageSize.width * scale), floorf(imageSize.height * scale)};
    
    // Configure the scroll view
    self.scrollView.minimumZoomScale = scale;
    self.scrollView.maximumZoomScale = scale * self.maximumZoomScale;

    //Set the crop box to the size we calculated and align in the middle of the screen
    CGRect frame = CGRectZero;
    frame.size = self.hasAspectRatio ? cropBoxSize : scaledSize;
    frame.origin.x = bounds.origin.x + floorf((CGRectGetWidth(bounds) - frame.size.width) * 0.5f);
    frame.origin.y = bounds.origin.y + floorf((CGRectGetHeight(bounds) - frame.size.height) * 0.5f);
    self.cropBoxFrame = frame;
    
    //set the fully zoomed out state initially
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    self.scrollView.contentSize = scaledSize;
    
    // If we ended up with a smaller crop box than the content, line up the content so its center
    // is in the center of the cropbox
    if (frame.size.width < scaledSize.width - FLT_EPSILON || frame.size.height < scaledSize.height - FLT_EPSILON) {
        CGPoint offset = CGPointZero;
        offset.x = -floorf(CGRectGetMidX(bounds) - (scaledSize.width * 0.5f));
        offset.y = -floorf(CGRectGetMidY(bounds) - (scaledSize.height * 0.5f));
        self.scrollView.contentOffset = offset;
    }

    //save the current state for use with 90-degree rotations
    self.cropBoxLastEditedAngle = 0;
    [self captureStateForImageRotation];
    
    //save the size for checking if we're in a resettable state
    self.originalCropBoxSize = self.resetAspectRatioEnabled ? scaledImageSize : self.cropBoxFrame.size;
    self.originalContentOffset = self.scrollView.contentOffset;
    
    [self checkForCanReset];
    [self matchForegroundToBackground];
}

- (void)prepareforRotation
{
    self.rotationContentOffset = self.scrollView.contentOffset;
    self.rotationContentSize   = self.scrollView.contentSize;
    self.rotationBoundFrame     = self.contentBounds;
}

- (void)performRelayoutForRotation
{
    CGRect cropFrame = self.cropBoxFrame;
    CGRect contentFrame = self.contentBounds;
 
    CGFloat scale = MIN(contentFrame.size.width / cropFrame.size.width, contentFrame.size.height / cropFrame.size.height);
    self.scrollView.minimumZoomScale *= scale;
    self.scrollView.zoomScale *= scale;
    
    //Work out the centered, upscaled version of the crop rectangle
    cropFrame.size.width  = floorf(cropFrame.size.width * scale);
    cropFrame.size.height = floorf(cropFrame.size.height * scale);
    cropFrame.origin.x    = floorf(contentFrame.origin.x + ((contentFrame.size.width - cropFrame.size.width) * 0.5f));
    cropFrame.origin.y    = floorf(contentFrame.origin.y + ((contentFrame.size.height - cropFrame.size.height) * 0.5f));
    self.cropBoxFrame = cropFrame;
    
    [self captureStateForImageRotation];
    
    //Work out the center point of the content before we rotated
    CGPoint oldMidPoint = (CGPoint){CGRectGetMidX(self.rotationBoundFrame), CGRectGetMidY(self.rotationBoundFrame)};
    CGPoint contentCenter = (CGPoint){self.rotationContentOffset.x + oldMidPoint.x, self.rotationContentOffset.y + oldMidPoint.y};
    
    //Normalize it to a percentage we can apply to different sizes
    CGPoint normalizedCenter = CGPointZero;
    normalizedCenter.x = contentCenter.x / self.rotationContentSize.width;
    normalizedCenter.y = contentCenter.y / self.rotationContentSize.height;
    
    //Work out the new content offset by applying the normalized values to the new layout
    CGPoint newMidPoint = (CGPoint){CGRectGetMidX(self.contentBounds),CGRectGetMidY(self.contentBounds)};

    CGPoint translatedContentOffset = CGPointZero;
    translatedContentOffset.x = self.scrollView.contentSize.width * normalizedCenter.x;
    translatedContentOffset.y = self.scrollView.contentSize.height * normalizedCenter.y;
    
    CGPoint offset = CGPointZero;
    offset.x = floorf(translatedContentOffset.x - newMidPoint.x);
    offset.y = floorf(translatedContentOffset.y - newMidPoint.y);
    
    //Make sure it doesn't overshoot the top left corner of the crop box
    offset.x = MAX(-self.scrollView.contentInset.left, offset.x);
    offset.y = MAX(-self.scrollView.contentInset.top, offset.y);

    //Nor undershoot the bottom right corner
    CGPoint maximumOffset = CGPointZero;
    maximumOffset.x = (self.bounds.size.width - self.scrollView.contentInset.right) + self.scrollView.contentSize.width;
    maximumOffset.y = (self.bounds.size.height - self.scrollView.contentInset.bottom) + self.scrollView.contentSize.height;
    offset.x = MIN(offset.x, maximumOffset.x);
    offset.y = MIN(offset.y, maximumOffset.y);
    self.scrollView.contentOffset = offset;
    
    //Line up the background instance of the image
    [self matchForegroundToBackground];
}

- (void)matchForegroundToBackground
{
    if (self.disableForgroundMatching)
        return;
    
    //We can't simply match the frames since if the images are rotated, the frame property becomes unusable
    self.foregroundImageView.frame = [self.backgroundContainerView.superview convertRect:self.backgroundContainerView.frame toView:self.foregroundContainerView];
}

- (void)updateCropBoxFrameWithGesturePoint:(CGPoint)point
{
    CGRect frame = self.cropBoxFrame;
    CGRect originFrame = self.cropOriginFrame;
    CGRect contentFrame = self.contentBounds;

    point.x = MAX(contentFrame.origin.x - self.cropViewPadding, point.x);
    point.y = MAX(contentFrame.origin.y - self.cropViewPadding, point.y);
    
    //The delta between where we first tapped, and where our finger is now
    CGFloat xDelta = ceilf(point.x - self.panOriginPoint.x);
    CGFloat yDelta = ceilf(point.y - self.panOriginPoint.y);

    //Current aspect ratio of the crop box in case we need to clamp it
    CGFloat aspectRatio = (originFrame.size.width / originFrame.size.height);

    //Note whether we're being aspect transformed horizontally or vertically
    BOOL aspectHorizontal = NO, aspectVertical = NO;
    
    //Depending on which corner we drag from, set the appropriate min flag to
    //ensure we can properly clamp the XY value of the box if it overruns the minimum size
    //(Otherwise the image itself will slide with the drag gesture)
    BOOL clampMinFromTop = NO, clampMinFromLeft = NO;

    switch (self.tappedEdge) {
        case __FWImageCropViewOverlayEdgeLeft:
            if (self.aspectRatioLockEnabled) {
                aspectHorizontal = YES;
                xDelta = MAX(xDelta, 0);
                CGPoint scaleOrigin = (CGPoint){CGRectGetMaxX(originFrame), CGRectGetMidY(originFrame)};
                frame.size.height = frame.size.width / aspectRatio;
                frame.origin.y = scaleOrigin.y - (frame.size.height * 0.5f);
            }
            CGFloat newWidth = originFrame.size.width - xDelta;
            CGFloat newHeight = originFrame.size.height;
            if (MIN(newHeight, newWidth) / MAX(newHeight, newWidth) >= (double)_minimumAspectRatio) {
                frame.origin.x   = originFrame.origin.x + xDelta;
                frame.size.width = originFrame.size.width - xDelta;
            }
            
            clampMinFromLeft = YES;
            
            break;
        case __FWImageCropViewOverlayEdgeRight:
            if (self.aspectRatioLockEnabled) {
                aspectHorizontal = YES;
                CGPoint scaleOrigin = (CGPoint){CGRectGetMinX(originFrame), CGRectGetMidY(originFrame)};
                frame.size.height = frame.size.width / aspectRatio;
                frame.origin.y = scaleOrigin.y - (frame.size.height * 0.5f);
                frame.size.width = originFrame.size.width + xDelta;
                frame.size.width = MIN(frame.size.width, contentFrame.size.height * aspectRatio);
            }
            else {
                CGFloat newWidth = originFrame.size.width + xDelta;
                CGFloat newHeight = originFrame.size.height;
                if (MIN(newHeight, newWidth) / MAX(newHeight, newWidth) >= (double)_minimumAspectRatio) {
                    frame.size.width = originFrame.size.width + xDelta;
                }
            }
            
            break;
        case __FWImageCropViewOverlayEdgeBottom:
            if (self.aspectRatioLockEnabled) {
                aspectVertical = YES;
                CGPoint scaleOrigin = (CGPoint){CGRectGetMidX(originFrame), CGRectGetMinY(originFrame)};
                frame.size.width = frame.size.height * aspectRatio;
                frame.origin.x = scaleOrigin.x - (frame.size.width * 0.5f);
                frame.size.height = originFrame.size.height + yDelta;
                frame.size.height = MIN(frame.size.height, contentFrame.size.width / aspectRatio);
            }
            else {
                CGFloat newWidth = originFrame.size.width;
                CGFloat newHeight = originFrame.size.height + yDelta;
                
                if (MIN(newHeight, newWidth) / MAX(newHeight, newWidth) >= (double)_minimumAspectRatio) {
                    frame.size.height = originFrame.size.height + yDelta;
                }
            }
            break;
        case __FWImageCropViewOverlayEdgeTop:
            if (self.aspectRatioLockEnabled) {
                aspectVertical = YES;
                yDelta = MAX(0,yDelta);
                CGPoint scaleOrigin = (CGPoint){CGRectGetMidX(originFrame), CGRectGetMaxY(originFrame)};
                frame.size.width = frame.size.height * aspectRatio;
                frame.origin.x = scaleOrigin.x - (frame.size.width * 0.5f);
                frame.origin.y    = originFrame.origin.y + yDelta;
                frame.size.height = originFrame.size.height - yDelta;
            }
            else {
                CGFloat newWidth = originFrame.size.width;
                CGFloat newHeight = originFrame.size.height - yDelta;
                
                if (MIN(newHeight, newWidth) / MAX(newHeight, newWidth) >= (double)_minimumAspectRatio) {
                    frame.origin.y    = originFrame.origin.y + yDelta;
                    frame.size.height = originFrame.size.height - yDelta;
                }
            }
            
            clampMinFromTop = YES;
            
            break;
        case __FWImageCropViewOverlayEdgeTopLeft:
            if (self.aspectRatioLockEnabled) {
                xDelta = MAX(xDelta, 0);
                yDelta = MAX(yDelta, 0);
                
                CGPoint distance;
                distance.x = 1.0f - (xDelta / CGRectGetWidth(originFrame));
                distance.y = 1.0f - (yDelta / CGRectGetHeight(originFrame));
                
                CGFloat scale = (distance.x + distance.y) * 0.5f;
                
                frame.size.width = ceilf(CGRectGetWidth(originFrame) * scale);
                frame.size.height = ceilf(CGRectGetHeight(originFrame) * scale);
                frame.origin.x = originFrame.origin.x + (CGRectGetWidth(originFrame) - frame.size.width);
                frame.origin.y = originFrame.origin.y + (CGRectGetHeight(originFrame) - frame.size.height);
                
                aspectVertical = YES;
                aspectHorizontal = YES;
            }
            else {
                CGFloat newWidth = originFrame.size.width - xDelta;
                CGFloat newHeight = originFrame.size.height - yDelta;
                
                if (MIN(newHeight, newWidth) / MAX(newHeight, newWidth) >= (double)_minimumAspectRatio) {
                    frame.origin.x   = originFrame.origin.x + xDelta;
                    frame.size.width = originFrame.size.width - xDelta;
                    frame.origin.y   = originFrame.origin.y + yDelta;
                    frame.size.height = originFrame.size.height - yDelta;
                }
            }
            
            clampMinFromTop = YES;
            clampMinFromLeft = YES;
            
            break;
        case __FWImageCropViewOverlayEdgeTopRight:
            if (self.aspectRatioLockEnabled) {
                xDelta = MIN(xDelta, 0);
                yDelta = MAX(yDelta, 0);
                
                CGPoint distance;
                distance.x = 1.0f - ((-xDelta) / CGRectGetWidth(originFrame));
                distance.y = 1.0f - ((yDelta) / CGRectGetHeight(originFrame));
                
                CGFloat scale = (distance.x + distance.y) * 0.5f;
                
                frame.size.width = ceilf(CGRectGetWidth(originFrame) * scale);
                frame.size.height = ceilf(CGRectGetHeight(originFrame) * scale);
                frame.origin.y = originFrame.origin.y + (CGRectGetHeight(originFrame) - frame.size.height);
                
                aspectVertical = YES;
                aspectHorizontal = YES;
            }
            else {
                CGFloat newWidth = originFrame.size.width + xDelta;
                CGFloat newHeight = originFrame.size.height - yDelta;
                
                if (MIN(newHeight, newWidth) / MAX(newHeight, newWidth) >= (double)_minimumAspectRatio) {
                    frame.size.width  = originFrame.size.width + xDelta;
                    frame.origin.y    = originFrame.origin.y + yDelta;
                    frame.size.height = originFrame.size.height - yDelta;
                }
            }
            
            clampMinFromTop = YES;
            
            break;
        case __FWImageCropViewOverlayEdgeBottomLeft:
            if (self.aspectRatioLockEnabled) {
                CGPoint distance;
                distance.x = 1.0f - (xDelta / CGRectGetWidth(originFrame));
                distance.y = 1.0f - (-yDelta / CGRectGetHeight(originFrame));
                
                CGFloat scale = (distance.x + distance.y) * 0.5f;
                
                frame.size.width = ceilf(CGRectGetWidth(originFrame) * scale);
                frame.size.height = ceilf(CGRectGetHeight(originFrame) * scale);
                frame.origin.x = CGRectGetMaxX(originFrame) - frame.size.width;
                
                aspectVertical = YES;
                aspectHorizontal = YES;
            }
            else {
                CGFloat newWidth = originFrame.size.width - xDelta;
                CGFloat newHeight = originFrame.size.height + yDelta;
                
                if (MIN(newHeight, newWidth) / MAX(newHeight, newWidth) >= (double)_minimumAspectRatio) {
                    frame.size.height = originFrame.size.height + yDelta;
                    frame.origin.x    = originFrame.origin.x + xDelta;
                    frame.size.width  = originFrame.size.width - xDelta;
                }
            }
            
            clampMinFromLeft = YES;
            
            break;
        case __FWImageCropViewOverlayEdgeBottomRight:
            if (self.aspectRatioLockEnabled) {
                
                CGPoint distance;
                distance.x = 1.0f - ((-1 * xDelta) / CGRectGetWidth(originFrame));
                distance.y = 1.0f - ((-1 * yDelta) / CGRectGetHeight(originFrame));
                
                CGFloat scale = (distance.x + distance.y) * 0.5f;
                
                frame.size.width = ceilf(CGRectGetWidth(originFrame) * scale);
                frame.size.height = ceilf(CGRectGetHeight(originFrame) * scale);
                
                aspectVertical = YES;
                aspectHorizontal = YES;
            }
            else {
                CGFloat newWidth = originFrame.size.width + xDelta;
                CGFloat newHeight = originFrame.size.height + yDelta;
                
                if (MIN(newHeight, newWidth) / MAX(newHeight, newWidth) >= (double)_minimumAspectRatio) {
                    frame.size.height = originFrame.size.height + yDelta;
                    frame.size.width = originFrame.size.width + xDelta;
                }
            }
            break;
        case __FWImageCropViewOverlayEdgeNone: break;
    }
    
    //The absolute max/min size the box may be in the bounds of the crop view
    CGSize minSize = (CGSize){k__FWImageCropViewMinimumBoxSize, k__FWImageCropViewMinimumBoxSize};
    CGSize maxSize = (CGSize){CGRectGetWidth(contentFrame), CGRectGetHeight(contentFrame)};
    
    //clamp the box to ensure it doesn't go beyond the bounds we've set
    if (self.aspectRatioLockEnabled && aspectHorizontal) {
        maxSize.height = contentFrame.size.width / aspectRatio;
        minSize.width = k__FWImageCropViewMinimumBoxSize * aspectRatio;
    }
        
    if (self.aspectRatioLockEnabled && aspectVertical) {
        maxSize.width = contentFrame.size.height * aspectRatio;
        minSize.height = k__FWImageCropViewMinimumBoxSize / aspectRatio;
    }

    // Clamp the width if it goes over
    if (clampMinFromLeft) {
        CGFloat maxWidth = CGRectGetMaxX(self.cropOriginFrame) - contentFrame.origin.x;
        frame.size.width = MIN(frame.size.width, maxWidth);
    }

    if (clampMinFromTop) {
        CGFloat maxHeight = CGRectGetMaxY(self.cropOriginFrame) - contentFrame.origin.y;
        frame.size.height = MIN(frame.size.height, maxHeight);
    }

    //Clamp the minimum size
    frame.size.width  = MAX(frame.size.width, minSize.width);
    frame.size.height = MAX(frame.size.height, minSize.height);
    
    //Clamp the maximum size
    frame.size.width  = MIN(frame.size.width, maxSize.width);
    frame.size.height = MIN(frame.size.height, maxSize.height);

    //Clamp the X position of the box to the interior of the cropping bounds
    frame.origin.x = MAX(frame.origin.x, CGRectGetMinX(contentFrame));
    frame.origin.x = MIN(frame.origin.x, CGRectGetMaxX(contentFrame) - minSize.width);

    //Clamp the Y postion of the box to the interior of the cropping bounds
    frame.origin.y = MAX(frame.origin.y, CGRectGetMinY(contentFrame));
    frame.origin.y = MIN(frame.origin.y, CGRectGetMaxY(contentFrame) - minSize.height);
    
    //Once the box is completely shrunk, clamp its ability to move
    if (clampMinFromLeft && frame.size.width <= minSize.width + FLT_EPSILON) {
        frame.origin.x = CGRectGetMaxX(originFrame) - minSize.width;
    }
    
    //Once the box is completely shrunk, clamp its ability to move
    if (clampMinFromTop && frame.size.height <= minSize.height + FLT_EPSILON) {
        frame.origin.y = CGRectGetMaxY(originFrame) - minSize.height;
    }
    
    self.cropBoxFrame = frame;
    
    [self checkForCanReset];
}

- (void)resetLayoutToDefaultAnimated:(BOOL)animated
{
    // If resetting the crop view includes resetting the aspect ratio,
    // reset it to zero here. But set the ivar directly since there's no point
    // in performing the relayout calculations right before a reset.
    if (self.hasAspectRatio && self.resetAspectRatioEnabled) {
        _aspectRatio = CGSizeZero;
    }
    
    if (animated == NO || self.angle != 0) {
        //Reset all of the rotation transforms
        _angle = 0;

        //Set the scroll to 1.0f to reset the transform scale
        self.scrollView.zoomScale = 1.0f;
        
        CGRect imageRect = (CGRect){CGPointZero, self.image.size};
        
        //Reset everything about the background container and image views
        self.backgroundImageView.transform = CGAffineTransformIdentity;
        self.backgroundContainerView.transform = CGAffineTransformIdentity;
        self.backgroundImageView.frame = imageRect;
        self.backgroundContainerView.frame = imageRect;

        //Reset the transform ans size of just the foreground image
        self.foregroundImageView.transform = CGAffineTransformIdentity;
        self.foregroundImageView.frame = imageRect;
        
        //Reset the layout
        [self layoutInitialImage];
        
        //Enable / Disable the reset button
        [self checkForCanReset];
        
        return;
    }

    //If we were in the middle of a reset timer, cancel it as we'll
    //manually perform a restoration animation here
    if (self.resetTimer) {
        [self cancelResetTimer];
        [self setEditing:NO resetCropBox:NO animated:NO];
    }
   
    [self setSimpleRenderMode:YES animated:NO];
    
    //Perform an animation of the image zooming back out to its original size
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:1.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self layoutInitialImage];
        } completion:^(BOOL complete) {
            [self setSimpleRenderMode:NO animated:YES];
        }];
    });
}

- (void)toggleTranslucencyViewVisible:(BOOL)visible
{
    [(UIVisualEffectView *)self.translucencyView setEffect:visible ? self.translucencyEffect : nil];
}

- (void)updateToImageCropFrame:(CGRect)imageCropframe
{
    //Convert the image crop frame's size from image space to the screen space
    CGFloat minimumSize = self.scrollView.minimumZoomScale;
    CGPoint scaledOffset = (CGPoint){imageCropframe.origin.x * minimumSize, imageCropframe.origin.y * minimumSize};
    CGSize scaledCropSize = (CGSize){imageCropframe.size.width * minimumSize, imageCropframe.size.height * minimumSize};
    
    // Work out the scale necessary to upscale the crop size to fit the content bounds of the crop bound
    CGRect bounds = self.contentBounds;
    CGFloat scale = MIN(bounds.size.width / scaledCropSize.width, bounds.size.height / scaledCropSize.height);
    
    // Zoom into the scroll view to the appropriate size
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale * scale;
    
    // Work out the size and offset of the upscaled crop box
    CGRect frame = CGRectZero;
    frame.size = (CGSize){scaledCropSize.width * scale, scaledCropSize.height * scale};
    
    //set the crop box
    CGRect cropBoxFrame = CGRectZero;
    cropBoxFrame.size = frame.size;
    cropBoxFrame.origin.x = CGRectGetMidX(bounds) - (frame.size.width * 0.5f);
    cropBoxFrame.origin.y = CGRectGetMidY(bounds) - (frame.size.height * 0.5f);
    self.cropBoxFrame = cropBoxFrame;
    
    frame.origin.x = (scaledOffset.x * scale) - self.scrollView.contentInset.left;
    frame.origin.y = (scaledOffset.y * scale) - self.scrollView.contentInset.top;
    self.scrollView.contentOffset = frame.origin;
}

#pragma mark - Gesture Recognizer -
- (void)gridPanGestureRecognized:(UIPanGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self startEditing];
        self.panOriginPoint = point;
        self.cropOriginFrame = self.cropBoxFrame;
        self.tappedEdge = [self cropEdgeForPoint:self.panOriginPoint];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self startResetTimer];
    }
    
    [self updateCropBoxFrameWithGesturePoint:point];
}

- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
        [self.gridOverlayView setGridHidden:NO animated:YES];
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
        [self.gridOverlayView setGridHidden:YES animated:YES];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer != self.gridPanGestureRecognizer)
        return YES;
    
    CGPoint tapPoint = [gestureRecognizer locationInView:self];
    
    CGRect frame = self.gridOverlayView.frame;
    CGRect innerFrame = CGRectInset(frame, 22.0f, 22.0f);
    CGRect outerFrame = CGRectInset(frame, -22.0f, -22.0f);
    
    if (CGRectContainsPoint(innerFrame, tapPoint) || !CGRectContainsPoint(outerFrame, tapPoint))
        return NO;
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.gridPanGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        return NO;
    }
    return YES;
}

#pragma mark - Timer -
- (void)startResetTimer
{
    if (self.resetTimer)
        return;
    
    self.resetTimer = [NSTimer scheduledTimerWithTimeInterval:self.cropAdjustingDelay target:self selector:@selector(timerTriggered) userInfo:nil repeats:NO];
}

- (void)timerTriggered
{
    [self setEditing:NO resetCropBox:YES animated:YES];
    [self.resetTimer invalidate];
    self.resetTimer = nil;
}

- (void)cancelResetTimer
{
    [self.resetTimer invalidate];
    self.resetTimer = nil;
}

- (__FWImageCropViewOverlayEdge)cropEdgeForPoint:(CGPoint)point
{
    CGRect frame = self.cropBoxFrame;
    
    //account for padding around the box
    frame = CGRectInset(frame, -32.0f, -32.0f);
    
    //Make sure the corners take priority
    CGRect topLeftRect = (CGRect){frame.origin, {64,64}};
    if (CGRectContainsPoint(topLeftRect, point))
        return __FWImageCropViewOverlayEdgeTopLeft;
    
    CGRect topRightRect = topLeftRect;
    topRightRect.origin.x = CGRectGetMaxX(frame) - 64.0f;
    if (CGRectContainsPoint(topRightRect, point))
        return __FWImageCropViewOverlayEdgeTopRight;
    
    CGRect bottomLeftRect = topLeftRect;
    bottomLeftRect.origin.y = CGRectGetMaxY(frame) - 64.0f;
    if (CGRectContainsPoint(bottomLeftRect, point))
        return __FWImageCropViewOverlayEdgeBottomLeft;
    
    CGRect bottomRightRect = topRightRect;
    bottomRightRect.origin.y = bottomLeftRect.origin.y;
    if (CGRectContainsPoint(bottomRightRect, point))
        return __FWImageCropViewOverlayEdgeBottomRight;
    
    //Check for edges
    CGRect topRect = (CGRect){frame.origin, {CGRectGetWidth(frame), 64.0f}};
    if (CGRectContainsPoint(topRect, point))
        return __FWImageCropViewOverlayEdgeTop;
    
    CGRect bottomRect = topRect;
    bottomRect.origin.y = CGRectGetMaxY(frame) - 64.0f;
    if (CGRectContainsPoint(bottomRect, point))
        return __FWImageCropViewOverlayEdgeBottom;
    
    CGRect leftRect = (CGRect){frame.origin, {64.0f, CGRectGetHeight(frame)}};
    if (CGRectContainsPoint(leftRect, point))
        return __FWImageCropViewOverlayEdgeLeft;
    
    CGRect rightRect = leftRect;
    rightRect.origin.x = CGRectGetMaxX(frame) - 64.0f;
    if (CGRectContainsPoint(rightRect, point))
        return __FWImageCropViewOverlayEdgeRight;
    
    return __FWImageCropViewOverlayEdgeNone;
}

#pragma mark - Scroll View Delegate -

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { return self.backgroundContainerView; }
- (void)scrollViewDidScroll:(UIScrollView *)scrollView            { [self matchForegroundToBackground]; }

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self startEditing];
    self.canBeReset = YES;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self startEditing];
    self.canBeReset = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self startResetTimer];
    [self checkForCanReset];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [self startResetTimer];
    [self checkForCanReset];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (scrollView.isTracking) {
        self.cropBoxLastEditedZoomScale = scrollView.zoomScale;
        self.cropBoxLastEditedMinZoomScale = scrollView.minimumZoomScale;
    }
    
    [self matchForegroundToBackground];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        [self startResetTimer];
}

#pragma mark - Accessors -

- (void)setCropBoxResizeEnabled:(BOOL)panResizeEnabled {
    _cropBoxResizeEnabled = panResizeEnabled;
    self.gridPanGestureRecognizer.enabled = _cropBoxResizeEnabled;
}

- (void)setCropBoxFrame:(CGRect)cropBoxFrame
{
    if (CGRectEqualToRect(cropBoxFrame, _cropBoxFrame)) {
        return;
    }
    
    // Upon init, sometimes the box size is still 0 (or NaN), which can result in CALayer issues
    CGSize frameSize = cropBoxFrame.size;
    if (frameSize.width < FLT_EPSILON || frameSize.height < FLT_EPSILON) { return; }
    if (isnan(frameSize.width) || isnan(frameSize.height)) { return; }

    //clamp the cropping region to the inset boundaries of the screen
    CGRect contentFrame = self.contentBounds;
    CGFloat xOrigin = ceilf(contentFrame.origin.x);
    CGFloat xDelta = cropBoxFrame.origin.x - xOrigin;
    cropBoxFrame.origin.x = floorf(MAX(cropBoxFrame.origin.x, xOrigin));
    if (xDelta < -FLT_EPSILON) //If we clamp the x value, ensure we compensate for the subsequent delta generated in the width (Or else, the box will keep growing)
        cropBoxFrame.size.width += xDelta;
    
    CGFloat yOrigin = ceilf(contentFrame.origin.y);
    CGFloat yDelta = cropBoxFrame.origin.y - yOrigin;
    cropBoxFrame.origin.y = floorf(MAX(cropBoxFrame.origin.y, yOrigin));
    if (yDelta < -FLT_EPSILON)
        cropBoxFrame.size.height += yDelta;
    
    //given the clamped X/Y values, make sure we can't extend the crop box beyond the edge of the screen in the current state
    CGFloat maxWidth = (contentFrame.size.width + contentFrame.origin.x) - cropBoxFrame.origin.x;
    cropBoxFrame.size.width = floorf(MIN(cropBoxFrame.size.width, maxWidth));
    
    CGFloat maxHeight = (contentFrame.size.height + contentFrame.origin.y) - cropBoxFrame.origin.y;
    cropBoxFrame.size.height = floorf(MIN(cropBoxFrame.size.height, maxHeight));
    
    //Make sure we can't make the crop box too small
    cropBoxFrame.size.width  = MAX(cropBoxFrame.size.width, k__FWImageCropViewMinimumBoxSize);
    cropBoxFrame.size.height = MAX(cropBoxFrame.size.height, k__FWImageCropViewMinimumBoxSize);
    
    _cropBoxFrame = cropBoxFrame;
    
    self.foregroundContainerView.frame = _cropBoxFrame; //set the clipping view to match the new rect
    self.gridOverlayView.frame = _cropBoxFrame; //set the new overlay view to match the same region
    
    // If the mask layer is present, adjust its transform to fit the new container view size
    if (self.circularMaskLayer) {
        CGFloat scale = _cropBoxFrame.size.width / k__FWImageCropViewCircularPathRadius;
        self.circularMaskLayer.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, 1.0f);
    }
    
    //reset the scroll view insets to match the region of the new crop rect
    self.scrollView.contentInset = (UIEdgeInsets){CGRectGetMinY(_cropBoxFrame),
                                                    CGRectGetMinX(_cropBoxFrame),
                                                    CGRectGetMaxY(self.bounds) - CGRectGetMaxY(_cropBoxFrame),
                                                    CGRectGetMaxX(self.bounds) - CGRectGetMaxX(_cropBoxFrame)};

    //if necessary, work out the new minimum size of the scroll view so it fills the crop box
    CGSize imageSize = self.backgroundContainerView.bounds.size;
    CGFloat scale = MAX(cropBoxFrame.size.height/imageSize.height, cropBoxFrame.size.width/imageSize.width);
    self.scrollView.minimumZoomScale = scale;
    
    //make sure content isn't smaller than the crop box
    CGSize size = self.scrollView.contentSize;
    size.width = floorf(size.width);
    size.height = floorf(size.height);
    self.scrollView.contentSize = size;
    
    //IMPORTANT: Force the scroll view to update its content after changing the zoom scale
    self.scrollView.zoomScale = self.scrollView.zoomScale;
    
    [self matchForegroundToBackground]; //re-align the background content to match
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing resetCropBox:NO animated:NO];
}

- (void)setSimpleRenderMode:(BOOL)simpleMode
{
    [self setSimpleRenderMode:simpleMode animated:NO];
}

- (BOOL)cropBoxAspectRatioIsPortrait
{
    CGRect cropFrame = self.cropBoxFrame;
    return CGRectGetWidth(cropFrame) < CGRectGetHeight(cropFrame);
}

- (CGRect)imageCropFrame
{
    CGSize imageSize = self.imageSize;
    CGSize contentSize = self.scrollView.contentSize;
    CGRect cropBoxFrame = self.cropBoxFrame;
    CGPoint contentOffset = self.scrollView.contentOffset;
    UIEdgeInsets edgeInsets = self.scrollView.contentInset;
    CGFloat scaleWidth = imageSize.width / contentSize.width;
    CGFloat scaleHeight = imageSize.height / contentSize.height;
    BOOL isSquare = floor(cropBoxFrame.size.width) == floor(cropBoxFrame.size.height);
    
    CGRect frame = CGRectZero;
    frame.origin.x = floorf((floorf(contentOffset.x) + edgeInsets.left) * (imageSize.width / contentSize.width));
    frame.origin.x = MAX(0, frame.origin.x);
    frame.origin.y = floorf((floorf(contentOffset.y) + edgeInsets.top) * (imageSize.height / contentSize.height));
    frame.origin.y = MAX(0, frame.origin.y);
    frame.size.width = ceilf(cropBoxFrame.size.width * (isSquare ? MIN(scaleWidth, scaleHeight) : scaleWidth));
    frame.size.width = MIN(imageSize.width, frame.size.width);
    frame.size.height = isSquare ? frame.size.width : ceilf(cropBoxFrame.size.height * scaleHeight);
    frame.size.height = MIN(imageSize.height, frame.size.height);
    return frame;
}

- (void)setImageCropFrame:(CGRect)imageCropFrame
{
    if (!self.initialSetupPerformed) {
        self.restoreImageCropFrame = imageCropFrame;
        return;
    }
    
    [self updateToImageCropFrame:imageCropFrame];
}

- (void)setCroppingViewsHidden:(BOOL)hidden
{
    [self setCroppingViewsHidden:hidden animated:NO];
}

- (void)setCroppingViewsHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (_croppingViewsHidden == hidden)
        return;
        
    _croppingViewsHidden = hidden;
    
    CGFloat alpha = hidden ? 0.0f : 1.0f;
    
    if (animated == NO) {
        self.backgroundImageView.alpha = alpha;
        self.foregroundContainerView.alpha = alpha;
        self.gridOverlayView.alpha = alpha;

        [self toggleTranslucencyViewVisible:!hidden];
        
        return;
    }
    
    self.foregroundContainerView.alpha = alpha;
    self.backgroundImageView.alpha = alpha;
    
    [UIView animateWithDuration:0.4f animations:^{
        [self toggleTranslucencyViewVisible:!hidden];
        self.gridOverlayView.alpha = alpha;
    }];
}

- (void)setBackgroundImageViewHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (animated == NO) {
        self.backgroundImageView.hidden = hidden;
        return;
    }
    
    CGFloat beforeAlpha = hidden ? 1.0f : 0.0f;
    CGFloat toAlpha = hidden ? 0.0f : 1.0f;
    
    self.backgroundImageView.hidden = NO;
    self.backgroundImageView.alpha = beforeAlpha;
    [UIView animateWithDuration:0.5f animations:^{
        self.backgroundImageView.alpha = toAlpha;
    }completion:^(BOOL complete) {
        if (hidden) {
            self.backgroundImageView.hidden = YES;
        }
    }];
}

-(void)setAlwaysShowCroppingGrid:(BOOL)alwaysShowCroppingGrid
{
    if (alwaysShowCroppingGrid == _alwaysShowCroppingGrid) { return; }
    _alwaysShowCroppingGrid = alwaysShowCroppingGrid;
    [self.gridOverlayView setGridHidden:!_alwaysShowCroppingGrid animated:YES];
}

-(void)setTranslucencyAlwaysHidden:(BOOL)translucencyAlwaysHidden
{
    if (_translucencyAlwaysHidden == translucencyAlwaysHidden) { return; }
    _translucencyAlwaysHidden = translucencyAlwaysHidden;
    self.translucencyView.hidden = _translucencyAlwaysHidden;
}

- (void)setGridOverlayHidden:(BOOL)gridOverlayHidden
{
    [self setGridOverlayHidden:_gridOverlayHidden animated:NO];
}

- (void)setGridOverlayHidden:(BOOL)gridOverlayHidden animated:(BOOL)animated
{
    _gridOverlayHidden = gridOverlayHidden;
    self.gridOverlayView.alpha = gridOverlayHidden ? 1.0f : 0.0f;
    
    [UIView animateWithDuration:0.4f animations:^{
        self.gridOverlayView.alpha = gridOverlayHidden ? 0.0f : 1.0f;
    }];
}

- (CGRect)imageViewFrame
{
    CGRect frame = CGRectZero;
    frame.origin.x = -self.scrollView.contentOffset.x;
    frame.origin.y = -self.scrollView.contentOffset.y;
    frame.size = self.scrollView.contentSize;
    return frame;
}

- (void)setCanBeReset:(BOOL)canReset
{
    if (canReset == _canBeReset) {
        return;
    }
    
    _canBeReset = canReset;
    
    if (canReset) {
        if ([self.delegate respondsToSelector:@selector(cropViewDidBecomeResettable:)])
            [self.delegate cropViewDidBecomeResettable:self];
    }
    else  {
        if ([self.delegate respondsToSelector:@selector(cropViewDidBecomeNonResettable:)])
            [self.delegate cropViewDidBecomeNonResettable:self];
    }
}

- (void)setAngle:(NSInteger)angle
{
    //The initial layout would not have been performed yet.
    //Save the value and it will be applied when it has
    NSInteger newAngle = angle;
    if (angle % 90 != 0) {
        newAngle = 0;
    }
    
    if (!self.initialSetupPerformed) {
        self.restoreAngle = newAngle;
        return;
    }
    
    // Negative values are allowed, so rotate clockwise or counter clockwise depending
    // on direction
    if (newAngle >= 0) {
        while (labs(self.angle) != labs(newAngle)) {
            [self rotateImageNinetyDegreesAnimated:NO clockwise:YES];
        }
    }
    else {
        while (-labs(self.angle) != -labs(newAngle)) {
            [self rotateImageNinetyDegreesAnimated:NO clockwise:NO];
        }
    }
}

#pragma mark - Editing Mode -
- (void)startEditing
{
    [self cancelResetTimer];
    [self setEditing:YES resetCropBox:NO animated:YES];
}

- (void)setEditing:(BOOL)editing resetCropBox:(BOOL)resetCropbox animated:(BOOL)animated
{
    if (editing == _editing)
        return;
    
    _editing = editing;

    // Toggle the visiblity of the gridlines when not editing
    BOOL hidden = !_editing;
    if (self.alwaysShowCroppingGrid) { hidden = NO; } // Override this if the user requires
    [self.gridOverlayView setGridHidden:hidden animated:animated];
    
    if (resetCropbox) {
        [self moveCroppedContentToCenterAnimated:animated];
        [self captureStateForImageRotation];
        self.cropBoxLastEditedAngle = self.angle;
    }
    
    if (animated == NO) {
        [self toggleTranslucencyViewVisible:!editing];
        return;
    }
    
    CGFloat duration = editing ? 0.05f : 0.35f;
    CGFloat delay = editing? 0.0f : 0.35f;
    
    if (self.croppingStyle == __FWImageCropCroppingStyleCircular) {
        delay = 0.0f;
    }
    
    [UIView animateKeyframesWithDuration:duration delay:delay options:0 animations:^{
        [self toggleTranslucencyViewVisible:!editing];
    } completion:nil];
}

- (void)moveCroppedContentToCenterAnimated:(BOOL)animated
{
    if (self.internalLayoutDisabled)
        return;
    
    CGRect contentRect = self.contentBounds;
    CGRect cropFrame = self.cropBoxFrame;
    
    // Ensure we only proceed after the crop frame has been setup for the first time
    if (cropFrame.size.width < FLT_EPSILON || cropFrame.size.height < FLT_EPSILON) {
        return;
    }
    
    //The scale we need to scale up the crop box to fit full screen
    CGFloat scale = MIN(CGRectGetWidth(contentRect)/CGRectGetWidth(cropFrame), CGRectGetHeight(contentRect)/CGRectGetHeight(cropFrame));
    
    CGPoint focusPoint = (CGPoint){CGRectGetMidX(cropFrame), CGRectGetMidY(cropFrame)};
    CGPoint midPoint = (CGPoint){CGRectGetMidX(contentRect), CGRectGetMidY(contentRect)};
    
    cropFrame.size.width = ceilf(cropFrame.size.width * scale);
    cropFrame.size.height = ceilf(cropFrame.size.height * scale);
    cropFrame.origin.x = contentRect.origin.x + ceilf((contentRect.size.width - cropFrame.size.width) * 0.5f);
    cropFrame.origin.y = contentRect.origin.y + ceilf((contentRect.size.height - cropFrame.size.height) * 0.5f);
    
    //Work out the point on the scroll content that the focusPoint is aiming at
    CGPoint contentTargetPoint = CGPointZero;
    contentTargetPoint.x = ((focusPoint.x + self.scrollView.contentOffset.x) * scale);
    contentTargetPoint.y = ((focusPoint.y + self.scrollView.contentOffset.y) * scale);
    
    //Work out where the crop box is focusing, so we can re-align to center that point
    __block CGPoint offset = CGPointZero;
    offset.x = -midPoint.x + contentTargetPoint.x;
    offset.y = -midPoint.y + contentTargetPoint.y;
    
    //clamp the content so it doesn't create any seams around the grid
    offset.x = MAX(-cropFrame.origin.x, offset.x);
    offset.y = MAX(-cropFrame.origin.y, offset.y);
    
    __weak typeof(self) weakSelf = self;
    void (^translateBlock)(void) = ^{
        typeof(self) strongSelf = weakSelf;
        
        // Setting these scroll view properties will trigger
        // the foreground matching method via their delegates,
        // multiple times inside the same animation block, resulting
        // in glitchy animations.
        //
        // Disable matching for now, and explicitly update at the end.
        strongSelf.disableForgroundMatching = YES;
        {
            // Slight hack. This method needs to be called during `[UIViewController viewDidLayoutSubviews]`
            // in order for the crop view to resize itself during iPad split screen events.
            // On the first run, even though scale is exactly 1.0f, performing this multiplication introduces
            // a floating point noise that zooms the image in by about 5 pixels. This fixes that issue.
            if (scale < 1.0f - FLT_EPSILON || scale > 1.0f + FLT_EPSILON) {
                strongSelf.scrollView.zoomScale *= scale;
                strongSelf.scrollView.zoomScale = MIN(strongSelf.scrollView.maximumZoomScale, strongSelf.scrollView.zoomScale);
            }

            // If it turns out the zoom operation would have exceeded the minizum zoom scale, don't apply
            // the content offset
            if (strongSelf.scrollView.zoomScale < strongSelf.scrollView.maximumZoomScale - FLT_EPSILON) {
                offset.x = MIN(-CGRectGetMaxX(cropFrame)+strongSelf.scrollView.contentSize.width, offset.x);
                offset.y = MIN(-CGRectGetMaxY(cropFrame)+strongSelf.scrollView.contentSize.height, offset.y);
                strongSelf.scrollView.contentOffset = offset;
            }
            
            strongSelf.cropBoxFrame = cropFrame;
        }
        strongSelf.disableForgroundMatching = NO;
        
        //Explicitly update the matching at the end of the calculations
        [strongSelf matchForegroundToBackground];
    };
    
    if (!animated) {
        translateBlock();
        return;
    }

    [self matchForegroundToBackground];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:1.0f
              initialSpringVelocity:1.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:translateBlock
                         completion:nil];
    });
}

- (void)setSimpleRenderMode:(BOOL)simpleMode animated:(BOOL)animated
{
    if (simpleMode == _simpleRenderMode)
        return;
    
    _simpleRenderMode = simpleMode;
    
    self.editing = NO;
    
    if (animated == NO) {
        [self toggleTranslucencyViewVisible:!simpleMode];
        
        return;
    }
    
    [UIView animateWithDuration:0.25f animations:^{
        [self toggleTranslucencyViewVisible:!simpleMode];
    }];
}

- (void)setAspectRatio:(CGSize)aspectRatio
{
    [self setAspectRatio:aspectRatio animated:NO];
}

- (void)setAspectRatio:(CGSize)aspectRatio animated:(BOOL)animated
{
    _aspectRatio = aspectRatio;
    
    // Will be executed automatically when added to a super view
    if (!self.initialSetupPerformed) {
        return;
    }
    
    // Passing in an empty size will revert back to the image aspect ratio
    if (aspectRatio.width < FLT_EPSILON && aspectRatio.height < FLT_EPSILON) {
        aspectRatio = (CGSize){self.imageSize.width, self.imageSize.height};
    }

    CGRect boundsFrame = self.contentBounds;
    CGRect cropBoxFrame = self.cropBoxFrame;
    CGPoint offset = self.scrollView.contentOffset;
    
    BOOL cropBoxIsPortrait = NO;
    if ((NSInteger)aspectRatio.width == 1 && (NSInteger)aspectRatio.height == 1)
        cropBoxIsPortrait = self.image.size.width > self.image.size.height;
    else
        cropBoxIsPortrait = aspectRatio.width < aspectRatio.height;

    BOOL zoomOut = NO;
    if (cropBoxIsPortrait) {
        CGFloat newWidth = floorf(cropBoxFrame.size.height * (aspectRatio.width/aspectRatio.height));
        CGFloat delta = cropBoxFrame.size.width - newWidth;
        cropBoxFrame.size.width = newWidth;
        offset.x += (delta * 0.5f);

        if (delta < FLT_EPSILON) {
            cropBoxFrame.origin.x = self.contentBounds.origin.x; //set to 0 to avoid accidental clamping by the crop frame sanitizer
        }

        // If the aspect ratio causes the new width to extend
        // beyond the content width, we'll need to zoom the image out
        CGFloat boundsWidth = CGRectGetWidth(boundsFrame);
        if (newWidth > boundsWidth) {
            CGFloat scale = boundsWidth / newWidth;

            // Scale the new height
            CGFloat newHeight = cropBoxFrame.size.height * scale;
            delta = cropBoxFrame.size.height - newHeight;
            cropBoxFrame.size.height = newHeight;

            // Offset the Y position so it stays in the middle
            offset.y += (delta * 0.5f);

            // Clamp the width to the bounds width
            cropBoxFrame.size.width = boundsWidth;
            zoomOut = YES;
        }
    }
    else {
        CGFloat newHeight = floorf(cropBoxFrame.size.width * (aspectRatio.height/aspectRatio.width));
        CGFloat delta = cropBoxFrame.size.height - newHeight;
        cropBoxFrame.size.height = newHeight;
        offset.y += (delta * 0.5f);

        if (delta < FLT_EPSILON) {
            cropBoxFrame.origin.y = self.contentBounds.origin.y;
        }

        // If the aspect ratio causes the new height to extend
        // beyond the content width, we'll need to zoom the image out
        CGFloat boundsHeight = CGRectGetHeight(boundsFrame);
        if (newHeight > boundsHeight) {
            CGFloat scale = boundsHeight / newHeight;

            // Scale the new width
            CGFloat newWidth = cropBoxFrame.size.width * scale;
            delta = cropBoxFrame.size.width - newWidth;
            cropBoxFrame.size.width = newWidth;

            // Offset the Y position so it stays in the middle
            offset.x += (delta * 0.5f);

            // Clamp the width to the bounds height
            cropBoxFrame.size.height = boundsHeight;
            zoomOut = YES;
        }
    }
    
    self.cropBoxLastEditedSize = cropBoxFrame.size;
    self.cropBoxLastEditedAngle = self.angle;
    
    void (^translateBlock)(void) = ^{
        self.scrollView.contentOffset = offset;
        self.cropBoxFrame = cropBoxFrame;
        
        if (zoomOut) {
            self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        }
            
        [self moveCroppedContentToCenterAnimated:NO];
        [self checkForCanReset];
    };
    
    if (animated == NO) {
        translateBlock();
        return;
    }
    
    [UIView animateWithDuration:0.5f
                          delay:0.0
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.7f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:translateBlock
                     completion:nil];
}

- (void)rotateImageNinetyDegreesAnimated:(BOOL)animated
{
    [self rotateImageNinetyDegreesAnimated:animated clockwise:NO];
}

- (void)rotateImageNinetyDegreesAnimated:(BOOL)animated clockwise:(BOOL)clockwise
{
    //Only allow one rotation animation at a time
    if (self.rotateAnimationInProgress)
        return;
    
    //Cancel any pending resizing timers
    if (self.resetTimer) {
        [self cancelResetTimer];
        [self setEditing:NO resetCropBox:YES animated:NO];
        
        self.cropBoxLastEditedAngle = self.angle;
        [self captureStateForImageRotation];
    }
    
    //Work out the new angle, and wrap around once we exceed 360s
    NSInteger newAngle = self.angle;
    newAngle = clockwise ? newAngle + 90 : newAngle - 90;
    if (newAngle <= -360 || newAngle >= 360) {
        newAngle = 0;
    }

    _angle = newAngle;
    
    //Convert the new angle to radians
    CGFloat angleInRadians = 0.0f;
    switch (newAngle) {
        case 90:    angleInRadians = M_PI_2;            break;
        case -90:   angleInRadians = -M_PI_2;           break;
        case 180:   angleInRadians = M_PI;              break;
        case -180:  angleInRadians = -M_PI;             break;
        case 270:   angleInRadians = (M_PI + M_PI_2);   break;
        case -270:  angleInRadians = -(M_PI + M_PI_2);  break;
        default:                                        break;
    }
    
    // Set up the transformation matrix for the rotation
    CGAffineTransform rotation = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
    
    //Work out how much we'll need to scale everything to fit to the new rotation
    CGRect contentBounds = self.contentBounds;
    CGRect cropBoxFrame = self.cropBoxFrame;
    CGFloat scale = MIN(contentBounds.size.width / cropBoxFrame.size.height, contentBounds.size.height / cropBoxFrame.size.width);
    
    //Work out which section of the image we're currently focusing at
    CGPoint cropMidPoint = (CGPoint){CGRectGetMidX(cropBoxFrame), CGRectGetMidY(cropBoxFrame)};
    CGPoint cropTargetPoint = (CGPoint){cropMidPoint.x + self.scrollView.contentOffset.x, cropMidPoint.y + self.scrollView.contentOffset.y};
    
    //Work out the dimensions of the crop box when rotated
    CGRect newCropFrame = CGRectZero;
    if (labs(self.angle) == labs(self.cropBoxLastEditedAngle) || (labs(self.angle)*-1) == ((labs(self.cropBoxLastEditedAngle) - 180) % 360)) {
        newCropFrame.size = self.cropBoxLastEditedSize;
        
        self.scrollView.minimumZoomScale = self.cropBoxLastEditedMinZoomScale;
        self.scrollView.zoomScale = self.cropBoxLastEditedZoomScale;
    }
    else {
        newCropFrame.size = (CGSize){floorf(self.cropBoxFrame.size.height * scale), floorf(self.cropBoxFrame.size.width * scale)};
        
        //Re-adjust the scrolling dimensions of the scroll view to match the new size
        self.scrollView.minimumZoomScale *= scale;
        self.scrollView.zoomScale *= scale;
    }
    
    newCropFrame.origin.x = floorf(CGRectGetMidX(contentBounds) - (newCropFrame.size.width * 0.5f));
    newCropFrame.origin.y = floorf(CGRectGetMidY(contentBounds) - (newCropFrame.size.height * 0.5f));
    
    //If we're animated, generate a snapshot view that we'll animate in place of the real view
    UIView *snapshotView = nil;
    if (animated) {
        snapshotView = [self.foregroundContainerView snapshotViewAfterScreenUpdates:NO];
        self.rotateAnimationInProgress = YES;
    }
    
    //Rotate the background image view, inside its container view
    self.backgroundImageView.transform = rotation;
    
    //Flip the width/height of the container view so it matches the rotated image view's size
    CGSize containerSize = self.backgroundContainerView.frame.size;
    self.backgroundContainerView.frame = (CGRect){CGPointZero, {containerSize.height, containerSize.width}};
    self.backgroundImageView.frame = (CGRect){CGPointZero, self.backgroundImageView.frame.size};

    //Rotate the foreground image view to match
    self.foregroundContainerView.transform = CGAffineTransformIdentity;
    self.foregroundImageView.transform = rotation;
    
    //Flip the content size of the scroll view to match the rotated bounds
    self.scrollView.contentSize = self.backgroundContainerView.frame.size;
    
    //assign the new crop box frame and re-adjust the content to fill it
    self.cropBoxFrame = newCropFrame;
    [self moveCroppedContentToCenterAnimated:NO];
    newCropFrame = self.cropBoxFrame;
    
    //work out how to line up out point of interest into the middle of the crop box
    cropTargetPoint.x *= scale;
    cropTargetPoint.y *= scale;
    
    //swap the target dimensions to match a 90 degree rotation (clockwise or counterclockwise)
    CGFloat swap = cropTargetPoint.x;
    if (clockwise) {
        cropTargetPoint.x = self.scrollView.contentSize.width - cropTargetPoint.y;
        cropTargetPoint.y = swap;
    } else {
        cropTargetPoint.x = cropTargetPoint.y;
        cropTargetPoint.y = self.scrollView.contentSize.height - swap;
    }
    
    //reapply the translated scroll offset to the scroll view
    CGPoint midPoint = {CGRectGetMidX(newCropFrame), CGRectGetMidY(newCropFrame)};
    CGPoint offset = CGPointZero;
    offset.x = floorf(-midPoint.x + cropTargetPoint.x);
    offset.y = floorf(-midPoint.y + cropTargetPoint.y);
    offset.x = MAX(-self.scrollView.contentInset.left, offset.x);
    offset.y = MAX(-self.scrollView.contentInset.top, offset.y);
    offset.x = MIN(self.scrollView.contentSize.width - (newCropFrame.size.width - self.scrollView.contentInset.right), offset.x);
    offset.y = MIN(self.scrollView.contentSize.height - (newCropFrame.size.height - self.scrollView.contentInset.bottom), offset.y);
    
    //if the scroll view's new scale is 1 and the new offset is equal to the old, will not trigger the delegate 'scrollViewDidScroll:'
    //so we should call the method manually to update the foregroundImageView's frame
    if (offset.x == self.scrollView.contentOffset.x && offset.y == self.scrollView.contentOffset.y && scale == 1) {
        [self matchForegroundToBackground];
    }
    self.scrollView.contentOffset = offset;
    
    //If we're animated, play an animation of the snapshot view rotating,
    //then fade it out over the live content
    if (animated) {
        snapshotView.center = (CGPoint){CGRectGetMidX(contentBounds), CGRectGetMidY(contentBounds)};
        [self addSubview:snapshotView];
        
        self.backgroundContainerView.hidden = YES;
        self.foregroundContainerView.hidden = YES;
        self.translucencyView.hidden = YES;
        self.gridOverlayView.hidden = YES;
        
        [UIView animateWithDuration:0.45f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.8f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, clockwise ? M_PI_2 : -M_PI_2);
            transform = CGAffineTransformScale(transform, scale, scale);
            snapshotView.transform = transform;
        } completion:^(BOOL complete) {
            self.backgroundContainerView.hidden = NO;
            self.foregroundContainerView.hidden = NO;
            self.translucencyView.hidden = self.translucencyAlwaysHidden;
            self.gridOverlayView.hidden = NO;
            
            self.backgroundContainerView.alpha = 0.0f;
            self.gridOverlayView.alpha = 0.0f;
            
            self.translucencyView.alpha = 1.0f;
            
            [UIView animateWithDuration:0.45f animations:^{
                snapshotView.alpha = 0.0f;
                self.backgroundContainerView.alpha = 1.0f;
                self.gridOverlayView.alpha = 1.0f;
            } completion:^(BOOL complete) {
                self.rotateAnimationInProgress = NO;
                [snapshotView removeFromSuperview];
                
                // If the aspect ratio lock is not enabled, allow a swap
                // If the aspect ratio lock is on, allow a aspect ratio swap
                // only if the allowDimensionSwap option is specified.
                BOOL aspectRatioCanSwapDimensions = !self.aspectRatioLockEnabled ||
                (self.aspectRatioLockEnabled && self.aspectRatioLockDimensionSwapEnabled);
                
                if (!aspectRatioCanSwapDimensions) {
                    //This will animate the aspect ratio back to the desired locked ratio after the image is rotated.
                    [self setAspectRatio:self.aspectRatio animated:animated];
                }
            }];
        }];
    }
    
    [self checkForCanReset];
}

- (void)captureStateForImageRotation
{
    self.cropBoxLastEditedSize = self.cropBoxFrame.size;
    self.cropBoxLastEditedZoomScale = self.scrollView.zoomScale;
    self.cropBoxLastEditedMinZoomScale = self.scrollView.minimumZoomScale;
}

#pragma mark - Resettable State -
- (void)checkForCanReset
{
    BOOL canReset = NO;
    
    if (self.angle != 0) { //Image has been rotated
        canReset = YES;
    }
    else if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale + FLT_EPSILON) { //image has been zoomed in
        canReset = YES;
    }
    else if ((NSInteger)floorf(self.cropBoxFrame.size.width) != (NSInteger)floorf(self.originalCropBoxSize.width) ||
             (NSInteger)floorf(self.cropBoxFrame.size.height) != (NSInteger)floorf(self.originalCropBoxSize.height))
    { //crop box has been changed
        canReset = YES;
    }
    else if ((NSInteger)floorf(self.scrollView.contentOffset.x) != (NSInteger)floorf(self.originalContentOffset.x) ||
             (NSInteger)floorf(self.scrollView.contentOffset.y) != (NSInteger)floorf(self.originalContentOffset.y))
    {
        canReset = YES;
    }

    self.canBeReset = canReset;
}

#pragma mark - Convienience Methods -
- (CGRect)contentBounds
{
    CGRect contentRect = CGRectZero;
    contentRect.origin.x = self.cropViewPadding + self.cropRegionInsets.left;
    contentRect.origin.y = self.cropViewPadding + self.cropRegionInsets.top;
    contentRect.size.width = CGRectGetWidth(self.bounds) - ((self.cropViewPadding * 2) + self.cropRegionInsets.left + self.cropRegionInsets.right);
    contentRect.size.height = CGRectGetHeight(self.bounds) - ((self.cropViewPadding * 2) + self.cropRegionInsets.top + self.cropRegionInsets.bottom);
    return contentRect;
}

- (CGSize)imageSize
{
    if (self.angle == -90 || self.angle == -270 || self.angle == 90 || self.angle == 270)
        return (CGSize){self.image.size.height, self.image.size.width};

    return (CGSize){self.image.size.width, self.image.size.height};
}

- (BOOL)hasAspectRatio
{
    return (self.aspectRatio.width > FLT_EPSILON && self.aspectRatio.height > FLT_EPSILON);
}

@end
