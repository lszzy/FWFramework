/*!
 @header     FWSegmentedControl.m
 @indexgroup FWFramework
 @brief      FWSegmentedControl
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/20
 */

#import "FWSegmentedControl.h"
#import "UIView+FWStatistical.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

NSUInteger FWSegmentedControlNoSegment = (NSUInteger)-1;

@protocol FWAccessibilityDelegate <NSObject>
@required
-(void)scrollToAccessibilityElement:(id)sender;
@end

@interface FWAccessibilityElement : UIAccessibilityElement
@property (nonatomic, weak) id<FWAccessibilityDelegate> delegate;
@end

@interface FWSegmentedScrollView : UIScrollView
@end

@interface FWSegmentedControl () <UIScrollViewDelegate, FWAccessibilityDelegate, FWStatisticalDelegate>

@property (nonatomic, strong) CALayer *selectionIndicatorStripLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorBoxLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorShapeLayer;
@property (nonatomic, readwrite) CGFloat segmentWidth;
@property (nonatomic, readwrite) NSArray<NSNumber *> *segmentWidthsArray;
@property (nonatomic, strong) FWSegmentedScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *accessibilityElements;
@property (nonatomic, strong) NSMutableArray *titleBackgroundLayers;

@property (nonatomic, copy) FWStatisticalCallback clickCallback;
@property (nonatomic, copy) FWStatisticalCallback exposureCallback;
@property (nonatomic, copy) NSArray<NSNumber *> *exposureIndexes;

@end

@implementation FWAccessibilityElement

- (void)accessibilityElementDidBecomeFocused
{
    if (_delegate!=nil && [_delegate respondsToSelector:@selector(scrollToAccessibilityElement:)])
        [_delegate performSelector:@selector(scrollToAccessibilityElement:) withObject:self];
}

@end

@implementation FWSegmentedScrollView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesBegan:touches withEvent:event];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (!self.dragging) {
        [self.nextResponder touchesMoved:touches withEvent:event];
    } else{
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesEnded:touches withEvent:event];
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

@end

@implementation FWSegmentedControl

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithSectionTitles:(NSArray<NSString *> *)sectionTitles {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
        self.type = FWSegmentedControlTypeText;
        self.sectionTitles = sectionTitles;
    }
    return self;
}

- (instancetype)initWithSectionImages:(NSArray<UIImage *> *)sectionImages sectionSelectedImages:(NSArray<UIImage *> *)sectionSelectedImages {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
        self.type = FWSegmentedControlTypeImages;
        self.sectionImages = sectionImages;
        self.sectionSelectedImages = sectionSelectedImages;
    }
    return self;
}

- (instancetype)initWithSectionImages:(NSArray<UIImage *> *)sectionImages sectionSelectedImages:(NSArray<UIImage *> *)sectionSelectedImages titlesForSections:(NSArray<NSString *> *)sectionTitles {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
        
        if (sectionImages.count != sectionTitles.count) {
            [NSException raise:NSRangeException format:@"***%s: Images bounds (%ld) Don't match Title bounds (%ld)", sel_getName(_cmd), (unsigned long)sectionImages.count, (unsigned long)sectionTitles.count];
        }
        
        self.type = FWSegmentedControlTypeTextImages;
        self.sectionImages = sectionImages;
        self.sectionSelectedImages = sectionSelectedImages;
        self.sectionTitles = sectionTitles;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.segmentWidth = 0.0f;
}

- (void)commonInit {
    self.scrollView = [[FWSegmentedScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    
    _backgroundColor = [UIColor whiteColor];
    self.opaque = NO;
    _selectionIndicatorColor = [UIColor colorWithRed:52.0f/255.0f green:181.0f/255.0f blue:229.0f/255.0f alpha:1.0f];
    _selectionIndicatorBoxColor = _selectionIndicatorColor;

    self.selectedSegmentIndex = 0;
    self.segmentEdgeInset = UIEdgeInsetsMake(0, 5, 0, 5);
    self.selectionIndicatorHeight = 5.0f;
    self.selectionIndicatorEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    self.selectionStyle = FWSegmentedControlSelectionStyleTextWidthStripe;
    self.selectionIndicatorLocation = FWSegmentedControlSelectionIndicatorLocationTop;
    self.segmentWidthStyle = FWSegmentedControlSegmentWidthStyleFixed;
    self.userDraggable = YES;
    self.touchEnabled = YES;
    self.verticalDividerEnabled = NO;
    self.type = FWSegmentedControlTypeText;
    self.verticalDividerWidth = 1.0f;
    _verticalDividerColor = [UIColor blackColor];
    self.borderColor = [UIColor blackColor];
    self.borderWidth = 1.0f;
    
    self.shouldAnimateUserSelection = YES;
    
    self.selectionIndicatorShapeLayer = [CALayer layer];
    self.selectionIndicatorStripLayer = [CALayer layer];
    self.selectionIndicatorBoxLayer = [CALayer layer];
    self.selectionIndicatorBoxLayer.opacity = self.selectionIndicatorBoxOpacity;
    self.selectionIndicatorBoxLayer.borderWidth = 1.0f;
    self.selectionIndicatorBoxOpacity = 0.2;
    self.selectionIndicatorCornerRadius = 0;
    
    self.contentMode = UIViewContentModeRedraw;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateSegmentsRects];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self updateSegmentsRects];
}

- (void)setSectionTitles:(NSArray<NSString *> *)sectionTitles {
    _sectionTitles = sectionTitles;
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)setSectionImages:(NSArray<UIImage *> *)sectionImages {
    _sectionImages = sectionImages;
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)setSelectionIndicatorLocation:(FWSegmentedControlSelectionIndicatorLocation)selectionIndicatorLocation {
    _selectionIndicatorLocation = selectionIndicatorLocation;
    
    if (selectionIndicatorLocation == FWSegmentedControlSelectionIndicatorLocationNone) {
        self.selectionIndicatorHeight = 0.0f;
    }
}

- (void)setSelectionIndicatorBoxOpacity:(CGFloat)selectionIndicatorBoxOpacity {
    _selectionIndicatorBoxOpacity = selectionIndicatorBoxOpacity;
    
    self.selectionIndicatorBoxLayer.opacity = _selectionIndicatorBoxOpacity;
}

- (void)setSelectionIndicatorCornerRadius:(CGFloat)selectionIndicatorCornerRadius {
    _selectionIndicatorCornerRadius = selectionIndicatorCornerRadius;
    
    self.selectionIndicatorStripLayer.cornerRadius = _selectionIndicatorCornerRadius;
}

- (void)setSegmentWidthStyle:(FWSegmentedControlSegmentWidthStyle)segmentWidthStyle {
    // Force FWSegmentedControlSegmentWidthStyleFixed when type is FWSegmentedControlTypeImages.
    if (self.type == FWSegmentedControlTypeImages) {
        _segmentWidthStyle = FWSegmentedControlSegmentWidthStyleFixed;
    } else {
        _segmentWidthStyle = segmentWidthStyle;
    }
}

- (void)setBorderType:(FWSegmentedControlBorderType)borderType {
    _borderType = borderType;
    [self setNeedsDisplay];
}

- (NSMutableArray *)titleBackgroundLayers {
    if (_titleBackgroundLayers) {
        return _titleBackgroundLayers;
    }
    _titleBackgroundLayers = @[].mutableCopy;
    return _titleBackgroundLayers;
}

#pragma mark - Drawing

- (CGSize)measureTitleAtIndex:(NSUInteger)index {
    if (index >= self.sectionTitles.count) {
        return CGSizeZero;
    }
    
    id title = self.sectionTitles[index];
    CGSize size = CGSizeZero;
    BOOL selected = (index == self.selectedSegmentIndex) ? YES : NO;
    if ([title isKindOfClass:[NSString class]] && !self.titleFormatter) {
        NSDictionary *titleAttrs = selected ? [self resultingSelectedTitleTextAttributes] : [self resultingTitleTextAttributes];
        size = [(NSString *)title sizeWithAttributes:titleAttrs];
        UIFont *font = titleAttrs[@"NSFont"];
        size = CGSizeMake(ceil(size.width), ceil(size.height-font.descender));
    } else if ([title isKindOfClass:[NSString class]] && self.titleFormatter) {
        size = [self.titleFormatter(self, title, index, selected) size];
    } else if ([title isKindOfClass:[NSAttributedString class]]) {
        size = [(NSAttributedString *)title size];
    } else {
        NSAssert(title == nil, @"Unexpected type of segment title: %@", [title class]);
        size = CGSizeZero;
    }
    return CGRectIntegral((CGRect){CGPointZero, size}).size;
}

- (NSAttributedString *)attributedTitleAtIndex:(NSUInteger)index {
    id title = self.sectionTitles[index];
    BOOL selected = (index == self.selectedSegmentIndex) ? YES : NO;
    
    if ([title isKindOfClass:[NSAttributedString class]]) {
        return (NSAttributedString *)title;
    } else if (!self.titleFormatter) {
        NSDictionary *titleAttrs = selected ? [self resultingSelectedTitleTextAttributes] : [self resultingTitleTextAttributes];
        
        // the color should be cast to CGColor in order to avoid invalid context on iOS7
        UIColor *titleColor = titleAttrs[NSForegroundColorAttributeName];
        
        if (titleColor) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:titleAttrs];
            
            dict[NSForegroundColorAttributeName] = titleColor;
            
            titleAttrs = [NSDictionary dictionaryWithDictionary:dict];
        }
        
        return [[NSAttributedString alloc] initWithString:(NSString *)title attributes:titleAttrs];
    } else {
        return self.titleFormatter(self, title, index, selected);
    }
}

- (void)drawRect:(CGRect)rect {
    [self.backgroundColor setFill];
    UIRectFill([self bounds]);
    
    self.selectionIndicatorShapeLayer.backgroundColor = self.selectionIndicatorColor.CGColor;
    
    self.selectionIndicatorStripLayer.backgroundColor = self.selectionIndicatorColor.CGColor;
    
    self.selectionIndicatorBoxLayer.backgroundColor = self.selectionIndicatorBoxColor.CGColor;
    self.selectionIndicatorBoxLayer.borderColor = self.selectionIndicatorBoxColor.CGColor;
    
    // Remove all sublayers to avoid drawing images over existing ones
    self.scrollView.layer.sublayers = nil;
    
    CGRect oldRect = rect;
    
    if (self.accessibilityElements==nil)
        self.accessibilityElements = [NSMutableArray arrayWithCapacity:0];
    
    if (self.type == FWSegmentedControlTypeText) {
        [self removeTitleBackgroundLayers];
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {

            CGFloat stringWidth = 0;
            CGFloat stringHeight = 0;
            CGSize size = [self measureTitleAtIndex:idx];
            stringWidth = size.width;
            stringHeight = size.height;
            CGRect rectDiv = CGRectZero;
            CGRect fullRect = CGRectZero;
            
            // Text inside the CATextLayer will appear blurry unless the rect values are rounded
            BOOL locationUp = (self.selectionIndicatorLocation == FWSegmentedControlSelectionIndicatorLocationTop);
            BOOL selectionStyleNotBox = (self.selectionStyle != FWSegmentedControlSelectionStyleBox);

            CGFloat y = roundf((CGRectGetHeight(self.frame) - selectionStyleNotBox * self.selectionIndicatorHeight) / 2 - stringHeight / 2 + self.selectionIndicatorHeight * locationUp);
            CGRect rect;
            if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleFixed) {
                rect = CGRectMake((self.segmentWidth * idx) + (self.segmentWidth - stringWidth) / 2, y, stringWidth, stringHeight);
                rectDiv = CGRectMake((self.segmentWidth * idx) - (self.verticalDividerWidth / 2), self.selectionIndicatorHeight * 2, self.verticalDividerWidth, self.frame.size.height - (self.selectionIndicatorHeight * 4));
                fullRect = CGRectMake(self.segmentWidth * idx, 0, self.segmentWidth, oldRect.size.height);
            } else {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                CGFloat xOffset = 0;
                NSUInteger i = 0;
                for (NSNumber *width in self.segmentWidthsArray) {
                    if (idx == i)
                        break;
                    xOffset = xOffset + [width floatValue];
                    i++;
                }
                
                CGFloat widthForIndex = [[self.segmentWidthsArray objectAtIndex:idx] floatValue];
                rect = CGRectMake(xOffset, y, widthForIndex, stringHeight);
                fullRect = CGRectMake(xOffset, 0, widthForIndex, oldRect.size.height);
                rectDiv = CGRectMake(xOffset - (self.verticalDividerWidth / 2), self.selectionIndicatorHeight * 2, self.verticalDividerWidth, self.frame.size.height - (self.selectionIndicatorHeight * 4));
            }
            
            // Fix rect position/size to avoid blurry labels
            rect = CGRectMake(ceilf(rect.origin.x), ceilf(rect.origin.y), ceilf(rect.size.width), ceilf(rect.size.height));
            
            CATextLayer *titleLayer = [CATextLayer layer];
            titleLayer.frame = rect;
            titleLayer.alignmentMode = kCAAlignmentCenter;
            if ([UIDevice currentDevice].systemVersion.floatValue < 10.0 ) {
                titleLayer.truncationMode = kCATruncationEnd;
            }
            titleLayer.string = [self attributedTitleAtIndex:idx];
            titleLayer.contentsScale = [[UIScreen mainScreen] scale];
            
            [self.scrollView.layer addSublayer:titleLayer];
            
            // Vertical Divider
            if (self.isVerticalDividerEnabled && idx > 0) {
                CALayer *verticalDividerLayer = [CALayer layer];
                verticalDividerLayer.frame = rectDiv;
                verticalDividerLayer.backgroundColor = self.verticalDividerColor.CGColor;
                
                [self.scrollView.layer addSublayer:verticalDividerLayer];
            }
            
            if ([self.accessibilityElements count]<=idx) {
                FWAccessibilityElement *element = [[FWAccessibilityElement alloc] initWithAccessibilityContainer:self];
                element.delegate = self;
                element.accessibilityLabel = (self.sectionTitles!=nil&&[self.sectionTitles count]>idx)?[self.sectionTitles objectAtIndex:idx]:[NSString stringWithFormat:@"item %u", (unsigned)idx+1];
                element.accessibilityFrame = [self convertRect:fullRect toView:nil];
                if (self.selectedSegmentIndex==idx)
                    element.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
                else
                    element.accessibilityTraits = UIAccessibilityTraitButton;
                [self.accessibilityElements addObject:element];
            } else {
                CGFloat offset = 0.f;
                for (NSUInteger i = 0; i<idx; i++) {
                    FWAccessibilityElement *accessibilityItem = [self.accessibilityElements objectAtIndex:i];
                    offset += accessibilityItem.accessibilityFrame.size.width;
                }
                FWAccessibilityElement *element = [self.accessibilityElements objectAtIndex:idx];
                CGRect newRect = CGRectMake(offset-self.scrollView.contentOffset.x, 0, element.accessibilityFrame.size.width, element.accessibilityFrame.size.height);
                element.accessibilityFrame = [self convertRect:newRect toView:nil];
                if (self.selectedSegmentIndex==idx)
                    element.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
                else
                    element.accessibilityTraits = UIAccessibilityTraitButton;
            }
        
            [self addBackgroundAndBorderLayerWithRect:fullRect];
        }];
    } else if (self.type == FWSegmentedControlTypeImages) {
        [self removeTitleBackgroundLayers];
        [self.sectionImages enumerateObjectsUsingBlock:^(id iconImage, NSUInteger idx, BOOL *stop) {
            UIImage *icon = iconImage;
            CGFloat imageWidth = icon.size.width;
            CGFloat imageHeight = icon.size.height;
            CGFloat y = roundf(CGRectGetHeight(self.frame) - self.selectionIndicatorHeight) / 2 - imageHeight / 2 + ((self.selectionIndicatorLocation == FWSegmentedControlSelectionIndicatorLocationTop) ? self.selectionIndicatorHeight : 0);
            CGFloat x = self.segmentWidth * idx + (self.segmentWidth - imageWidth)/2.0f;
            CGRect rect = CGRectMake(x, y, imageWidth, imageHeight);
            
            CALayer *imageLayer = [CALayer layer];
            imageLayer.frame = rect;
            
            if (self.selectedSegmentIndex == idx && self.selectedSegmentIndex < self.sectionSelectedImages.count) {
                if (self.sectionSelectedImages) {
                    UIImage *highlightIcon = [self.sectionSelectedImages objectAtIndex:idx];
                    imageLayer.contents = (id)highlightIcon.CGImage;
                } else {
                    imageLayer.contents = (id)icon.CGImage;
                }
            } else {
                imageLayer.contents = (id)icon.CGImage;
            }
            
            [self.scrollView.layer addSublayer:imageLayer];
            // Vertical Divider
            if (self.isVerticalDividerEnabled && idx>0) {
                CALayer *verticalDividerLayer = [CALayer layer];
                verticalDividerLayer.frame = CGRectMake((self.segmentWidth * idx) - (self.verticalDividerWidth / 2), self.selectionIndicatorHeight * 2, self.verticalDividerWidth, self.frame.size.height-(self.selectionIndicatorHeight * 4));
                verticalDividerLayer.backgroundColor = self.verticalDividerColor.CGColor;
                
                [self.scrollView.layer addSublayer:verticalDividerLayer];
            }
            
            if ([self.accessibilityElements count]<=idx) {
                FWAccessibilityElement *element = [[FWAccessibilityElement alloc] initWithAccessibilityContainer:self];
                element.delegate = self;
                element.accessibilityLabel = (self.sectionTitles!=nil&&[self.sectionTitles count]>idx)?[self.sectionTitles objectAtIndex:idx]:[NSString stringWithFormat:@"item %u", (unsigned)idx+1];
                element.accessibilityFrame = [self convertRect:rect toView:nil];
                if (self.selectedSegmentIndex==idx)
                    element.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
                else
                    element.accessibilityTraits = UIAccessibilityTraitButton;
                [self.accessibilityElements addObject:element];
            } else {
                CGFloat offset = 0.f;
                for (NSUInteger i = 0; i<idx; i++) {
                    FWAccessibilityElement *accessibilityItem = [self.accessibilityElements objectAtIndex:i];
                    offset += accessibilityItem.accessibilityFrame.size.width;
                }
                FWAccessibilityElement *element = [self.accessibilityElements objectAtIndex:idx];
                CGRect newRect = CGRectMake(offset-self.scrollView.contentOffset.x, 0, element.accessibilityFrame.size.width, element.accessibilityFrame.size.height);
                element.accessibilityFrame = [self convertRect:newRect toView:nil];
                if (self.selectedSegmentIndex==idx)
                    element.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
                else
                    element.accessibilityTraits = UIAccessibilityTraitButton;
            }
            
            [self addBackgroundAndBorderLayerWithRect:rect];
        }];
    } else if (self.type == FWSegmentedControlTypeTextImages){
        [self removeTitleBackgroundLayers];
        [self.sectionImages enumerateObjectsUsingBlock:^(id iconImage, NSUInteger idx, BOOL *stop) {
            UIImage *icon = iconImage;
            CGFloat imageWidth = icon.size.width;
            CGFloat imageHeight = icon.size.height;
            
            CGSize stringSize = [self measureTitleAtIndex:idx];
            CGFloat stringHeight = stringSize.height;
            CGFloat stringWidth = stringSize.width;
            
            CGFloat imageXOffset = self.segmentWidth * idx; // Start with edge inset
            CGFloat textXOffset  = self.segmentWidth * idx;
            CGFloat imageYOffset = ceilf((self.frame.size.height - imageHeight) / 2.0); // Start in center
            CGFloat textYOffset  = ceilf((self.frame.size.height - stringHeight) / 2.0);
            
            
            if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleFixed) {
                BOOL isImageInLineWidthText = self.imagePosition == FWSegmentedControlImagePositionLeftOfText || self.imagePosition == FWSegmentedControlImagePositionRightOfText;
                if (isImageInLineWidthText) {
                    CGFloat whitespace = self.segmentWidth - stringSize.width - imageWidth - self.textImageSpacing;
                    if (self.imagePosition == FWSegmentedControlImagePositionLeftOfText) {
                        imageXOffset += whitespace / 2.0;
                        textXOffset = imageXOffset + imageWidth + self.textImageSpacing;
                    } else {
                        textXOffset += whitespace / 2.0;
                        imageXOffset = textXOffset + stringWidth + self.textImageSpacing;
                    }
                } else {
                    imageXOffset = self.segmentWidth * idx + (self.segmentWidth - imageWidth) / 2.0f; // Start with edge inset
                    textXOffset  = self.segmentWidth * idx + (self.segmentWidth - stringWidth) / 2.0f;
                    
                    CGFloat whitespace = CGRectGetHeight(self.frame) - imageHeight - stringHeight - self.textImageSpacing;
                    if (self.imagePosition == FWSegmentedControlImagePositionAboveText) {
                        imageYOffset = ceilf(whitespace / 2.0);
                        textYOffset = imageYOffset + imageHeight + self.textImageSpacing;
                    } else if (self.imagePosition == FWSegmentedControlImagePositionBelowText) {
                        textYOffset = ceilf(whitespace / 2.0);
                        imageYOffset = textYOffset + stringHeight + self.textImageSpacing;
                    }
                }
            } else if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic) {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                CGFloat xOffset = 0;
                NSUInteger i = 0;
                
                for (NSNumber *width in self.segmentWidthsArray) {
                    if (idx == i) {
                        break;
                    }
                    
                    xOffset = xOffset + [width floatValue];
                    i++;
                }
                
                BOOL isImageInLineWidthText = self.imagePosition == FWSegmentedControlImagePositionLeftOfText || self.imagePosition == FWSegmentedControlImagePositionRightOfText;
                if (isImageInLineWidthText) {
                    if (self.imagePosition == FWSegmentedControlImagePositionLeftOfText) {
                        imageXOffset = xOffset;
                        textXOffset = imageXOffset + imageWidth + self.textImageSpacing;
                    } else {
                        textXOffset = xOffset;
                        imageXOffset = textXOffset + stringWidth + self.textImageSpacing;
                    }
                } else {
                    imageXOffset = xOffset + ([self.segmentWidthsArray[i] floatValue] - imageWidth) / 2.0f; // Start with edge inset
                    textXOffset  = xOffset + ([self.segmentWidthsArray[i] floatValue] - stringWidth) / 2.0f;
                    
                    CGFloat whitespace = CGRectGetHeight(self.frame) - imageHeight - stringHeight - self.textImageSpacing;
                    if (self.imagePosition == FWSegmentedControlImagePositionAboveText) {
                        imageYOffset = ceilf(whitespace / 2.0);
                        textYOffset = imageYOffset + imageHeight + self.textImageSpacing;
                    } else if (self.imagePosition == FWSegmentedControlImagePositionBelowText) {
                        textYOffset = ceilf(whitespace / 2.0);
                        imageYOffset = textYOffset + stringHeight + self.textImageSpacing;
                    }
                }
            }
            
            CGRect imageRect = CGRectMake(imageXOffset, imageYOffset, imageWidth, imageHeight);
            CGRect textRect = CGRectMake(ceilf(textXOffset), ceilf(textYOffset), ceilf(stringWidth), ceilf(stringHeight));

            CATextLayer *titleLayer = [CATextLayer layer];
            titleLayer.frame = textRect;
            titleLayer.alignmentMode = kCAAlignmentCenter;
            titleLayer.string = [self attributedTitleAtIndex:idx];
            if ([UIDevice currentDevice].systemVersion.floatValue < 10.0 ) {
                titleLayer.truncationMode = kCATruncationEnd;
            }
            CALayer *imageLayer = [CALayer layer];
            imageLayer.frame = imageRect;
            
            if (self.selectedSegmentIndex == idx) {
                if (self.sectionSelectedImages) {
                    UIImage *highlightIcon = [self.sectionSelectedImages objectAtIndex:idx];
                    imageLayer.contents = (id)highlightIcon.CGImage;
                } else {
                    imageLayer.contents = (id)icon.CGImage;
                }
            } else {
                imageLayer.contents = (id)icon.CGImage;
            }
            
            [self.scrollView.layer addSublayer:imageLayer];
            titleLayer.contentsScale = [[UIScreen mainScreen] scale];
            [self.scrollView.layer addSublayer:titleLayer];
            
            if ([self.accessibilityElements count]<=idx) {
                FWAccessibilityElement *element = [[FWAccessibilityElement alloc] initWithAccessibilityContainer:self];
                element.delegate = self;
                element.accessibilityLabel = (self.sectionTitles!=nil&&[self.sectionTitles count]>idx)?[self.sectionTitles objectAtIndex:idx]:[NSString stringWithFormat:@"item %u", (unsigned)idx+1];
                element.accessibilityFrame = [self convertRect:CGRectUnion(textRect, imageRect) toView:nil];
                if (self.selectedSegmentIndex==idx)
                    element.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
                else
                    element.accessibilityTraits = UIAccessibilityTraitButton;
                [self.accessibilityElements addObject:element];
            } else {
                CGFloat offset = 0.f;
                for (NSUInteger i = 0; i<idx; i++) {
                    FWAccessibilityElement *accessibilityItem = [self.accessibilityElements objectAtIndex:i];
                    offset += accessibilityItem.accessibilityFrame.size.width;
                }
                FWAccessibilityElement *element = [self.accessibilityElements objectAtIndex:idx];
                CGRect newRect = CGRectMake(offset-self.scrollView.contentOffset.x, 0, element.accessibilityFrame.size.width, element.accessibilityFrame.size.height);
                element.accessibilityFrame = [self convertRect:newRect toView:nil];
                if (self.selectedSegmentIndex==idx)
                    element.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
                else
                    element.accessibilityTraits = UIAccessibilityTraitButton;
            }
            
            [self addBackgroundAndBorderLayerWithRect:imageRect];
        }];
    }
    
    // Add the selection indicators
    if (self.selectedSegmentIndex != FWSegmentedControlNoSegment && [self sectionCount] > 0) {
        if (self.selectionStyle == FWSegmentedControlSelectionStyleArrow ||
            self.selectionStyle == FWSegmentedControlSelectionStyleCircle) {
            if (!self.selectionIndicatorShapeLayer.superlayer) {
                [self setShapeFrame];
                [self.scrollView.layer addSublayer:self.selectionIndicatorShapeLayer];
            }
        } else {
            if (!self.selectionIndicatorStripLayer.superlayer) {
                self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
                [self.scrollView.layer addSublayer:self.selectionIndicatorStripLayer];
                
                if (self.selectionStyle == FWSegmentedControlSelectionStyleBox && !self.selectionIndicatorBoxLayer.superlayer) {
                    self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
                    [self.scrollView.layer insertSublayer:self.selectionIndicatorBoxLayer atIndex:0];
                }
            }
        }
    }
}

- (void)removeTitleBackgroundLayers {
    [self.titleBackgroundLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.titleBackgroundLayers removeAllObjects];
}

- (void)addBackgroundAndBorderLayerWithRect:(CGRect)fullRect {
    // Background layer
    CALayer *backgroundLayer = [CALayer layer];
    backgroundLayer.frame = fullRect;
    [self.layer insertSublayer:backgroundLayer atIndex:0];
    [self.titleBackgroundLayers addObject:backgroundLayer];
    
    // Border layer
    if (self.borderType & FWSegmentedControlBorderTypeTop) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(0, 0, fullRect.size.width, self.borderWidth);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    if (self.borderType & FWSegmentedControlBorderTypeLeft) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(0, 0, self.borderWidth, fullRect.size.height);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    if (self.borderType & FWSegmentedControlBorderTypeBottom) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(0, fullRect.size.height - self.borderWidth, fullRect.size.width, self.borderWidth);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    if (self.borderType & FWSegmentedControlBorderTypeRight) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(fullRect.size.width - self.borderWidth, 0, self.borderWidth, fullRect.size.height);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
}

- (void)setShapeFrame {
    self.selectionIndicatorShapeLayer.frame = [self frameForSelectionIndicator];
    self.selectionIndicatorShapeLayer.mask = nil;
    
    UIBezierPath *shapePath = nil;
    if (self.selectionStyle == FWSegmentedControlSelectionStyleArrow) {
        shapePath = [UIBezierPath bezierPath];
        
        CGPoint p1 = CGPointZero;
        CGPoint p2 = CGPointZero;
        CGPoint p3 = CGPointZero;
        
        if (self.selectionIndicatorLocation == FWSegmentedControlSelectionIndicatorLocationBottom) {
            p1 = CGPointMake(self.selectionIndicatorShapeLayer.bounds.size.width / 2, 0);
            p2 = CGPointMake(0, self.selectionIndicatorShapeLayer.bounds.size.height);
            p3 = CGPointMake(self.selectionIndicatorShapeLayer.bounds.size.width, self.selectionIndicatorShapeLayer.bounds.size.height);
        }
        
        if (self.selectionIndicatorLocation == FWSegmentedControlSelectionIndicatorLocationTop) {
            p1 = CGPointMake(self.selectionIndicatorShapeLayer.bounds.size.width / 2, self.selectionIndicatorShapeLayer.bounds.size.height);
            p2 = CGPointMake(self.selectionIndicatorShapeLayer.bounds.size.width, 0);
            p3 = CGPointMake(0, 0);
        }
        
        [shapePath moveToPoint:p1];
        [shapePath addLineToPoint:p2];
        [shapePath addLineToPoint:p3];
        [shapePath closePath];
    } else {
        shapePath = [UIBezierPath bezierPathWithRoundedRect:self.selectionIndicatorShapeLayer.bounds cornerRadius:self.selectionIndicatorHeight / 2];
    }
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.selectionIndicatorShapeLayer.bounds;
    maskLayer.path = shapePath.CGPath;
    self.selectionIndicatorShapeLayer.mask = maskLayer;
}

- (CGRect)frameForSelectionIndicator {
    CGFloat indicatorYOffset = 0.0f;
    
    if (self.selectionIndicatorLocation == FWSegmentedControlSelectionIndicatorLocationBottom) {
        indicatorYOffset = self.bounds.size.height - self.selectionIndicatorHeight + self.selectionIndicatorEdgeInsets.bottom;
    }
    
    if (self.selectionIndicatorLocation == FWSegmentedControlSelectionIndicatorLocationTop) {
        indicatorYOffset = self.selectionIndicatorEdgeInsets.top;
    }
    
    CGFloat sectionWidth = 0.0f;
    
    if (self.type == FWSegmentedControlTypeText) {
        CGFloat stringWidth = [self measureTitleAtIndex:self.selectedSegmentIndex].width;
        sectionWidth = stringWidth;
    } else if (self.type == FWSegmentedControlTypeImages) {
        UIImage *sectionImage = [self.sectionImages objectAtIndex:self.selectedSegmentIndex];
        CGFloat imageWidth = sectionImage.size.width;
        sectionWidth = imageWidth;
    } else if (self.type == FWSegmentedControlTypeTextImages) {
        CGFloat stringWidth = [self measureTitleAtIndex:self.selectedSegmentIndex].width;
        UIImage *sectionImage = [self.sectionImages objectAtIndex:self.selectedSegmentIndex];
        CGFloat imageWidth = sectionImage.size.width;
        sectionWidth = MAX(stringWidth, imageWidth);
    }
    
    if (self.selectionStyle == FWSegmentedControlSelectionStyleArrow ||
        self.selectionStyle == FWSegmentedControlSelectionStyleCircle) {
        CGFloat widthToEndOfSelectedSegment = 0.0f;
        CGFloat widthToStartOfSelectedIndex = 0.0f;
        
        if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic) {
            NSUInteger i = 0;
            for (NSNumber *width in self.segmentWidthsArray) {
                if (self.selectedSegmentIndex == i) {
                    widthToEndOfSelectedSegment = widthToStartOfSelectedIndex + [width floatValue];
                    break;
                }
                widthToStartOfSelectedIndex = widthToStartOfSelectedIndex + [width floatValue];
                i++;
            }
        } else {
            widthToEndOfSelectedSegment = (self.segmentWidth * self.selectedSegmentIndex) + self.segmentWidth;
            widthToStartOfSelectedIndex = (self.segmentWidth * self.selectedSegmentIndex);
        }
        
        CGFloat x = widthToStartOfSelectedIndex + ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) - (self.selectionIndicatorHeight/2);
        if (self.selectionStyle == FWSegmentedControlSelectionStyleArrow) {
            return CGRectMake(x - (self.selectionIndicatorHeight / 2), indicatorYOffset, self.selectionIndicatorHeight * 2, self.selectionIndicatorHeight);
        } else {
            return CGRectMake(x, indicatorYOffset, self.selectionIndicatorHeight, self.selectionIndicatorHeight);
        }
    } else {
        if (self.selectionStyle == FWSegmentedControlSelectionStyleTextWidthStripe &&
            sectionWidth <= self.segmentWidth &&
            self.segmentWidthStyle != FWSegmentedControlSegmentWidthStyleDynamic) {
            CGFloat widthToEndOfSelectedSegment = (self.segmentWidth * self.selectedSegmentIndex) + self.segmentWidth;
            CGFloat widthToStartOfSelectedIndex = (self.segmentWidth * self.selectedSegmentIndex);
            
            CGFloat x = ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) + (widthToStartOfSelectedIndex - sectionWidth / 2);
            return CGRectMake(x + self.selectionIndicatorEdgeInsets.left, indicatorYOffset, sectionWidth - self.selectionIndicatorEdgeInsets.right, self.selectionIndicatorHeight);
        } else {
            if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic) {
                CGFloat selectedSegmentOffset = 0.0f;
                
                NSUInteger i = 0;
                for (NSNumber *width in self.segmentWidthsArray) {
                    if (self.selectedSegmentIndex == i)
                        break;
                    selectedSegmentOffset = selectedSegmentOffset + [width floatValue];
                    i++;
                }
                if (self.selectionStyle == FWSegmentedControlSelectionStyleTextWidthStripe) {
                   return CGRectMake(selectedSegmentOffset + self.selectionIndicatorEdgeInsets.left + self.segmentEdgeInset.left, indicatorYOffset, [[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue] - self.selectionIndicatorEdgeInsets.right - self.segmentEdgeInset.left - self.segmentEdgeInset.right, self.selectionIndicatorHeight + self.selectionIndicatorEdgeInsets.bottom);
                } else {
                    return CGRectMake(selectedSegmentOffset + self.selectionIndicatorEdgeInsets.left, indicatorYOffset, [[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue] - self.selectionIndicatorEdgeInsets.right, self.selectionIndicatorHeight + self.selectionIndicatorEdgeInsets.bottom);
                }
            }
            
            return CGRectMake(self.segmentWidth * self.selectedSegmentIndex + self.selectionIndicatorEdgeInsets.left, indicatorYOffset, self.segmentWidth - self.selectionIndicatorEdgeInsets.left - self.selectionIndicatorEdgeInsets.right, self.selectionIndicatorHeight);
        }
    }
}

- (CGRect)frameForFillerSelectionIndicator {
    if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic) {
        CGFloat selectedSegmentOffset = 0.0f;
        
        NSUInteger i = 0;
        for (NSNumber *width in self.segmentWidthsArray) {
            if (self.selectedSegmentIndex == i) {
                break;
            }
            selectedSegmentOffset = selectedSegmentOffset + [width floatValue];
            
            i++;
        }
        
        return CGRectMake(selectedSegmentOffset, 0, [[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue], CGRectGetHeight(self.frame));
    }
    return CGRectMake(self.segmentWidth * self.selectedSegmentIndex, 0, self.segmentWidth, CGRectGetHeight(self.frame));
}

- (void)updateSegmentsRects {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
    if ([self sectionCount] > 0) {
        self.segmentWidth = self.frame.size.width / [self sectionCount];
    }
    
    if (self.type == FWSegmentedControlTypeText && self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleFixed) {
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            self.segmentWidth = MAX(stringWidth, self.segmentWidth);
        }];
    } else if (self.type == FWSegmentedControlTypeText && self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic) {
        NSMutableArray *mutableSegmentWidths = [NSMutableArray array];
        __block CGFloat totalWidth = 0.0;

        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            totalWidth += stringWidth;
            [mutableSegmentWidths addObject:[NSNumber numberWithFloat:stringWidth]];
        }];

        if (self.shouldStretchSegmentsToScreenSize && totalWidth < self.bounds.size.width) {
            CGFloat whitespace = self.bounds.size.width - totalWidth;
            CGFloat whitespaceForSegment = whitespace / [mutableSegmentWidths count];
            [mutableSegmentWidths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat extendedWidth = whitespaceForSegment + [obj floatValue];
                [mutableSegmentWidths replaceObjectAtIndex:idx withObject:[NSNumber numberWithFloat:extendedWidth]];
            }];
        }

        self.segmentWidthsArray = [mutableSegmentWidths copy];
    } else if (self.type == FWSegmentedControlTypeImages) {
        for (UIImage *sectionImage in self.sectionImages) {
            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            self.segmentWidth = MAX(imageWidth, self.segmentWidth);
        }
    } else if (self.type == FWSegmentedControlTypeTextImages && self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleFixed){
        //lets just use the title.. we will assume it is wider then images...
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            self.segmentWidth = MAX(stringWidth, self.segmentWidth);
        }];
    } else if (self.type == FWSegmentedControlTypeTextImages && self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic) {
        NSMutableArray *mutableSegmentWidths = [NSMutableArray array];
        __block CGFloat totalWidth = 0.0;
        
        int i = 0;
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.right;
            UIImage *sectionImage = [self.sectionImages objectAtIndex:i];
            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left;
            
            CGFloat combinedWidth = 0.0;
            if (self.imagePosition == FWSegmentedControlImagePositionLeftOfText || self.imagePosition == FWSegmentedControlImagePositionRightOfText) {
                combinedWidth = imageWidth + stringWidth + self.textImageSpacing;
            } else {
                combinedWidth = MAX(imageWidth, stringWidth);
            }
            
            totalWidth += combinedWidth;
            
            [mutableSegmentWidths addObject:[NSNumber numberWithFloat:combinedWidth]];
        }];
        
        if (self.shouldStretchSegmentsToScreenSize && totalWidth < self.bounds.size.width) {
            CGFloat whitespace = self.bounds.size.width - totalWidth;
            CGFloat whitespaceForSegment = whitespace / [mutableSegmentWidths count];
            [mutableSegmentWidths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat extendedWidth = whitespaceForSegment + [obj floatValue];
                [mutableSegmentWidths replaceObjectAtIndex:idx withObject:[NSNumber numberWithFloat:extendedWidth]];
            }];
        }
        
        self.segmentWidthsArray = [mutableSegmentWidths copy];
    }

    self.scrollView.scrollEnabled = self.isUserDraggable;
    self.scrollView.contentSize = CGSizeMake([self totalSegmentedControlWidth], self.frame.size.height);
}

- (NSUInteger)sectionCount {
    if (self.type == FWSegmentedControlTypeText) {
        return self.sectionTitles.count;
    } else if (self.type == FWSegmentedControlTypeImages ||
               self.type == FWSegmentedControlTypeTextImages) {
        return self.sectionImages.count;
    }
    
    return 0;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    // Control is being removed
    if (newSuperview == nil)
        return;
    
    if (self.sectionTitles || self.sectionImages) {
        [self updateSegmentsRects];
    }
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    
    CGRect enlargeRect =   CGRectMake(self.bounds.origin.x - self.enlargeEdgeInset.left,
                      self.bounds.origin.y - self.enlargeEdgeInset.top,
                      self.bounds.size.width + self.enlargeEdgeInset.left + self.enlargeEdgeInset.right,
                      self.bounds.size.height + self.enlargeEdgeInset.top + self.enlargeEdgeInset.bottom);
    
    if (CGRectContainsPoint(enlargeRect, touchLocation)) {
        NSUInteger segment = 0;
        if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleFixed) {
            segment = (touchLocation.x + self.scrollView.contentOffset.x) / self.segmentWidth;
        } else if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic) {
            // To know which segment the user touched, we need to loop over the widths and substract it from the x position.
            CGFloat widthLeft = (touchLocation.x + self.scrollView.contentOffset.x);
            for (NSNumber *width in self.segmentWidthsArray) {
                widthLeft = widthLeft - [width floatValue];
                
                // When we don't have any width left to substract, we have the segment index.
                if (widthLeft <= 0)
                    break;
                
                segment++;
            }
        }
        
        NSUInteger sectionsCount = 0;
        
        if (self.type == FWSegmentedControlTypeImages) {
            sectionsCount = [self.sectionImages count];
        } else if (self.type == FWSegmentedControlTypeTextImages || self.type == FWSegmentedControlTypeText) {
            sectionsCount = [self.sectionTitles count];
        }
        
        if (segment != self.selectedSegmentIndex && segment < sectionsCount) {
            // Check if we have to do anything with the touch event
            if (self.isTouchEnabled)
                [self setSelectedSegmentIndex:segment animated:self.shouldAnimateUserSelection notify:YES];
        }
    }
}

#pragma mark - Scrolling

- (CGFloat)totalSegmentedControlWidth {
    if (self.type == FWSegmentedControlTypeText && self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleFixed) {
        return self.sectionTitles.count * self.segmentWidth;
    } else if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic) {
        return [[self.segmentWidthsArray valueForKeyPath:@"@sum.self"] floatValue];
    } else {
        return self.sectionImages.count * self.segmentWidth;
    }
}

- (void)scrollToSelectedSegmentIndex:(BOOL)animated {
    [self scrollTo:self.selectedSegmentIndex animated:animated];
}

- (void)scrollTo:(NSUInteger)index animated:(BOOL)animated {
    CGRect rectForSelectedIndex = CGRectZero;
    CGFloat selectedSegmentOffset = 0;
    if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleFixed) {
        rectForSelectedIndex = CGRectMake(self.segmentWidth * index,
                                          0,
                                          self.segmentWidth,
                                          self.frame.size.height);
        
        selectedSegmentOffset = (CGRectGetWidth(self.frame) / 2) - (self.segmentWidth / 2);
    } else {
        NSUInteger i = 0;
        CGFloat offsetter = 0;
        for (NSNumber *width in self.segmentWidthsArray) {
            if (index == i)
                break;
            offsetter = offsetter + [width floatValue];
            i++;
        }
        
        rectForSelectedIndex = CGRectMake(offsetter,
                                          0,
                                          [[self.segmentWidthsArray objectAtIndex:index] floatValue],
                                          self.frame.size.height);
        
        selectedSegmentOffset = (CGRectGetWidth(self.frame) / 2) - ([[self.segmentWidthsArray objectAtIndex:index] floatValue] / 2);
    }
    
    
    CGRect rectToScrollTo = rectForSelectedIndex;
    rectToScrollTo.origin.x -= selectedSegmentOffset;
    rectToScrollTo.size.width += selectedSegmentOffset * 2;
    [self.scrollView scrollRectToVisible:rectToScrollTo animated:animated];
    
    if (!animated) {
        [self statisticalExposureDidChange];
    }
}

#pragma mark - Index Change

- (void)setSelectedSegmentIndex:(NSUInteger)index {
    [self setSelectedSegmentIndex:index animated:NO notify:NO];
}

- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated {
    [self setSelectedSegmentIndex:index animated:animated notify:NO];
}

- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated notify:(BOOL)notify {
    _selectedSegmentIndex = index;
    [self setNeedsDisplay];
    
    if (index == FWSegmentedControlNoSegment || [self sectionCount] < 1) {
        [self.selectionIndicatorShapeLayer removeFromSuperlayer];
        [self.selectionIndicatorStripLayer removeFromSuperlayer];
        [self.selectionIndicatorBoxLayer removeFromSuperlayer];
    } else {
        if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic &&
            [self sectionCount] != self.segmentWidthsArray.count) {
            // layoutIfNeeded if frame is zero
            [self layoutIfNeeded];
            if ([self sectionCount] != self.segmentWidthsArray.count) return;
        }
        
        [self scrollToSelectedSegmentIndex:animated];
        
        if (animated) {
            // If the selected segment layer is not added to the super layer, that means no
            // index is currently selected, so add the layer then move it to the new
            // segment index without animating.
            if(self.selectionStyle == FWSegmentedControlSelectionStyleArrow ||
               self.selectionStyle == FWSegmentedControlSelectionStyleCircle) {
                if ([self.selectionIndicatorShapeLayer superlayer] == nil) {
                    [self.scrollView.layer addSublayer:self.selectionIndicatorShapeLayer];
                    
                    [self setSelectedSegmentIndex:index animated:NO notify:YES];
                    return;
                }
            }else {
                if ([self.selectionIndicatorStripLayer superlayer] == nil) {
                    [self.scrollView.layer addSublayer:self.selectionIndicatorStripLayer];
                    
                    if (self.selectionStyle == FWSegmentedControlSelectionStyleBox && [self.selectionIndicatorBoxLayer superlayer] == nil)
                        [self.scrollView.layer insertSublayer:self.selectionIndicatorBoxLayer atIndex:0];
                    
                    [self setSelectedSegmentIndex:index animated:NO notify:YES];
                    return;
                }
            }
            
            if (notify)
                [self notifyForSegmentChangeToIndex:index];
            
            // Restore CALayer animations
            self.selectionIndicatorShapeLayer.actions = nil;
            self.selectionIndicatorStripLayer.actions = nil;
            self.selectionIndicatorBoxLayer.actions = nil;
            
            // Animate to new position
            [CATransaction begin];
            [CATransaction setAnimationDuration:0.15f];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [self setShapeFrame];
            self.selectionIndicatorBoxLayer.frame = [self frameForSelectionIndicator];
            self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
            self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
            [CATransaction commit];
        } else {
            // Disable CALayer animations
            NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position", [NSNull null], @"bounds", nil];
            self.selectionIndicatorShapeLayer.actions = newActions;
            [self setShapeFrame];
            
            self.selectionIndicatorStripLayer.actions = newActions;
            self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
            
            self.selectionIndicatorBoxLayer.actions = newActions;
            self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
            
            if (notify)
                [self notifyForSegmentChangeToIndex:index];
        }
    }
}

- (void)notifyForSegmentChangeToIndex:(NSInteger)index {
    if (self.superview)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    if (self.indexChangeBlock)
        self.indexChangeBlock(index);
    
    if (self.clickCallback)
        self.clickCallback(nil, [NSIndexPath indexPathForRow:index inSection:0]);
}

#pragma mark - Styling Support

- (NSDictionary *)resultingTitleTextAttributes {
    NSDictionary *defaults = @{
        NSFontAttributeName : [UIFont systemFontOfSize:19.0f],
        NSForegroundColorAttributeName : [UIColor blackColor],
    };
    
    NSMutableDictionary *resultingAttrs = [NSMutableDictionary dictionaryWithDictionary:defaults];
    
    if (self.titleTextAttributes) {
        [resultingAttrs addEntriesFromDictionary:self.titleTextAttributes];
    }

    return [resultingAttrs copy];
}

- (NSDictionary *)resultingSelectedTitleTextAttributes {
    NSMutableDictionary *resultingAttrs = [NSMutableDictionary dictionaryWithDictionary:[self resultingTitleTextAttributes]];
    
    if (self.selectedTitleTextAttributes) {
        [resultingAttrs addEntriesFromDictionary:self.selectedTitleTextAttributes];
    }
    
    return [resultingAttrs copy];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    for (FWAccessibilityElement *element in self.accessibilityElements) {
        NSUInteger idx = [self.accessibilityElements indexOfObject:element];
        CGFloat offset = 0.f;
        for (NSUInteger i = 0; i<idx; i++) {
            FWAccessibilityElement *elem = [self.accessibilityElements objectAtIndex:i];
            offset += elem.accessibilityFrame.size.width;
        }
        CGRect rect = CGRectMake(offset-scrollView.contentOffset.x, 0, element.accessibilityFrame.size.width, element.accessibilityFrame.size.height);
        element.accessibilityFrame = [self convertRect:rect toView:nil];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self statisticalExposureDidChange];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self statisticalExposureDidChange];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self statisticalExposureDidChange];
}

#pragma mark - FWAccessibilityDelegate

- (void)scrollToAccessibilityElement:(id)sender {
    NSUInteger index = [self.accessibilityElements indexOfObject:sender];
    
    if (index!=NSNotFound)
        [self scrollTo:index animated:NO];
}

#pragma mark - UIAccessibilityContainer

- (NSArray *)accessibilityElements {
    return _accessibilityElements;
}

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    return [[self accessibilityElements] count];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return [[self accessibilityElements] indexOfObject:element];
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    return [[self accessibilityElements] objectAtIndex:index];
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
    
    CGFloat visibleMin = self.scrollView.contentOffset.x;
    CGFloat visibleMax = visibleMin + self.scrollView.frame.size.width;
    NSInteger sectionCount = 0;
    BOOL dynamicWidth = NO;
    if (self.type == FWSegmentedControlTypeText && self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleFixed) {
        sectionCount = self.sectionTitles.count;
    } else if (self.segmentWidthStyle == FWSegmentedControlSegmentWidthStyleDynamic) {
        sectionCount = self.segmentWidthsArray.count;
        dynamicWidth = YES;
    } else {
        sectionCount = self.sectionImages.count;
    }
    
    // Calculate current exposure indexes, including segmentEdgeInset
    NSMutableArray *exposureIndexes = [NSMutableArray new];
    NSArray *previousIndexes = self.exposureIndexes;
    CGFloat currentMin = 0;
    for (NSInteger i = 0; i < sectionCount; i++) {
        CGFloat currentMax = currentMin + (dynamicWidth ? self.segmentWidthsArray[i].floatValue : self.segmentWidth);
        if (currentMin > visibleMax) break;
        if (currentMin >= visibleMin && currentMax <= visibleMax) {
            [exposureIndexes addObject:@(i)];
            if (![previousIndexes containsObject:@(i)]) {
                self.exposureCallback(nil, [NSIndexPath indexPathForRow:i inSection:0]);
            }
        }
        currentMin = currentMax;
    }
    self.exposureIndexes = [exposureIndexes copy];
}

@end