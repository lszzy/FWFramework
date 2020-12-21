/*!
 @header     FWAsyncLayer.h
 @indexgroup FWFramework
 @brief      FWAsyncLayer
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/28
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "FWAttributedLabel.h"
#import "FWBannerView.h"
#import "FWBarrageView.h"
#import "FWCollectionViewFlowLayout.h"
#import "FWCropViewController.h"
#import "FWFloatLayoutView.h"
#import "FWGridView.h"
#import "FWIndicatorControl.h"
#import "FWMarqueeLabel.h"
#import "FWPageControl.h"
#import "FWPhotoBrowser.h"
#import "FWPopupMenu.h"
#import "FWProgressView.h"
#import "FWQrcodeScanView.h"
#import "FWSegmentedControl.h"
#import "FWTagCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

@class FWAsyncLayerDisplayTask;

/**
 The FWAsyncLayer class is a subclass of CALayer used for render contents asynchronously.
 
 @discussion When the layer need update it's contents, it will ask the delegate
 for a async display task to render the contents in a background queue.
 
 @see https://github.com/ibireme/YYAsyncLayer
 */
@interface FWAsyncLayer : CALayer
/// Whether the render code is executed in background. Default is YES.
@property BOOL displaysAsynchronously;
@end


/**
 The FWAsyncLayer's delegate protocol. The delegate of the FWAsyncLayer (typically a UIView)
 must implements the method in this protocol.
 */
@protocol FWAsyncLayerDelegate <NSObject>
@required
/// This method is called to return a new display task when the layer's contents need update.
- (FWAsyncLayerDisplayTask *)newAsyncDisplayTask;
@end


/**
 A display task used by FWAsyncLayer to render the contents in background queue.
 */
@interface FWAsyncLayerDisplayTask : NSObject

/**
 This block will be called before the asynchronous drawing begins.
 It will be called on the main thread.
 
 block param layer:  The layer.
 */
@property (nullable, nonatomic, copy) void (^willDisplay)(CALayer *layer);

/**
 This block is called to draw the layer's contents.
 
 @discussion This block may be called on main thread or background thread,
 so is should be thread-safe.
 
 block param context:      A new bitmap content created by layer.
 block param size:         The content size (typically same as layer's bound size).
 block param isCancelled:  If this block returns `YES`, the method should cancel the
   drawing process and return as quickly as possible.
 */
@property (nullable, nonatomic, copy) void (^display)(CGContextRef context, CGSize size, BOOL(^isCancelled)(void));

/**
 This block will be called after the asynchronous drawing finished.
 It will be called on the main thread.
 
 block param layer:  The layer.
 block param finished:  If the draw process is cancelled, it's `NO`, otherwise it's `YES`.
 */
@property (nullable, nonatomic, copy) void (^didDisplay)(CALayer *layer, BOOL finished);

@end

/**
 FWSentinel is a thread safe incrementing counter.
 It may be used in some multi-threaded situation.
 */
@interface FWSentinel : NSObject

/// Returns the current value of the counter.
@property (readonly) int32_t value;

/// Increase the value atomically.
/// @return The new value.
- (int32_t)increase;

@end

/**
 FWTransaction let you perform a selector once before current runloop sleep.
 */
@interface FWTransaction : NSObject

/**
 Creates and returns a transaction with a specified target and selector.
 
 @param target    A specified target, the target is retained until runloop end.
 @param selector  A selector for target.
 
 @return A new transaction, or nil if an error occurs.
 */
+ (FWTransaction *)transactionWithTarget:(id)target selector:(SEL)selector;

/**
 Commit the trancaction to main runloop.
 
 @discussion It will perform the selector on the target once before main runloop's
 current loop sleep. If the same transaction (same target and same selector) has
 already commit to runloop in this loop, this method do nothing.
 */
- (void)commit;

@end

NS_ASSUME_NONNULL_END
