//
//  FWPageControl.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWPageControl

@class FWPageControl;

NS_SWIFT_NAME(PageControlDelegate)
@protocol FWPageControlDelegate <NSObject>

@optional

- (void)pageControl:(FWPageControl *)pageControl didSelectPageAtIndex:(NSInteger)index;

@end

/**
 FWPageControl
 
 @see https://github.com/TanguyAladenise/TAPageControl
 */
NS_SWIFT_NAME(PageControl)
@interface FWPageControl : UIControl

/**
 *  The Class of your custom UIView, make sure to implement FWDotViewProtocol, default FWDotView.
 */
@property (nonatomic, nullable) Class dotViewClass;

/**
 *  UIImage to represent a dot.
 */
@property (nonatomic, nullable) UIImage *dotImage;

/**
 *  UIImage to represent current page dot.
 */
@property (nonatomic, nullable) UIImage *currentDotImage;

/**
 *  Dot size for dot views. Default is 8 by 8.
 */
@property (nonatomic) CGSize dotSize;

/**
 *  UIColor to represent a dot.
 */
@property (nonatomic, strong, nullable) UIColor *dotColor;

/**
 *  UIColor to represent current page dot.
 */
@property (nonatomic, strong, nullable) UIColor *currentDotColor;

/**
 *  Spacing between two dot views. Default is 8.
 */
@property (nonatomic) NSInteger spacingBetweenDots;

/**
 * Delegate for FWPageControl
 */
@property(nonatomic,assign,nullable) id<FWPageControlDelegate> delegate;

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

NS_SWIFT_NAME(DotViewProtocol)
@protocol FWDotViewProtocol <NSObject>

@required

/**
 *  A method call let view know which state appearance it should take. Active meaning it's current page. Inactive not the current page.
 *
 *  @param active BOOL to tell if view is active or not
 */
- (void)changeActivityState:(BOOL)active;

@end

NS_SWIFT_NAME(DotView)
@interface FWDotView : UIView <FWDotViewProtocol>

@property (nonatomic, strong) UIColor *dotColor;

@property (nonatomic, strong) UIColor *currentDotColor;

@property (nonatomic, assign) BOOL isAnimated;

@end

NS_SWIFT_NAME(BorderDotView)
@interface FWBorderDotView : FWDotView

@end

NS_ASSUME_NONNULL_END
