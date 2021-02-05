//
//  TestCustomerAlertController.m
//  Example
//
//  Created by wuyong on 2020/4/25.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestCustomerAlertController.h"

@interface CommodityListView : UIView

@end

@interface CommodityListView()
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *imageViews;
@end

@implementation CommodityListView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    
    NSArray *images = @[@"public_icon",@"public_icon",@"public_icon",@"public_icon",@"public_icon",@"public_icon",@"public_icon",@"public_icon",@"public_icon",@"public_icon"];
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.backgroundColor = [Theme backgroundColor];
    scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:scrollView];
    _scrollView = scrollView;
    
    for (int i = 0; i < images.count; i++) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [TestBundle imageNamed:images[i]];
        imageView.backgroundColor = [Theme cellColor];
        [scrollView addSubview:imageView];
        [self.imageViews addObject:imageView];
    }
}

- (NSMutableArray *)imageViews {
    
    if (!_imageViews) {
        _imageViews = [NSMutableArray array];
        
    }
    return _imageViews;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = self.bounds;

    CGFloat imageViewW = self.bounds.size.width/2-20;
    CGFloat imageViewH = self.bounds.size.height;
    CGFloat imageViewY = 0;
    if (@available(iOS 11.0, *)) {
        imageViewY = self.safeAreaInsets.top;
    }
    UIImageView *lastImageView;
    for (int i = 0; i < self.imageViews.count; i++) {
        UIImageView *imageView = self.imageViews[i];
        imageView.frame = CGRectMake((imageViewW +10) * i, imageViewY, imageViewW, imageViewH);
        if (i == self.imageViews.count-1) {
            lastImageView = imageView;
        }
    }
    self.scrollView.contentSize = CGSizeMake(CGRectGetMaxX(lastImageView.frame), 0);
}

@end

@interface PickerView : UIView

@property (nonatomic, copy) void(^cancelClickedBlock)(void);
@property (nonatomic, copy) void(^doneClickedBlock)(void);

@end

@interface PickerView() <UIPickerViewDelegate,UIPickerViewDataSource>

@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation PickerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [self addSubview:self.toolbar];
    [self addSubview:self.pickerView];
}

- (void)doneClick {
    if (self.doneClickedBlock) {
        self.doneClickedBlock();
    }
}

- (void)cancelClick {
    if (self.cancelClickedBlock) {
        self.cancelClickedBlock();
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 2;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @[@"男",@"女"][row];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *pickerLabel = (UILabel *)view;
    if (!pickerLabel) {
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        pickerLabel.textAlignment = NSTextAlignmentCenter;
        [pickerLabel setFont:[UIFont boldSystemFontOfSize:18]];
    }
    pickerLabel.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    return pickerLabel;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 50;
}

- (UIPickerView *)pickerView {
    if (!_pickerView) {
        _pickerView = [[UIPickerView alloc] init];
        _pickerView.delegate = self;
        _pickerView.dataSource = self;
        _pickerView.backgroundColor = [Theme backgroundColor];
    }
    return _pickerView;
}

- (UIToolbar *)toolbar {
    
    if (!_toolbar) {
        UIBarButtonItem *doneBBI = [[UIBarButtonItem alloc]
                                    initWithTitle:@"确定"
                                    style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(doneClick)];
        
        UIBarButtonItem *cancelBBI = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelClick)];
        UIBarButtonItem *flexibleBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        _toolbar = [[UIToolbar alloc] init];
        // 设置tollbar的背景色
        _toolbar.barTintColor = [Theme cellColor];
        NSArray *toolbarItems = [NSArray arrayWithObjects:cancelBBI, flexibleBBI, doneBBI, nil];
        [_toolbar setItems:toolbarItems];
    }
    return _toolbar;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.toolbar.frame = CGRectMake(0, 0, self.bounds.size.width, 40);
    self.pickerView.frame = CGRectMake(0, CGRectGetMaxY(self.toolbar.frame), self.bounds.size.width, self.bounds.size.height-40);
}

@end

typedef BOOL(^HCSStarRatingViewShouldBeginGestureRecognizerBlock)(UIGestureRecognizer *gestureRecognizer);

IB_DESIGNABLE
@interface HCSStarRatingView : UIControl
@property (nonatomic) IBInspectable NSUInteger maximumValue;
@property (nonatomic) IBInspectable CGFloat minimumValue;
@property (nonatomic) IBInspectable CGFloat value;
@property (nonatomic) IBInspectable CGFloat spacing;
@property (nonatomic) IBInspectable BOOL allowsHalfStars;
@property (nonatomic) IBInspectable BOOL accurateHalfStars;
@property (nonatomic) IBInspectable BOOL continuous;

@property (nonatomic) BOOL shouldBecomeFirstResponder;

// Optional: if `nil` method will return `NO`.
@property (nonatomic, copy) HCSStarRatingViewShouldBeginGestureRecognizerBlock shouldBeginGestureRecognizerBlock;

@property (nonatomic, strong) IBInspectable UIColor *starBorderColor;
@property (nonatomic) IBInspectable CGFloat starBorderWidth;

@property (nonatomic, strong) IBInspectable UIColor *emptyStarColor;

@property (nonatomic, strong) IBInspectable UIImage *emptyStarImage;
@property (nonatomic, strong) IBInspectable UIImage *halfStarImage;
@property (nonatomic, strong) IBInspectable UIImage *filledStarImage;
@end

@interface HCSStarRatingView ()
@property (nonatomic, readonly) BOOL shouldUseImages;
@end

@implementation HCSStarRatingView {
    CGFloat _minimumValue;
    NSUInteger _maximumValue;
    CGFloat _value;
    UIColor *_starBorderColor;
}

@dynamic minimumValue;
@dynamic maximumValue;
@dynamic value;
@dynamic shouldUseImages;
@dynamic starBorderColor;

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _customInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _customInit];
    }
    return self;
}

- (void)_customInit {
    self.exclusiveTouch = YES;
    _minimumValue = 0;
    _maximumValue = 5;
    _value = 0;
    _spacing = 5.f;
    _continuous = YES;
    _starBorderWidth = 1.0f;
    _emptyStarColor = [UIColor clearColor];
    
    [self _updateAppearanceForState:self.enabled];
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [self setNeedsDisplay];
}

#pragma mark - Properties

- (UIColor *)backgroundColor {
    if ([super backgroundColor]) {
        return [super backgroundColor];
    } else {
        return self.isOpaque ? [Theme backgroundColor] : [UIColor clearColor];
    };
}

- (CGFloat)minimumValue {
    return MAX(_minimumValue, 0);
}

- (void)setMinimumValue:(CGFloat)minimumValue {
    if (_minimumValue != minimumValue) {
        _minimumValue = minimumValue;
        [self setNeedsDisplay];
    }
}

- (NSUInteger)maximumValue {
    return MAX(_minimumValue, _maximumValue);
}

- (void)setMaximumValue:(NSUInteger)maximumValue {
    if (_maximumValue != maximumValue) {
        _maximumValue = maximumValue;
        [self setNeedsDisplay];
        [self invalidateIntrinsicContentSize];
    }
}

- (CGFloat)value {
    return MIN(MAX(_value, _minimumValue), _maximumValue);
}

- (void)setValue:(CGFloat)value {
    [self setValue:value sendValueChangedAction:NO];
}

- (void)setValue:(CGFloat)value sendValueChangedAction:(BOOL)sendAction {
    [self willChangeValueForKey:NSStringFromSelector(@selector(value))];
    if (_value != value && value >= _minimumValue && value <= _maximumValue) {
        _value = value;
        if (sendAction) [self sendActionsForControlEvents:UIControlEventValueChanged];
        [self setNeedsDisplay];
    }
    [self didChangeValueForKey:NSStringFromSelector(@selector(value))];
}

- (void)setSpacing:(CGFloat)spacing {
    _spacing = MAX(spacing, 0);
    [self setNeedsDisplay];
}

- (void)setAllowsHalfStars:(BOOL)allowsHalfStars {
    if (_allowsHalfStars != allowsHalfStars) {
        _allowsHalfStars = allowsHalfStars;
        [self setNeedsDisplay];
    }
}

- (void)setAccurateHalfStars:(BOOL)accurateHalfStars {
    if (_accurateHalfStars != accurateHalfStars) {
        _accurateHalfStars = accurateHalfStars;
        [self setNeedsDisplay];
    }
}

- (void)setEmptyStarImage:(UIImage *)emptyStarImage {
    if (_emptyStarImage != emptyStarImage) {
        _emptyStarImage = emptyStarImage;
        [self setNeedsDisplay];
    }
}

- (void)setHalfStarImage:(UIImage *)halfStarImage {
    if (_halfStarImage != halfStarImage) {
        _halfStarImage = halfStarImage;
        [self setNeedsDisplay];
    }
}

- (void)setFilledStarImage:(UIImage *)filledStarImage {
    if (_filledStarImage != filledStarImage) {
        _filledStarImage = filledStarImage;
        [self setNeedsDisplay];
    }
}

- (void)setEmptyStarColor:(UIColor *)emptyStarColor {
    if (_emptyStarColor != emptyStarColor) {
        _emptyStarColor = emptyStarColor;
        [self setNeedsDisplay];
    }
}

- (void)setStarBorderColor:(UIColor *)starBorderColor {
    if (_starBorderColor != starBorderColor) {
        _starBorderColor = starBorderColor;
        [self setNeedsDisplay];
    }
}

- (UIColor *)starBorderColor {
    if (_starBorderColor == nil) {
        return self.tintColor;
    } else {
        return _starBorderColor;
    }
}

- (void)setStarBorderWidth:(CGFloat)starBorderWidth {
    _starBorderWidth = MAX(0, starBorderWidth);
    [self setNeedsDisplay];
}


- (BOOL)shouldUseImages {
    return (self.emptyStarImage!=nil && self.filledStarImage!=nil);
}

#pragma mark - State

- (void)setEnabled:(BOOL)enabled
{
    [self _updateAppearanceForState:enabled];
    [super setEnabled:enabled];
}

- (void)_updateAppearanceForState:(BOOL)enabled
{
    self.alpha = enabled ? 1.f : .5f;
}

#pragma mark - Image Drawing

- (void)_drawStarImageWithFrame:(CGRect)frame tintColor:(UIColor*)tintColor highlighted:(BOOL)highlighted {
    UIImage *image = highlighted ? self.filledStarImage : self.emptyStarImage;
    [self _drawImage:image frame:frame tintColor:tintColor];
}

- (void)_drawHalfStarImageWithFrame:(CGRect)frame tintColor:(UIColor *)tintColor {
    [self _drawAccurateHalfStarImageWithFrame:frame tintColor:tintColor progress:.5f];
}

- (void)_drawAccurateHalfStarImageWithFrame:(CGRect)frame tintColor:(UIColor *)tintColor progress:(CGFloat)progress {
    UIImage *image = self.halfStarImage;
    if (image == nil) {
        // first draw star outline
        [self _drawStarImageWithFrame:frame tintColor:tintColor highlighted:NO];
        
        image = self.filledStarImage;
        CGRect imageFrame = CGRectMake(0, 0, image.size.width * image.scale * progress, image.size.height * image.scale);
        frame.size.width *= progress;
        CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, imageFrame);
        UIImage *halfImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
        image = [halfImage imageWithRenderingMode:image.renderingMode];
        CGImageRelease(imageRef);
    }
    [self _drawImage:image frame:frame tintColor:tintColor];
}

- (void)_drawImage:(UIImage *)image frame:(CGRect)frame tintColor:(UIColor *)tintColor {
    if (image.renderingMode == UIImageRenderingModeAlwaysTemplate) {
        [tintColor setFill];
    }
    [image drawInRect:frame];
}

#pragma mark - Shape Drawing

- (void)_drawStarShapeWithFrame:(CGRect)frame tintColor:(UIColor*)tintColor highlighted:(BOOL)highlighted {
    [self _drawAccurateHalfStarShapeWithFrame:frame tintColor:tintColor progress:highlighted ? 1.f : 0.f];
}

- (void)_drawHalfStarShapeWithFrame:(CGRect)frame tintColor:(UIColor *)tintColor {
    [self _drawAccurateHalfStarShapeWithFrame:frame tintColor:tintColor progress:.5f];
}

- (void)_drawAccurateHalfStarShapeWithFrame:(CGRect)frame tintColor:(UIColor *)tintColor progress:(CGFloat)progress {
    UIBezierPath* starShapePath = UIBezierPath.bezierPath;
    [starShapePath moveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.62723 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.37309 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.50000 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.02500 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.37292 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.37309 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.02500 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.39112 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.30504 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.62908 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.20642 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.97500 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.50000 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.78265 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.79358 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.97500 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.69501 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.62908 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.97500 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.39112 * CGRectGetHeight(frame))];
    [starShapePath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.62723 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.37309 * CGRectGetHeight(frame))];
    [starShapePath closePath];
    starShapePath.miterLimit = 4;
    
    CGFloat frameWidth = frame.size.width;
    CGRect rightRectOfStar = CGRectMake(frame.origin.x + progress * frameWidth, frame.origin.y, frameWidth - progress * frameWidth, frame.size.height);
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectInfinite];
    [clipPath appendPath:[UIBezierPath bezierPathWithRect:rightRectOfStar]];
    clipPath.usesEvenOddFillRule = YES;
    
    [_emptyStarColor setFill];
    [starShapePath fill];
    
    CGContextSaveGState(UIGraphicsGetCurrentContext()); {
        [clipPath addClip];
        [tintColor setFill];
        [starShapePath fill];
    }
    CGContextRestoreGState(UIGraphicsGetCurrentContext());
    
    [self.starBorderColor setStroke];
    starShapePath.lineWidth = _starBorderWidth;
    [starShapePath stroke];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextFillRect(context, rect);
    
    CGFloat availableWidth = rect.size.width - (_spacing * (_maximumValue - 1)) - 2;
    CGFloat cellWidth = (availableWidth / _maximumValue);
    CGFloat starSide = (cellWidth <= rect.size.height) ? cellWidth : rect.size.height;
    starSide = (self.shouldUseImages) ? starSide : (starSide - _starBorderWidth);
    
    for (int idx = 0; idx < _maximumValue; idx++) {
        CGPoint center = CGPointMake(cellWidth*idx + cellWidth/2 + _spacing*idx + 1, rect.size.height/2);
        CGRect frame = CGRectMake(center.x - starSide/2, center.y - starSide/2, starSide, starSide);
        BOOL highlighted = (idx+1 <= ceilf(_value));
        if (_allowsHalfStars && highlighted && (idx+1 > _value)) {
            if (_accurateHalfStars) {
                [self _drawAccurateStarWithFrame:frame tintColor:self.tintColor progress:_value - idx];
            }
            else {
                 [self _drawHalfStarWithFrame:frame tintColor:self.tintColor];
            }
        } else {
            [self _drawStarWithFrame:frame tintColor:self.tintColor highlighted:highlighted];
        }
    }
}

- (void)_drawStarWithFrame:(CGRect)frame tintColor:(UIColor *)tintColor highlighted:(BOOL)highlighted {
    if (self.shouldUseImages) {
        [self _drawStarImageWithFrame:frame tintColor:tintColor highlighted:highlighted];
    } else {
        [self _drawStarShapeWithFrame:frame tintColor:tintColor highlighted:highlighted];
    }
}

- (void)_drawHalfStarWithFrame:(CGRect)frame tintColor:(UIColor *)tintColor {
    if (self.shouldUseImages) {
        [self _drawHalfStarImageWithFrame:frame tintColor:tintColor];
    } else {
        [self _drawHalfStarShapeWithFrame:frame tintColor:tintColor];
    }
}
- (void)_drawAccurateStarWithFrame:(CGRect)frame tintColor:(UIColor *)tintColor progress:(CGFloat)progress {
    if (self.shouldUseImages) {
        [self _drawAccurateHalfStarImageWithFrame:frame tintColor:tintColor progress:progress];
    } else {
        [self _drawAccurateHalfStarShapeWithFrame:frame tintColor:tintColor progress:progress];
    }
}
#pragma mark - Touches

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.isEnabled) {
        [super beginTrackingWithTouch:touch withEvent:event];
        if (_shouldBecomeFirstResponder && ![self isFirstResponder]) {
            [self becomeFirstResponder];
        }
        [self _handleTouch:touch];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.isEnabled) {
        [super continueTrackingWithTouch:touch withEvent:event];
        [self _handleTouch:touch];
        return YES;
    } else {
        return NO;
    }
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    if (_shouldBecomeFirstResponder && [self isFirstResponder]) {
        [self resignFirstResponder];
    }
    [self _handleTouch:touch];
    if (!_continuous) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
    if (_shouldBecomeFirstResponder && [self isFirstResponder]) {
        [self resignFirstResponder];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer.view isEqual:self]) {
        return !self.isUserInteractionEnabled;
    }
    return self.shouldBeginGestureRecognizerBlock ? self.shouldBeginGestureRecognizerBlock(gestureRecognizer) : NO;
}

- (void)_handleTouch:(UITouch *)touch {
    CGFloat cellWidth = self.bounds.size.width / _maximumValue;
    CGPoint location = [touch locationInView:self];
    CGFloat value = location.x / cellWidth;
    if (_allowsHalfStars) {
        if (_accurateHalfStars) {
            value = value;
        }
        else {
            if (value+.5f < ceilf(value)) {
                value = floor(value)+.5f;
            } else {
                value = ceilf(value);
            }
        }
    } else {
        value = ceilf(value);
    }
    [self setValue:value sendValueChangedAction:_continuous];
}

#pragma mark - First responder

- (BOOL)canBecomeFirstResponder {
    return _shouldBecomeFirstResponder;
}

#pragma mark - Intrinsic Content Size

- (CGSize)intrinsicContentSize {
    CGFloat height = 44.f;
    return CGSizeMake(_maximumValue * height + (_maximumValue-1) * _spacing, height);
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return [super accessibilityLabel] ?: NSLocalizedString(@"Rating", @"Accessibility label for star rating control.");
}

- (UIAccessibilityTraits)accessibilityTraits {
    return ([super accessibilityTraits] | UIAccessibilityTraitAdjustable);
}

- (NSString *)accessibilityValue {
    return [@(self.value) description];
}

- (BOOL)accessibilityActivate {
    return YES;
}

- (void)accessibilityIncrement {
    CGFloat value = self.value + (self.allowsHalfStars ? .5f : 1.f);
    [self setValue:value sendValueChangedAction:YES];
}

- (void)accessibilityDecrement {
    CGFloat value = self.value - (self.allowsHalfStars ? .5f : 1.f);
    [self setValue:value sendValueChangedAction:YES];
}

@end

@interface ScoreView : UIView
@property (nonatomic, copy) void(^finishButtonBlock)(void);

@end

@interface ScoreView()

@property (nonatomic, weak) HCSStarRatingView *starRatingView;
@property (nonatomic, weak) UIView *line;
@property (nonatomic, weak) UIButton *finishButton;
@property (nonatomic, strong) NSMutableArray *subViewContraints;
@end

@implementation ScoreView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        HCSStarRatingView *starRatingView = [[HCSStarRatingView alloc] init];
        starRatingView.translatesAutoresizingMaskIntoConstraints = NO;
        starRatingView.maximumValue = 5;
        starRatingView.minimumValue = 0;
        starRatingView.value = 2;
        starRatingView.spacing = 20;
        starRatingView.tintColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
        starRatingView.allowsHalfStars = YES;
        [starRatingView addTarget:self action:@selector(starRatingViewDidChangeValue:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:starRatingView];
        _starRatingView = starRatingView;
        
        UIView *line = [UIView new];
        line.translatesAutoresizingMaskIntoConstraints = NO;
        line.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
        [self addSubview:line];
        _line = line;
        
        UIButton *finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        finishButton.translatesAutoresizingMaskIntoConstraints = NO;
        finishButton.backgroundColor = [UIColor whiteColor];
        [finishButton setTitle:@"完成" forState:UIControlStateNormal];
        [finishButton setTitleColor:[UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        [finishButton addTarget:self action:@selector(finishButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:finishButton];
        _finishButton = finishButton;
    }
    return self;
}

- (void)starRatingViewDidChangeValue:(HCSStarRatingView *)starRatingView {
    
}

- (void)finishButtonAction {
    if (self.finishButtonBlock) {
        self.finishButtonBlock();
    }
}

- (void)updateConstraints {
    [super updateConstraints];
    CGFloat lineH = 1.0/[UIScreen mainScreen].scale;
    
    HCSStarRatingView *starRatingView = self.starRatingView;
    UIView *line = self.line;
    UIButton *finishButton = self.finishButton;
    
    NSMutableArray *subViewContraints = [NSMutableArray array];
    if (self.subViewContraints) {
        [NSLayoutConstraint deactivateConstraints:self.subViewContraints];
        subViewContraints = nil;
    }
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:starRatingView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0f constant:40]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:starRatingView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0f constant:-40]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:starRatingView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:0]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:starRatingView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:line attribute:NSLayoutAttributeTop multiplier:1.0f constant:0]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:starRatingView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:50]];

    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0f constant:0]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:finishButton attribute:NSLayoutAttributeTop multiplier:1.0f constant:0]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:lineH]];

    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:finishButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:finishButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0f constant:0]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:finishButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0]];
    [subViewContraints addObject:[NSLayoutConstraint constraintWithItem:finishButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:50]];
    [NSLayoutConstraint activateConstraints:subViewContraints];
    self.subViewContraints = subViewContraints;
}

@end

@interface MyCenterView : UIView

@end

@interface MyCenterView() <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation MyCenterView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [self addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"myCell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"第%zd行",indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.text = @"这是自定义tableView";
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    return cell;
}

- (UITableView *)tableView {
    
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
}

@end

typedef NS_ENUM(NSInteger, FWButtonImagePosition) {
    FWButtonImagePositionLeft   = 0,     // 图片在文字左侧
    FWButtonImagePositionRight  = 1,     // 图片在文字右侧
    FWButtonImagePositionTop    = 2,     // 图片在文字上侧
    FWButtonImagePositionBottom = 3      // 图片在文字下侧
};

IB_DESIGNABLE
@interface FWButton : UIButton

- (instancetype)initWithImagePosition:(FWButtonImagePosition)imagePosition;

#if TARGET_INTERFACE_BUILDER // storyBoard/xib中设置
@property (nonatomic,assign) IBInspectable NSInteger imagePosition; // 图片位置
@property (nonatomic, assign) IBInspectable CGFloat imageTitleSpace; // 图片和文字之间的间距
#else // 纯代码设置
@property (nonatomic) FWButtonImagePosition imagePosition; // 图片位置
@property (nonatomic, assign) CGFloat imageTitleSpace; // 图片和文字之间的间距
#endif


@end

@implementation FWButton

- (instancetype)initWithImagePosition:(FWButtonImagePosition)imagePosition {
    if (self = [super init]) {
        self.imagePosition = imagePosition;
    }
    return self;
}

#pragma mark - system methods

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    _imagePosition = FWButtonImagePositionLeft;
    _imageTitleSpace = 0.0;
}

// 下面这2个方法，我所知道的:
// 在第一次调用titleLabel和imageView的getter方法(懒加载)时,alloc init之前会调用一次(无论有无图片文字都会直接调)，因此，在重写这2个方法时，在方法里面不要使用self.imageView和self.titleLabel，因为这2个控件是懒加载，如果在重写的这2个方法里是第一调用imageView和titleLabel的getter方法, 则会造成死循环
// 在layoutsSubviews中如果文字或图片不为空时会调用, 测试方式：在重写的这两个方法里调用setNeedsLayout(layutSubviews)，发现会造成死循环
// 设置文字图片、改动文字和图片、设置对齐方式，设置内容区域等时会调用，其实设置这些属性，系统是调用了layoutSubviews从而间接的去调用imageRectForContentRect:和titleRectForContentRect:
// ...
- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    // 先获取系统为我们计算好的rect，这样大小图片在左右时我们就不要自己去计算,我门要改变的，仅仅是origin
    CGRect imageRect = [super imageRectForContentRect:contentRect];
    CGRect titleRect = [super titleRectForContentRect:contentRect];
    if (!self.currentTitle) { // 如果没有文字，则图片占据整个button，空格算一个文字
        return imageRect;
    }
    switch (self.imagePosition) {
        case FWButtonImagePositionLeft: { // 图片在左
            imageRect = [self imageRectImageAtLeftForContentRect:contentRect imageRect:imageRect titleRect:titleRect];
        }
            break;
        case FWButtonImagePositionRight: {
            imageRect = [self imageRectImageAtRightForContentRect:contentRect imageRect:imageRect titleRect:titleRect];
        }
            break;
        case FWButtonImagePositionTop: {
            imageRect = [self imageRectImageAtTopForContentRect:contentRect imageRect:imageRect titleRect:titleRect];
        }
            break;
        case FWButtonImagePositionBottom: {
            imageRect = [self imageRectImageAtBottomForContentRect:contentRect imageRect:imageRect titleRect:titleRect];
        }
            break;
    }
    return imageRect;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    CGRect titleRect = [super titleRectForContentRect:contentRect];
    CGRect imageRect = [super imageRectForContentRect:contentRect];
    if (!self.currentImage) {  // 如果没有图片
        return titleRect;
    }
    switch (self.imagePosition) {
        case FWButtonImagePositionLeft: {
            titleRect = [self titleRectImageAtLeftForContentRect:contentRect titleRect:titleRect imageRect:imageRect];
        }
            break;
        case FWButtonImagePositionRight: {
            titleRect = [self titleRectImageAtRightForContentRect:contentRect titleRect:titleRect imageRect:imageRect];
        }
            break;
        case FWButtonImagePositionTop: {
            titleRect = [self titleRectImageAtTopForContentRect:contentRect titleRect:titleRect imageRect:imageRect];
        }
            break;
        case FWButtonImagePositionBottom: {
            titleRect = [self titleRectImageAtBottomForContentRect:contentRect titleRect:titleRect imageRect:imageRect];
        }
            break;
    }
    return titleRect;
    
}

- (void)sizeToFit {
    // 这个super很重要，它能保证下面使用的self.frame的值是系统计算好的结果
    [super sizeToFit];
    
    CGRect myFrame = self.frame;
    switch (self.imagePosition) {
        case FWButtonImagePositionLeft:
        case FWButtonImagePositionRight: // 图片在左右时，在系统计算好的基础上宽度再加间距
            myFrame.size.width = self.frame.size.width + _imageTitleSpace;
            break;
        case FWButtonImagePositionTop:
        case FWButtonImagePositionBottom: {// 图片在上下时，就不能再在系统计算的基础上增减值了，因为系统计算是基于图片在左文字在右时进行的，宽度依赖图片+文字之和，而图片在上下时，宽度应该依赖图片和文字较大的那个
            CGFloat imageFitWidth = self.contentEdgeInsets.left + self.currentImage.size.width + self.contentEdgeInsets.right;
            CGFloat titleFitWidth = self.contentEdgeInsets.left + [self calculateTitleSizeForSystemTitleSize:CGSizeMake(0, 0)].width + self.contentEdgeInsets.right;
            myFrame.size.width = MAX(imageFitWidth, titleFitWidth);
            myFrame.size.height = self.contentEdgeInsets.top + self.currentImage.size.height + [self calculateTitleSizeForSystemTitleSize:CGSizeMake(0, 0)].height + self.contentEdgeInsets.bottom + _imageTitleSpace;
        }
            break;
        default:
            break;
    }
    
    self.frame = myFrame;
}

#pragma - private

// ----------------------------------------------------- left -----------------------------------------------------

- (CGRect)imageRectImageAtLeftForContentRect:(CGRect)contentRect imageRect:(CGRect)imageRect titleRect:(CGRect)titleRect {
    CGPoint imageOrigin = imageRect.origin;
    CGSize imageSize = imageRect.size;
    
    //CGSize titleSize = titleRect.size;
    
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter: // 中心对齐
            // imageView的x值向左偏移间距的一半，另一半由titleLabe分担，不用管会不会超出contentRect，我定的规则是允许超出，如果对此作出限制，那么必须要对图片或者文字宽高有所压缩，压缩只能由imageEdgeInsets决定，当图片的内容区域容不下时才产生宽度压缩
            imageOrigin.x = imageOrigin.x - _imageTitleSpace*0.5;
            break;
        case UIControlContentHorizontalAlignmentRight:
        case UIControlContentHorizontalAlignmentTrailing: // 右对齐
            imageOrigin.x = imageOrigin.x - _imageTitleSpace;
            break;
        case UIControlContentHorizontalAlignmentFill: // 填充整个按钮,水平填充模式有点怪异，填充的意思是将图片和文字整个水平填满，但是，事实上能够被填满，但是titleLabel的x值不会发生变化，即图片被拉伸，但是图片的右边会预留一个titleLabel的宽度，这个titleLabel的宽度由系统计算，我们不必关心计算过程。还有，填充模式下，设置图片的contentMode是不管用的，因为系统强制设置了图片的大小
            imageOrigin.x = imageOrigin.x - _imageTitleSpace*0.5;
            break;
        default: // 剩下的就是左对齐，左对齐image不用做任何改变
            break;
    }
    imageRect.size = imageSize;
    imageRect.origin = imageOrigin;
    return imageRect;
}

- (CGRect)titleRectImageAtLeftForContentRect:(CGRect)contentRect titleRect:(CGRect)titleRect imageRect:(CGRect)imageRect {
    CGPoint titleOrigin = titleRect.origin;
    CGSize titleSize = titleRect.size;
    
    //CGSize imageSize = imageRect.size;
    
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter: { // 中心对齐
            titleOrigin.x = titleOrigin.x + _imageTitleSpace * 0.5;
        }
            break;
        case UIControlContentHorizontalAlignmentLeft:
        case UIControlContentHorizontalAlignmentLeading: { // 左对齐
            titleOrigin.x = titleOrigin.x + _imageTitleSpace;
        }
            break;
        case UIControlContentHorizontalAlignmentFill: // 填充整个按钮
            // 填充整个按钮,水平填充模式有点怪异，填充的意思是将图片和文字整个水平填满，但是，事实上能够被填满，但是titleLabel的x值不会发生变化，即图片被拉伸，但是图片的右边会预留一个titleLabel的宽度，这个titleLabel的宽度由系统计算，我们不必关心计算过程。还有，填充模式下，设置图片的contentMode是不管用的，因为系统强制设置了图片的大小
            // 宽度减去间距的一半，另一半由imageView分担,x值保持系统值
            titleOrigin.x = titleOrigin.x + _imageTitleSpace * 0.5;
            break;
        default: // 剩下的就是右对齐，右对齐titleLabel不用做任何改变
            break;
    }
    
    titleRect.size = titleSize;
    titleRect.origin = titleOrigin;
    return titleRect;
}

// ----------------------------------------------------- right -----------------------------------------------------

- (CGRect)imageRectImageAtRightForContentRect:(CGRect)contentRect imageRect:(CGRect)imageRect titleRect:(CGRect)titleRect {
    
    CGFloat imageSafeWidth = contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right;
    if (imageRect.size.width >= imageSafeWidth) {
        return imageRect;
    }
    
    CGPoint imageOrigin = imageRect.origin;
    CGSize imageSize = imageRect.size;
    CGSize titleSize = titleRect.size;
    
    // 这里水平中心对齐，跟图片在右边时的中心对齐时差别在于：图片在右边时中心对齐考虑了titleLabel+imageView这个整体，而这里只单独考虑imageView
    if (imageSize.width + titleSize.width > imageSafeWidth) {
        imageSize.width = imageSize.width - (imageSize.width + titleSize.width - imageSafeWidth);
    }
    
    CGFloat buttonWidth = contentRect.size.width + self.contentEdgeInsets.left + self.contentEdgeInsets.right;
    titleSize = [self calculateTitleSizeForSystemTitleSize:titleSize];
    
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter: // 中心对齐
            // (contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right - (imageSize.width + titleSize.width))/2.0+titleSize.width指的是imageView在其有效区域内联合titleLabel整体居中时的x值，有效区域指的是contentRect内缩imageEdgeInsets后的区域
            imageOrigin.x = (contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right - (imageSize.width + titleSize.width))/2.0 + titleSize.width + self.contentEdgeInsets.left + self.imageEdgeInsets.left + _imageTitleSpace * 0.5;
            break;
        case UIControlContentHorizontalAlignmentLeft:
        case UIControlContentHorizontalAlignmentLeading: // 左对齐
            imageOrigin.x = self.contentEdgeInsets.left + self.imageEdgeInsets.left + titleSize.width + _imageTitleSpace;
            break;
        case UIControlContentHorizontalAlignmentRight:
        case UIControlContentHorizontalAlignmentTrailing: // 右对齐
            // 注意image的大小要使用系统计算的结果，这里不能使用self.currentImage.size.width，当imageEdgeInsets的left过大时可以进行测试
            imageOrigin.x = buttonWidth - imageSize.width - self.imageEdgeInsets.right - self.contentEdgeInsets.right;
            break;
        case UIControlContentHorizontalAlignmentFill: // 填充
            imageOrigin.x = buttonWidth - imageSize.width - self.imageEdgeInsets.right - self.contentEdgeInsets.right + _imageTitleSpace * 0.5;
            break;
    }
    imageRect.size = imageSize;
    imageRect.origin = imageOrigin;
    return imageRect;
}

- (CGRect)titleRectImageAtRightForContentRect:(CGRect)contentRect titleRect:(CGRect)titleRect imageRect:(CGRect)imageRect {
    
    CGPoint titleOrigin = titleRect.origin;
    CGSize titleSize = titleRect.size;
    CGSize imageSize = imageRect.size;
    
    CGFloat buttonWidth = contentRect.size.width + self.contentEdgeInsets.left + self.contentEdgeInsets.right;
    
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter: // 中心对齐
            // (contentRect.size.width - self.titleEdgeInsets.left - self.titleEdgeInsets.right - (imageSize.width + titleSize.width))/2.0的意思是titleLabel在其有效区域内联合imageView整体居中时的x值，有效区域指的是contentRect内缩titleEdgeInsets后的区域
            titleOrigin.x = (contentRect.size.width - self.titleEdgeInsets.left - self.titleEdgeInsets.right - (imageSize.width + titleSize.width))/2.0 + self.contentEdgeInsets.left + self.titleEdgeInsets.left - _imageTitleSpace * 0.5;
            break;
        case UIControlContentHorizontalAlignmentLeft:
        case UIControlContentHorizontalAlignmentLeading: // 左对齐
            titleOrigin.x = self.contentEdgeInsets.left + self.titleEdgeInsets.left;
            break;
        case UIControlContentHorizontalAlignmentRight:
        case UIControlContentHorizontalAlignmentTrailing: // 右对齐
            // 这里必须使用self.currentImage的宽度。不能使用imageSize.width，因为图片可能会被压缩或者拉伸，例如当图片的imageEdgeInsets的right设置过大，图片的宽度就会被压缩，这时的图片宽度不是我们要的
            titleOrigin.x = buttonWidth - (titleSize.width + self.currentImage.size.width) - self.titleEdgeInsets.right - self.contentEdgeInsets.right - _imageTitleSpace;
            break;
        case UIControlContentHorizontalAlignmentFill:
            titleOrigin.x = buttonWidth - (titleSize.width + self.currentImage.size.width) - self.titleEdgeInsets.right - self.contentEdgeInsets.right - _imageTitleSpace * 0.5;
            break;
    }
    titleRect.size = titleSize;
    titleRect.origin = titleOrigin;
    return titleRect;
}

// ----------------------------------------------------- top -----------------------------------------------------

- (CGRect)imageRectImageAtTopForContentRect:(CGRect)contentRect imageRect:(CGRect)imageRect titleRect:(CGRect)titleRect {
    CGPoint imageOrigin = imageRect.origin;
    CGSize imageSize = self.currentImage.size;
    CGSize titleSize = [self calculateTitleSizeForSystemTitleSize:titleRect.size];
    
    CGFloat imageSafeWidth = contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right;
    CGFloat imageSafeHeight = contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom;
    
    // 这里水平中心对齐，跟图片在右边时的中心对齐时差别在于：图片在右边时中心对齐考虑了titleLabel+imageView这个整体，而这里只单独考虑imageView
    if (imageSize.width > imageSafeWidth) {
        imageSize.width = imageSafeWidth;
    }
    if (imageSize.height > imageSafeHeight) {
        imageSize.height = imageSafeHeight;
    }
    
    CGFloat buttonWidth = contentRect.size.width + self.contentEdgeInsets.left + self.contentEdgeInsets.right;
    CGFloat buttonHeight = contentRect.size.height + self.contentEdgeInsets.top + self.contentEdgeInsets.bottom;
    
    // 水平方向
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter: {// 中心对齐
            imageOrigin.x = (contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right - imageSize.width) / 2.0 + self.contentEdgeInsets.left + self.imageEdgeInsets.left;
        }
            break;
        case UIControlContentHorizontalAlignmentLeft:
        case UIControlContentHorizontalAlignmentLeading: // 左对齐
            imageOrigin.x = self.contentEdgeInsets.left + self.imageEdgeInsets.left;
            break;
        case UIControlContentHorizontalAlignmentRight:
        case UIControlContentHorizontalAlignmentTrailing: // 右对齐
            imageOrigin.x = buttonWidth - imageSize.width - self.imageEdgeInsets.right - self.contentEdgeInsets.right;
            break;
        case UIControlContentHorizontalAlignmentFill: // 填充
            imageOrigin.x = self.contentEdgeInsets.left + self.imageEdgeInsets.left;
            imageSize.width = imageSafeWidth; // 宽度填满
            break;
    }
    
    // 给图片高度作最大限制，超出限制对高度进行压缩，这样还可以保证titeLabel不会超出其有效区域
    CGFloat imageTitleLimitMaxH = contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom;
    if (imageSize.height < imageTitleLimitMaxH) {
        if (titleSize.height + imageSize.height > imageTitleLimitMaxH) {
            CGFloat beyondValue = titleSize.height + self.currentImage.size.height - imageTitleLimitMaxH;
            imageSize.height = imageSize.height - beyondValue;
        }
    }
    
    // 垂直方向
    switch (self.contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter: // 中心对齐
            // (imageSize.height + titleSize.height)这个整体高度很重要，这里相当于按照按钮原有规则进行对齐，即按钮的对齐方式不管是设置谁的insets，计算时都是以图片+文字这个整体作为考虑对象
            imageOrigin.y =  (contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom - (imageSize.height + titleSize.height)) / 2.0 + self.contentEdgeInsets.top + self.imageEdgeInsets.top - _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentTop: // 顶部对齐
            imageOrigin.y = self.contentEdgeInsets.top + self.imageEdgeInsets.top - _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentBottom: // 底部对齐
            imageOrigin.y = buttonHeight - (imageSize.height + titleSize.height) - self.contentEdgeInsets.bottom - self.imageEdgeInsets.bottom - _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentFill: // 填充
            imageOrigin.y = self.contentEdgeInsets.top + self.imageEdgeInsets.top - _imageTitleSpace * 0.5;
            imageSize.height = contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom - [self calculateTitleSizeForSystemTitleSize:titleSize].height;
            break;
    }
    imageRect.size = imageSize;
    imageRect.origin = imageOrigin;
    return imageRect;
}

- (CGRect)titleRectImageAtTopForContentRect:(CGRect)contentRect titleRect:(CGRect)titleRect imageRect:(CGRect)imageRect {
    CGPoint titleOrigin = titleRect.origin;
    CGSize imageSize = self.currentImage.size;
    CGSize titleSize = [self calculateTitleSizeForSystemTitleSize:titleRect.size];
    
    CGFloat buttonWidth = contentRect.size.width + self.contentEdgeInsets.left + self.contentEdgeInsets.right;
    CGFloat buttonHeight = contentRect.size.height + self.contentEdgeInsets.top + self.contentEdgeInsets.bottom;
    
    // 这个if语句的含义是：计算图片由于设置了contentEdgeInsets而被压缩的高度，设置imageEdgeInsets被压缩的高度不计算在内。这样做的目的是，当设置了contentEdgeInsets时，图片可能会被压缩，此时titleLabel的y值依赖于图片压缩后的高度，当设置了imageEdgeInsets时，图片也可能被压缩，此时titleLabel的y值依赖于图片压缩前的高度，这样以来，设置imageEdgeInsets就不会对titleLabel的y值产生影响
    if (imageSize.height + titleSize.height > contentRect.size.height) {
        imageSize.height = self.currentImage.size.height - (self.currentImage.size.height + titleSize.height - contentRect.size.height);
    }
    // titleLabel的安全宽度，这里一定要改变宽度值，因为当外界设置了titleEdgeInsets值时，系统计算出来的所有值都是在”左图右文“的基础上进行的，这个基础上可能会导致titleLabel的宽度被压缩，所以我们在此自己重新计算
    CGFloat titleSafeWidth = contentRect.size.width - self.titleEdgeInsets.left - self.titleEdgeInsets.right;
    if (titleSize.width > titleSafeWidth) {
        titleSize.width = titleSafeWidth;
    }
    
    // 水平方向
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter: {// 中心对齐
            
            titleOrigin.x = (titleSafeWidth - titleSize.width) / 2.0 + self.contentEdgeInsets.left + self.titleEdgeInsets.left;
        }
            break;
        case UIControlContentHorizontalAlignmentLeft:
        case UIControlContentHorizontalAlignmentLeading: // 左对齐
            titleOrigin.x = self.contentEdgeInsets.left + self.titleEdgeInsets.left;
            break;
        case UIControlContentHorizontalAlignmentRight:
        case UIControlContentHorizontalAlignmentTrailing: // 右对齐
            titleOrigin.x = buttonWidth - titleSize.width - self.titleEdgeInsets.right - self.contentEdgeInsets.right;
            break;
        case UIControlContentHorizontalAlignmentFill: // 填充
            titleOrigin.x = self.contentEdgeInsets.left + self.titleEdgeInsets.left;
            // titleLabel宽度上不填充,按系统一样，在有效区域内，自适应文字宽度
            break;
    }
    
    if (titleSize.height > contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom) {
        titleSize.height = contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom;
    }
    
    // 垂直方向
    switch (self.contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter: {// 中心对齐
            // (imageSize.height + titleSize.height)这个整体高度很重要，这里相当于按照按钮原有规则进行对齐，即按钮的对齐方式不管是设置谁的Insets，计算时都是以图片+文字这个整体作为考虑对象
            titleOrigin.y =  (contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom - (imageSize.height + titleSize.height)) / 2.0 + imageSize.height + self.contentEdgeInsets.top + self.titleEdgeInsets.top + _imageTitleSpace * 0.5;
        }
            break;
        case UIControlContentVerticalAlignmentTop: // 顶部对齐
            titleOrigin.y = self.contentEdgeInsets.top + self.titleEdgeInsets.top + imageSize.height + _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentBottom: // 底部对齐
            titleOrigin.y = buttonHeight - titleSize.height - self.contentEdgeInsets.bottom - self.titleEdgeInsets.bottom+ _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentFill: // 填充
            titleOrigin.y = buttonHeight - titleSize.height - self.contentEdgeInsets.bottom - self.titleEdgeInsets.bottom + _imageTitleSpace * 0.5;
            break;
    }
    
    titleRect.size = titleSize;
    titleRect.origin = titleOrigin;
    return titleRect;
}

// ----------------------------------------------------- bottom -----------------------------------------------------

- (CGRect)imageRectImageAtBottomForContentRect:(CGRect)contentRect imageRect:(CGRect)imageRect titleRect:(CGRect)titleRect {
    CGPoint imageOrigin = imageRect.origin;
    CGSize imageSize = self.currentImage.size;
    CGSize titleSize = [self calculateTitleSizeForSystemTitleSize:titleRect.size];
    
    CGFloat imageSafeWidth = contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right;
    CGFloat imageSafeHeight = contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom;
    
    // 这里水平中心对齐，跟图片在右边时的中心对齐时差别在于：图片在右边时中心对齐考虑了titleLabel+imageView这个整体，而这里只单独考虑imageView
    if (imageSize.width > imageSafeWidth) {
        imageSize.width = imageSafeWidth;
    }
    if (imageSize.height > imageSafeHeight) {
        imageSize.height = imageSafeHeight;
    }
    
    CGFloat buttonWidth = contentRect.size.width + self.contentEdgeInsets.left + self.contentEdgeInsets.right;
    CGFloat buttonHeight = contentRect.size.height + self.contentEdgeInsets.top + self.contentEdgeInsets.bottom;
    
    // 水平方向
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter: {// 中心对齐
            imageOrigin.x = (contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right - imageSize.width) / 2.0 + self.contentEdgeInsets.left + self.imageEdgeInsets.left;
        }
            break;
        case UIControlContentHorizontalAlignmentLeft:
        case UIControlContentHorizontalAlignmentLeading: // 左对齐
            imageOrigin.x = self.contentEdgeInsets.left + self.imageEdgeInsets.left;
            break;
        case UIControlContentHorizontalAlignmentRight:
        case UIControlContentHorizontalAlignmentTrailing: // 右对齐
            imageOrigin.x = buttonWidth - imageSize.width - self.imageEdgeInsets.right - self.contentEdgeInsets.right;
            break;
        case UIControlContentHorizontalAlignmentFill: // 填充
            imageOrigin.x = self.contentEdgeInsets.left + self.imageEdgeInsets.left;
            imageSize.width = imageSafeWidth; // 宽度填满
            break;
    }
    
    // 给图片高度作最大限制，超出限制对高度进行压缩，这样还可以保证titeLabel不会超出其有效区域
    CGFloat imageTitleLimitMaxH = contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom;
    if (imageSize.height < imageTitleLimitMaxH) {
        if (titleSize.height + imageSize.height > imageTitleLimitMaxH) {
            CGFloat beyondValue = titleSize.height + self.currentImage.size.height - imageTitleLimitMaxH;
            imageSize.height = imageSize.height - beyondValue;
        }
    }
    // 垂直方向
    switch (self.contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter: // 中心对齐
            // (self.currentImage.size.height + titleSize.height)这个整体高度很重要，这里相当于按照按钮原有规则进行对齐，即按钮的对齐方式不管是设置谁的insets，计算时都是以图片+文字这个整体作为考虑对象
            imageOrigin.y =  (contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom - (imageSize.height + titleSize.height)) / 2.0 + titleSize.height + self.contentEdgeInsets.top + self.imageEdgeInsets.top + _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentTop: // 顶部对齐
            imageOrigin.y = self.contentEdgeInsets.top + self.imageEdgeInsets.top + titleSize.height + _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentBottom: // 底部对齐
            imageOrigin.y = buttonHeight - imageSize.height - self.contentEdgeInsets.bottom - self.imageEdgeInsets.bottom + _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentFill: // 填充
            // 这里不能使用titleSize.height,因为垂直填充模式下，系统计算出的titleSize就是contentRect的高度，我们需要的是titleLabel拉伸前的高度
            imageSize.height = contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom - [self calculateTitleSizeForSystemTitleSize:titleSize].height;
            imageOrigin.y = buttonHeight - imageSize.height - self.contentEdgeInsets.bottom - self.imageEdgeInsets.bottom + _imageTitleSpace * 0.5;
            break;
    }
    
    imageRect.size = imageSize;
    imageRect.origin = imageOrigin;
    return imageRect;
}

- (CGRect)titleRectImageAtBottomForContentRect:(CGRect)contentRect titleRect:(CGRect)titleRect imageRect:(CGRect)imageRect {
    CGPoint titleOrigin = titleRect.origin;
    CGSize imageSize = self.currentImage.size;
    CGSize titleSize = [self calculateTitleSizeForSystemTitleSize:titleRect.size];
    
    // 这个if语句的含义是：计算图片由于设置了contentEdgeInsets而被压缩的高度，设置imageEdgeInsets被压缩的高度不计算在内。这样做的目的是，当设置了contentEdgeInsets时，图片可能会被压缩，此时titleLabel的y值依赖于图片压缩后的高度，当设置了imageEdgeInsets时，图片也可能被压缩，此时titleLabel的y值依赖于图片压缩前的高度，这样一来，设置imageEdgeInsets就不会对titleLabel的y值产生影响
    if (self.currentImage.size.height + titleSize.height > contentRect.size.height) {
        imageSize.height = self.currentImage.size.height - (self.currentImage.size.height + titleSize.height - contentRect.size.height);
    }
    
    // titleLabel的安全宽度，因为当外界设置了titleEdgeInsets值时，系统计算出来的所有值都是在”左图右文“的基础上进行的，这个基础上可能会导致titleLabel的宽度被压缩，所以我们在此自己重新计算
    CGFloat titleSafeWidth = contentRect.size.width - self.titleEdgeInsets.left - self.titleEdgeInsets.right;
    if (titleSize.width > titleSafeWidth) {
        titleSize.width = titleSafeWidth;
    }
    
    CGFloat buttonWidth = contentRect.size.width + self.contentEdgeInsets.left + self.contentEdgeInsets.right;
    CGFloat buttonHeight = contentRect.size.height + self.contentEdgeInsets.top + self.contentEdgeInsets.bottom;
    
    // 水平方向
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter: {// 中心对齐
            titleOrigin.x = (titleSafeWidth - titleSize.width) / 2.0 + self.contentEdgeInsets.left + self.titleEdgeInsets.left;
        }
            break;
        case UIControlContentHorizontalAlignmentLeft:
        case UIControlContentHorizontalAlignmentLeading: // 左对齐
            titleOrigin.x = self.contentEdgeInsets.left + self.titleEdgeInsets.left;
            break;
        case UIControlContentHorizontalAlignmentRight:
        case UIControlContentHorizontalAlignmentTrailing: // 右对齐
            titleOrigin.x = buttonWidth - titleSize.width - self.titleEdgeInsets.right - self.contentEdgeInsets.right;
            break;
        case UIControlContentHorizontalAlignmentFill: // 填充
            titleOrigin.x = self.contentEdgeInsets.left + self.titleEdgeInsets.left;
            // titleLabel宽度上不填充,按系统一样，在有效区域内，自适应文字宽度
            break;
    }
    
    if (titleSize.height > contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom) {
        titleSize.height = contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom;
    }
    
    // 垂直方向
    switch (self.contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter: // 中心对齐
            // (self.currentImage.size.height + titleSize.height)这个整体高度很重要，这里相当于按照按钮原有规则进行对齐，即按钮的对齐方式不管是设置谁的Insets，计算时都是以图片+文字这个整体作为考虑对象
            titleOrigin.y =  (contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom - (imageSize.height + titleSize.height)) / 2.0 + self.contentEdgeInsets.top + self.titleEdgeInsets.top - _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentTop: // 顶部对齐
            titleOrigin.y = self.contentEdgeInsets.top + self.titleEdgeInsets.top - _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentBottom: // 底部对齐
            titleOrigin.y = buttonHeight - (titleSize.height + imageSize.height) - self.contentEdgeInsets.bottom - self.titleEdgeInsets.bottom - _imageTitleSpace * 0.5;
            break;
        case UIControlContentVerticalAlignmentFill: // 填充
            titleOrigin.y = self.contentEdgeInsets.top + self.titleEdgeInsets.top - _imageTitleSpace * 0.5;
            break;
    }
    
    titleRect.size = titleSize;
    titleRect.origin = titleOrigin;
    return titleRect;
}

// 自己计算titleLabel的大小
- (CGSize)calculateTitleSizeForSystemTitleSize:(CGSize)titleSize {
    CGSize myTitleSize = titleSize;
    // 获取按钮里的titleLabel,之所以遍历获取而不直接调用self.titleLabel，是因为假如这里是第一次调用self.titleLabel，则会跟titleRectForContentRect: 方法造成死循环,titleLabel的getter方法中，alloc init之前调用了titleRectForContentRect:
    UILabel *titleLabel = [self findTitleLabel];
    if (!titleLabel) { // 此时还没有创建titleLabel，先通过系统button的字体进行文字宽度计算
        CGFloat fontSize = [UIFont buttonFontSize]; // 按钮默认字体，18号
        // 说明外界使用了被废弃的font属性，被废弃但是依然生效
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (self.font.pointSize != [UIFont buttonFontSize]) {
            fontSize = self.font.pointSize;
        }
#pragma clang diagnostic pop
        myTitleSize.height = ceil([self.currentTitle boundingRectWithSize:CGSizeMake(titleSize.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size.height);
        // 根据文字计算宽度，取上整，补齐误差，保证跟titleLabel.intrinsicContentSize.width一致
        myTitleSize.width = ceil([self.currentTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, titleSize.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size.width);
    } else { // 说明此时titeLabel已经产生，直接取titleLabel的内容宽度
        myTitleSize.width = titleLabel.intrinsicContentSize.width;
        myTitleSize.height = titleLabel.intrinsicContentSize.height;
    }
    return myTitleSize;
}

// 遍历获取按钮里面的titleLabel
- (UILabel *)findTitleLabel {
    for (UIView *subView in self.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"UIButtonLabel")]) {
            UILabel *titleLabel = (UILabel *)subView;
            return titleLabel;
        }
    }
    return nil;
}



#pragma mark - setter
// 以下所有setter方法中都调用了layoutSubviews, 其实是为了间接的调用imageRectForContentRect:和titleRectForContentRect:，不能直接调用imageRectForContentRect:和titleRectForContentRect:,因为按钮的子控件布局最终都是通过调用layoutSubviews而确定，如果直接调用这两个方法，那么只能保证我们能够获取的CGRect是对的，但并不会作用在titleLabel和imageView上
- (void)setImagePosition:(FWButtonImagePosition)imagePosition {
    _imagePosition = imagePosition;
    [self setNeedsLayout];
}

- (void)setImageTitleSpace:(CGFloat)imageTitleSpace {
    _imageTitleSpace = imageTitleSpace;
    [self setNeedsLayout];
}

- (void)setContentHorizontalAlignment:(UIControlContentHorizontalAlignment)contentHorizontalAlignment {
    [super setContentHorizontalAlignment:contentHorizontalAlignment];
    [self setNeedsLayout];
}

// 垂直方向的排列方式在设置之前如果调用了titleLabel或imageView的getter方法，则设置后不会生效，点击一下按钮之后就生效了，这应该属于按钮的一个小bug，我们只要重写它的setter方法重新布局一次就好
- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment {
    [super setContentVerticalAlignment:contentVerticalAlignment];
    [self setNeedsLayout];
}

@end

@interface PopView : UIView

- (instancetype)initWithImages:(NSArray<NSString *> *)images
                        titles:(NSArray<NSString *> *)titles
            clickedButtonBlock:(void(^)(NSInteger index))clickedButtonBlock
                   cancelBlock:(void(^)(PopView *popView))cancelBlock;

@property (nonatomic, copy) void(^tapBackgroundBlock)(PopView *popView);

- (void)open;

- (void)close;

@end

static NSInteger const kColumnCount = 4; // 每一页的列数
static NSInteger const kRowCount = 2; // 每一页的行数
static CGFloat const kColSpacing = 15; // 列间距
static CGFloat const kRowSpacing = 20; // 行间距
static NSTimeInterval kAnimationDuration = 0.7; // 动画总时长
static NSTimeInterval kDelay = 0.0618; // 按钮接着上一个按钮的延时时间

@interface PopView() <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, copy) void (^clickedButtonBlock)(NSInteger);
@property (nonatomic, copy) void (^cancelBlock)(PopView *popView);
@end

@implementation PopView
{
    NSInteger buttonCount;
}

- (instancetype)initWithImages:(NSArray<NSString *> *)images
                        titles:(NSArray<NSString *> *)titles
                  clickedButtonBlock:(void (^)(NSInteger))clickedButtonBlock
                   cancelBlock:(void (^)(PopView *popView))cancelBlock {
    
    _clickedButtonBlock = clickedButtonBlock;
    _cancelBlock = cancelBlock;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self addGestureRecognizer:tap];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (self = [self initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)]) {
        buttonCount = MIN(images.count, titles.count);
        for (int i = 0; i < buttonCount; i++) {
            FWButton *button = [[FWButton alloc] initWithImagePosition:FWButtonImagePositionTop];
            [button setImage:[TestBundle imageNamed:images[i]] forState:UIControlStateNormal];
            [button setTitle:titles[i] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:14];
            [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            button.imageView.contentMode = UIViewContentModeScaleAspectFit;
            button.imageTitleSpace = 5;
            [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
            button.tag = i+100;
            [self.scrollView addSubview:button];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)open {

    for (int i = 0; i < buttonCount; i++) {
        FWButton *button = [self.scrollView viewWithTag:i+100];
        CGFloat buttonH = button.bounds.size.height;
        CGFloat totalH = (buttonH * kRowCount + kRowSpacing * (kRowCount - 1));
        CGFloat buttonEndY = button.frame.origin.y - totalH - buttonH;
        // delay参数计算出来的意思是：每一列比它的上一列延时kDelay秒
        [UIView animateWithDuration:kAnimationDuration
                              delay:i % kColumnCount * kDelay
             usingSpringWithDamping:0.6
              initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseIn animations:^{
                                CGRect buttonFrame = button.frame;
                                buttonFrame.origin.y = buttonEndY;
                                button.frame = buttonFrame;
                            } completion:^(BOOL finished) {
                            }];
    }
}

- (void)close {
    for (int i = 0; i < buttonCount; i++) {
        FWButton *button = [self.scrollView viewWithTag:i+100];
        CGFloat buttonH = button.bounds.size.height;
        CGFloat totalH = (buttonH * kRowCount + kRowSpacing * (kRowCount - 1));
        CGFloat buttonBeginY = button.frame.origin.y + buttonH + totalH;
        
        // delay参数计算出来的意思是：第一行每个按钮都比第二行的每个按钮延时0.1秒,同时每列比它的下一列延时kDelay秒
        [UIView animateWithDuration:kAnimationDuration
                              delay:(1-i/kColumnCount)/10.0 + (kDelay * kColumnCount - i % kColumnCount * kDelay - kDelay)
             usingSpringWithDamping:0.6
              initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseOut animations:^{
                                CGRect buttonFrame = button.frame;
                                buttonFrame.origin.y = buttonBeginY;
                                button.frame = buttonFrame;
                            } completion:^(BOOL finished) {
                                [self removeFromSuperview];
                            }];
    }
}

- (void)buttonAction:(UIButton *)sender {
    if (self.clickedButtonBlock) {
        self.clickedButtonBlock(sender.tag-100);
    }
}

- (void)tapAction {
    if (self.tapBackgroundBlock) {
        self.tapBackgroundBlock(self);
    }
}

- (void)cancelButtonAction {
    if (self.cancelBlock) {
        self.cancelBlock(self);
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    self.pageControl.currentPage = (NSInteger)(offsetX / self.bounds.size.width + 0.5);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat bottom = 0;
    if (@available(iOS 11.0, *)) {
        bottom = self.safeAreaInsets.bottom;
    }
    
    CGFloat superWidth = self.frame.size.width;
    CGFloat superHeight = self.frame.size.height;
    
    CGFloat cancelButtonW = superWidth;
    CGFloat cancelButtonH = 40;
    CGFloat cancelButtonX = 0;
    CGFloat cancelButtonY = superHeight-cancelButtonH-bottom;
    self.cancelButton.frame = CGRectMake(cancelButtonX, cancelButtonY, cancelButtonW, cancelButtonH);
    
    CGFloat lineW = superWidth;
    CGFloat lineH = 1.0/[UIScreen mainScreen].scale;
    CGFloat lineX = 0;
    CGFloat lineY = superHeight-cancelButtonH-lineH-bottom;
    self.line.frame = CGRectMake(lineX, lineY, lineW, lineH);
    
    CGFloat scrollViewH = superHeight-cancelButtonH-lineH-bottom;
    self.scrollView.frame = CGRectMake(0, 0, superWidth, scrollViewH);
    self.pageControl.frame = CGRectMake(0, superHeight-cancelButtonH-lineH-bottom-30, superWidth, 30);
    
    // 先计算好每个按钮的动画前的frame，等执行动画的时候只要改变y值即可
    NSInteger buttonCountEveryPage = kColumnCount * kRowCount; // 每一页的按钮个数
    NSInteger pageCount = (buttonCount-1) / buttonCountEveryPage + 1; // 总页数
    self.pageControl.numberOfPages = pageCount;

    for (int i = 0; i < buttonCount; i++) {
        FWButton *button = [self.scrollView viewWithTag:i+100];
        NSInteger page = i / buttonCountEveryPage; // 第几页
        NSInteger row = (i - buttonCountEveryPage * page) / kColumnCount; // 第几页的第几行
        NSInteger col = i % kColumnCount; // 第几列
        CGFloat buttonW = (superWidth - kColSpacing * (kColumnCount + 1)) / kColumnCount;
        CGFloat buttonH = MIN(buttonW, button.currentImage.size.width)+30;
        CGFloat buttonX = kColSpacing + (buttonW + kColSpacing) * col + page * superWidth;
        CGFloat buttonBeginY = scrollViewH + (buttonH + kRowSpacing) * row;
        button.frame = CGRectMake(buttonX, buttonBeginY, buttonW, buttonH);
    }
    self.scrollView.contentSize = CGSizeMake(superWidth * pageCount, 0);
}

- (UIScrollView *)scrollView {
    
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.scrollsToTop = NO;
        _scrollView.bounces = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.delegate = self;
        [self addSubview:_scrollView];
    }
    return _scrollView;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.currentPageIndicatorTintColor = [UIColor orangeColor];
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        [self addSubview:_pageControl];
    }
    return _pageControl;
}

- (UIButton *)cancelButton {
    
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.backgroundColor = [UIColor clearColor];
        [_cancelButton setImage:[UIImage imageNamed:@"取消"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cancelButton];
    }
    return _cancelButton;
}

- (UIView *)line {
    
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
        [self addSubview:_line];
    }
    return _line;
}

@end

// RGB颜色
#define FWColorRGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define SYSTEM_COLOR [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]

// 随机色
#define FWRandomColor ZCColorRGBA(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256),1)

@interface TestCustomerAlertController () <FWTableViewController>

@property (nonatomic, assign) BOOL lookBlur;

@end

@implementation TestCustomerAlertController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderData
{
    NSArray *tableData = @[
        @[@"actionSheet样式 默认动画(从底部弹出,有取消按钮)", @"actionSheetTest1"],
        @[@"actionSheet样式 默认动画(从底部弹出,无取消按钮)", @"actionSheetTest2"],
        @[@"actionSheet样式 从顶部弹出(无标题)", @"actionSheetTest3"],
        @[@"actionSheet样式 从顶部弹出(有标题)", @"actionSheetTest4"],
        @[@"actionSheet样式 水平排列（有取消样式按钮）", @"actionSheetTest5"],
        @[@"actionSheet样式 水平排列（无取消样式按钮)", @"actionSheetTest6"],
        @[@"actionSheet样式 action含图标", @"actionSheetTest7"],
        @[@"actionSheet样式 模拟多分区样式(>=iOS11才支持)", @"actionSheetTest8"],
        
        @[@"alert样式 默认动画(收缩动画)", @"alertTest1"],
        @[@"alert样式 发散动画", @"alertTest2"],
        @[@"alert样式 渐变动画", @"alertTest3"],
        @[@"alert样式 垂直排列2个按钮", @"alertTest4"],
        @[@"alert样式 水平排列2个以上的按钮", @"alertTest5"],
        @[@"alert样式 设置头部图标", @"alertTest6"],
        @[@"alert样式 含有文本输入框", @"alertTest7"],
        @[@"alert样式 自定义头部视图", @"alertTest8"],
        
        @[@"富文本(action设置富文本)", @"attributedStringTest1"],
        @[@"富文本(头部设置富文本)", @"attributedStringTest2"],
        
        @[@"自定义整个对话框(actionSheet样式(顶))", @"customTest1"],
        @[@"自定义整个对话框(pickerView)", @"customTest2"],
        @[@"自定义action部分", @"customTest3"],
        @[@"插入一个组件", @"customTest4"],
        @[@"自定义整个对话框(全屏)", @"customTest5"],
        
        @[@"当按钮过多时，以scrollView滑动", @"specialtest1"],
        @[@"当文字和按钮同时过多时,二者都可滑动", @"specialtest2"],
        @[@"含有文本输入框，且文字过多", @"specialtest3"],
        @[@"action上的文字过长（垂直）", @"specialtest4"],
        @[@"action上的文字过长（水平）", @"specialtest5"],
        @[@"背景毛玻璃Dark样式", @"specialtest6"],
        @[@"背景毛玻璃Light样式", @"specialtest7"],
    ];
    [self.tableData addObjectsFromArray:tableData];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = [rowData objectAtIndex:0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    SEL selector = NSSelectorFromString([rowData objectAtIndex:1]);
    if ([self respondsToSelector:selector]) {
        FWIgnoredBegin();
        [self performSelector:selector];
        FWIgnoredEnd();
    }
}

#pragma mark - Action

// 示例1:actionSheet的默认动画样式(从底部弹出，有取消按钮)
- (void)actionSheetTest1 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet];
    alertController.needDialogBlur = _lookBlur;
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"Default" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Default ");
    }];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"Destructive" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Destructive");
    }];

    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"Cancel" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Cancel");
    }];
    [alertController addAction:action1];
    [alertController addAction:action3]; // 取消按钮一定排在最底部
    [alertController addAction:action2];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// 示例2:actionSheet的默认动画(从底部弹出,无取消按钮)
- (void)actionSheetTest2 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet];
    alertController.needDialogBlur = _lookBlur;
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"Default" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Default ");
    }];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"Destructive" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Destructive");
    }];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

// 示例3:actionSheet从顶部弹出(无标题)
- (void)actionSheetTest3 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:nil message:nil preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeFromTop];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例4:actionSheet从顶部弹出(有标题)
- (void)actionSheetTest4 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:nil message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeFromTop];
    
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    action3.titleColor = FWColorRGBA(30, 170, 40, 1);
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例5:actionSheet 水平排列（有取消按钮）
- (void)actionSheetTest5 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeDefault];
    alertController.actionAxis = UILayoutConstraintAxisHorizontal;
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    FWAlertAction *action4 = [FWAlertAction actionWithTitle:@"第4个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第4个");
    }];
    FWAlertAction *action5 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    // 注:在addAction之后设置action的文字颜色和字体同样有效
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:action4];
    [alertController addAction:action5];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例6:actionSheet 水平排列（无取消按钮）
- (void)actionSheetTest6 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeDefault];
    alertController.actionAxis = UILayoutConstraintAxisHorizontal;
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    FWAlertAction *action4 = [FWAlertAction actionWithTitle:@"第4个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第4个");
    }];
    // 注:在addAction之后设置action的文字颜色和字体同样有效
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:action4];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例7:actionSheet action上有图标
- (void)actionSheetTest7 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:nil message:nil preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeDefault];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"视频通话" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了‘视频通话’");
    }];
    action1.image = [TestBundle imageNamed:@"public_icon"];
    action1.imageTitleSpacing = 5;
    
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"语音通话" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了‘语音通话’");
    }];
    action2.image = [TestBundle imageNamed:@"public_icon"];
    action2.imageTitleSpacing = 5;
    
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    // 注:在addAction之后设置action的文字颜色和字体同样有效
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例8:actionSheet 模拟多分区样式
- (void)actionSheetTest8 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    action1.titleColor = [UIColor orangeColor];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    action2.titleColor = [UIColor orangeColor];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    FWAlertAction *action4 = [FWAlertAction actionWithTitle:@"第4个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第4个");
    }];
    FWAlertAction *action5 = [FWAlertAction actionWithTitle:@"第5个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第5个");
    }];
    FWAlertAction *action6 = [FWAlertAction actionWithTitle:@"第6个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第6个");
    }];
    FWAlertAction *action7 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    action7.titleColor = SYSTEM_COLOR;
    // 注:在addAction之后设置action的文字颜色和字体同样有效
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:action4];
    [alertController addAction:action5];
    [alertController addAction:action6];
    [alertController addAction:action7];
    
    if (@available(iOS 11.0, *)) {
        [alertController setCustomSpacing:6.0 afterAction:action2]; // 设置第2个action之后的间隙
    }
    if (@available(iOS 11.0, *)) {
        [alertController setCustomSpacing:6.0 afterAction:action4];  // 设置第4个action之后的间隙
    }
   
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Alert

// 示例9:alert 默认动画(收缩动画)
- (void)alertTest1 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeDefault];
    alertController.needDialogBlur = _lookBlur;

    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"确定" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了确定");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    // 设置第2个action的颜色
    action2.titleColor = SYSTEM_COLOR;
    [alertController addAction:action2];
    [alertController addAction:action1];

    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例10:alert 发散动画
- (void)alertTest2 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeExpand];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // 设置第1个action的颜色
    action1.titleColor = SYSTEM_COLOR;
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点点击了第3个");
    }];
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// 示例11:alert渐变动画
- (void)alertTest3 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeFade];

    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"确定" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了确定");
    }];
    // 设置第1个action的字体
    action1.titleColor = SYSTEM_COLOR;
    
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    action2.titleColor = [UIColor redColor];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例12:alert 垂直排列2个按钮（2个按钮默认是水平排列）
- (void)alertTest4 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeExpand];
    
    // 2个按钮时默认是水平排列，这里强制垂直排列
    alertController.actionAxis = UILayoutConstraintAxisVertical;

    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"确定" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了确定");
    }];
    // 设置第1个action的颜色
    action1.titleColor = [UIColor redColor];
    
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    action2.titleColor = SYSTEM_COLOR;
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例13:alert 水平排列2个以上的按钮(默认超过2个按钮是垂直排列)
- (void)alertTest5 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleAlert];
    
    // 2个按钮以上默认是垂直排列，这里强制设置水平排列
    alertController.actionAxis = UILayoutConstraintAxisHorizontal;
    
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // 设置第1个action的字体
    action1.titleColor = SYSTEM_COLOR;
    
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    action2.titleColor = [UIColor magentaColor];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例14:alert 设置头部图标
- (void)alertTest6 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"“支付宝”的触控 ID" message:@"请验证已有指纹" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeShrink];

    // 设置图标
    alertController.image = [TestBundle imageNamed:@"public_icon"];
    
    FWAlertAction *action = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    action.titleColor = SYSTEM_COLOR;
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例15:alert 含有文本输入框
- (void)alertTest7 {

    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeShrink];

    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    action1.titleColor = [UIColor redColor];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"确定" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"确定");
    }];
    action2.titleColor = SYSTEM_COLOR;
    action2.enabled = NO;
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        NSLog(@"第1个文本输入框回调");
        // 这个block只会回调一次，因此可以在这里自由定制textFiled，如设置textField的相关属性，设置代理，添加addTarget，监听通知等
        textField.placeholder = @"请输入手机号码";
        textField.clearButtonMode = UITextFieldViewModeAlways;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        NSLog(@"第2个文本输入框回调");
        textField.placeholder = @"请输入密码";
        textField.secureTextEntry = YES;
        textField.clearButtonMode = UITextFieldViewModeAlways;
    }];
    [self presentViewController:alertController animated:YES completion:nil];
}

// alert 自定义头部视图
- (void)alertTest8 {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    headerView.backgroundColor = Theme.backgroundColor;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = Theme.textColor;
    titleLabel.text = @"请输入验证码";
    [headerView addSubview:titleLabel];
    titleLabel.fwLayoutChain.centerX().topWithInset(40);
    
    FWPasscodeView *boxInputView = [[FWPasscodeView alloc] initWithCodeLength:4];
    boxInputView.endEditWhenEditingFinished = NO;
    [boxInputView prepareViewWithBeginEdit:YES];
    [headerView addSubview:boxInputView];
    boxInputView.fwLayoutChain.topToBottomOfViewWithOffset(titleLabel, 40).centerX().size(CGSizeMake(260, 50));
    
    FWAlertController *alertController = [FWAlertController alertControllerWithCustomHeaderView:headerView preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeDefault];
    alertController.customTextField = YES;

    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"确定" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"确定");
    }];
    [alertController addAction:action1];
    [alertController addAction:action2];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Attribute

// 示例16:富文本(action设置富文本)
- (void)attributedStringTest1 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:nil message:nil preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeDefault];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:nil style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了拍摄");
    }];
    NSString *mainTitle1 = @"拍摄";
    NSString *subTitle1 = @"照片或视频";
    NSString *totalTitle1 = [NSString stringWithFormat:@"%@\n%@",mainTitle1,subTitle1];
    NSMutableAttributedString *attrTitle1 = [[NSMutableAttributedString alloc] initWithString:totalTitle1];
    
    NSMutableParagraphStyle *paragraphStyle1 = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle1.lineSpacing = 3;  // 设置行间距
    paragraphStyle1.lineBreakMode = 0;
    paragraphStyle1.alignment = NSTextAlignmentCenter;
    // 段落样式
    [attrTitle1 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle1 range:NSMakeRange(0, totalTitle1.length)];
    // 设置富文本子标题的字体
    [attrTitle1 addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[totalTitle1 rangeOfString:subTitle1]];
    [attrTitle1 addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:[totalTitle1 rangeOfString:subTitle1]];

    action1.attributedTitle = attrTitle1; // 设置富文本标题

    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"从手机相册选择" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了'从手机相册选择'");
    }];

    FWAlertAction *action3 = [FWAlertAction actionWithTitle:nil style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了'用微视拍摄'");
    }];
    NSString *mainTitle3 = @"用微视拍摄";
    NSString *subTitle3 = @"推广";
    NSString *totalTitle3 = [NSString stringWithFormat:@"%@\n%@",mainTitle3,subTitle3];
    NSMutableAttributedString *attrTitle3 = [[NSMutableAttributedString alloc] initWithString:totalTitle3];
    
    NSMutableParagraphStyle *paragraphStyle3 = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle3.lineSpacing = 3;  // 设置行间距
    paragraphStyle3.lineBreakMode = 0;
    paragraphStyle3.alignment = NSTextAlignmentCenter;
    // 段落样式
    [attrTitle3 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle3 range:NSMakeRange(0, totalTitle3.length)];
    // 设置富文本子标题的字体
    [attrTitle3 addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[totalTitle3 rangeOfString:subTitle3]];
    [attrTitle3 addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:[totalTitle3 rangeOfString:subTitle3]];
    
    action3.attributedTitle = attrTitle3; // 设置富文本标题
    
    FWAlertAction *action4 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];

    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:action4];

    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例17:富文本(头部设置富文本)
- (void)attributedStringTest2 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"" message:@"确定拨打吗？" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeDefault];
    NSString *num = @"18077887788";
    NSString *desc = @"可能是一个电话号码";
    NSString *totalTitle = [NSString stringWithFormat:@"%@%@",num,desc];
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:totalTitle];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:SYSTEM_COLOR range:[totalTitle rangeOfString:num]];
    alertController.attributedTitle = attrTitle;
    
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"确定" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了确定");
    }];
    action2.titleColor = SYSTEM_COLOR;

    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - View

// 示例23:自定义整个对话框(actionSheet样式从顶部弹出)
- (void)customTest1 {
    CommodityListView *commodityListView = [[CommodityListView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 200)];
    commodityListView.backgroundColor = [UIColor whiteColor];
    
    FWAlertController *alertController = [FWAlertController alertControllerWithCustomAlertView:commodityListView preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeFromTop];
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例24:自定义整个对话框(pickerView)
- (void)customTest2 {
    PickerView *pickerView = [[PickerView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 240)];
    pickerView.backgroundColor = [UIColor whiteColor];
    pickerView.cancelClickedBlock = ^{
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    };
    pickerView.doneClickedBlock = ^{
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    FWAlertController *alertController = [FWAlertController alertControllerWithCustomAlertView:pickerView preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeFromBottom];
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例25:自定义action部分
- (void)customTest3 {
    // scoreview的子控件采用的是自动布局，由于高度上能够由子控件撑起来，所以高度可以给0，如果宽度也能撑起，宽度也可以给0
    ScoreView *scoreView = [[ScoreView alloc] initWithFrame:CGRectMake(0, 0, 275, 0)];
    scoreView.finishButtonBlock = ^{
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    };
    FWAlertController *alertController = [FWAlertController alertControllerWithCustomActionSequenceView:scoreView title:@"提示" message:@"请给我们的app打分" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeDefault];
    alertController.needDialogBlur = NO;
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例26:插入一个组件
- (void)customTest4 {
    MyCenterView *centerView = [[MyCenterView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth-40, 200)];
    
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeDefault];
    
    // 插入一个view
    [alertController insertComponentView:centerView];

    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // 设置第1个action的颜色
    action1.titleColor = SYSTEM_COLOR;
    
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    
    // 设置第2个action的颜色
    action2.titleColor = [UIColor redColor];
    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例27:自定义整个对话框(全屏)
- (void)customTest5 {
    NSArray *titles = @[@"文字", @"图片", @"视频", @"语音", @"投票", @"签到", @"点赞",@"笔记",@"导航",@"收藏",@"下载",@"更多"];
    NSMutableArray *imgs = [NSMutableArray arrayWithCapacity:titles.count];
    for (NSInteger i = 0; i < titles.count; i ++) {
        [imgs addObject:@"public_icon"];
    }
    PopView *popView = [[PopView alloc] initWithImages:imgs titles:titles clickedButtonBlock:^(NSInteger index) {
        NSLog(@"点击了----%zi",index);
    } cancelBlock:^(PopView *popView) {
        [popView close];
        // 不要等到所有动画结束之后再dismiss，那样感觉太生硬
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        });
    }];
    popView.tapBackgroundBlock = ^(PopView *popView) {
        [popView close];
        // 不要等到所有动画结束之后再dismiss，那样感觉太生硬
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        });
    };
    
    // 这里也可以用actionSheet样式
    FWAlertController *alertController = [FWAlertController alertControllerWithCustomAlertView:popView preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeNone];
    alertController.minDistanceToEdges = 0; // 要想自定义view全屏，该属性必须为0，否则四周会有间距
    alertController.needDialogBlur = NO; // 去除对话框的毛玻璃
    alertController.cornerRadius = 0; // 去除圆角半径
    // 设置背景遮罩为毛玻璃样式
    [alertController setBackgroundViewAppearanceStyle:UIBlurEffectStyleExtraLight alpha:1.0];
    [self presentViewController:alertController animated:NO completion:^{
        // 执行popView的弹出动画
        [popView open];
    }];
}

#pragma mark - Special

// 示例28:当按钮过多时
- (void)specialtest1 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"请滑动查看更多内容" message:@"谢谢" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeDefault];
    alertController.minDistanceToEdges = 100;
    
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    FWAlertAction *action4 = [FWAlertAction actionWithTitle:@"第4个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第4个");
    }];
    FWAlertAction *action5 = [FWAlertAction actionWithTitle:@"第5个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第5个");
    }];
    FWAlertAction *action6 = [FWAlertAction actionWithTitle:@"第6个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第6个");
    }];
    FWAlertAction *action7 = [FWAlertAction actionWithTitle:@"第7个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第7个");
    }];
    FWAlertAction *action8 = [FWAlertAction actionWithTitle:@"第8个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第8个");
    }];
    FWAlertAction *action9 = [FWAlertAction actionWithTitle:@"第9个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第9个");
    }];
    FWAlertAction *action10 = [FWAlertAction actionWithTitle:@"第10个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第10个");
    }];
    FWAlertAction *action11 = [FWAlertAction actionWithTitle:@"第11个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第11个");
    }];
    FWAlertAction *action12 = [FWAlertAction actionWithTitle:@"第12个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第12个");
    }];
    FWAlertAction *action13 = [FWAlertAction actionWithTitle:@"第13个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第13个");
    }];
    FWAlertAction *action14 = [FWAlertAction actionWithTitle:@"第14个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第14个");
    }];
    FWAlertAction *action15 = [FWAlertAction actionWithTitle:@"第15个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第15个");
    }];
    FWAlertAction *action16 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:action4];
    [alertController addAction:action5];
    [alertController addAction:action6];
    [alertController addAction:action7];
    [alertController addAction:action8];
    [alertController addAction:action9];
    [alertController addAction:action10];
    [alertController addAction:action11];
    [alertController addAction:action12];
    [alertController addAction:action13];
    [alertController addAction:action14];
    [alertController addAction:action15];
    [alertController addAction:action16];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例29:当文字和按钮同时过多时，文字占据更多位置
- (void)specialtest2 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"请滑动查看更多内容" message:@"谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeDefault];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"第3个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第3个");
    }];
    FWAlertAction *action4 = [FWAlertAction actionWithTitle:@"第4个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第4个");
    }];
    FWAlertAction *action5 = [FWAlertAction actionWithTitle:@"取消" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    
    FWAlertAction *action6 = [FWAlertAction actionWithTitle:@"第5个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第5个");
    }];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:action4];
    [alertController addAction:action5];
    [alertController addAction:action6];

    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例30:含有文本输入框，且文字过多,默认会滑动到第一个文本输入框的位置
- (void)specialtest3 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"请滑动查看更多内容" message:@"谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢谢" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeNone];
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"第1个" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第1个");
    }];
    
    // FWAlertActionStyleDestructive默认文字为红色(可修改)
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"第2个" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了第2个");
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
    }];
    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例31:action上的文字过长（垂直）
- (void)specialtest4 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"提示" message:@"FWAlertControllerStyleAlert样式下2个按钮默认是水平排列，如果存在按钮文字过长，则自动会切换为垂直排列，除非外界设置了'actionAxis'。如果垂直排列后文字依然过长，则会压缩字体适应宽度，压缩到0.5倍封顶" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeDefault];
    alertController.messageColor = [UIColor redColor];
    
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"明白" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了明白");
    }];
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"我的文字太长了，所以垂直排列显示更多文字，垂直后依然显示不全则压缩字体，压缩到0.5倍封顶" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了'上九天揽月，下五洋捉鳖'");
    }];
    action2.titleColor = SYSTEM_COLOR;

    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例32:action上的文字过长（水平）
- (void)specialtest5 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"提示" message:@"FWAlertControllerStyleAlert样式下2个按钮默认是水平排列，如果存在按钮文字过长，则自动会切换为垂直排列，本例之所以为水平排列，是因为外界设置了'actionAxis'为UILayoutConstraintAxisHorizontal。" preferredStyle:FWAlertControllerStyleAlert animationType:FWAlertAnimationTypeDefault];
    alertController.messageColor = [UIColor redColor];
    
    // 强制水平排列
    alertController.actionAxis = UILayoutConstraintAxisHorizontal;
    
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"明白" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了明白");
    }];
    
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"我的文字太长了，会压缩字体" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了'我的文字太长了，会压缩字体'");
    }];
    action2.titleColor = SYSTEM_COLOR;
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例33:背景外观样式
- (void)specialtest6 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeFromBottom];
    
    alertController.needDialogBlur = _lookBlur;
    
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"Default" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Default");
    }];
    
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"Destructive" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Destructive");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"Cancel" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Cancel");
    }];
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
    [alertController setBackgroundViewAppearanceStyle:UIBlurEffectStyleDark alpha:0.5];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 示例33:背景外观样式
- (void)specialtest7 {
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:@"我是主标题" message:@"我是副标题" preferredStyle:FWAlertControllerStyleActionSheet animationType:FWAlertAnimationTypeFromBottom];
    
    alertController.needDialogBlur = _lookBlur;
    
    FWAlertAction *action1 = [FWAlertAction actionWithTitle:@"Default" style:FWAlertActionStyleDefault handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Default");
    }];
    
    FWAlertAction *action2 = [FWAlertAction actionWithTitle:@"Destructive" style:FWAlertActionStyleDestructive handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Destructive");
    }];
    FWAlertAction *action3 = [FWAlertAction actionWithTitle:@"Cancel" style:FWAlertActionStyleCancel handler:^(FWAlertAction * _Nonnull action) {
        NSLog(@"点击了Cancel");
    }];
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
    [alertController setBackgroundViewAppearanceStyle:UIBlurEffectStyleLight alpha:0.5];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
