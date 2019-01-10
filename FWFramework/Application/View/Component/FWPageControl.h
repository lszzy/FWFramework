/*!
 @header     FWPageControl.h
 @indexgroup FWFramework
 @brief      FWPageControl
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/10
 */

#import <UIKit/UIKit.h>

@class FWPageControl;

@protocol FWPageControlDelegate <NSObject>

@optional

- (void)pageControl:(FWPageControl *)pageControl didSelectPageAtIndex:(NSInteger)index;

@end

/*!
 @brief FWPageControl
 
 @see https://github.com/TanguyAladenise/TAPageControl
 */
@interface FWPageControl : UIControl

/**
 * Dot view customization properties
 */

/**
 *  The Class of your custom UIView, make sure to respect the FWAbstractDotView class, default FWDotView.
 */
@property (nonatomic) Class dotViewClass;


/**
 *  UIImage to represent a dot.
 */
@property (nonatomic) UIImage *dotImage;


/**
 *  UIImage to represent current page dot.
 */
@property (nonatomic) UIImage *currentDotImage;


/**
 *  Dot size for dot views. Default is 8 by 8.
 */
@property (nonatomic) CGSize dotSize;


@property (nonatomic, strong) UIColor *dotColor;

/**
 *  Spacing between two dot views. Default is 8.
 */
@property (nonatomic) NSInteger spacingBetweenDots;


/**
 * Page control setup properties
 */


/**
 * Delegate for FWPageControl
 */
@property(nonatomic,assign) id<FWPageControlDelegate> delegate;


/**
 *  Number of pages for control. Default is 0.
 */
@property (nonatomic) NSInteger numberOfPages;


/**
 *  Current page on which control is active. Default is 0.
 */
@property (nonatomic) NSInteger currentPage;


/**
 *  Hide the control if there is only one page. Default is NO.
 */
@property (nonatomic) BOOL hidesForSinglePage;


/**
 *  Let the control know if should grow bigger by keeping center, or just get longer (right side expanding). By default YES.
 */
@property (nonatomic) BOOL shouldResizeFromCenter;


/**
 *  Return the minimum size required to display control properly for the given page count.
 *
 *  @param pageCount Number of dots that will require display
 *
 *  @return The CGSize being the minimum size required.
 */
- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount;

@end

@interface FWAbstractDotView : UIView


/**
 *  A method call let view know which state appearance it should take. Active meaning it's current page. Inactive not the current page.
 *
 *  @param active BOOL to tell if view is active or not
 */
- (void)changeActivityState:(BOOL)active;


@end

@interface FWDotView : FWAbstractDotView

@property (nonatomic, strong) UIColor *dotColor;

@end

@interface FWAnimatedDotView : FWDotView

@end
