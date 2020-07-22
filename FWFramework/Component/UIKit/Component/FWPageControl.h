/*!
 @header     FWPageControl.h
 @indexgroup FWFramework
 @brief      FWPageControl
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/10
 */

#import <UIKit/UIKit.h>

#pragma mark - FWPageControl

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
 *  The Class of your custom UIView, make sure to implement FWDotViewProtocol, default FWDotView.
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

/**
 *  UIColor to represent a dot.
 */
@property (nonatomic, strong) UIColor *dotColor;

/**
 *  UIColor to represent current page dot.
 */
@property (nonatomic, strong) UIColor *currentDotColor;

/**
 *  Spacing between two dot views. Default is 8.
 */
@property (nonatomic) NSInteger spacingBetweenDots;

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

#pragma mark - FWDotView

@protocol FWDotViewProtocol <NSObject>

@required

/**
 *  A method call let view know which state appearance it should take. Active meaning it's current page. Inactive not the current page.
 *
 *  @param active BOOL to tell if view is active or not
 */
- (void)changeActivityState:(BOOL)active;

@end

@interface FWDotView : UIView <FWDotViewProtocol>

@property (nonatomic, strong) UIColor *dotColor;

@property (nonatomic, strong) UIColor *currentDotColor;

@property (nonatomic, assign) BOOL isAnimated;

@end

@interface FWBorderDotView : FWDotView

@end
