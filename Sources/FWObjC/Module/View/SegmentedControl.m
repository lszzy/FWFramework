//
//  SegmentedControl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "SegmentedControl.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import <FWFramework/FWFramework-Swift.h>

@interface __FWSegmentedControl () <UIScrollViewDelegate, __FWAccessibilityDelegate>

@property (nonatomic, strong) CALayer *selectionIndicatorStripLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorBoxLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorShapeLayer;
@property (nonatomic, readwrite) CGFloat segmentWidth;
@property (nonatomic, readwrite) NSArray<NSNumber *> *segmentWidthsArray;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *accessibilityElements;
@property (nonatomic, strong) NSMutableArray *titleBackgroundLayers;
@property (nonatomic, strong) NSMutableArray *segmentBackgroundLayers;

@end

@implementation __FWSegmentedControl

#pragma mark - Drawing

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
    
    if (self.type == __FWSegmentedControlTypeText) {
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
            BOOL locationUp = (self.selectionIndicatorLocation == __FWSegmentedControlSelectionIndicatorLocationTop);
            BOOL selectionStyleNotBox = (self.selectionStyle != __FWSegmentedControlSelectionStyleBox);

            CGFloat y = roundf((CGRectGetHeight(self.frame) - selectionStyleNotBox * self.selectionIndicatorHeight) / 2 - stringHeight / 2 + self.selectionIndicatorHeight * locationUp);
            CGRect rect;
            if (self.segmentWidthStyle == __FWSegmentedControlSegmentWidthStyleFixed) {
                rect = CGRectMake((self.segmentWidth * idx) + (self.segmentWidth - stringWidth) / 2, y, stringWidth, stringHeight);
                rectDiv = CGRectMake((self.segmentWidth * idx) - (self.verticalDividerWidth / 2) + self.contentEdgeInset.left, self.selectionIndicatorHeight * 2, self.verticalDividerWidth, self.frame.size.height - (self.selectionIndicatorHeight * 4));
                fullRect = CGRectMake(self.segmentWidth * idx + self.contentEdgeInset.left, 0, self.segmentWidth, oldRect.size.height);
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
                fullRect = CGRectMake(xOffset + self.contentEdgeInset.left, 0, widthForIndex, oldRect.size.height);
                rectDiv = CGRectMake(xOffset - (self.verticalDividerWidth / 2) + self.contentEdgeInset.left, self.selectionIndicatorHeight * 2, self.verticalDividerWidth, self.frame.size.height - (self.selectionIndicatorHeight * 4));
            }
            
            // Fix rect position/size to avoid blurry labels
            rect = CGRectMake(ceilf(rect.origin.x) + self.contentEdgeInset.left, ceilf(rect.origin.y), ceilf(rect.size.width), ceilf(rect.size.height));
            
            CATextLayer *titleLayer = [CATextLayer layer];
            titleLayer.frame = rect;
            titleLayer.alignmentMode = kCAAlignmentCenter;
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
                __FWAccessibilityElement *element = [[__FWAccessibilityElement alloc] initWithAccessibilityContainer:self];
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
                    __FWAccessibilityElement *accessibilityItem = [self.accessibilityElements objectAtIndex:i];
                    offset += accessibilityItem.accessibilityFrame.size.width;
                }
                __FWAccessibilityElement *element = [self.accessibilityElements objectAtIndex:idx];
                CGRect newRect = CGRectMake(offset-self.scrollView.contentOffset.x + self.contentEdgeInset.left, 0, element.accessibilityFrame.size.width, element.accessibilityFrame.size.height);
                element.accessibilityFrame = [self convertRect:newRect toView:nil];
                if (self.selectedSegmentIndex==idx)
                    element.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
                else
                    element.accessibilityTraits = UIAccessibilityTraitButton;
            }
        
            [self addBackgroundAndBorderLayerWithRect:fullRect index:idx];
        }];
    } else if (self.type == __FWSegmentedControlTypeImages) {
        [self removeTitleBackgroundLayers];
        [self.sectionImages enumerateObjectsUsingBlock:^(id iconImage, NSUInteger idx, BOOL *stop) {
            UIImage *icon = iconImage;
            CGFloat imageWidth = icon.size.width;
            CGFloat imageHeight = icon.size.height;
            CGFloat y = roundf(CGRectGetHeight(self.frame) - self.selectionIndicatorHeight) / 2 - imageHeight / 2 + ((self.selectionIndicatorLocation == __FWSegmentedControlSelectionIndicatorLocationTop) ? self.selectionIndicatorHeight : 0);
            CGFloat x = self.segmentWidth * idx + (self.segmentWidth - imageWidth)/2.0f;
            CGRect rect = CGRectMake(x + self.contentEdgeInset.left, y, imageWidth, imageHeight);
            
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
                verticalDividerLayer.frame = CGRectMake((self.segmentWidth * idx) - (self.verticalDividerWidth / 2) + self.contentEdgeInset.left, self.selectionIndicatorHeight * 2, self.verticalDividerWidth, self.frame.size.height-(self.selectionIndicatorHeight * 4));
                verticalDividerLayer.backgroundColor = self.verticalDividerColor.CGColor;
                
                [self.scrollView.layer addSublayer:verticalDividerLayer];
            }
            
            if ([self.accessibilityElements count]<=idx) {
                __FWAccessibilityElement *element = [[__FWAccessibilityElement alloc] initWithAccessibilityContainer:self];
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
                    __FWAccessibilityElement *accessibilityItem = [self.accessibilityElements objectAtIndex:i];
                    offset += accessibilityItem.accessibilityFrame.size.width;
                }
                __FWAccessibilityElement *element = [self.accessibilityElements objectAtIndex:idx];
                CGRect newRect = CGRectMake(offset-self.scrollView.contentOffset.x + self.contentEdgeInset.left, 0, element.accessibilityFrame.size.width, element.accessibilityFrame.size.height);
                element.accessibilityFrame = [self convertRect:newRect toView:nil];
                if (self.selectedSegmentIndex==idx)
                    element.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
                else
                    element.accessibilityTraits = UIAccessibilityTraitButton;
            }
            
            [self addBackgroundAndBorderLayerWithRect:rect index:idx];
        }];
    } else if (self.type == __FWSegmentedControlTypeTextImages){
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
            
            
            if (self.segmentWidthStyle == __FWSegmentedControlSegmentWidthStyleFixed) {
                BOOL isImageInLineWidthText = self.imagePosition == __FWSegmentedControlImagePositionLeftOfText || self.imagePosition == __FWSegmentedControlImagePositionRightOfText;
                if (isImageInLineWidthText) {
                    CGFloat whitespace = self.segmentWidth - stringSize.width - imageWidth - self.textImageSpacing;
                    if (self.imagePosition == __FWSegmentedControlImagePositionLeftOfText) {
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
                    if (self.imagePosition == __FWSegmentedControlImagePositionAboveText) {
                        imageYOffset = ceilf(whitespace / 2.0);
                        textYOffset = imageYOffset + imageHeight + self.textImageSpacing;
                    } else if (self.imagePosition == __FWSegmentedControlImagePositionBelowText) {
                        textYOffset = ceilf(whitespace / 2.0);
                        imageYOffset = textYOffset + stringHeight + self.textImageSpacing;
                    }
                }
            } else if (self.segmentWidthStyle == __FWSegmentedControlSegmentWidthStyleDynamic) {
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
                
                BOOL isImageInLineWidthText = self.imagePosition == __FWSegmentedControlImagePositionLeftOfText || self.imagePosition == __FWSegmentedControlImagePositionRightOfText;
                if (isImageInLineWidthText) {
                    if (self.imagePosition == __FWSegmentedControlImagePositionLeftOfText) {
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
                    if (self.imagePosition == __FWSegmentedControlImagePositionAboveText) {
                        imageYOffset = ceilf(whitespace / 2.0);
                        textYOffset = imageYOffset + imageHeight + self.textImageSpacing;
                    } else if (self.imagePosition == __FWSegmentedControlImagePositionBelowText) {
                        textYOffset = ceilf(whitespace / 2.0);
                        imageYOffset = textYOffset + stringHeight + self.textImageSpacing;
                    }
                }
            }
            
            CGRect imageRect = CGRectMake(imageXOffset + self.contentEdgeInset.left, imageYOffset, imageWidth, imageHeight);
            CGRect textRect = CGRectMake(ceilf(textXOffset) + self.contentEdgeInset.left, ceilf(textYOffset), ceilf(stringWidth), ceilf(stringHeight));

            CATextLayer *titleLayer = [CATextLayer layer];
            titleLayer.frame = textRect;
            titleLayer.alignmentMode = kCAAlignmentCenter;
            titleLayer.string = [self attributedTitleAtIndex:idx];
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
                __FWAccessibilityElement *element = [[__FWAccessibilityElement alloc] initWithAccessibilityContainer:self];
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
                    __FWAccessibilityElement *accessibilityItem = [self.accessibilityElements objectAtIndex:i];
                    offset += accessibilityItem.accessibilityFrame.size.width;
                }
                __FWAccessibilityElement *element = [self.accessibilityElements objectAtIndex:idx];
                CGRect newRect = CGRectMake(offset-self.scrollView.contentOffset.x + self.contentEdgeInset.left, 0, element.accessibilityFrame.size.width, element.accessibilityFrame.size.height);
                element.accessibilityFrame = [self convertRect:newRect toView:nil];
                if (self.selectedSegmentIndex==idx)
                    element.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
                else
                    element.accessibilityTraits = UIAccessibilityTraitButton;
            }
            
            [self addBackgroundAndBorderLayerWithRect:imageRect index:idx];
        }];
    }
    
    // Add the selection indicators
    if (self.selectedSegmentIndex != __FWSegmentedControlNoSegment && [self sectionCount] > 0) {
        if (self.selectionStyle == __FWSegmentedControlSelectionStyleArrow ||
            self.selectionStyle == __FWSegmentedControlSelectionStyleCircle) {
            if (!self.selectionIndicatorShapeLayer.superlayer) {
                [self setShapeFrame];
                [self.scrollView.layer addSublayer:self.selectionIndicatorShapeLayer];
            }
        } else {
            if (!self.selectionIndicatorStripLayer.superlayer) {
                self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
                [self.scrollView.layer addSublayer:self.selectionIndicatorStripLayer];
                
                if (self.selectionStyle == __FWSegmentedControlSelectionStyleBox && !self.selectionIndicatorBoxLayer.superlayer) {
                    self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
                    [self.scrollView.layer insertSublayer:self.selectionIndicatorBoxLayer atIndex:0];
                }
            }
        }
    }
}

- (void)addBackgroundAndBorderLayerWithRect:(CGRect)fullRect index:(NSUInteger)index {
    // Segment Background layer
    if (self.segmentBackgroundColor) {
        CALayer *backgroundLayer = [CALayer layer];
        backgroundLayer.zPosition = -1;
        backgroundLayer.backgroundColor = self.segmentBackgroundColor.CGColor;
        backgroundLayer.opacity = self.segmentBackgroundOpacity;
        backgroundLayer.cornerRadius = self.segmentBackgroundCornerRadius;
        backgroundLayer.frame = CGRectMake(fullRect.origin.x + self.segmentBackgroundEdgeInset.left, fullRect.origin.y + self.segmentBackgroundEdgeInset.top, fullRect.size.width - self.segmentBackgroundEdgeInset.left - self.segmentBackgroundEdgeInset.right, fullRect.size.height - self.segmentBackgroundEdgeInset.top - self.segmentBackgroundEdgeInset.bottom);
        [self.scrollView.layer insertSublayer:backgroundLayer atIndex:0];
        [self.segmentBackgroundLayers addObject:backgroundLayer];
    }
    
    // Title Background layer
    CALayer *backgroundLayer = [CALayer layer];
    backgroundLayer.frame = fullRect;
    [self.layer insertSublayer:backgroundLayer atIndex:0];
    [self.titleBackgroundLayers addObject:backgroundLayer];
    
    // Title Border layer
    if (self.borderType & __FWSegmentedControlBorderTypeTop) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(0, 0, fullRect.size.width, self.borderWidth);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    if (self.borderType & __FWSegmentedControlBorderTypeLeft) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(0, 0, self.borderWidth, fullRect.size.height);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    if (self.borderType & __FWSegmentedControlBorderTypeBottom) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(0, fullRect.size.height - self.borderWidth, fullRect.size.width, self.borderWidth);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    if (self.borderType & __FWSegmentedControlBorderTypeRight) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(fullRect.size.width - self.borderWidth, 0, self.borderWidth, fullRect.size.height);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    
    if (self.segmentCustomBlock) {
        self.segmentCustomBlock(self, index, fullRect);
    }
}

- (CGRect)frameForSelectionIndicator {
    CGFloat indicatorYOffset = 0.0f;
    
    if (self.selectionIndicatorLocation == __FWSegmentedControlSelectionIndicatorLocationBottom) {
        indicatorYOffset = self.bounds.size.height - self.selectionIndicatorHeight + self.selectionIndicatorEdgeInsets.bottom;
    }
    
    if (self.selectionIndicatorLocation == __FWSegmentedControlSelectionIndicatorLocationTop) {
        indicatorYOffset = self.selectionIndicatorEdgeInsets.top;
    }
    
    CGFloat sectionWidth = 0.0f;
    
    if (self.type == __FWSegmentedControlTypeText) {
        CGFloat stringWidth = [self measureTitleAtIndex:self.selectedSegmentIndex].width;
        sectionWidth = stringWidth;
    } else if (self.type == __FWSegmentedControlTypeImages) {
        UIImage *sectionImage = [self.sectionImages objectAtIndex:self.selectedSegmentIndex];
        CGFloat imageWidth = sectionImage.size.width;
        sectionWidth = imageWidth;
    } else if (self.type == __FWSegmentedControlTypeTextImages) {
        CGFloat stringWidth = [self measureTitleAtIndex:self.selectedSegmentIndex].width;
        UIImage *sectionImage = [self.sectionImages objectAtIndex:self.selectedSegmentIndex];
        CGFloat imageWidth = sectionImage.size.width;
        sectionWidth = MAX(stringWidth, imageWidth);
    }
    
    if (self.selectionStyle == __FWSegmentedControlSelectionStyleArrow ||
        self.selectionStyle == __FWSegmentedControlSelectionStyleCircle) {
        CGFloat widthToEndOfSelectedSegment = 0.0f;
        CGFloat widthToStartOfSelectedIndex = 0.0f;
        
        if (self.segmentWidthStyle == __FWSegmentedControlSegmentWidthStyleDynamic) {
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
        if (self.selectionStyle == __FWSegmentedControlSelectionStyleArrow) {
            return CGRectMake(x - (self.selectionIndicatorHeight / 2) + self.contentEdgeInset.left, indicatorYOffset, self.selectionIndicatorHeight * 2, self.selectionIndicatorHeight);
        } else {
            return CGRectMake(x + self.contentEdgeInset.left, indicatorYOffset, self.selectionIndicatorHeight, self.selectionIndicatorHeight);
        }
    } else {
        if (self.selectionStyle == __FWSegmentedControlSelectionStyleTextWidthStripe &&
            sectionWidth <= self.segmentWidth &&
            self.segmentWidthStyle != __FWSegmentedControlSegmentWidthStyleDynamic) {
            CGFloat widthToEndOfSelectedSegment = (self.segmentWidth * self.selectedSegmentIndex) + self.segmentWidth;
            CGFloat widthToStartOfSelectedIndex = (self.segmentWidth * self.selectedSegmentIndex);
            
            CGFloat x = ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) + (widthToStartOfSelectedIndex - sectionWidth / 2);
            return CGRectMake(x + self.selectionIndicatorEdgeInsets.left + self.contentEdgeInset.left, indicatorYOffset, sectionWidth - self.selectionIndicatorEdgeInsets.right, self.selectionIndicatorHeight);
        } else {
            if (self.segmentWidthStyle == __FWSegmentedControlSegmentWidthStyleDynamic) {
                CGFloat selectedSegmentOffset = 0.0f;
                
                NSUInteger i = 0;
                for (NSNumber *width in self.segmentWidthsArray) {
                    if (self.selectedSegmentIndex == i)
                        break;
                    selectedSegmentOffset = selectedSegmentOffset + [width floatValue];
                    i++;
                }
                if (self.selectionStyle == __FWSegmentedControlSelectionStyleTextWidthStripe) {
                   return CGRectMake(selectedSegmentOffset + self.selectionIndicatorEdgeInsets.left + self.segmentEdgeInset.left + self.contentEdgeInset.left, indicatorYOffset, [[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue] - self.selectionIndicatorEdgeInsets.right - self.segmentEdgeInset.left - self.segmentEdgeInset.right, self.selectionIndicatorHeight + self.selectionIndicatorEdgeInsets.bottom);
                } else {
                    return CGRectMake(selectedSegmentOffset + self.selectionIndicatorEdgeInsets.left + self.contentEdgeInset.left, indicatorYOffset, [[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue] - self.selectionIndicatorEdgeInsets.right, self.selectionIndicatorHeight + self.selectionIndicatorEdgeInsets.bottom);
                }
            }
            
            return CGRectMake(self.segmentWidth * self.selectedSegmentIndex + self.selectionIndicatorEdgeInsets.left + self.contentEdgeInset.left, indicatorYOffset, self.segmentWidth - self.selectionIndicatorEdgeInsets.left - self.selectionIndicatorEdgeInsets.right, self.selectionIndicatorHeight);
        }
    }
}

- (void)updateSegmentsRects {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
    if ([self sectionCount] > 0) {
        self.segmentWidth = self.frame.size.width / [self sectionCount];
    }
    
    if (self.type == __FWSegmentedControlTypeText && self.segmentWidthStyle == __FWSegmentedControlSegmentWidthStyleFixed) {
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            self.segmentWidth = MAX(stringWidth, self.segmentWidth);
        }];
    } else if (self.type == __FWSegmentedControlTypeText && self.segmentWidthStyle == __FWSegmentedControlSegmentWidthStyleDynamic) {
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
    } else if (self.type == __FWSegmentedControlTypeImages) {
        for (UIImage *sectionImage in self.sectionImages) {
            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            self.segmentWidth = MAX(imageWidth, self.segmentWidth);
        }
    } else if (self.type == __FWSegmentedControlTypeTextImages && self.segmentWidthStyle == __FWSegmentedControlSegmentWidthStyleFixed){
        //lets just use the title.. we will assume it is wider then images...
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            self.segmentWidth = MAX(stringWidth, self.segmentWidth);
        }];
    } else if (self.type == __FWSegmentedControlTypeTextImages && self.segmentWidthStyle == __FWSegmentedControlSegmentWidthStyleDynamic) {
        NSMutableArray *mutableSegmentWidths = [NSMutableArray array];
        __block CGFloat totalWidth = 0.0;
        
        int i = 0;
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.right;
            UIImage *sectionImage = [self.sectionImages objectAtIndex:i];
            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left;
            
            CGFloat combinedWidth = 0.0;
            if (self.imagePosition == __FWSegmentedControlImagePositionLeftOfText || self.imagePosition == __FWSegmentedControlImagePositionRightOfText) {
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
    self.scrollView.contentSize = CGSizeMake([self totalSegmentedControlWidth] + self.contentEdgeInset.left + self.contentEdgeInset.right, self.frame.size.height);
}

@end
