/*!
 @header     FWCropViewController.h
 @indexgroup FWFramework
 @brief      FWCropViewController
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/6/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The shape of the cropping region of this crop view controller
 */
typedef NS_ENUM(NSInteger, FWCropViewCroppingStyle) {
    FWCropViewCroppingStyleDefault,     // The regular, rectangular crop box
    FWCropViewCroppingStyleCircular     // A fixed, circular crop box
};

/**
 Preset values of the most common aspect ratios that can be used to quickly configure
 the crop view controller.
 */
typedef NS_ENUM(NSInteger, FWCropViewControllerAspectRatioPreset) {
    FWCropViewControllerAspectRatioPresetOriginal,
    FWCropViewControllerAspectRatioPresetSquare,
    FWCropViewControllerAspectRatioPreset3x2,
    FWCropViewControllerAspectRatioPreset5x3,
    FWCropViewControllerAspectRatioPreset4x3,
    FWCropViewControllerAspectRatioPreset5x4,
    FWCropViewControllerAspectRatioPreset7x5,
    FWCropViewControllerAspectRatioPreset16x9,
    FWCropViewControllerAspectRatioPresetCustom
};

/**
 Whether the control toolbar is placed at the bottom or the top
 */
typedef NS_ENUM(NSInteger, FWCropViewControllerToolbarPosition) {
    FWCropViewControllerToolbarPositionBottom,  // Bar is placed along the bottom in portrait
    FWCropViewControllerToolbarPositionTop     // Bar is placed along the top in portrait (Respects the status bar)
};

@class FWCropViewController;
@class FWCropView;
@class FWCropToolbar;

///------------------------------------------------
/// @name Delegate
///------------------------------------------------

@protocol FWCropViewControllerDelegate <NSObject>
@optional

/**
 Called when the user has committed the crop action, and provides
 just the cropping rectangle.

 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
- (void)cropViewController:(nonnull FWCropViewController *)cropViewController
        didCropImageToRect:(CGRect)cropRect
                     angle:(NSInteger)angle;

/**
 Called when the user has committed the crop action, and provides
 both the original image with crop co-ordinates.
 
 @param image The newly cropped image.
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
- (void)cropViewController:(nonnull FWCropViewController *)cropViewController
            didCropToImage:(nonnull UIImage *)image withRect:(CGRect)cropRect
                     angle:(NSInteger)angle;

/**
 If the cropping style is set to circular, implementing this delegate will return a circle-cropped version of the selected
 image, as well as it's cropping co-ordinates
 
 @param image The newly cropped image, clipped to a circle shape
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
- (void)cropViewController:(nonnull FWCropViewController *)cropViewController
    didCropToCircularImage:(nonnull UIImage *)image withRect:(CGRect)cropRect
                     angle:(NSInteger)angle;

/**
 If implemented, when the user hits cancel, or completes a
 UIActivityViewController operation, this delegate will be called,
 giving you a chance to manually dismiss the view controller

 @param cancelled Whether a cropping action was actually performed, or if the user explicitly hit 'Cancel'
 
 */
- (void)cropViewController:(nonnull FWCropViewController *)cropViewController
        didFinishCancelled:(BOOL)cancelled;

@end

/*!
 @brief FWCropViewController

 @see https://github.com/TimOliver/TOCropViewController
 */
@interface FWCropViewController : UIViewController

/**
 The original, uncropped image that was passed to this controller.
 */
@property (nonnull, nonatomic, readonly) UIImage *image;

/**
 The minimum croping aspect ratio. If set, user is prevented from setting cropping rectangle to lower aspect ratio than defined by the parameter.
 */
@property (nonatomic, assign) CGFloat minimumAspectRatio;

/**
 The view controller's delegate that will receive the resulting
 cropped image, as well as crop information.
 */
@property (nullable, nonatomic, weak) id<FWCropViewControllerDelegate> delegate;

/**
 The crop view managed by this view controller.
 */
@property (nonnull, nonatomic, strong, readonly) FWCropView *cropView;

/**
 In the coordinate space of the image itself, the region that is currently
 being highlighted by the crop box.
 
 This property can be set before the controller is presented to have
 the image 'restored' to a previous cropping layout.
 */
@property (nonatomic, assign) CGRect imageCropFrame;

/**
 The angle in which the image is rotated in the crop view.
 This can only be in 90 degree increments (eg, 0, 90, 180, 270).
 
 This property can be set before the controller is presented to have
 the image 'restored' to a previous cropping layout.
 */
@property (nonatomic, assign) NSInteger angle;

/**
 The toolbar view managed by this view controller.
 */
@property (nonnull, nonatomic, strong, readonly) FWCropToolbar *toolbar;

/**
 The cropping style of this particular crop view controller
 */
@property (nonatomic, readonly) FWCropViewCroppingStyle croppingStyle;

/**
 A choice from one of the pre-defined aspect ratio presets
 */
@property (nonatomic, assign) FWCropViewControllerAspectRatioPreset aspectRatioPreset;

/**
 A CGSize value representing a custom aspect ratio, not listed in the presets.
 E.g. A ratio of 4:3 would be represented as (CGSize){4.0f, 3.0f}
 */
@property (nonatomic, assign) CGSize customAspectRatio;

/**
 If this is set alongside `customAspectRatio`, the custom aspect ratio
 will be shown as a selectable choice in the list of aspect ratios. (Default is `nil`)
 */
@property (nullable, nonatomic, copy) NSString *customAspectRatioName;

/**
 The original aspect ratio
 will be shown as first choice in the list of aspect ratios. (Default is `nil`)
 */
@property (nullable, nonatomic, copy) NSString *originalAspectRatioName;

/**
 Title label which can be used to show instruction on the top of the crop view controller
 */
@property (nullable, nonatomic, readonly) UILabel *titleLabel;

/**
 Title for the 'Done' button.
 Setting this will override the Default which is a localized string for "Done".
 */
@property (nullable, nonatomic, copy) NSString *doneButtonTitle;

/**
 Title for the 'Cancel' button.
 Setting this will override the Default which is a localized string for "Cancel".
 */
@property (nullable, nonatomic, copy) NSString *cancelButtonTitle;

/**
 If true, a custom aspect ratio is set, and the aspectRatioLockEnabled is set to YES, the crop box
 will swap it's dimensions depending on portrait or landscape sized images.
 This value also controls whether the dimensions can swap when the image is rotated.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL aspectRatioLockDimensionSwapEnabled;

/**
 If true, while it can still be resized, the crop box will be locked to its current aspect ratio.
 
 If this is set to YES, and `resetAspectRatioEnabled` is set to NO, then the aspect ratio
 button will automatically be hidden from the toolbar.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL aspectRatioLockEnabled;

/**
 If true, tapping the reset button will also reset the aspect ratio back to the image
 default ratio. Otherwise, the reset will just zoom out to the current aspect ratio.
 
 If this is set to NO, and `aspectRatioLockEnabled` is set to YES, then the aspect ratio
 button will automatically be hidden from the toolbar.
 
 Default is YES
 */
@property (nonatomic, assign) BOOL resetAspectRatioEnabled;

/**
 The position of the Toolbar the default value is `FWCropViewControllerToolbarPositionBottom`.
 */
@property (nonatomic, assign) FWCropViewControllerToolbarPosition toolbarPosition;

/**
 When disabled, an additional rotation button that rotates the canvas in
 90-degree segments in a clockwise direction is shown in the toolbar.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL rotateClockwiseButtonHidden;

/*
 If this controller is embedded in UINavigationController its navigation bar is hidden by default. Set this property to false to show the navigation bar. This must be set before this controller is presented.
 */
@property (nonatomic, assign) BOOL hidesNavigationBar;

/**
 When enabled, hides the rotation button, as well as the alternative rotation
 button visible when `showClockwiseRotationButton` is set to YES.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL rotateButtonsHidden;

/**
 When enabled, hides the 'Reset' button on the toolbar.

 Default is NO.
 */
@property (nonatomic, assign) BOOL resetButtonHidden;
/**
 When enabled, hides the 'Aspect Ratio Picker' button on the toolbar.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL aspectRatioPickerButtonHidden;

/**
 When enabled, hides the 'Done' button on the toolbar.

 Default is NO.
 */
@property (nonatomic, assign) BOOL doneButtonHidden;

/**
 When enabled, hides the 'Cancel' button on the toolbar.

 Default is NO.
 */
@property (nonatomic, assign) BOOL cancelButtonHidden;

/**
 An array of `FWCropViewControllerAspectRatioPreset` enum values denoting which
 aspect ratios the crop view controller may display (Default is nil. All are shown)
 */
@property (nullable, nonatomic, strong) NSArray<NSNumber *> *allowedAspectRatios;

/**
 When the user hits cancel, or completes a
 UIActivityViewController operation, this block will be called,
 giving you a chance to manually dismiss the view controller
 */
@property (nullable, nonatomic, strong) void (^onDidFinishCancelled)(BOOL isFinished);

/**
 Called when the user has committed the crop action, and provides
 just the cropping rectangle.
 
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
@property (nullable, nonatomic, strong) void (^onDidCropImageToRect)(CGRect cropRect, NSInteger angle);

/**
 Called when the user has committed the crop action, and provides
 both the cropped image with crop co-ordinates.
 
 @param image The newly cropped image.
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
@property (nullable, nonatomic, strong) void (^onDidCropToRect)(UIImage* _Nonnull image, CGRect cropRect, NSInteger angle);

/**
 If the cropping style is set to circular, this block will return a circle-cropped version of the selected
 image, as well as it's cropping co-ordinates
 
 @param image The newly cropped image, clipped to a circle shape
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
@property (nullable, nonatomic, strong) void (^onDidCropToCircleImage)(UIImage* _Nonnull image, CGRect cropRect, NSInteger angle);


///------------------------------------------------
/// @name Object Creation
///------------------------------------------------

/**
 Creates a new instance of a crop view controller with the supplied image
 
 @param image The image that will be used to crop.
 */
- (nonnull instancetype)initWithImage:(nonnull UIImage *)image NS_SWIFT_NAME(init(image:));

/**
 Creates a new instance of a crop view controller with the supplied image and cropping style
 
 @param style The cropping style that will be used with this view controller (eg, rectangular, or circular)
 @param image The image that will be cropped
 */
- (nonnull instancetype)initWithCroppingStyle:(FWCropViewCroppingStyle)style image:(nonnull UIImage *)image NS_SWIFT_NAME(init(croppingStyle:image:));

/**
 Resets object of FWCropViewController class as if user pressed reset button in the bottom bar themself
 */
- (void)resetCropViewLayout;

/**
 Set the aspect ratio to be one of the available preset options. These presets have specific behaviour
 such as swapping their dimensions depending on portrait or landscape sized images.
 
 @param aspectRatioPreset The aspect ratio preset
 @param animated Whether the transition to the aspect ratio is animated
 */
- (void)setAspectRatioPreset:(FWCropViewControllerAspectRatioPreset)aspectRatioPreset animated:(BOOL)animated NS_SWIFT_NAME(setAspectRatioPresent(_:animated:));

@end

@interface UIImage (FWCropRotate)

- (nonnull UIImage *)fwCroppedImageWithFrame:(CGRect)frame angle:(NSInteger)angle circularClip:(BOOL)circular;

@end

@interface UIImagePickerController (FWCropRotate)

/** Custom cropController for UIImagePickerController, if nil, consistent with the system effect  */
+ (nullable instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType cropController:(nullable FWCropViewController *)cropController completion:(void (^)(UIImage * _Nullable image, BOOL cancel))completion;

@end

@interface FWCropOverlayView : UIView

/** Hides the interior grid lines, sans animation. */
@property (nonatomic, assign) BOOL gridHidden;

/** Add/Remove the interior horizontal grid lines. */
@property (nonatomic, assign) BOOL displayHorizontalGridLines;

/** Add/Remove the interior vertical grid lines. */
@property (nonatomic, assign) BOOL displayVerticalGridLines;

/** Shows and hides the interior grid lines with an optional crossfade animation. */
- (void)setGridHidden:(BOOL)hidden animated:(BOOL)animated;

@end

/*
 Subclassing UIScrollView was necessary in order to directly capture
 touch events that weren't otherwise accessible via UIGestureRecognizer objects.
 */
@interface FWCropScrollView : UIScrollView

@property (nullable, nonatomic, copy) void (^touchesBegan)(void);
@property (nullable, nonatomic, copy) void (^touchesCancelled)(void);
@property (nullable, nonatomic, copy) void (^touchesEnded)(void);

@end

@interface FWCropToolbar : UIView

/* In horizontal mode, offsets all of the buttons vertically by height of status bar. */
@property (nonatomic, assign) CGFloat statusBarHeightInset;

/* Set an inset that will expand the background view beyond the bounds. */
@property (nonatomic, assign) UIEdgeInsets backgroundViewOutsets;

/* The 'Done' buttons to commit the crop. The text button is displayed
 in portrait mode and the icon one, in landscape. */
@property (nonatomic, strong, readonly) UIButton *doneTextButton;
@property (nonatomic, strong, readonly) UIButton *doneIconButton;
@property (nonatomic, copy) NSString *doneTextButtonTitle;


/* The 'Cancel' buttons to cancel the crop. The text button is displayed
 in portrait mode and the icon one, in landscape. */
@property (nonatomic, strong, readonly) UIButton *cancelTextButton;
@property (nonatomic, strong, readonly) UIButton *cancelIconButton;
@property (nonatomic, readonly) UIView *visibleCancelButton;
@property (nonatomic, copy) NSString *cancelTextButtonTitle;

/* The cropper control buttons */
@property (nonatomic, strong, readonly)  UIButton *rotateCounterclockwiseButton;
@property (nonatomic, strong, readonly)  UIButton *resetButton;
@property (nonatomic, strong, readonly)  UIButton *clampButton;
@property (nullable, nonatomic, strong, readonly) UIButton *rotateClockwiseButton;

@property (nonatomic, readonly) UIButton *rotateButton; // Points to `rotateCounterClockwiseButton`

/* Button feedback handler blocks */
@property (nullable, nonatomic, copy) void (^cancelButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^doneButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^rotateCounterclockwiseButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^rotateClockwiseButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^clampButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^resetButtonTapped)(void);

/* State management for the 'clamp' button */
@property (nonatomic, assign) BOOL clampButtonGlowing;
@property (nonatomic, readonly) CGRect clampButtonFrame;

/* Aspect ratio button visibility settings */
@property (nonatomic, assign) BOOL clampButtonHidden;
@property (nonatomic, assign) BOOL rotateCounterclockwiseButtonHidden;
@property (nonatomic, assign) BOOL rotateClockwiseButtonHidden;
@property (nonatomic, assign) BOOL resetButtonHidden;
@property (nonatomic, assign) BOOL doneButtonHidden;
@property (nonatomic, assign) BOOL cancelButtonHidden;

/* Enable the reset button */
@property (nonatomic, assign) BOOL resetButtonEnabled;

/* Done button frame for popover controllers */
@property (nonatomic, readonly) CGRect doneButtonFrame;

@end

@class FWCropView;

@protocol FWCropViewDelegate<NSObject>

- (void)cropViewDidBecomeResettable:(nonnull FWCropView *)cropView;
- (void)cropViewDidBecomeNonResettable:(nonnull FWCropView *)cropView;

@end

@interface FWCropView : UIView

/**
 The image that the crop view is displaying. This cannot be changed once the crop view is instantiated.
 */
@property (nonnull, nonatomic, strong, readonly) UIImage *image;

/**
 The cropping style of the crop view (eg, rectangular or circular)
 */
@property (nonatomic, assign, readonly) FWCropViewCroppingStyle croppingStyle;

/**
 A grid view overlaid on top of the foreground image view's container.
 */
@property (nonnull, nonatomic, strong, readonly) FWCropOverlayView *gridOverlayView;

/**
 A container view that clips the a copy of the image so it appears over the dimming view
 */
@property (nonnull, nonatomic, readonly) UIView *foregroundContainerView;

/**
 A delegate object that receives notifications from the crop view
 */
@property (nullable, nonatomic, weak) id<FWCropViewDelegate> delegate;

/**
 If false, the user cannot resize the crop box frame using a pan gesture from a corner.
 Default vaue is YES.
 */
@property (nonatomic, assign) BOOL cropBoxResizeEnabled;

/**
 Whether the user has manipulated the crop view to the point where it can be reset
 */
@property (nonatomic, readonly) BOOL canBeReset;

/**
 The frame of the cropping box in the coordinate space of the crop view
 */
@property (nonatomic, readonly) CGRect cropBoxFrame;

/**
 The frame of the entire image in the backing scroll view
 */
@property (nonatomic, readonly) CGRect imageViewFrame;

/**
 Inset the workable region of the crop view in case in order to make space for accessory views
 */
@property (nonatomic, assign) UIEdgeInsets cropRegionInsets;

/**
 Disable the dynamic translucency in order to smoothly relayout the view
 */
@property (nonatomic, assign) BOOL simpleRenderMode;

/**
 When performing manual content layout (such as during screen rotation), disable any internal layout
 */
@property (nonatomic, assign) BOOL internalLayoutDisabled;

/**
 A width x height ratio that the crop box will be rescaled to (eg 4:3 is {4.0f, 3.0f})
 Setting it to CGSizeZero will reset the aspect ratio to the image's own ratio.
 */
@property (nonatomic, assign) CGSize aspectRatio;

/**
 When the cropping box is locked to its current aspect ratio (But can still be resized)
 */
@property (nonatomic, assign) BOOL aspectRatioLockEnabled;

/**
 If true, a custom aspect ratio is set, and the aspectRatioLockEnabled is set to YES,
 the crop box will swap it's dimensions depending on portrait or landscape sized images.
 This value also controls whether the dimensions can swap when the image is rotated.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL aspectRatioLockDimensionSwapEnabled;

/**
 When the user taps 'reset', whether the aspect ratio will also be reset as well
 Default is YES
 */
@property (nonatomic, assign) BOOL resetAspectRatioEnabled;

/**
 True when the height of the crop box is bigger than the width
 */
@property (nonatomic, readonly) BOOL cropBoxAspectRatioIsPortrait;

/**
 The rotation angle of the crop view (Will always be negative as it rotates in a counter-clockwise direction)
 */
@property (nonatomic, assign) NSInteger angle;

/**
 Hide all of the crop elements for transition animations
 */
@property (nonatomic, assign) BOOL croppingViewsHidden;

/**
 In relation to the coordinate space of the image, the frame that the crop view is focusing on
 */
@property (nonatomic, assign) CGRect imageCropFrame;

/**
 Set the grid overlay graphic to be hidden
 */
@property (nonatomic, assign) BOOL gridOverlayHidden;

///**
// Paddings of the crop rectangle. Default to 14.0
// */
@property (nonatomic) CGFloat cropViewPadding;

/**
 Delay before crop frame is adjusted according new crop area. Default to 0.8
 */
@property (nonatomic) NSTimeInterval cropAdjustingDelay;

/**
The minimum croping aspect ratio. If set, user is prevented from setting cropping
 rectangle to lower aspect ratio than defined by the parameter.
*/
@property (nonatomic, assign) CGFloat minimumAspectRatio;

/**
 The maximum scale that user can apply to image by pinching to zoom. Small values
 are only recomended with aspectRatioLockEnabled set to true. Default to 15.0
 */
@property (nonatomic, assign) CGFloat maximumZoomScale;

/**
 Always show the cropping grid lines, even when the user isn't interacting.
 This also disables the fading animation.
 (Default is NO)
 */
@property (nonatomic, assign) BOOL alwaysShowCroppingGrid;

/**
 Permanently hides the translucency effect covering the outside bounds of the
 crop box. (Default is NO)
 */
@property (nonatomic, assign) BOOL translucencyAlwaysHidden;

/**
 Create a default instance of the crop view with the supplied image
 */
- (nonnull instancetype)initWithImage:(nonnull UIImage *)image;

/**
 Create a new instance of the crop view with the specified image and cropping
 */
- (nonnull instancetype)initWithCroppingStyle:(FWCropViewCroppingStyle)style image:(nonnull UIImage *)image;

/**
 Performs the initial set up, including laying out the image and applying any restore properties.
 This should be called once the crop view has been added to a parent that is in its final layout frame.
 */
- (void)performInitialSetup;

/**
 When performing large size transitions (eg, orientation rotation),
 set simple mode to YES to temporarily graphically heavy effects like translucency.
 
 @param simpleMode Whether simple mode is enabled or not
 
 */
- (void)setSimpleRenderMode:(BOOL)simpleMode animated:(BOOL)animated;

/**
 When performing a screen rotation that will change the size of the scroll view, this takes
 a snapshot of all of the scroll view data before it gets manipulated by iOS.
 Please call this in your view controller, before the rotation animation block is committed.
 */
- (void)prepareforRotation;

/**
 Performs the realignment of the crop view while the screen is rotating.
 Please call this inside your view controller's screen rotation animation block.
 */
- (void)performRelayoutForRotation;

/**
 Reset the crop box and zoom scale back to the initial layout
 
 @param animated The reset is animated
 */
- (void)resetLayoutToDefaultAnimated:(BOOL)animated;

/**
 Changes the aspect ratio of the crop box to match the one specified
 
 @param aspectRatio The aspect ratio (For example 16:9 is 16.0f/9.0f). 'CGSizeZero' will reset it to the image's own ratio
 @param animated Whether the locking effect is animated
 */
- (void)setAspectRatio:(CGSize)aspectRatio animated:(BOOL)animated;

/**
 Rotates the entire canvas to a 90-degree angle. The default rotation is counterclockwise.
 
 @param animated Whether the transition is animated
 */
- (void)rotateImageNinetyDegreesAnimated:(BOOL)animated;

/**
 Rotates the entire canvas to a 90-degree angle
 
 @param animated Whether the transition is animated
 @param clockwise Whether the rotation is clockwise. Passing 'NO' means counterclockwise
 */
- (void)rotateImageNinetyDegreesAnimated:(BOOL)animated clockwise:(BOOL)clockwise;

/**
 Animate the grid overlay graphic to be visible
 */
- (void)setGridOverlayHidden:(BOOL)gridOverlayHidden animated:(BOOL)animated;

/**
 Animate the cropping component views to become visible
 */
- (void)setCroppingViewsHidden:(BOOL)hidden animated:(BOOL)animated;

/**
 Animate the background image view to become visible
 */
- (void)setBackgroundImageViewHidden:(BOOL)hidden animated:(BOOL)animated;

/**
 When triggered, the crop view will perform a relayout to ensure the crop box
 fills the entire crop view region
 */
- (void)moveCroppedContentToCenterAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
