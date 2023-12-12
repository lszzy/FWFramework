//
//  ImageCropController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ImageCropController.h"
#import <FWFramework/FWFramework-Swift.h>

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

#pragma mark - Accessors -

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

- (void)setGridOverlayHidden:(BOOL)gridOverlayHidden animated:(BOOL)animated
{
    _gridOverlayHidden = gridOverlayHidden;
    self.gridOverlayView.alpha = gridOverlayHidden ? 1.0f : 0.0f;
    
    [UIView animateWithDuration:0.4f animations:^{
        self.gridOverlayView.alpha = gridOverlayHidden ? 0.0f : 1.0f;
    }];
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

@end
