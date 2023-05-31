//
//  FWSegmentedControl.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

@class FWSegmentedControl;

NS_ASSUME_NONNULL_BEGIN

typedef void (^FWIndexChangeBlock)(NSUInteger index) NS_SWIFT_NAME(IndexChangeBlock);
typedef NSAttributedString *_Nonnull(^FWTitleFormatterBlock)(FWSegmentedControl *segmentedControl, NSString *title, NSUInteger index, BOOL selected) NS_SWIFT_NAME(TitleFormatterBlock);

typedef NS_ENUM(NSInteger, FWSegmentedControlSelectionStyle) {
    FWSegmentedControlSelectionStyleTextWidthStripe, // Indicator width will only be as big as the text width
    FWSegmentedControlSelectionStyleFullWidthStripe, // Indicator width will fill the whole segment
    FWSegmentedControlSelectionStyleBox, // A rectangle that covers the whole segment
    FWSegmentedControlSelectionStyleArrow, // An arrow in the middle of the segment pointing up or down depending on `FWSegmentedControlSelectionIndicatorLocation`
    FWSegmentedControlSelectionStyleCircle // An circle in the middle of the segment pointing up or down depending on `FWSegmentedControlSelectionIndicatorLocation`
} NS_SWIFT_NAME(SegmentedControlSelectionStyle);

typedef NS_ENUM(NSInteger, FWSegmentedControlSelectionIndicatorLocation) {
    FWSegmentedControlSelectionIndicatorLocationTop,
    FWSegmentedControlSelectionIndicatorLocationBottom,
    FWSegmentedControlSelectionIndicatorLocationNone // No selection indicator
} NS_SWIFT_NAME(SegmentedControlSelectionIndicatorLocation);

typedef NS_ENUM(NSInteger, FWSegmentedControlSegmentWidthStyle) {
    FWSegmentedControlSegmentWidthStyleFixed, // Segment width is fixed
    FWSegmentedControlSegmentWidthStyleDynamic, // Segment width will only be as big as the text width (including inset)
} NS_SWIFT_NAME(SegmentedControlSegmentWidthStyle);

typedef NS_OPTIONS(NSInteger, FWSegmentedControlBorderType) {
    FWSegmentedControlBorderTypeNone = 0,
    FWSegmentedControlBorderTypeTop = (1 << 0),
    FWSegmentedControlBorderTypeLeft = (1 << 1),
    FWSegmentedControlBorderTypeBottom = (1 << 2),
    FWSegmentedControlBorderTypeRight = (1 << 3)
} NS_SWIFT_NAME(SegmentedControlBorderType);

/// Segment index for no selected segment
FOUNDATION_EXPORT NSUInteger FWSegmentedControlNoSegment NS_SWIFT_NAME(SegmentedControlNoSegment);

typedef NS_ENUM(NSInteger, FWSegmentedControlType) {
    FWSegmentedControlTypeText,
    FWSegmentedControlTypeImages,
    FWSegmentedControlTypeTextImages
} NS_SWIFT_NAME(SegmentedControlType);

typedef NS_ENUM(NSInteger, FWSegmentedControlImagePosition) {
    FWSegmentedControlImagePositionBehindText,
    FWSegmentedControlImagePositionLeftOfText,
    FWSegmentedControlImagePositionRightOfText,
    FWSegmentedControlImagePositionAboveText,
    FWSegmentedControlImagePositionBelowText
} NS_SWIFT_NAME(SegmentedControlImagePosition);

/**
 FWSegmentedControl
 
 [HMSegmentedControl 1.5.6](https://github.com/HeshamMegid/HMSegmentedControl)
 */
NS_SWIFT_NAME(SegmentedControl)
@interface FWSegmentedControl : UIControl

@property (nonatomic, strong, nullable) NSArray<NSString *> *sectionTitles;
@property (nonatomic, strong, nullable) NSArray<UIImage *> *sectionImages;
@property (nonatomic, strong, nullable) NSArray<UIImage *> *sectionSelectedImages;

/**
 Provide a block to be executed when selected index is changed.
 
 Alternativly, you could use `addTarget:action:forControlEvents:`
 */
@property (nonatomic, copy, nullable) FWIndexChangeBlock indexChangeBlock;

/**
 Used to apply custom text styling to titles when set.
 
 When this block is set, no additional styling is applied to the `NSAttributedString` object returned from this block.
 */
@property (nonatomic, copy, nullable) FWTitleFormatterBlock titleFormatter;

/**
 Text attributes to apply to item title text.
 */
@property (nonatomic, strong) NSDictionary *titleTextAttributes UI_APPEARANCE_SELECTOR;

/*
 Text attributes to apply to selected item title text.
 
 Attributes not set in this dictionary are inherited from `titleTextAttributes`.
 */
@property (nonatomic, strong) NSDictionary *selectedTitleTextAttributes UI_APPEARANCE_SELECTOR;

/**
 Segmented control background color.
 
 Default is `[UIColor whiteColor]`
 */
@property (nonatomic, strong) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;

/**
 Color for the selection indicator stripe
 
 Default is `R:52, G:181, B:229`
 */
@property (nonatomic, strong) UIColor *selectionIndicatorColor UI_APPEARANCE_SELECTOR;

/**
 Color for the selection indicator box
 
 Default is selectionIndicatorColor
 */
@property (nonatomic, strong) UIColor *selectionIndicatorBoxColor UI_APPEARANCE_SELECTOR;

/**
 Color for the vertical divider between segments.
 
 Default is `[UIColor blackColor]`
 */
@property (nonatomic, strong) UIColor *verticalDividerColor UI_APPEARANCE_SELECTOR;

/**
 Opacity for the seletion indicator box.
 
 Default is `0.2f`
 */
@property (nonatomic) CGFloat selectionIndicatorBoxOpacity;

/**
 Width the vertical divider between segments that is added when `verticalDividerEnabled` is set to YES.
 
 Default is `1.0f`
 */
@property (nonatomic, assign) CGFloat verticalDividerWidth;

/**
 Specifies the style of the control
 
 Default is `FWSegmentedControlTypeText`
 */
@property (nonatomic, assign) FWSegmentedControlType type;

/**
 Specifies the style of the selection indicator.
 
 Default is `FWSegmentedControlSelectionStyleTextWidthStripe`
 */
@property (nonatomic, assign) FWSegmentedControlSelectionStyle selectionStyle;

/**
 Specifies the style of the segment's width.
 
 Default is `FWSegmentedControlSegmentWidthStyleFixed`
 */
@property (nonatomic, assign) FWSegmentedControlSegmentWidthStyle segmentWidthStyle;

/**
 Specifies the location of the selection indicator.
 
 Default is `FWSegmentedControlSelectionIndicatorLocationUp`
 */
@property (nonatomic, assign) FWSegmentedControlSelectionIndicatorLocation selectionIndicatorLocation;

/*
 Specifies the border type.
 
 Default is `FWSegmentedControlBorderTypeNone`
 */
@property (nonatomic, assign) FWSegmentedControlBorderType borderType;

/**
 Specifies the image position relative to the text. Only applicable for FWSegmentedControlTypeTextImages
 
 Default is `FWSegmentedControlImagePositionBehindText`
 */
@property (nonatomic) FWSegmentedControlImagePosition imagePosition;

/**
 Specifies the distance between the text and the image. Only applicable for FWSegmentedControlTypeTextImages
 
 Default is `0,0`
 */
@property (nonatomic) CGFloat textImageSpacing;

/**
 Specifies the border color.
 
 Default is `[UIColor blackColor]`
 */
@property (nonatomic, strong) UIColor *borderColor;

/**
 Specifies the border width.
 
 Default is `1.0f`
 */
@property (nonatomic, assign) CGFloat borderWidth;

/**
 Default is YES. Set to NO to deny scrolling by dragging the scrollView by the user.
 */
@property(nonatomic, getter = isUserDraggable) BOOL userDraggable;

/**
 Default is YES. Set to NO to deny any touch events by the user.
 */
@property(nonatomic, getter = isTouchEnabled) BOOL touchEnabled;

/**
 Default is NO. Set to YES to show a vertical divider between the segments.
 */
@property(nonatomic, getter = isVerticalDividerEnabled) BOOL verticalDividerEnabled;

@property (nonatomic, getter=shouldStretchSegmentsToScreenSize) BOOL stretchSegmentsToScreenSize;

/**
 Index of the currently selected segment.
 */
@property (nonatomic, assign) NSUInteger selectedSegmentIndex;

/**
 Height of the selection indicator. Only effective when `FWSegmentedControlSelectionStyle` is either `FWSegmentedControlSelectionStyleTextWidthStripe` or `FWSegmentedControlSelectionStyleFullWidthStripe`.
 
 Default is 5.0
 */
@property (nonatomic, readwrite) CGFloat selectionIndicatorHeight;

/**
 Edge insets for the selection indicator.
 NOTE: This does not affect the bounding box of FWSegmentedControlSelectionStyleBox
 
 When FWSegmentedControlSelectionIndicatorLocationUp is selected, bottom edge insets are not used
 
 When FWSegmentedControlSelectionIndicatorLocationDown is selected, top edge insets are not used
 
 Defaults are top: 0.0f
             left: 0.0f
           bottom: 0.0f
            right: 0.0f
 */
@property (nonatomic, readwrite) UIEdgeInsets selectionIndicatorEdgeInsets;

/**
 Edge insets for the selection indicator box.
 NOTE: This only affect the bounding box of FWSegmentedControlSelectionStyleBox
 
 Defaults are top: 0.0f
             left: 0.0f
           bottom: 0.0f
            right: 0.0f
 */
@property (nonatomic, readwrite) UIEdgeInsets selectionIndicatorBoxEdgeInsets;

/**
 Corner radius for the selection indicator.
 
 Defaults is 0
 */
@property (nonatomic, assign) CGFloat selectionIndicatorCornerRadius;

/**
 Corner radius for the selection indicator box.
 
 Defaults is 0
 */
@property (nonatomic, assign) CGFloat selectionIndicatorBoxCornerRadius;

/**
 Inset left and right edges of content.
 
 Default is UIEdgeInsetsMake(0, 0, 0, 0)
 */
@property (nonatomic, readwrite) UIEdgeInsets contentEdgeInset;

/**
 Inset left and right edges of segments.
 
 Default is UIEdgeInsetsMake(0, 5, 0, 5)
 */
@property (nonatomic, readwrite) UIEdgeInsets segmentEdgeInset;

/**
 Background color of segments.
 
 Defaults is nil
 */
@property (nonatomic, readwrite, nullable) UIColor *segmentBackgroundColor;

/**
 Background opacity of segments.
 
 Defaults is 1.0
 */
@property (nonatomic, readwrite) CGFloat segmentBackgroundOpacity;

/**
 Background corner radius of segments.
 
 Defaults is 0
 */
@property (nonatomic, readwrite) CGFloat segmentBackgroundCornerRadius;

/**
 Background edge inset of segments.
 
 Defaults is UIEdgeInsetsZero
 */
@property (nonatomic, readwrite) UIEdgeInsets segmentBackgroundEdgeInset;

@property (nonatomic, readwrite) UIEdgeInsets enlargeEdgeInset;

/**
 Default is YES. Set to NO to disable animation during user selection.
 */
@property (nonatomic) BOOL shouldAnimateUserSelection;

- (instancetype)initWithSectionTitles:(NSArray<NSString *> *)sectiontitles;
- (instancetype)initWithSectionImages:(NSArray<UIImage *> *)sectionImages sectionSelectedImages:(NSArray<UIImage *> *)sectionSelectedImages;
- (instancetype)initWithSectionImages:(NSArray<UIImage *> *)sectionImages sectionSelectedImages:(NSArray<UIImage *> *)sectionSelectedImages titlesForSections:(NSArray<NSString *> *)sectiontitles;

- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)setIndexChangeBlock:(FWIndexChangeBlock)indexChangeBlock;
- (void)setTitleFormatter:(FWTitleFormatterBlock)titleFormatter;

@end

NS_ASSUME_NONNULL_END
