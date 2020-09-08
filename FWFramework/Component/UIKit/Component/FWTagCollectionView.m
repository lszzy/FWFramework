/*!
 @header     FWTagCollectionView.m
 @indexgroup FWFramework
 @brief      FWTagCollectionView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/13
 */

#import "FWTagCollectionView.h"
#import "UIView+FWStatistical.h"

@interface FWTagCollectionView () <FWStatisticalDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) BOOL needsLayoutTagViews;
@property (nonatomic, assign) NSUInteger actualNumberOfLines;
@property (nonatomic, copy) FWStatisticalCallback clickCallback;
@property (nonatomic, copy) FWStatisticalCallback exposureCallback;
@property (nonatomic, copy) NSArray<NSNumber *> *exposureIndexes;
@end

@implementation FWTagCollectionView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    if (_scrollView) {
        return;
    }
    
    _horizontalSpacing = 4;
    _verticalSpacing = 4;
    _contentInset = UIEdgeInsetsMake(2, 2, 2, 2);
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.userInteractionEnabled = YES;
    _scrollView.scrollsToTop = NO;
    [self addSubview:_scrollView];
    
    _containerView = [[UIView alloc] initWithFrame:_scrollView.bounds];
    _containerView.backgroundColor = [UIColor clearColor];
    _containerView.userInteractionEnabled = YES;
    [_scrollView addSubview:_containerView];
    
    UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer new];
    [tapGesture addTarget:self action:@selector(onTapGesture:)];
    [_containerView addGestureRecognizer:tapGesture];
    
    [self setNeedsLayoutTagViews];
}

#pragma mark - Public methods

- (void)reload {
    if (![self isDelegateAndDataSourceValid]) {
        return;
    }
    
    // Remove all tag views
    [_containerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // Add tag view
    for (NSUInteger i = 0; i < [_dataSource numberOfTagsInTagCollectionView:self]; i++) {
        [_containerView addSubview:[_dataSource tagCollectionView:self tagViewForIndex:i]];
    }
    
    // Update tag view frame
    [self setNeedsLayoutTagViews];
    [self layoutTagViews];
    
    [self statisticalExposureDidChange];
}

- (NSInteger)indexOfTagAt:(CGPoint)point {
    // We expect the point to be a point wrt to the FWTagCollectionView.
    // so convert this point first to a point wrt to the container view.
    CGPoint convertedPoint = [self convertPoint:point toView:_containerView];
    for (NSUInteger i = 0; i < [self.dataSource numberOfTagsInTagCollectionView:self]; i++) {
        UIView *tagView = [self.dataSource tagCollectionView:self tagViewForIndex:i];
        if (CGRectContainsPoint(tagView.frame, convertedPoint) && !tagView.isHidden) {
            return i;
        }
    }
    return NSNotFound;
}

#pragma mark - Gesture

- (void)onTapGesture:(UITapGestureRecognizer *)tapGesture {
    CGPoint tapPointInCollectionView = [tapGesture locationInView:self];
    
    if (![self.dataSource respondsToSelector:@selector(numberOfTagsInTagCollectionView:)] ||
        ![self.dataSource respondsToSelector:@selector(tagCollectionView:tagViewForIndex:)] ||
        ![self.delegate respondsToSelector:@selector(tagCollectionView:didSelectTag:atIndex:)]) {
        if (_onTapBlankArea) {
            _onTapBlankArea(tapPointInCollectionView);
        }
        if (_onTapAllArea) {
            _onTapAllArea(tapPointInCollectionView);
        }
        return;
    }
    
    CGPoint tapPointInScrollView = [tapGesture locationInView:_containerView];
    BOOL hasLocatedToTag = NO;
    
    for (NSUInteger i = 0; i < [self.dataSource numberOfTagsInTagCollectionView:self]; i++) {
        UIView *tagView = [self.dataSource tagCollectionView:self tagViewForIndex:i];
        if (CGRectContainsPoint(tagView.frame, tapPointInScrollView) && !tagView.isHidden) {
            hasLocatedToTag = YES;
            if ([self.delegate respondsToSelector:@selector(tagCollectionView:shouldSelectTag:atIndex:)]) {
                if ([self.delegate tagCollectionView:self shouldSelectTag:tagView atIndex:i]) {
                    [self.delegate tagCollectionView:self didSelectTag:tagView atIndex:i];
                    if (self.clickCallback) {
                        self.clickCallback(nil, [NSIndexPath indexPathForRow:i inSection:0]);
                    }
                }
            } else {
                [self.delegate tagCollectionView:self didSelectTag:tagView atIndex:i];
                if (self.clickCallback) {
                    self.clickCallback(nil, [NSIndexPath indexPathForRow:i inSection:0]);
                }
            }
        }
    }
    
    if (!hasLocatedToTag) {
        if (_onTapBlankArea) {
            _onTapBlankArea(tapPointInCollectionView);
        }
    }
    if (_onTapAllArea) {
        _onTapAllArea(tapPointInCollectionView);
    }
}

#pragma mark - Override

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(_scrollView.frame, self.bounds)) {
        _scrollView.frame = self.bounds;
        [self setNeedsLayoutTagViews];
        [self layoutTagViews];
        _containerView.frame = (CGRect){CGPointZero, _scrollView.contentSize};
    }
    [self layoutTagViews];
}

- (CGSize)intrinsicContentSize {
    return _scrollView.contentSize;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return self.contentSize;
}

#pragma mark - Layout

- (void)layoutTagViews {
    if (!_needsLayoutTagViews || ![self isDelegateAndDataSourceValid]) {
        return;
    }
    
    if (_scrollDirection == FWTagCollectionScrollDirectionVertical) {
        [self layoutTagViewsForVerticalDirection];
    } else {
        [self layoutTagViewsForHorizontalDirection];
    }
    
    _needsLayoutTagViews = NO;
    [self invalidateIntrinsicContentSize];
}

- (void)layoutTagViewsForVerticalDirection {
    NSUInteger count = [_dataSource numberOfTagsInTagCollectionView:self];
    NSUInteger currentLineTagsCount = 0;
    CGFloat totalWidth = (_manualCalculateHeight && _preferredMaxLayoutWidth > 0) ? _preferredMaxLayoutWidth : CGRectGetWidth(self.bounds);
    CGFloat maxLineWidth = totalWidth - _contentInset.left - _contentInset.right;
    CGFloat currentLineX = 0;
    CGFloat currentLineMaxHeight = 0;
    
    NSMutableArray <NSNumber *> *eachLineMaxHeightNumbers = [NSMutableArray new];
    NSMutableArray <NSNumber *> *eachLineWidthNumbers = [NSMutableArray new];
    NSMutableArray <NSNumber *> *eachLineTagCountNumbers = [NSMutableArray new];
    
    NSMutableArray <NSArray <NSNumber *> *> *eachLineTagIndexs = [NSMutableArray new];
    NSMutableArray <NSNumber *> *tmpTagIndexNumbers = [NSMutableArray new];
    
    // Get each line max height ,width and tag count
    for (NSUInteger i = 0; i < count; i++) {
        CGSize tagSize = [_delegate tagCollectionView:self sizeForTagAtIndex:i];
        
        if (currentLineX + tagSize.width > maxLineWidth && tmpTagIndexNumbers.count > 0) {
            // New Line
            [eachLineMaxHeightNumbers addObject:@(currentLineMaxHeight)];
            [eachLineWidthNumbers addObject:@(currentLineX - _horizontalSpacing)];
            [eachLineTagCountNumbers addObject:@(currentLineTagsCount)];
            [eachLineTagIndexs addObject:tmpTagIndexNumbers];
            tmpTagIndexNumbers = [NSMutableArray new];
            currentLineTagsCount = 0;
            currentLineMaxHeight = 0;
            currentLineX = 0;
        }
        
        // Line limit
        if (_numberOfLines != 0) {
            UIView *tagView = [_dataSource tagCollectionView:self tagViewForIndex:i];
            tagView.hidden = eachLineWidthNumbers.count >= _numberOfLines;
        }
        
        currentLineX += tagSize.width + _horizontalSpacing;
        currentLineTagsCount += 1;
        currentLineMaxHeight = MAX(tagSize.height, currentLineMaxHeight);
        [tmpTagIndexNumbers addObject:@(i)];
    }
    
    // Add last
    [eachLineMaxHeightNumbers addObject:@(currentLineMaxHeight)];
    [eachLineWidthNumbers addObject:@(currentLineX - _horizontalSpacing)];
    [eachLineTagCountNumbers addObject:@(currentLineTagsCount)];
    [eachLineTagIndexs addObject:tmpTagIndexNumbers];
    
    // Actual number of lines
    _actualNumberOfLines = eachLineTagCountNumbers.count;
    
    // Line limit
    if (_numberOfLines != 0) {
        eachLineMaxHeightNumbers = [[eachLineMaxHeightNumbers subarrayWithRange:NSMakeRange(0, MIN(eachLineMaxHeightNumbers.count, _numberOfLines))] mutableCopy];
        eachLineWidthNumbers = [[eachLineWidthNumbers subarrayWithRange:NSMakeRange(0, MIN(eachLineWidthNumbers.count, _numberOfLines))] mutableCopy];
        eachLineTagCountNumbers = [[eachLineTagCountNumbers subarrayWithRange:NSMakeRange(0, MIN(eachLineTagCountNumbers.count, _numberOfLines))] mutableCopy];
        eachLineTagIndexs = [[eachLineTagIndexs subarrayWithRange:NSMakeRange(0, MIN(eachLineTagIndexs.count, _numberOfLines))] mutableCopy];
    }
    
    // Prepare
    [self layoutEachLineTagsWithMaxLineWidth:maxLineWidth
                               numberOfLines:eachLineTagCountNumbers.count
                           eachLineTagIndexs:eachLineTagIndexs
                            eachLineTagCount:eachLineTagCountNumbers
                               eachLineWidth:eachLineWidthNumbers
                           eachLineMaxHeight:eachLineMaxHeightNumbers];
}

- (void)layoutTagViewsForHorizontalDirection {
    NSInteger count = [_dataSource numberOfTagsInTagCollectionView:self];
    _numberOfLines = _numberOfLines == 0 ? 1 : _numberOfLines;
    _numberOfLines = MIN(count, _numberOfLines);
    
    CGFloat maxLineWidth = 0;
    
    NSMutableArray <NSNumber *> *eachLineMaxHeightNumbers = [NSMutableArray new];
    NSMutableArray <NSNumber *> *eachLineWidthNumbers = [NSMutableArray new];
    NSMutableArray <NSNumber *> *eachLineTagCountNumbers = [NSMutableArray new];
    
    NSMutableArray <NSMutableArray <NSNumber *> *> *eachLineTagIndexs = [NSMutableArray new];
    
    // Init each line
    for (NSInteger currentLine = 0; currentLine < _numberOfLines; currentLine++) {
        [eachLineMaxHeightNumbers addObject:@0];
        [eachLineWidthNumbers addObject:@0];
        [eachLineTagCountNumbers addObject:@0];
        [eachLineTagIndexs addObject:[NSMutableArray new]];
    }
    
    // Add tags
    for (NSUInteger tagIndex = 0; tagIndex < count; tagIndex++) {
        NSUInteger currentLine = tagIndex % _numberOfLines;
        
        NSUInteger currentLineTagsCount = eachLineTagCountNumbers[currentLine].unsignedIntegerValue;
        CGFloat currentLineMaxHeight = eachLineMaxHeightNumbers[currentLine].floatValue;
        CGFloat currentLineX = eachLineWidthNumbers[currentLine].floatValue;
        NSMutableArray *currentLineTagIndexNumbers = eachLineTagIndexs[currentLine];
        
        CGSize tagSize = [_delegate tagCollectionView:self sizeForTagAtIndex:tagIndex];
        currentLineX += tagSize.width + _horizontalSpacing;
        currentLineMaxHeight = MAX(tagSize.height, currentLineMaxHeight);
        currentLineTagsCount += 1;
        [currentLineTagIndexNumbers addObject:@(tagIndex)];
        
        eachLineTagCountNumbers[currentLine] = @(currentLineTagsCount);
        eachLineMaxHeightNumbers[currentLine] = @(currentLineMaxHeight);
        eachLineWidthNumbers[currentLine] = @(currentLineX);
        eachLineTagIndexs[currentLine] = currentLineTagIndexNumbers;
    }
    
    // Remove extra space
    for (NSInteger currentLine = 0; currentLine < _numberOfLines; currentLine++) {
        CGFloat currentLineWidth = eachLineWidthNumbers[currentLine].floatValue;
        currentLineWidth -= _horizontalSpacing;
        eachLineWidthNumbers[currentLine] = @(currentLineWidth);
        
        maxLineWidth = MAX(currentLineWidth, maxLineWidth);
    }
    
    // Prepare
    [self layoutEachLineTagsWithMaxLineWidth:maxLineWidth
                               numberOfLines:eachLineTagCountNumbers.count
                           eachLineTagIndexs:eachLineTagIndexs
                            eachLineTagCount:eachLineTagCountNumbers
                               eachLineWidth:eachLineWidthNumbers
                           eachLineMaxHeight:eachLineMaxHeightNumbers];
}

- (void)layoutEachLineTagsWithMaxLineWidth:(CGFloat)maxLineWidth
                             numberOfLines:(NSUInteger)numberOfLines
                         eachLineTagIndexs:(NSArray <NSArray <NSNumber *> *> *)eachLineTagIndexs
                          eachLineTagCount:(NSArray <NSNumber *> *)eachLineTagCount
                             eachLineWidth:(NSArray <NSNumber *> *)eachLineWidth
                         eachLineMaxHeight:(NSArray <NSNumber *> *)eachLineMaxHeight {
    
    CGFloat currentYBase = _contentInset.top;
    
    for (NSUInteger currentLine = 0; currentLine < numberOfLines; currentLine++) {
        CGFloat currentLineMaxHeight = eachLineMaxHeight[currentLine].floatValue;
        CGFloat currentLineWidth = eachLineWidth[currentLine].floatValue;
        CGFloat currentLineTagsCount = eachLineTagCount[currentLine].unsignedIntegerValue;
        
        // Alignment x offset
        CGFloat currentLineXOffset = 0;
        CGFloat currentLineAdditionWidth = 0;
        CGFloat acturalHorizontalSpacing = _horizontalSpacing;
        __block CGFloat currentLineX = 0;
        
        switch (_alignment) {
            case FWTagCollectionAlignmentLeft:
                currentLineXOffset = _contentInset.left;
                break;
            case FWTagCollectionAlignmentCenter:
                currentLineXOffset = (maxLineWidth - currentLineWidth) / 2 + _contentInset.left;
                break;
            case FWTagCollectionAlignmentRight:
                currentLineXOffset = maxLineWidth - currentLineWidth + _contentInset.left;
                break;
            case FWTagCollectionAlignmentFillByExpandingSpace:
                currentLineXOffset = _contentInset.left;
                acturalHorizontalSpacing = _horizontalSpacing +
                (maxLineWidth - currentLineWidth) / (CGFloat)(currentLineTagsCount - 1);
                currentLineWidth = maxLineWidth;
                break;
            case FWTagCollectionAlignmentFillByExpandingWidth:
            case FWTagCollectionAlignmentFillByExpandingWidthExceptLastLine:
                currentLineXOffset = _contentInset.left;
                currentLineAdditionWidth = (maxLineWidth - currentLineWidth) / (CGFloat)currentLineTagsCount;
                currentLineWidth = maxLineWidth;
                
                if (_alignment == FWTagCollectionAlignmentFillByExpandingWidthExceptLastLine &&
                    currentLine == numberOfLines - 1 &&
                    numberOfLines != 1) {
                    // Reset last line width for FWTagCollectionAlignmentFillByExpandingWidthExceptLastLine
                    currentLineAdditionWidth = 0;
                }
                
                break;
        }
        
        // Current line
        [eachLineTagIndexs[currentLine] enumerateObjectsUsingBlock:^(NSNumber * _Nonnull tagIndexNumber, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger tagIndex = tagIndexNumber.unsignedIntegerValue;
            
            UIView *tagView = [self.dataSource tagCollectionView:self tagViewForIndex:tagIndex];
            CGSize tagSize = [self.delegate tagCollectionView:self sizeForTagAtIndex:tagIndex];
            
            CGPoint origin;
            origin.x = currentLineXOffset + currentLineX;
            origin.y = currentYBase + (currentLineMaxHeight - tagSize.height) / 2;
            
            tagSize.width += currentLineAdditionWidth;
            if (self.scrollDirection == FWTagCollectionScrollDirectionVertical && tagSize.width > maxLineWidth) {
                tagSize.width = maxLineWidth;
            }
            
            tagView.hidden = NO;
            tagView.frame = (CGRect){origin, tagSize};
            
            currentLineX += tagSize.width + acturalHorizontalSpacing;
        }];
        
        // Next line
        currentYBase += currentLineMaxHeight + _verticalSpacing;
    }
    
    // Content size
    maxLineWidth += _contentInset.right + _contentInset.left;
    CGSize contentSize = CGSizeMake(maxLineWidth, currentYBase - _verticalSpacing + _contentInset.bottom);
    if (!CGSizeEqualToSize(contentSize, _scrollView.contentSize)) {
        _scrollView.contentSize = contentSize;
        _containerView.frame = (CGRect){CGPointZero, contentSize};
        
        if ([self.delegate respondsToSelector:@selector(tagCollectionView:updateContentSize:)]) {
            [self.delegate tagCollectionView:self updateContentSize:contentSize];
        }
    }
}

- (void)setNeedsLayoutTagViews {
    _needsLayoutTagViews = YES;
}

#pragma mark - Check delegate and dataSource

- (BOOL)isDelegateAndDataSourceValid {
    BOOL isValid = _delegate != nil && _dataSource != nil;
    isValid = isValid && [_delegate respondsToSelector:@selector(tagCollectionView:sizeForTagAtIndex:)];
    isValid = isValid && [_dataSource respondsToSelector:@selector(tagCollectionView:tagViewForIndex:)];
    isValid = isValid && [_dataSource respondsToSelector:@selector(numberOfTagsInTagCollectionView:)];
    return isValid;
}

#pragma mark - Setter Getter

- (UIScrollView *)scrollView {
    return _scrollView;
}

- (void)setScrollDirection:(FWTagCollectionScrollDirection)scrollDirection {
    _scrollDirection = scrollDirection;
    [self setNeedsLayoutTagViews];
}

- (void)setAlignment:(FWTagCollectionAlignment)alignment {
    _alignment = alignment;
    [self setNeedsLayoutTagViews];
}

- (void)setNumberOfLines:(NSUInteger)numberOfLines {
    _numberOfLines = numberOfLines;
    [self setNeedsLayoutTagViews];
}

- (NSUInteger)actualNumberOfLines {
    if (_scrollDirection == FWTagCollectionScrollDirectionHorizontal) {
        return _numberOfLines;
    } else {
        return _actualNumberOfLines;
    }
}

- (void)setHorizontalSpacing:(CGFloat)horizontalSpacing {
    _horizontalSpacing = horizontalSpacing;
    [self setNeedsLayoutTagViews];
}

- (void)setVerticalSpacing:(CGFloat)verticalSpacing {
    _verticalSpacing = verticalSpacing;
    [self setNeedsLayoutTagViews];
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    [self setNeedsLayoutTagViews];
}

- (CGSize)contentSize {
    [self layoutTagViews];
    return _scrollView.contentSize;
}

- (void)setManualCalculateHeight:(BOOL)manualCalculateHeight {
    _manualCalculateHeight = manualCalculateHeight;
    [self setNeedsLayoutTagViews];
}

- (void)setPreferredMaxLayoutWidth:(CGFloat)preferredMaxLayoutWidth {
    _preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    [self setNeedsLayoutTagViews];
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)showsHorizontalScrollIndicator {
    _scrollView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator;
}

- (BOOL)showsHorizontalScrollIndicator {
    return _scrollView.showsHorizontalScrollIndicator;
}

- (void)setShowsVerticalScrollIndicator:(BOOL)showsVerticalScrollIndicator {
    _scrollView.showsVerticalScrollIndicator = showsVerticalScrollIndicator;
}

- (BOOL)showsVerticalScrollIndicator {
    return _scrollView.showsVerticalScrollIndicator;
}

#pragma mark - FWStatisticalDelegate

- (void)statisticalClickWithCallback:(FWStatisticalCallback)callback {
    self.clickCallback = callback;
}

- (void)statisticalExposureWithCallback:(FWStatisticalCallback)callback {
    self.exposureCallback = callback;
    
    [self statisticalExposureDidChange];
}

- (void)statisticalExposureDidChange {
    if (!self.exposureCallback) return;
    
    // Calculate current exposure indexes
    NSMutableArray *exposureIndexes = [NSMutableArray new];
    NSArray *previousIndexes = self.exposureIndexes;
    [_containerView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *obj, NSUInteger idx, BOOL *stop) {
        [exposureIndexes addObject:@(obj.hash)];
        if (![previousIndexes containsObject:@(obj.hash)]) {
            self.exposureCallback(nil, [NSIndexPath indexPathForRow:idx inSection:0]);
        }
    }];
    self.exposureIndexes = [exposureIndexes copy];
}

@end

#pragma mark - FWTextTagConfig

@implementation FWTextTagConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _textFont = [UIFont systemFontOfSize:16.0f];
        
        _textColor = [UIColor whiteColor];
        _selectedTextColor = [UIColor whiteColor];
        
        _backgroundColor = [UIColor colorWithRed:0.30 green:0.72 blue:0.53 alpha:1.00];
        _selectedBackgroundColor = [UIColor colorWithRed:0.22 green:0.29 blue:0.36 alpha:1.00];
        
        _enableGradientBackground = NO;
        _gradientBackgroundStartColor = [UIColor clearColor];
        _gradientBackgroundEndColor = [UIColor clearColor];
        _selectedGradientBackgroundStartColor = [UIColor clearColor];
        _selectedGradientBackgroundEndColor = [UIColor clearColor];
        _gradientBackgroundStartPoint = CGPointMake(0.5, 0.0);
        _gradientBackgroundEndPoint = CGPointMake(0.5, 1.0);
        
        _cornerRadius = 4.0f;
        _selectedCornerRadius = 4.0f;
        _cornerTopLeft = true;
        _cornerTopRight = true;
        _cornerBottomLeft = true;
        _cornerBottomRight = true;
        
        _borderWidth = 1.0f;
        _selectedBorderWidth = 1.0f;
        
        _borderColor = [UIColor whiteColor];
        _selectedBorderColor = [UIColor whiteColor];
        
        _shadowColor = [UIColor clearColor];
        _shadowOffset = CGSizeMake(0, 0);
        _shadowRadius = 0;
        _shadowOpacity = 0.0f;
        
        _extraSpace = CGSizeMake(14, 14);
        _maxWidth = 0.0f;
        _minWidth = 0.0f;
        
        _exactWidth = 0.0f;
        _exactHeight = 0.0f;
        
        _extraData = nil;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    FWTextTagConfig *newConfig = [FWTextTagConfig new];
    newConfig.textFont = [_textFont copyWithZone:zone];
    
    newConfig.textColor = [_textColor copyWithZone:zone];
    newConfig.selectedTextColor = [_selectedTextColor copyWithZone:zone];
    
    newConfig.backgroundColor = [_backgroundColor copyWithZone:zone];
    newConfig.selectedBackgroundColor = [_selectedBackgroundColor copyWithZone:zone];
    
    newConfig.enableGradientBackground = _enableGradientBackground;
    newConfig.gradientBackgroundStartColor = [_gradientBackgroundStartColor copyWithZone:zone];
    newConfig.gradientBackgroundEndColor = [_gradientBackgroundEndColor copyWithZone:zone];
    newConfig.selectedGradientBackgroundStartColor = [_selectedGradientBackgroundStartColor copyWithZone:zone];
    newConfig.selectedGradientBackgroundEndColor = [_selectedGradientBackgroundEndColor copyWithZone:zone];
    newConfig.gradientBackgroundStartPoint = _gradientBackgroundStartPoint;
    newConfig.gradientBackgroundEndPoint = _gradientBackgroundEndPoint;
    
    newConfig.cornerRadius = _cornerRadius;
    newConfig.selectedCornerRadius = _selectedCornerRadius;
    newConfig.cornerTopLeft = _cornerTopLeft;
    newConfig.cornerTopRight = _cornerTopRight;
    newConfig.cornerBottomLeft = _cornerBottomLeft;
    newConfig.cornerBottomRight = _cornerBottomRight;
    
    newConfig.borderWidth = _borderWidth;
    newConfig.selectedBorderWidth = _selectedBorderWidth;
    
    newConfig.borderColor = [_borderColor copyWithZone:zone];
    newConfig.selectedBorderColor = [_selectedBorderColor copyWithZone:zone];
    
    newConfig.shadowColor = [_shadowColor copyWithZone:zone];
    newConfig.shadowOffset = _shadowOffset;
    newConfig.shadowRadius = _shadowRadius;
    newConfig.shadowOpacity = _shadowOpacity;
    
    newConfig.extraSpace = _extraSpace;
    newConfig.maxWidth = _maxWidth;
    newConfig.minWidth = _minWidth;
    
    newConfig.exactWidth = _exactWidth;
    newConfig.exactHeight = _exactHeight;
    
    if ([_extraData conformsToProtocol:@protocol(NSCopying)] &&
        [_extraData respondsToSelector:@selector(copyWithZone:)]) {
        newConfig.extraData = [((id <NSCopying>)_extraData) copyWithZone:zone];
    } else {
        newConfig.extraData = _extraData;
    }
    
    return newConfig;
}

@end

#pragma mark - FWTagGradientLabel

@interface FWTagGradientLabel: UILabel
@end

@implementation FWTagGradientLabel
+ (Class)layerClass {
    return [CAGradientLayer class];
}
@end

#pragma mark - FWTextTagLabel

// UILabel wrapper for round corner and shadow at the same time.
@interface FWTextTagLabel : UIView
@property (nonatomic, strong) FWTextTagConfig *config;
@property (nonatomic, strong) FWTagGradientLabel *label;
@property (nonatomic, strong) CAShapeLayer *borderLayer;
@property (assign, nonatomic) BOOL selected;
@end

@implementation FWTextTagLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _label = [[FWTagGradientLabel alloc] initWithFrame:self.bounds];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.userInteractionEnabled = YES;
    [self addSubview:_label];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Update frame
    _label.frame = self.bounds;
    
    // Get new path
    UIBezierPath *path = [self getNewPath];
    // Mask
    [self updateMaskWithPath:path];
    // Border
    [self updateBorderWithPath:path];
    // Shadow
    [self updateShadowWithPath:path];
}

#pragma mark - intrinsicContentSize

- (CGSize)intrinsicContentSize {
    return _label.intrinsicContentSize;
}

#pragma mark - Apply config

- (void)updateContentStyle {
    // Text style
    _label.font = _config.textFont;
    _label.textColor = _selected ? _config.selectedTextColor : _config.textColor;
    
    // Normal background
    _label.backgroundColor = _selected ? _config.selectedBackgroundColor : _config.backgroundColor;
    
    // Gradient background
    if (_config.enableGradientBackground) {
        _label.backgroundColor = [UIColor clearColor];
        if (_selected) {
            ((CAGradientLayer *)_label.layer).colors = @[(id)_config.selectedGradientBackgroundStartColor.CGColor,
                                                         (id)_config.selectedGradientBackgroundEndColor.CGColor];
        } else {
            ((CAGradientLayer *)_label.layer).colors = @[(id)_config.gradientBackgroundStartColor.CGColor,
                                                         (id)_config.gradientBackgroundEndColor.CGColor];
        }
        ((CAGradientLayer *)_label.layer).startPoint = _config.gradientBackgroundStartPoint;
        ((CAGradientLayer *)_label.layer).endPoint = _config.gradientBackgroundEndPoint;
    }
}

- (void)updateFrameWithMaxSize:(CGSize)maxSize {
    [_label sizeToFit];
    
    CGSize size = _label.frame.size;
    CGSize finalSize = size;
    
    finalSize.width += _config.extraSpace.width;
    finalSize.height += _config.extraSpace.height;
    
    if (self.config.maxWidth > 0 && size.width > self.config.maxWidth) {
        finalSize.width = self.config.maxWidth;
    }
    if (self.config.minWidth > 0 && size.width < self.config.minWidth) {
        finalSize.width = self.config.minWidth;
    }
    if (self.config.exactWidth > 0) {
        finalSize.width = self.config.exactWidth;
    }
    if (self.config.exactHeight > 0) {
        finalSize.height = self.config.exactHeight;
    }
    
    if (maxSize.width > 0) {
        finalSize.width = MIN(maxSize.width, finalSize.width);
    }
    if (maxSize.height > 0) {
        finalSize.height = MIN(maxSize.height, finalSize.height);
    }
    
    CGRect frame = self.frame;
    frame.size = finalSize;
    self.frame = frame;
    _label.frame = self.bounds;
}

- (void)updateShadowWithPath:(UIBezierPath *)path {
    self.layer.shadowColor = (_config.shadowColor ?: [UIColor clearColor]).CGColor;
    self.layer.shadowOffset = _config.shadowOffset;
    self.layer.shadowRadius = _config.shadowRadius;
    self.layer.shadowOpacity = _config.shadowOpacity;
    self.layer.shadowPath = path.CGPath;
    self.layer.shouldRasterize = YES;
    [self.layer setRasterizationScale:[[UIScreen mainScreen] scale]];
}

- (void)updateMaskWithPath:(UIBezierPath *)path {
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.bounds;
    maskLayer.path = path.CGPath;
    _label.layer.mask = maskLayer;
}

- (void)updateBorderWithPath:(UIBezierPath *)path {
    if (!_borderLayer) {
        _borderLayer = [CAShapeLayer new];
    }
    [_borderLayer removeFromSuperlayer];
    _borderLayer.frame = self.bounds;
    _borderLayer.path = path.CGPath;
    _borderLayer.fillColor = nil;
    _borderLayer.opacity = 1;
    _borderLayer.lineWidth = _selected ? _config.selectedBorderWidth : _config.borderWidth;
    _borderLayer.strokeColor = (_selected && _config.selectedBorderColor) ? _config.selectedBorderColor.CGColor : _config.borderColor.CGColor;
    [self.layer addSublayer:_borderLayer];
}

- (UIBezierPath *)getNewPath {
    // Round corner
    UIRectCorner corners = (UIRectCorner) -1;
    if (_config.cornerTopLeft) {
        corners = UIRectCornerTopLeft;
    }
    if (_config.cornerTopRight) {
        if (corners == -1) {
            corners = UIRectCornerTopRight;
        } else {
            corners = corners | UIRectCornerTopRight;
        }
    }
    if (_config.cornerBottomLeft) {
        if (corners == -1) {
            corners = UIRectCornerBottomLeft;
        } else {
            corners = corners | UIRectCornerBottomLeft;
        }
    }
    if (_config.cornerBottomRight) {
        if (corners == -1) {
            corners = UIRectCornerBottomRight;
        } else {
            corners = corners | UIRectCornerBottomRight;
        }
    }
    
    // Corner radius
    CGFloat currentCornerRadius = _selected ? _config.selectedCornerRadius : _config.cornerRadius;
    
    // Path
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                               byRoundingCorners:corners
                                                     cornerRadii:CGSizeMake(currentCornerRadius, currentCornerRadius)];
    return path;
}

@end

#pragma mark - FWTextTagCollectionView

@interface FWTextTagCollectionView () <FWTagCollectionViewDataSource, FWTagCollectionViewDelegate, FWStatisticalDelegate>
@property (strong, nonatomic) NSMutableArray <FWTextTagLabel *> *tagLabels;
@property (strong, nonatomic) FWTagCollectionView *tagCollectionView;
@end

@implementation FWTextTagCollectionView

#pragma mark - Init

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    if (_tagCollectionView) {
        return;
    }
    
    _enableTagSelection = YES;
    _tagLabels = [NSMutableArray new];
    
    _defaultConfig = [FWTextTagConfig new];
    
    _tagCollectionView = [[FWTagCollectionView alloc] initWithFrame:self.bounds];
    _tagCollectionView.delegate = self;
    _tagCollectionView.dataSource = self;
    _tagCollectionView.horizontalSpacing = 8;
    _tagCollectionView.verticalSpacing = 8;
    [self addSubview:_tagCollectionView];
}

#pragma mark - Override

- (CGSize)intrinsicContentSize {
    return [_tagCollectionView intrinsicContentSize];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(_tagCollectionView.frame, self.bounds)) {
        [self updateAllLabelStyleAndFrame];
        _tagCollectionView.frame = self.bounds;
        [_tagCollectionView setNeedsLayout];
        [_tagCollectionView layoutIfNeeded];
        [self invalidateIntrinsicContentSize];
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    return self.contentSize;
}

#pragma mark - Public methods

- (void)reload {
    [self updateAllLabelStyleAndFrame];
    [_tagCollectionView reload];
    [self invalidateIntrinsicContentSize];
}

- (void)addTag:(NSString *)tag {
    [self insertTag:tag atIndex:_tagLabels.count];
}

- (void)addTag:(NSString *)tag withConfig:(FWTextTagConfig *)config {
    [self insertTag:tag atIndex:_tagLabels.count withConfig:config];
}

- (void)addTags:(NSArray <NSString *> *)tags {
    [self insertTags:tags atIndex:_tagLabels.count withConfig:_defaultConfig copyConfig:NO];
}

- (void)addTags:(NSArray<NSString *> *)tags withConfig:(FWTextTagConfig *)config {
    [self insertTags:tags atIndex:_tagLabels.count withConfig:config copyConfig:YES];
}

- (void)insertTag:(NSString *)tag atIndex:(NSUInteger)index {
    if ([tag isKindOfClass:[NSString class]]) {
        [self insertTags:@[tag] atIndex:index withConfig:_defaultConfig copyConfig:NO];
    }
}

- (void)insertTag:(NSString *)tag atIndex:(NSUInteger)index withConfig:(FWTextTagConfig *)config {
    if ([tag isKindOfClass:[NSString class]]) {
        [self insertTags:@[tag] atIndex:index withConfig:config copyConfig:YES];
    }
}

- (void)insertTags:(NSArray<NSString *> *)tags atIndex:(NSUInteger)index {
    [self insertTags:tags atIndex:index withConfig:_defaultConfig copyConfig:NO];
}

- (void)insertTags:(NSArray<NSString *> *)tags atIndex:(NSUInteger)index withConfig:(FWTextTagConfig *)config {
    [self insertTags:tags atIndex:index withConfig:config copyConfig:YES];
}

- (void)insertTags:(NSArray<NSString *> *)tags atIndex:(NSUInteger)index withConfig:(FWTextTagConfig *)config copyConfig:(BOOL)copyConfig {
    if (![tags isKindOfClass:[NSArray class]] || index > _tagLabels.count || ![config isKindOfClass:[FWTextTagConfig class]]) {
        return;
    }
    
    if (copyConfig) {
        config = [config copy];
    }
    
    NSMutableArray *newTagLabels = [NSMutableArray new];
    for (NSString *tagText in tags) {
        FWTextTagLabel *label = [self newLabelForTagText:[tagText description] withConfig:config];
        [newTagLabels addObject:label];
    }
    [_tagLabels insertObjects:newTagLabels atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, newTagLabels.count)]];
    [self reload];
}

- (void)removeTag:(NSString *)tag {
    if (![tag isKindOfClass:[NSString class]] || tag.length == 0) {
        return;
    }
    
    NSMutableArray *labelsToRemoved = [NSMutableArray new];
    for (FWTextTagLabel *label in _tagLabels) {
        if ([label.label.text isEqualToString:tag]) {
            [labelsToRemoved addObject:label];
        }
    }
    [_tagLabels removeObjectsInArray:labelsToRemoved];
    [self reload];
}

- (void)removeTagAtIndex:(NSUInteger)index {
    if (index >= _tagLabels.count) {
        return;
    }
    
    [_tagLabels removeObjectAtIndex:index];
    [self reload];
}

- (void)removeAllTags {
    [_tagLabels removeAllObjects];
    [self reload];
}

- (void)setTagAtIndex:(NSUInteger)index selected:(BOOL)selected {
    if (index >= _tagLabels.count) {
        return;
    }
    
    _tagLabels[index].selected = selected;
    [self reload];
}

- (void)setTagAtIndex:(NSUInteger)index withConfig:(FWTextTagConfig *)config {
    if (index >= _tagLabels.count || ![config isKindOfClass:[FWTextTagConfig class]]) {
        return;
    }
    
    _tagLabels[index].config = [config copy];
    [self reload];
}

- (void)setTagsInRange:(NSRange)range withConfig:(FWTextTagConfig *)config {
    if (NSMaxRange(range) > _tagLabels.count || ![config isKindOfClass:[FWTextTagConfig class]]) {
        return;
    }
    
    NSArray *tagLabels = [_tagLabels subarrayWithRange:range];
    config = [config copy];
    for (FWTextTagLabel *label in tagLabels) {
        label.config = config;
    }
    [self reload];
}

- (NSString *)getTagAtIndex:(NSUInteger)index {
    if (index < _tagLabels.count) {
        return [_tagLabels[index].label.text copy];
    } else {
        return nil;
    }
}

- (NSArray<NSString *> *)getTagsInRange:(NSRange)range {
    if (NSMaxRange(range) <= _tagLabels.count) {
        NSMutableArray *tags = [NSMutableArray new];
        for (FWTextTagLabel *label in [_tagLabels subarrayWithRange:range]) {
            [tags addObject:[label.label.text copy]];
        }
        return [tags copy];
    } else {
        return nil;
    }
}

- (FWTextTagConfig *)getConfigAtIndex:(NSUInteger)index {
    if (index < _tagLabels.count) {
        return [_tagLabels[index].config copy];
    } else {
        return nil;
    }
}

- (NSArray<FWTextTagConfig *> *)getConfigsInRange:(NSRange)range {
    if (NSMaxRange(range) <= _tagLabels.count) {
        NSMutableArray *configs = [NSMutableArray new];
        for (FWTextTagLabel *label in [_tagLabels subarrayWithRange:range]) {
            [configs addObject:[label.config copy]];
        }
        return [configs copy];
    } else {
        return nil;
    }
}

- (NSArray <NSString *> *)allTags {
    NSMutableArray *allTags = [NSMutableArray new];
    
    for (FWTextTagLabel *label in _tagLabels) {
        [allTags addObject:[label.label.text copy]];
    }
    
    return [allTags copy];
}

- (NSArray <NSString *> *)allSelectedTags {
    NSMutableArray *allTags = [NSMutableArray new];
    
    for (FWTextTagLabel *label in _tagLabels) {
        if (label.selected) {
            [allTags addObject:[label.label.text copy]];
        }
    }
    
    return [allTags copy];
}

- (NSArray <NSString *> *)allNotSelectedTags {
    NSMutableArray *allTags = [NSMutableArray new];
    
    for (FWTextTagLabel *label in _tagLabels) {
        if (!label.selected) {
            [allTags addObject:[label.label.text copy]];
        }
    }
    
    return [allTags copy];
}

- (NSInteger)indexOfTagAt:(CGPoint)point {
    // We expect the point to be a point wrt to the FWTextTagCollectionView.
    // so convert this point first to a point wrt to the FWTagCollectionView.
    CGPoint convertedPoint = [self convertPoint:point toView:_tagCollectionView];
    return [_tagCollectionView indexOfTagAt:convertedPoint];
}

#pragma mark - FWTagCollectionViewDataSource

- (NSUInteger)numberOfTagsInTagCollectionView:(FWTagCollectionView *)tagCollectionView {
    return _tagLabels.count;
}

- (UIView *)tagCollectionView:(FWTagCollectionView *)tagCollectionView tagViewForIndex:(NSUInteger)index {
    return _tagLabels[index];
}

#pragma mark - FWTagCollectionViewDelegate

- (BOOL)tagCollectionView:(FWTagCollectionView *)tagCollectionView shouldSelectTag:(UIView *)tagView atIndex:(NSUInteger)index {
    if (_enableTagSelection) {
        FWTextTagLabel *label = _tagLabels[index];
        
        if ([self.delegate respondsToSelector:@selector(textTagCollectionView:canTapTag:atIndex:currentSelected:tagConfig:)]) {
            return [self.delegate textTagCollectionView:self canTapTag:label.label.text atIndex:index currentSelected:label.selected tagConfig:label.config];
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

- (void)tagCollectionView:(FWTagCollectionView *)tagCollectionView didSelectTag:(UIView *)tagView atIndex:(NSUInteger)index {
    if (_enableTagSelection) {
        FWTextTagLabel *label = _tagLabels[index];
        
        if (!label.selected && _selectionLimit > 0 && [self allSelectedTags].count + 1 > _selectionLimit) {
            return;
        }
        
        label.selected = !label.selected;
        
        if (self.alignment == FWTagCollectionAlignmentFillByExpandingWidth ||
            self.alignment == FWTagCollectionAlignmentFillByExpandingWidthExceptLastLine) {
            [self reload];
        } else {
            [self updateStyleAndFrameForLabel:label];
        }
        
        if ([_delegate respondsToSelector:@selector(textTagCollectionView:didTapTag:atIndex:selected:tagConfig:)]) {
            [_delegate textTagCollectionView:self didTapTag:label.label.text atIndex:index selected:label.selected tagConfig:label.config];
        }
    }
}

- (CGSize)tagCollectionView:(FWTagCollectionView *)tagCollectionView sizeForTagAtIndex:(NSUInteger)index {
    return _tagLabels[index].frame.size;
}

- (void)tagCollectionView:(FWTagCollectionView *)tagCollectionView updateContentSize:(CGSize)contentSize {
    if ([_delegate respondsToSelector:@selector(textTagCollectionView:updateContentSize:)]) {
        [_delegate textTagCollectionView:self updateContentSize:contentSize];
    }
}

#pragma mark - Setter and Getter

- (UIScrollView *)scrollView {
    return _tagCollectionView.scrollView;
}

- (CGFloat)horizontalSpacing {
    return _tagCollectionView.horizontalSpacing;
}

- (void)setHorizontalSpacing:(CGFloat)horizontalSpacing {
    _tagCollectionView.horizontalSpacing = horizontalSpacing;
}

- (CGFloat)verticalSpacing {
    return _tagCollectionView.verticalSpacing;
}

- (void)setVerticalSpacing:(CGFloat)verticalSpacing {
    _tagCollectionView.verticalSpacing = verticalSpacing;
}

- (CGSize)contentSize {
    return _tagCollectionView.contentSize;
}

- (FWTagCollectionScrollDirection)scrollDirection {
    return _tagCollectionView.scrollDirection;
}

- (void)setScrollDirection:(FWTagCollectionScrollDirection)scrollDirection {
    _tagCollectionView.scrollDirection = scrollDirection;
}

- (FWTagCollectionAlignment)alignment {
    return _tagCollectionView.alignment;
}

- (void)setAlignment:(FWTagCollectionAlignment)alignment {
    _tagCollectionView.alignment = alignment;
}

- (NSUInteger)numberOfLines {
    return _tagCollectionView.numberOfLines;
}

- (void)setNumberOfLines:(NSUInteger)numberOfLines {
    _tagCollectionView.numberOfLines = numberOfLines;
}

- (NSUInteger)actualNumberOfLines {
    return _tagCollectionView.actualNumberOfLines;
}

- (UIEdgeInsets)contentInset {
    return _tagCollectionView.contentInset;
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _tagCollectionView.contentInset = contentInset;
}

- (BOOL)manualCalculateHeight {
    return _tagCollectionView.manualCalculateHeight;
}

- (void)setManualCalculateHeight:(BOOL)manualCalculateHeight {
    _tagCollectionView.manualCalculateHeight = manualCalculateHeight;
}

- (CGFloat)preferredMaxLayoutWidth {
    return _tagCollectionView.preferredMaxLayoutWidth;
}

- (void)setPreferredMaxLayoutWidth:(CGFloat)preferredMaxLayoutWidth {
    _tagCollectionView.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)showsHorizontalScrollIndicator {
    _tagCollectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator;
}

- (BOOL)showsHorizontalScrollIndicator {
    return _tagCollectionView.showsHorizontalScrollIndicator;
}

- (void)setShowsVerticalScrollIndicator:(BOOL)showsVerticalScrollIndicator {
    _tagCollectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator;
}

- (BOOL)showsVerticalScrollIndicator {
    return _tagCollectionView.showsVerticalScrollIndicator;
}

- (void)setOnTapBlankArea:(void (^)(CGPoint location))onTapBlankArea {
    _tagCollectionView.onTapBlankArea = onTapBlankArea;
}

- (void (^)(CGPoint location))onTapBlankArea {
    return _tagCollectionView.onTapBlankArea;
}

- (void)setOnTapAllArea:(void (^)(CGPoint location))onTapAllArea {
    _tagCollectionView.onTapAllArea = onTapAllArea;
}

- (void (^)(CGPoint location))onTapAllArea {
    return _tagCollectionView.onTapAllArea;
}

#pragma mark - Private methods

- (void)updateAllLabelStyleAndFrame {
    for (FWTextTagLabel *label in _tagLabels) {
        [self updateStyleAndFrameForLabel:label];
    }
}

- (void)updateStyleAndFrameForLabel:(FWTextTagLabel *)label {
    // Update content style
    [label updateContentStyle];
    // Width limit for vertical scroll direction
    CGSize maxSize = CGSizeZero;
    if (self.scrollDirection == FWTagCollectionScrollDirectionVertical &&
        CGRectGetWidth(self.bounds) > 0) {
        maxSize.width = (CGRectGetWidth(self.bounds) - self.contentInset.left - self.contentInset.right);
    }
    // Update frame
    [label updateFrameWithMaxSize:maxSize];
}

- (FWTextTagLabel *)newLabelForTagText:(NSString *)tagText withConfig:(FWTextTagConfig *)config {
    FWTextTagLabel *label = [FWTextTagLabel new];
    label.label.text = tagText;
    label.config = config;
    return label;
}

#pragma mark - FWStatisticalDelegate

- (void)statisticalClickWithCallback:(FWStatisticalCallback)callback {
    [self.tagCollectionView statisticalClickWithCallback:callback];
}

- (void)statisticalExposureWithCallback:(FWStatisticalCallback)callback {
    [self.tagCollectionView statisticalExposureWithCallback:callback];
}

@end
