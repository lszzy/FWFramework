/*!
 @header     FWTagCollectionView.h
 @indexgroup FWFramework
 @brief      FWTagCollectionView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/13
 */

#import <UIKit/UIKit.h>

@class FWTagCollectionView;

/**
 * Tags scroll direction
 */
typedef NS_ENUM(NSInteger, FWTagCollectionScrollDirection) {
    FWTagCollectionScrollDirectionVertical = 0, // Default
    FWTagCollectionScrollDirectionHorizontal = 1
};

/**
 * Tags alignment
 */
typedef NS_ENUM(NSInteger, FWTagCollectionAlignment) {
    FWTagCollectionAlignmentLeft = 0,                           // Default
    FWTagCollectionAlignmentCenter,                             // Center
    FWTagCollectionAlignmentRight,                              // Right
    FWTagCollectionAlignmentFillByExpandingSpace,               // Expand horizontal spacing and fill
    FWTagCollectionAlignmentFillByExpandingWidth,               // Expand width and fill
    FWTagCollectionAlignmentFillByExpandingWidthExceptLastLine  // Expand width and fill, except last line
};

/**
 * Tags delegate
 */
@protocol FWTagCollectionViewDelegate <NSObject>
@required
- (CGSize)tagCollectionView:(FWTagCollectionView *)tagCollectionView sizeForTagAtIndex:(NSUInteger)index;

@optional
- (BOOL)tagCollectionView:(FWTagCollectionView *)tagCollectionView shouldSelectTag:(UIView *)tagView atIndex:(NSUInteger)index;

- (void)tagCollectionView:(FWTagCollectionView *)tagCollectionView didSelectTag:(UIView *)tagView atIndex:(NSUInteger)index;

- (void)tagCollectionView:(FWTagCollectionView *)tagCollectionView updateContentSize:(CGSize)contentSize;
@end

/**
 * Tags dataSource
 */
@protocol FWTagCollectionViewDataSource <NSObject>
@required
- (NSUInteger)numberOfTagsInTagCollectionView:(FWTagCollectionView *)tagCollectionView;

- (UIView *)tagCollectionView:(FWTagCollectionView *)tagCollectionView tagViewForIndex:(NSUInteger)index;
@end

/*!
 @brief FWTagCollectionView
 
 @see https://github.com/zekunyan/TTGTagCollectionView
 */
@interface FWTagCollectionView : UIView
@property (nonatomic, weak) id <FWTagCollectionViewDataSource> dataSource;
@property (nonatomic, weak) id <FWTagCollectionViewDelegate> delegate;

// Inside scrollView
@property (nonatomic, strong, readonly) UIScrollView *scrollView;

// Tags scroll direction, default is vertical.
@property (nonatomic, assign) FWTagCollectionScrollDirection scrollDirection;

// Tags layout alignment, default is left.
@property (nonatomic, assign) FWTagCollectionAlignment alignment;

// Number of lines. 0 means no limit, default is 0 for vertical and 1 for horizontal.
@property (nonatomic, assign) NSUInteger numberOfLines;
// The real number of lines ignoring the numberOfLines value
@property (nonatomic, assign, readonly) NSUInteger actualNumberOfLines;

// Horizontal and vertical space between tags, default is 4.
@property (nonatomic, assign) CGFloat horizontalSpacing;
@property (nonatomic, assign) CGFloat verticalSpacing;

// Content inset, default is UIEdgeInsetsMake(2, 2, 2, 2).
@property (nonatomic, assign) UIEdgeInsets contentInset;

// The true tags content size, readonly
@property (nonatomic, assign, readonly) CGSize contentSize;

// Manual content height
// Default = NO, set will update content
@property (nonatomic, assign) BOOL manualCalculateHeight;
// Default = 0, set will update content
@property (nonatomic, assign) CGFloat preferredMaxLayoutWidth;

// Scroll indicator
@property (nonatomic, assign) BOOL showsHorizontalScrollIndicator;
@property (nonatomic, assign) BOOL showsVerticalScrollIndicator;

// Tap blank area callback
@property (nonatomic, copy) void (^onTapBlankArea)(CGPoint location);
// Tap all area callback
@property (nonatomic, copy) void (^onTapAllArea)(CGPoint location);

/**
 * Reload all tag cells
 */
- (void)reload;

/**
 * Returns the index of the tag located at the specified point.
 * If item at point is not found, returns NSNotFound.
 */
- (NSInteger)indexOfTagAt:(CGPoint)point;

@end

/// TTGTextTagConfig

@interface FWTextTagConfig : NSObject;
// Text font
@property (strong, nonatomic) UIFont *tagTextFont;

// Text color
@property (strong, nonatomic) UIColor *tagTextColor;
@property (strong, nonatomic) UIColor *tagSelectedTextColor;

// Background color
@property (strong, nonatomic) UIColor *tagBackgroundColor;
@property (strong, nonatomic) UIColor *tagSelectedBackgroundColor;

// Gradient background color
@property (assign, nonatomic) BOOL tagShouldUseGradientBackgrounds;
@property (strong, nonatomic) UIColor *tagGradientBackgroundStartColor;
@property (strong, nonatomic) UIColor *tagGradientBackgroundEndColor;
@property (strong, nonatomic) UIColor *tagSelectedGradientBackgroundStartColor;
@property (strong, nonatomic) UIColor *tagSelectedGradientBackgroundEndColor;
@property (assign, nonatomic) CGPoint tagGradientStartPoint;
@property (assign, nonatomic) CGPoint tagGradientEndPoint;

// Corner radius
@property (assign, nonatomic) CGFloat tagCornerRadius;
@property (assign, nonatomic) CGFloat tagSelectedCornerRadius;
@property (assign, nonatomic) Boolean roundTopRight;
@property (assign, nonatomic) Boolean roundTopLeft;
@property (assign, nonatomic) Boolean roundBottomRight;
@property (assign, nonatomic) Boolean roundBottomLeft;

// Border
@property (assign, nonatomic) CGFloat tagBorderWidth;
@property (assign, nonatomic) CGFloat tagSelectedBorderWidth;
@property (strong, nonatomic) UIColor *tagBorderColor;
@property (strong, nonatomic) UIColor *tagSelectedBorderColor;

// Tag shadow.
@property (nonatomic, copy) UIColor *tagShadowColor;    // Default is [UIColor clear]
@property (nonatomic, assign) CGSize tagShadowOffset;   // Default is (0, 0)
@property (nonatomic, assign) CGFloat tagShadowRadius;  // Default is 0f
@property (nonatomic, assign) CGFloat tagShadowOpacity; // Default is 0.0f

// Tag extra space in width and height, will expand each tag's size
@property (assign, nonatomic) CGSize tagExtraSpace;
// Tag max width for a text tag. 0 and below means no max width.
@property (assign, nonatomic) CGFloat tagMaxWidth;
// Tag min width for a text tag. 0 and below means no min width.
@property (assign, nonatomic) CGFloat tagMinWidth;

// Extra data. You can use this to bind any object you want to each tag.
@property (nonatomic, strong) NSObject *extraData;

@end

/// TTGTextTagCollectionView

@class FWTextTagCollectionView;

@protocol FWTextTagCollectionViewDelegate <NSObject>
@optional

- (BOOL)textTagCollectionView:(FWTextTagCollectionView *)textTagCollectionView
                    canTapTag:(NSString *)tagText
                      atIndex:(NSUInteger)index
              currentSelected:(BOOL)currentSelected
                    tagConfig:(FWTextTagConfig *)config;

- (void)textTagCollectionView:(FWTextTagCollectionView *)textTagCollectionView
                    didTapTag:(NSString *)tagText
                      atIndex:(NSUInteger)index
                     selected:(BOOL)selected
                    tagConfig:(FWTextTagConfig *)config;

- (void)textTagCollectionView:(FWTextTagCollectionView *)textTagCollectionView
            updateContentSize:(CGSize)contentSize;

// Deprecated
- (BOOL)textTagCollectionView:(FWTextTagCollectionView *)textTagCollectionView
                    canTapTag:(NSString *)tagText
                      atIndex:(NSUInteger)index
              currentSelected:(BOOL)currentSelected __attribute__((deprecated("Use the new method")));
- (void)textTagCollectionView:(FWTextTagCollectionView *)textTagCollectionView
                    didTapTag:(NSString *)tagText
                      atIndex:(NSUInteger)index
                     selected:(BOOL)selected __attribute__((deprecated("Use the new method")));
@end

@interface FWTextTagCollectionView : UIView
// Delegate
@property (weak, nonatomic) id <FWTextTagCollectionViewDelegate> delegate;

// Inside scrollView
@property (nonatomic, strong, readonly) UIScrollView *scrollView;

// Define if the tag can be selected.
@property (assign, nonatomic) BOOL enableTagSelection;

// Default tag config
@property (nonatomic, strong) FWTextTagConfig *defaultConfig;

// Tags scroll direction, default is vertical.
@property (nonatomic, assign) FWTagCollectionScrollDirection scrollDirection;

// Tags layout alignment, default is left.
@property (nonatomic, assign) FWTagCollectionAlignment alignment;

// Number of lines. 0 means no limit, default is 0 for vertical and 1 for horizontal.
@property (nonatomic, assign) NSUInteger numberOfLines;
// The real number of lines ignoring the numberOfLines value
@property (nonatomic, assign, readonly) NSUInteger actualNumberOfLines;

// Tag selection limit, default is 0, means no limit
@property (nonatomic, assign) NSUInteger selectionLimit;

// Horizontal and vertical space between tags, default is 4.
@property (assign, nonatomic) CGFloat horizontalSpacing;
@property (assign, nonatomic) CGFloat verticalSpacing;

// Content inset, like padding, default is UIEdgeInsetsMake(2, 2, 2, 2).
@property (nonatomic, assign) UIEdgeInsets contentInset;

// The true tags content size, readonly
@property (nonatomic, assign, readonly) CGSize contentSize;

// Manual content height
// Default = NO, set will update content
@property (nonatomic, assign) BOOL manualCalculateHeight;
// Default = 0, set will update content
@property (nonatomic, assign) CGFloat preferredMaxLayoutWidth;

// Scroll indicator
@property (nonatomic, assign) BOOL showsHorizontalScrollIndicator;
@property (nonatomic, assign) BOOL showsVerticalScrollIndicator;

// Tap blank area callback
@property (nonatomic, copy) void (^onTapBlankArea)(CGPoint location);
// Tap all area callback
@property (nonatomic, copy) void (^onTapAllArea)(CGPoint location);

// Reload
- (void)reload;

// Add tag with detalt config
- (void)addTag:(NSString *)tag;

- (void)addTags:(NSArray <NSString *> *)tags;

// Add tag with custom config
- (void)addTag:(NSString *)tag withConfig:(FWTextTagConfig *)config;

- (void)addTags:(NSArray <NSString *> *)tags withConfig:(FWTextTagConfig *)config;

// Insert tag with default config
- (void)insertTag:(NSString *)tag atIndex:(NSUInteger)index;

- (void)insertTags:(NSArray <NSString *> *)tags atIndex:(NSUInteger)index;

// Insert tag with custom config
- (void)insertTag:(NSString *)tag atIndex:(NSUInteger)index withConfig:(FWTextTagConfig *)config;

- (void)insertTags:(NSArray <NSString *> *)tags atIndex:(NSUInteger)index withConfig:(FWTextTagConfig *)config;

// Remove tag
- (void)removeTag:(NSString *)tag;

- (void)removeTagAtIndex:(NSUInteger)index;

- (void)removeAllTags;

// Update tag selected state
- (void)setTagAtIndex:(NSUInteger)index selected:(BOOL)selected;

// Update tag config
- (void)setTagAtIndex:(NSUInteger)index withConfig:(FWTextTagConfig *)config;

- (void)setTagsInRange:(NSRange)range withConfig:(FWTextTagConfig *)config;

// Get tag
- (NSString *)getTagAtIndex:(NSUInteger)index;

- (NSArray <NSString *> *)getTagsInRange:(NSRange)range;

// Get tag config
- (FWTextTagConfig *)getConfigAtIndex:(NSUInteger)index;

- (NSArray <FWTextTagConfig *> *)getConfigsInRange:(NSRange)range;

// Get all
- (NSArray <NSString *> *)allTags;

- (NSArray <NSString *> *)allSelectedTags;

- (NSArray <NSString *> *)allNotSelectedTags;

/**
 * Returns the index of the tag located at the specified point.
 * If item at point is not found, returns NSNotFound.
 */
- (NSInteger)indexOfTagAt:(CGPoint)point;

@end
