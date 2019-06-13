/*!
 @header     FWPageControl.m
 @indexgroup FWFramework
 @brief      FWPageControl
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/10
 */

#import "FWPageControl.h"

#pragma mark - FWPageControl

@interface FWPageControl()

/**
 *  Array of dot views for reusability and touch events.
 */
@property (strong, nonatomic) NSMutableArray *dots;

@end

@implementation FWPageControl

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialization];
    }
    return self;
}

/**
 *  Default setup when initiating control
 */
- (void)initialization
{
    self.dotViewClass           = [FWDotView class];
    self.spacingBetweenDots     = 8;
    self.numberOfPages          = 0;
    self.currentPage            = 0;
    self.hidesForSinglePage     = NO;
    self.shouldResizeFromCenter = YES;
}

#pragma mark - Touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if (touch.view != self) {
        NSInteger index = [self.dots indexOfObject:touch.view];
        if ([self.delegate respondsToSelector:@selector(pageControl:didSelectPageAtIndex:)]) {
            [self.delegate pageControl:self didSelectPageAtIndex:index];
        }
    }
}

#pragma mark - Layout

/**
 *  Resizes and moves the receiver view so it just encloses its subviews.
 */
- (void)sizeToFit
{
    [self updateFrame:YES];
}

- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount
{
    return CGSizeMake((self.dotSize.width + self.spacingBetweenDots) * pageCount - self.spacingBetweenDots , self.dotSize.height);
}

/**
 *  Will update dots display and frame. Reuse existing views or instantiate one if required. Update their position in case frame changed.
 */
- (void)updateDots
{
    if (self.numberOfPages == 0) {
        return;
    }
    
    for (NSInteger i = 0; i < self.numberOfPages; i++) {
        UIView *dot;
        if (i < self.dots.count) {
            dot = [self.dots objectAtIndex:i];
        } else {
            dot = [self generateDotView];
        }
        [self updateDotFrame:dot atIndex:i];
    }
    
    [self changeActivity:YES atIndex:self.currentPage];
    
    [self hideForSinglePage];
}

/**
 *  Update frame control to fit current number of pages. It will apply required size if authorize and required.
 *
 *  @param overrideExistingFrame BOOL to allow frame to be overriden. Meaning the required size will be apply no mattter what.
 */
- (void)updateFrame:(BOOL)overrideExistingFrame
{
    CGPoint center = self.center;
    CGSize requiredSize = [self sizeForNumberOfPages:self.numberOfPages];
    
    // We apply requiredSize only if authorize to and necessary
    if (overrideExistingFrame || ((CGRectGetWidth(self.frame) < requiredSize.width || CGRectGetHeight(self.frame) < requiredSize.height) && !overrideExistingFrame)) {
        self.frame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame), requiredSize.width, requiredSize.height);
        if (self.shouldResizeFromCenter) {
            self.center = center;
        }
    }
    
    [self resetDotViews];
}

/**
 *  Update the frame of a specific dot at a specific index
 *
 *  @param dot   Dot view
 *  @param index Page index of dot
 */
- (void)updateDotFrame:(UIView *)dot atIndex:(NSInteger)index
{
    // Dots are always centered within view
    CGFloat x = (self.dotSize.width + self.spacingBetweenDots) * index + ( (CGRectGetWidth(self.frame) - [self sizeForNumberOfPages:self.numberOfPages].width) / 2);
    CGFloat y = (CGRectGetHeight(self.frame) - self.dotSize.height) / 2;
    
    dot.frame = CGRectMake(x, y, self.dotSize.width, self.dotSize.height);
}

#pragma mark - Utils

/**
 *  Generate a dot view and add it to the collection
 *
 *  @return The UIView object representing a dot
 */
- (UIView *)generateDotView
{
    UIView *dotView;
    
    if (self.dotViewClass) {
        dotView = [[self.dotViewClass alloc] initWithFrame:CGRectMake(0, 0, self.dotSize.width, self.dotSize.height)];
        if ([dotView isKindOfClass:[FWDotView class]]) {
            if (self.dotColor) {
                ((FWDotView *)dotView).dotColor = self.dotColor;
            }
            if (self.currentDotColor) {
                ((FWDotView *)dotView).currentDotColor = self.currentDotColor;
            }
        }
    } else {
        dotView = [[UIImageView alloc] initWithImage:self.dotImage];
        dotView.frame = CGRectMake(0, 0, self.dotSize.width, self.dotSize.height);
    }
    
    if (dotView) {
        [self addSubview:dotView];
        [self.dots addObject:dotView];
    }
    
    dotView.userInteractionEnabled = YES;
    return dotView;
}

/**
 *  Change activity state of a dot view. Current/not currrent.
 *
 *  @param active Active state to apply
 *  @param index  Index of dot for state update
 */
- (void)changeActivity:(BOOL)active atIndex:(NSInteger)index
{
    if (self.dotViewClass) {
        id<FWDotViewProtocol> dotView = (id<FWDotViewProtocol>)[self.dots objectAtIndex:index];
        if ([dotView respondsToSelector:@selector(changeActivityState:)]) {
            [dotView changeActivityState:active];
        } else {
            NSLog(@"Custom view : %@ must implement an 'changeActivityState' method for protocol %@", self.dotViewClass, NSStringFromProtocol(@protocol(FWDotViewProtocol)));
        }
    } else if (self.dotImage && self.currentDotImage) {
        UIImageView *dotView = (UIImageView *)[self.dots objectAtIndex:index];
        dotView.image = (active) ? self.currentDotImage : self.dotImage;
    }
}

- (void)resetDotViews
{
    for (UIView *dotView in self.dots) {
        [dotView removeFromSuperview];
    }
    
    [self.dots removeAllObjects];
    [self updateDots];
}

- (void)hideForSinglePage
{
    if (self.dots.count == 1 && self.hidesForSinglePage) {
        self.hidden = YES;
    } else {
        self.hidden = NO;
    }
}

#pragma mark - Setters

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    _numberOfPages = numberOfPages;
    
    // Update dot position to fit new number of pages
    [self resetDotViews];
}

- (void)setSpacingBetweenDots:(NSInteger)spacingBetweenDots
{
    _spacingBetweenDots = spacingBetweenDots;
    
    [self resetDotViews];
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    // If no pages, no current page to treat.
    if (self.numberOfPages == 0 || currentPage == _currentPage) {
        _currentPage = currentPage;
        return;
    }
    
    // Less than max page
    if (currentPage > self.numberOfPages - 1) {
        currentPage = self.numberOfPages - 1;
    }
    
    // Pre set
    [self changeActivity:NO atIndex:_currentPage];
    _currentPage = currentPage;
    // Post set
    [self changeActivity:YES atIndex:_currentPage];
}

- (void)setDotImage:(UIImage *)dotImage
{
    _dotImage = dotImage;
    [self resetDotViews];
    self.dotViewClass = nil;
}

- (void)setCurrentDotImage:(UIImage *)currentDotimage
{
    _currentDotImage = currentDotimage;
    [self resetDotViews];
    self.dotViewClass = nil;
}

- (void)setDotViewClass:(Class)dotViewClass
{
    _dotViewClass = dotViewClass;
    self.dotSize = CGSizeZero;
    [self resetDotViews];
}

#pragma mark - Getters

- (NSMutableArray *)dots
{
    if (!_dots) {
        _dots = [[NSMutableArray alloc] init];
    }
    return _dots;
}

- (CGSize)dotSize
{
    // Dot size logic depending on the source of the dot view
    if (self.dotImage && CGSizeEqualToSize(_dotSize, CGSizeZero)) {
        _dotSize = self.dotImage.size;
    } else if (self.dotViewClass && CGSizeEqualToSize(_dotSize, CGSizeZero)) {
        _dotSize = CGSizeMake(8, 8);
        return _dotSize;
    }
    return _dotSize;
}

@end

#pragma mark - FWDotView

@implementation FWDotView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupView];
    }
    return self;
}

#pragma mark - Protect

- (void)setupView
{
    _dotColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    _currentDotColor = [UIColor whiteColor];
    self.layer.cornerRadius = MIN(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)) / 2;
    self.backgroundColor = self.dotColor;
}

#pragma mark - FWDotViewProtocol

- (void)changeActivityState:(BOOL)active
{
    if (!self.isAnimated) {
        if (active) {
            self.backgroundColor = self.currentDotColor;
        } else {
            self.backgroundColor = self.dotColor;
        }
    } else {
        if (active) {
            [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:-20 options:UIViewAnimationOptionCurveLinear animations:^{
                self.backgroundColor = self.currentDotColor;
                self.transform = CGAffineTransformMakeScale(1.4, 1.4);
            } completion:nil];
        } else {
            [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.backgroundColor = self.dotColor;
                self.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    }
}

@end

@implementation FWBorderDotView

#pragma mark - Setter

- (void)setDotColor:(UIColor *)dotColor
{
    [super setDotColor:dotColor];
    self.backgroundColor = dotColor;
}

- (void)setCurrentDotColor:(UIColor *)currentDotColor
{
    [super setCurrentDotColor:currentDotColor];
    self.layer.borderColor = currentDotColor.CGColor;
}

#pragma mark - Protect

- (void)setupView
{
    self.dotColor = [UIColor clearColor];
    self.currentDotColor = [UIColor whiteColor];
    self.layer.cornerRadius = MIN(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)) / 2;
    self.layer.borderWidth = 2;
    self.backgroundColor = self.dotColor;
    self.layer.borderColor = self.currentDotColor.CGColor;
}

@end
