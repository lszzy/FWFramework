/*!
 @header     FWTagCollectionView.m
 @indexgroup FWFramework
 @brief      FWTagCollectionView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/13
 */

#import "FWTagCollectionView.h"

@interface TTGTagCollectionView ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) BOOL needsLayoutTagViews;
@property (nonatomic, assign) NSUInteger actualNumberOfLines;
@end

@implementation TTGTagCollectionView

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
}

- (NSInteger)indexOfTagAt:(CGPoint)point {
    // We expect the point to be a point wrt to the TTGTagCollectionView.
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
                }
            } else {
                [self.delegate tagCollectionView:self didSelectTag:tagView atIndex:i];
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

#pragma mark - Layout

- (void)layoutTagViews {
    if (!_needsLayoutTagViews || ![self isDelegateAndDataSourceValid]) {
        return;
    }
    
    if (_scrollDirection == TTGTagCollectionScrollDirectionVertical) {
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
            case TTGTagCollectionAlignmentLeft:
                currentLineXOffset = _contentInset.left;
                break;
            case TTGTagCollectionAlignmentCenter:
                currentLineXOffset = (maxLineWidth - currentLineWidth) / 2 + _contentInset.left;
                break;
            case TTGTagCollectionAlignmentRight:
                currentLineXOffset = maxLineWidth - currentLineWidth + _contentInset.left;
                break;
            case TTGTagCollectionAlignmentFillByExpandingSpace:
                currentLineXOffset = _contentInset.left;
                acturalHorizontalSpacing = _horizontalSpacing +
                (maxLineWidth - currentLineWidth) / (CGFloat)(currentLineTagsCount - 1);
                currentLineWidth = maxLineWidth;
                break;
            case TTGTagCollectionAlignmentFillByExpandingWidth:
            case TTGTagCollectionAlignmentFillByExpandingWidthExceptLastLine:
                currentLineXOffset = _contentInset.left;
                currentLineAdditionWidth = (maxLineWidth - currentLineWidth) / (CGFloat)currentLineTagsCount;
                currentLineWidth = maxLineWidth;
                
                if (_alignment == TTGTagCollectionAlignmentFillByExpandingWidthExceptLastLine &&
                    currentLine == numberOfLines - 1 &&
                    numberOfLines != 1) {
                    // Reset last line width for TTGTagCollectionAlignmentFillByExpandingWidthExceptLastLine
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
            if (self.scrollDirection == TTGTagCollectionScrollDirectionVertical && tagSize.width > maxLineWidth) {
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

- (void)setScrollDirection:(TTGTagCollectionScrollDirection)scrollDirection {
    _scrollDirection = scrollDirection;
    [self setNeedsLayoutTagViews];
}

- (void)setAlignment:(TTGTagCollectionAlignment)alignment {
    _alignment = alignment;
    [self setNeedsLayoutTagViews];
}

- (void)setNumberOfLines:(NSUInteger)numberOfLines {
    _numberOfLines = numberOfLines;
    [self setNeedsLayoutTagViews];
}

- (NSUInteger)actualNumberOfLines {
    if (_scrollDirection == TTGTagCollectionScrollDirectionHorizontal) {
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

@end

#pragma mark - -----TTGTextTagConfig-----

@implementation TTGTextTagConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _tagTextFont = [UIFont systemFontOfSize:16.0f];
        
        _tagTextColor = [UIColor whiteColor];
        _tagSelectedTextColor = [UIColor whiteColor];
        
        _tagBackgroundColor = [UIColor colorWithRed:0.30 green:0.72 blue:0.53 alpha:1.00];
        _tagSelectedBackgroundColor = [UIColor colorWithRed:0.22 green:0.29 blue:0.36 alpha:1.00];
        
        _tagShouldUseGradientBackgrounds = NO;
        _tagGradientBackgroundStartColor = [UIColor clearColor];
        _tagGradientBackgroundEndColor = [UIColor clearColor];
        _tagSelectedGradientBackgroundStartColor = [UIColor clearColor];
        _tagSelectedGradientBackgroundEndColor = [UIColor clearColor];
        _tagGradientStartPoint = CGPointMake(0.5, 0.0);
        _tagGradientEndPoint = CGPointMake(0.5, 1.0);
        
        _tagCornerRadius = 4.0f;
        _tagSelectedCornerRadius = 4.0f;
        _roundTopLeft = true;
        _roundTopRight = true;
        _roundBottomLeft = true;
        _roundBottomRight = true;
        
        _tagBorderWidth = 1.0f;
        _tagSelectedBorderWidth = 1.0f;
        
        _tagBorderColor = [UIColor whiteColor];
        _tagSelectedBorderColor = [UIColor whiteColor];
        
        _tagShadowColor = [UIColor clearColor];
        _tagShadowOffset = CGSizeZero;
        _tagShadowRadius = 0;
        _tagShadowOpacity = 0.0f;
        
        _tagExtraSpace = CGSizeMake(14, 14);
        _tagMaxWidth = 0.0f;
        _tagMinWidth = 0.0f;
        
        _extraData = nil;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    TTGTextTagConfig *newConfig = [TTGTextTagConfig new];
    newConfig.tagTextFont = [_tagTextFont copyWithZone:zone];
    
    newConfig.tagTextColor = [_tagTextColor copyWithZone:zone];
    newConfig.tagSelectedTextColor = [_tagSelectedTextColor copyWithZone:zone];
    
    newConfig.tagBackgroundColor = [_tagBackgroundColor copyWithZone:zone];
    newConfig.tagSelectedBackgroundColor = [_tagSelectedBackgroundColor copyWithZone:zone];
    
    newConfig.tagShouldUseGradientBackgrounds = _tagShouldUseGradientBackgrounds;
    newConfig.tagGradientBackgroundStartColor = [_tagGradientBackgroundStartColor copyWithZone:zone];
    newConfig.tagGradientBackgroundEndColor = [_tagGradientBackgroundEndColor copyWithZone:zone];
    newConfig.tagSelectedGradientBackgroundStartColor = [_tagSelectedGradientBackgroundStartColor copyWithZone:zone];
    newConfig.tagSelectedGradientBackgroundEndColor = [_tagSelectedGradientBackgroundEndColor copyWithZone:zone];
    newConfig.tagGradientStartPoint = _tagGradientStartPoint;
    newConfig.tagGradientEndPoint = _tagGradientEndPoint;
    
    newConfig.tagCornerRadius = _tagCornerRadius;
    newConfig.tagSelectedCornerRadius = _tagSelectedCornerRadius;
    newConfig.roundTopLeft = _roundTopLeft;
    newConfig.roundTopRight = _roundTopRight;
    newConfig.roundBottomLeft = _roundBottomLeft;
    newConfig.roundBottomRight = _roundBottomRight;
    
    newConfig.tagBorderWidth = _tagBorderWidth;
    newConfig.tagSelectedBorderWidth = _tagSelectedBorderWidth;
    
    newConfig.tagBorderColor = [_tagBorderColor copyWithZone:zone];
    newConfig.tagSelectedBorderColor = [_tagSelectedBorderColor copyWithZone:zone];
    
    newConfig.tagShadowColor = [_tagShadowColor copyWithZone:zone];
    newConfig.tagShadowOffset = _tagShadowOffset;
    newConfig.tagShadowRadius = _tagShadowRadius;
    newConfig.tagShadowOpacity = _tagShadowOpacity;
    
    newConfig.tagExtraSpace = _tagExtraSpace;
    newConfig.tagMaxWidth = _tagMaxWidth;
    newConfig.tagMinWidth = _tagMinWidth;
    
    if ([_extraData conformsToProtocol:@protocol(NSCopying)] &&
        [_extraData respondsToSelector:@selector(copyWithZone:)]) {
        newConfig.extraData = [((id <NSCopying>)_extraData) copyWithZone:zone];
    } else {
        newConfig.extraData = _extraData;
    }
    
    return newConfig;
}

@end

#pragma mark - -----TTGTextTagLabel-----

#pragma mark - GradientLabel

@interface GradientLabel: UILabel
@end

@implementation GradientLabel
+ (Class)layerClass {
    return [CAGradientLayer class];
}
@end

// UILabel wrapper for round corner and shadow at the same time.
@interface TTGTextTagLabel : UIView
@property (nonatomic, strong) TTGTextTagConfig *config;
@property (nonatomic, strong) GradientLabel *label;
@property (assign, nonatomic) BOOL selected;
@end

@implementation TTGTextTagLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _label = [[GradientLabel alloc] initWithFrame:self.bounds];
    _label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_label];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _label.frame = self.bounds;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_label.bounds
                                                       cornerRadius:_label.layer.cornerRadius].CGPath;
}

- (void)sizeToFit {
    [_label sizeToFit];
    CGRect frame = self.frame;
    frame.size = _label.frame.size;
    self.frame = frame;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self configLimitedSize:[_label sizeThatFits:size]];
    return [_label sizeThatFits:size];
}

- (CGSize)intrinsicContentSize {
    return _label.intrinsicContentSize;
}

- (CGSize)configLimitedSize:(CGSize)size {
    if (self.config.tagMaxWidth <= 0.0 && self.config.tagMinWidth <= 0.0) { return size; }
    
    CGSize finalSize = size;
    if (self.config.tagMaxWidth > 0 && size.width > self.config.tagMaxWidth) {
        finalSize.width = self.config.tagMaxWidth;
    }
    if (self.config.tagMinWidth > 0 && size.width < self.config.tagMinWidth) {
        finalSize.width = self.config.tagMinWidth;
    }
    
    return finalSize;
}

@end

#pragma mark - -----TTGTextTagCollectionView-----

@interface TTGTextTagCollectionView () <TTGTagCollectionViewDataSource, TTGTagCollectionViewDelegate>
@property (strong, nonatomic) NSMutableArray <TTGTextTagLabel *> *tagLabels;
@property (strong, nonatomic) TTGTagCollectionView *tagCollectionView;
@end

@implementation TTGTextTagCollectionView

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
    
    _defaultConfig = [TTGTextTagConfig new];
    
    _tagCollectionView = [[TTGTagCollectionView alloc] initWithFrame:self.bounds];
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

#pragma mark - Public methods

- (void)reload {
    [self updateAllLabelStyleAndFrame];
    [_tagCollectionView reload];
    [self invalidateIntrinsicContentSize];
}

- (void)addTag:(NSString *)tag {
    [self insertTag:tag atIndex:_tagLabels.count];
}

- (void)addTag:(NSString *)tag withConfig:(TTGTextTagConfig *)config {
    [self insertTag:tag atIndex:_tagLabels.count withConfig:config];
}

- (void)addTags:(NSArray <NSString *> *)tags {
    [self insertTags:tags atIndex:_tagLabels.count withConfig:_defaultConfig copyConfig:NO];
}

- (void)addTags:(NSArray<NSString *> *)tags withConfig:(TTGTextTagConfig *)config {
    [self insertTags:tags atIndex:_tagLabels.count withConfig:config copyConfig:YES];
}

- (void)insertTag:(NSString *)tag atIndex:(NSUInteger)index {
    if ([tag isKindOfClass:[NSString class]]) {
        [self insertTags:@[tag] atIndex:index withConfig:_defaultConfig copyConfig:NO];
    }
}

- (void)insertTag:(NSString *)tag atIndex:(NSUInteger)index withConfig:(TTGTextTagConfig *)config {
    if ([tag isKindOfClass:[NSString class]]) {
        [self insertTags:@[tag] atIndex:index withConfig:config copyConfig:YES];
    }
}

- (void)insertTags:(NSArray<NSString *> *)tags atIndex:(NSUInteger)index {
    [self insertTags:tags atIndex:index withConfig:_defaultConfig copyConfig:NO];
}

- (void)insertTags:(NSArray<NSString *> *)tags atIndex:(NSUInteger)index withConfig:(TTGTextTagConfig *)config {
    [self insertTags:tags atIndex:index withConfig:config copyConfig:YES];
}

- (void)insertTags:(NSArray<NSString *> *)tags atIndex:(NSUInteger)index withConfig:(TTGTextTagConfig *)config copyConfig:(BOOL)copyConfig {
    if (![tags isKindOfClass:[NSArray class]] || index > _tagLabels.count || ![config isKindOfClass:[TTGTextTagConfig class]]) {
        return;
    }
    
    if (copyConfig) {
        config = [config copy];
    }
    
    NSMutableArray *newTagLabels = [NSMutableArray new];
    for (NSString *tagText in tags) {
        TTGTextTagLabel *label = [self newLabelForTagText:[tagText description] withConfig:config];
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
    for (TTGTextTagLabel *label in _tagLabels) {
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

- (void)setTagAtIndex:(NSUInteger)index withConfig:(TTGTextTagConfig *)config {
    if (index >= _tagLabels.count || ![config isKindOfClass:[TTGTextTagConfig class]]) {
        return;
    }
    
    _tagLabels[index].config = [config copy];
    [self reload];
}

- (void)setTagsInRange:(NSRange)range withConfig:(TTGTextTagConfig *)config {
    if (NSMaxRange(range) > _tagLabels.count || ![config isKindOfClass:[TTGTextTagConfig class]]) {
        return;
    }
    
    NSArray *tagLabels = [_tagLabels subarrayWithRange:range];
    config = [config copy];
    for (TTGTextTagLabel *label in tagLabels) {
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
        for (TTGTextTagLabel *label in [_tagLabels subarrayWithRange:range]) {
            [tags addObject:[label.label.text copy]];
        }
        return [tags copy];
    } else {
        return nil;
    }
}

- (TTGTextTagConfig *)getConfigAtIndex:(NSUInteger)index {
    if (index < _tagLabels.count) {
        return [_tagLabels[index].config copy];
    } else {
        return nil;
    }
}

- (NSArray<TTGTextTagConfig *> *)getConfigsInRange:(NSRange)range {
    if (NSMaxRange(range) <= _tagLabels.count) {
        NSMutableArray *configs = [NSMutableArray new];
        for (TTGTextTagLabel *label in [_tagLabels subarrayWithRange:range]) {
            [configs addObject:[label.config copy]];
        }
        return [configs copy];
    } else {
        return nil;
    }
}

- (NSArray <NSString *> *)allTags {
    NSMutableArray *allTags = [NSMutableArray new];
    
    for (TTGTextTagLabel *label in _tagLabels) {
        [allTags addObject:[label.label.text copy]];
    }
    
    return [allTags copy];
}

- (NSArray <NSString *> *)allSelectedTags {
    NSMutableArray *allTags = [NSMutableArray new];
    
    for (TTGTextTagLabel *label in _tagLabels) {
        if (label.selected) {
            [allTags addObject:[label.label.text copy]];
        }
    }
    
    return [allTags copy];
}

- (NSArray <NSString *> *)allNotSelectedTags {
    NSMutableArray *allTags = [NSMutableArray new];
    
    for (TTGTextTagLabel *label in _tagLabels) {
        if (!label.selected) {
            [allTags addObject:[label.label.text copy]];
        }
    }
    
    return [allTags copy];
}

- (NSInteger)indexOfTagAt:(CGPoint)point {
    // We expect the point to be a point wrt to the TTGTextTagCollectionView.
    // so convert this point first to a point wrt to the TTGTagCollectionView.
    CGPoint convertedPoint = [self convertPoint:point toView:_tagCollectionView];
    return [_tagCollectionView indexOfTagAt:convertedPoint];
}

#pragma mark - TTGTagCollectionViewDataSource

- (NSUInteger)numberOfTagsInTagCollectionView:(TTGTagCollectionView *)tagCollectionView {
    return _tagLabels.count;
}

- (UIView *)tagCollectionView:(TTGTagCollectionView *)tagCollectionView tagViewForIndex:(NSUInteger)index {
    return _tagLabels[index];
}

#pragma mark - TTGTagCollectionViewDelegate

- (BOOL)tagCollectionView:(TTGTagCollectionView *)tagCollectionView shouldSelectTag:(UIView *)tagView atIndex:(NSUInteger)index {
    if (_enableTagSelection) {
        TTGTextTagLabel *label = _tagLabels[index];
        
        if ([self.delegate respondsToSelector:@selector(textTagCollectionView:canTapTag:atIndex:currentSelected:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            return [self.delegate textTagCollectionView:self canTapTag:label.label.text atIndex:index currentSelected:label.selected];
#pragma clang diagnostic pop
        } else if ([self.delegate respondsToSelector:@selector(textTagCollectionView:canTapTag:atIndex:currentSelected:tagConfig:)]) {
            return [self.delegate textTagCollectionView:self canTapTag:label.label.text atIndex:index currentSelected:label.selected tagConfig:label.config];
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

- (void)tagCollectionView:(TTGTagCollectionView *)tagCollectionView didSelectTag:(UIView *)tagView atIndex:(NSUInteger)index {
    if (_enableTagSelection) {
        TTGTextTagLabel *label = _tagLabels[index];
        
        if (!label.selected && _selectionLimit > 0 && [self allSelectedTags].count + 1 > _selectionLimit) {
            return;
        }
        
        label.selected = !label.selected;
        
        if (self.alignment == TTGTagCollectionAlignmentFillByExpandingWidth) {
            [self reload];
        } else {
            [self updateStyleAndFrameForLabel:label];
        }
        
        if ([_delegate respondsToSelector:@selector(textTagCollectionView:didTapTag:atIndex:selected:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [_delegate textTagCollectionView:self didTapTag:label.label.text atIndex:index selected:label.selected];
#pragma clang diagnostic pop
        }
        
        if ([_delegate respondsToSelector:@selector(textTagCollectionView:didTapTag:atIndex:selected:tagConfig:)]) {
            [_delegate textTagCollectionView:self didTapTag:label.label.text atIndex:index selected:label.selected tagConfig:label.config];
        }
    }
}

- (CGSize)tagCollectionView:(TTGTagCollectionView *)tagCollectionView sizeForTagAtIndex:(NSUInteger)index {
    return _tagLabels[index].frame.size;
}

- (void)tagCollectionView:(TTGTagCollectionView *)tagCollectionView updateContentSize:(CGSize)contentSize {
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

- (TTGTagCollectionScrollDirection)scrollDirection {
    return _tagCollectionView.scrollDirection;
}

- (void)setScrollDirection:(TTGTagCollectionScrollDirection)scrollDirection {
    _tagCollectionView.scrollDirection = scrollDirection;
}

- (TTGTagCollectionAlignment)alignment {
    return _tagCollectionView.alignment;
}

- (void)setAlignment:(TTGTagCollectionAlignment)alignment {
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
    for (TTGTextTagLabel *label in _tagLabels) {
        [self updateStyleAndFrameForLabel:label];
    }
}

- (void)updateStyleAndFrameForLabel:(TTGTextTagLabel *)label {
    [super layoutSubviews];
    
    TTGTextTagConfig *config = label.config;
    
    
    UIRectCorner corners = -1;
    if (config.roundTopLeft) {
        if (corners == -1) {
            corners = UIRectCornerTopLeft;
        } else {
            corners = corners | UIRectCornerTopLeft;
        }
    }
    
    if (config.roundTopRight) {
        if (corners == -1) {
            corners = UIRectCornerTopRight;
        } else {
            corners = corners | UIRectCornerTopRight;
        }
    }
    
    if (config.roundBottomLeft) {
        if (corners == -1) {
            corners = UIRectCornerBottomLeft;
        } else {
            corners = corners | UIRectCornerBottomLeft;
        }
    }
    
    if (config.roundBottomRight) {
        if (corners == -1) {
            corners = UIRectCornerBottomRight;
        } else {
            corners = corners | UIRectCornerBottomRight;
        }
    }
    
    CGFloat currentCornerRadius = label.selected ? config.tagSelectedCornerRadius : config.tagCornerRadius;
    
    UIBezierPath *maskPath = [UIBezierPath
                              bezierPathWithRoundedRect:label.bounds
                              byRoundingCorners: corners
                              cornerRadii:CGSizeMake(currentCornerRadius, currentCornerRadius)
                              ];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    
    maskLayer.frame = label.bounds;
    maskLayer.path = maskPath.CGPath;
    
    label.layer.mask = maskLayer;
    
    label.label.font = config.tagTextFont;
    label.label.textColor = label.selected ? config.tagSelectedTextColor : config.tagTextColor;
    label.label.backgroundColor = label.selected ? config.tagSelectedBackgroundColor : config.tagBackgroundColor;
    
    if (config.tagShouldUseGradientBackgrounds) {
        label.label.backgroundColor = [UIColor clearColor];
        if (label.selected) {
            ((CAGradientLayer *)label.label.layer).colors = @[(id)config.tagSelectedGradientBackgroundStartColor.CGColor,
                                                              (id)config.tagSelectedGradientBackgroundEndColor.CGColor];
        } else {
            ((CAGradientLayer *)label.label.layer).colors = @[(id)config.tagGradientBackgroundStartColor.CGColor,
                                                              (id)config.tagGradientBackgroundEndColor.CGColor];
        }
        ((CAGradientLayer *)label.label.layer).startPoint = config.tagGradientStartPoint;
        ((CAGradientLayer *)label.label.layer).endPoint = config.tagGradientEndPoint;
    }
    
    label.label.layer.borderWidth = label.selected ? config.tagSelectedBorderWidth : config.tagBorderWidth;
    label.label.layer.borderColor = (label.selected && config.tagSelectedBorderColor) ? config.tagSelectedBorderColor.CGColor : config.tagBorderColor.CGColor;
    label.label.layer.cornerRadius = label.selected ? config.tagSelectedCornerRadius : config.tagCornerRadius;
    label.label.layer.masksToBounds = YES;
    
    label.layer.shadowColor = (config.tagShadowColor ?: [UIColor clearColor]).CGColor;
    label.layer.shadowOffset = config.tagShadowOffset;
    label.layer.shadowRadius = config.tagShadowRadius;
    label.layer.shadowOpacity = config.tagShadowOpacity;
    label.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:label.bounds cornerRadius:label.label.layer.cornerRadius].CGPath;
    label.layer.shouldRasterize = YES;
    [label.layer setRasterizationScale:[[UIScreen mainScreen] scale]];
    
    // Update frame
    CGSize size = [label sizeThatFits:CGSizeZero];
    size.width += config.tagExtraSpace.width;
    size.height += config.tagExtraSpace.height;
    
    // Width limit for vertical scroll direction
    if (self.scrollDirection == TTGTagCollectionScrollDirectionVertical &&
        size.width > (CGRectGetWidth(self.bounds) - self.contentInset.left - self.contentInset.right)) {
        size.width = (CGRectGetWidth(self.bounds) - self.contentInset.left - self.contentInset.right);
    }
    
    label.frame = (CGRect){label.frame.origin, size};
}

- (TTGTextTagLabel *)newLabelForTagText:(NSString *)tagText withConfig:(TTGTextTagConfig *)config {
    TTGTextTagLabel *label = [TTGTextTagLabel new];
    label.label.text = tagText;
    label.config = config;
    [self updateStyleAndFrameForLabel:label];
    return label;
}

@end
