/*!
 @header     UIScrollView+FWEmptyView.m
 @indexgroup FWFramework
 @brief      UIScrollView+FWEmptyView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import "UIScrollView+FWEmptyView.h"
#import "UIView+FWAutoLayout.h"
#import "UIImageView+FWFramework.h"
#import <objc/runtime.h>

#pragma mark - FWEmptyViewWeakTarget

@interface FWEmptyViewWeakTarget : NSObject

@property (nonatomic, readonly, weak) id weakObject;

- (instancetype)initWithWeakObject:(id)object;

@end

@implementation FWEmptyViewWeakTarget

- (instancetype)initWithWeakObject:(id)object
{
    self = [super init];
    if (self) {
        _weakObject = object;
    }
    return self;
}

@end

#pragma mark - FWEmptyContentView

@interface FWEmptyContentView : UIView

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, assign) CGFloat verticalOffset;
@property (nonatomic, assign) CGFloat verticalSpace;

@property (nonatomic, assign) BOOL fadeInOnDisplay;

- (void)setupConstraints;
- (void)prepareForReuse;

@end

@implementation FWEmptyContentView

- (instancetype)init
{
    self =  [super init];
    if (self) {
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)didMoveToSuperview
{
    CGRect superviewBounds = self.superview.bounds;
    self.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(superviewBounds), CGRectGetHeight(superviewBounds));
    
    if (self.fadeInOnDisplay) {
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.contentView.alpha = 1.0;
                         }
                         completion:NULL];
    } else {
        self.contentView.alpha = 1.0;
    }
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.userInteractionEnabled = YES;
        _contentView.alpha = 0;
    }
    return _contentView;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = NO;
        _imageView.accessibilityIdentifier = @"empty view background image";
        
        [_contentView addSubview:_imageView];
    }
    return _imageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.backgroundColor = [UIColor clearColor];
        
        _titleLabel.font = [UIFont systemFontOfSize:27.0];
        _titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        _titleLabel.accessibilityIdentifier = @"empty view title";
        
        [_contentView addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel
{
    if (!_detailLabel) {
        _detailLabel = [UILabel new];
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _detailLabel.backgroundColor = [UIColor clearColor];
        
        _detailLabel.font = [UIFont systemFontOfSize:17.0];
        _detailLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _detailLabel.textAlignment = NSTextAlignmentCenter;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailLabel.numberOfLines = 0;
        _detailLabel.accessibilityIdentifier = @"empty view detail label";
        
        [_contentView addSubview:_detailLabel];
    }
    return _detailLabel;
}

- (UIButton *)button
{
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        _button.backgroundColor = [UIColor clearColor];
        _button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _button.accessibilityIdentifier = @"empty view button";
        
        [_button addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [_contentView addSubview:_button];
    }
    return _button;
}

- (BOOL)canShowImage
{
    return (_imageView.image && _imageView.superview);
}

- (BOOL)canShowTitle
{
    return (_titleLabel.attributedText.string.length > 0 && _titleLabel.superview);
}

- (BOOL)canShowDetail
{
    return (_detailLabel.attributedText.string.length > 0 && _detailLabel.superview);
}

- (BOOL)canShowButton
{
    if ([_button attributedTitleForState:UIControlStateNormal].string.length > 0 || [_button imageForState:UIControlStateNormal]) {
        return (_button.superview != nil);
    }
    return NO;
}

- (void)setCustomView:(UIView *)view
{
    if (!view) {
        return;
    }
    
    if (_customView) {
        [_customView removeFromSuperview];
        _customView = nil;
    }
    
    _customView = view;
    _customView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_customView];
}

- (void)didTapButton:(id)sender
{
    SEL selector = NSSelectorFromString(@"fwEmptyDidTapDataButton:");
    
    if ([self.superview respondsToSelector:selector]) {
        [self.superview performSelector:selector withObject:sender afterDelay:0.0f];
    }
}

- (void)removeAllConstraints
{
    [self removeConstraints:self.constraints];
    [_contentView removeConstraints:_contentView.constraints];
}

- (void)prepareForReuse
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _titleLabel = nil;
    _detailLabel = nil;
    _imageView = nil;
    _button = nil;
    _customView = nil;
    
    [self removeAllConstraints];
}

- (void)setupConstraints
{
    // First, configure the content view constaints
    // The content view must alway be centered to its superview
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    [self addConstraint:centerXConstraint];
    [self addConstraint:centerYConstraint];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:nil views:@{@"contentView": self.contentView}]];
    
    // When a custom offset is available, we adjust the vertical constraints' constants
    if (self.verticalOffset != 0 && self.constraints.count > 0) {
        centerYConstraint.constant = self.verticalOffset;
    }
    
    // If applicable, set the custom view's constraints
    if (_customView) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[customView]|" options:0 metrics:nil views:@{@"customView":_customView}]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[customView]|" options:0 metrics:nil views:@{@"customView":_customView}]];
    } else {
        CGFloat width = CGRectGetWidth(self.frame) ? : CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat padding = roundf(width/16.0);
        CGFloat verticalSpace = self.verticalSpace ? : 11.0; // Default is 11 pts
        
        NSMutableArray *subviewStrings = [NSMutableArray array];
        NSMutableDictionary *views = [NSMutableDictionary dictionary];
        NSDictionary *metrics = @{@"padding": @(padding)};
        
        // Assign the image view's horizontal constraints
        if (_imageView.superview) {
            [subviewStrings addObject:@"imageView"];
            views[[subviewStrings lastObject]] = _imageView;
            
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        }
        
        // Assign the title label's horizontal constraints
        if ([self canShowTitle]) {
            [subviewStrings addObject:@"titleLabel"];
            views[[subviewStrings lastObject]] = _titleLabel;
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[titleLabel(>=0)]-(padding@750)-|"
                                                                                     options:0 metrics:metrics views:views]];
        }
        // or removes from its superview
        else {
            [_titleLabel removeFromSuperview];
            _titleLabel = nil;
        }
        
        // Assign the detail label's horizontal constraints
        if ([self canShowDetail]) {
            [subviewStrings addObject:@"detailLabel"];
            views[[subviewStrings lastObject]] = _detailLabel;
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[detailLabel(>=0)]-(padding@750)-|"
                                                                                     options:0 metrics:metrics views:views]];
        }
        // or removes from its superview
        else {
            [_detailLabel removeFromSuperview];
            _detailLabel = nil;
        }
        
        // Assign the button's horizontal constraints
        if ([self canShowButton]) {
            
            [subviewStrings addObject:@"button"];
            views[[subviewStrings lastObject]] = _button;
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[button(>=0)]-(padding@750)-|"
                                                                                     options:0 metrics:metrics views:views]];
        }
        // or removes from its superview
        else {
            [_button removeFromSuperview];
            _button = nil;
        }
        
        
        NSMutableString *verticalFormat = [NSMutableString new];
        
        // Build a dynamic string format for the vertical constraints, adding a margin between each element. Default is 11 pts.
        for (int i = 0; i < subviewStrings.count; i++) {
            
            NSString *string = subviewStrings[i];
            [verticalFormat appendFormat:@"[%@]", string];
            
            if (i < subviewStrings.count-1) {
                [verticalFormat appendFormat:@"-(%.f@750)-", verticalSpace];
            }
        }
        
        // Assign the vertical constraints to the content view
        if (verticalFormat.length > 0) {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|%@|", verticalFormat]
                                                                                     options:0 metrics:metrics views:views]];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    // Return any UIControl instance such as buttons, segmented controls, switches, etc.
    if ([hitView isKindOfClass:[UIControl class]]) {
        return hitView;
    }
    
    // Return either the contentView or customView
    if ([hitView isEqual:_contentView] || [hitView isEqual:_customView]) {
        return hitView;
    }
    
    return nil;
}

@end


#pragma mark - UIScrollView+FWEmptyView

static char const * const kEmptyViewDataSource = "emptyViewDataSource";
static char const * const kEmptyViewDelegate   = "emptyViewDelegate";
static char const * const kEmptyContentView    = "emptyContentView";

static NSString * const kEmptyViewImageAnimationKey = @"emptyViewImageAnimation";

@interface UIScrollView () <UIGestureRecognizerDelegate>

@property (nonatomic, readonly) FWEmptyContentView *fwEmptyContentView;

@end

@implementation UIScrollView (FWEmptyView)

- (id<FWEmptyViewDataSource>)fwEmptyViewDataSource
{
    FWEmptyViewWeakTarget *target = objc_getAssociatedObject(self, kEmptyViewDataSource);
    return target.weakObject;
}

- (id<FWEmptyViewDelegate>)fwEmptyViewDelegate
{
    FWEmptyViewWeakTarget *target = objc_getAssociatedObject(self, kEmptyViewDelegate);
    return target.weakObject;
}

- (BOOL)fwEmptyViewVisible
{
    UIView *view = objc_getAssociatedObject(self, kEmptyContentView);
    return view ? !view.hidden : NO;
}

- (FWEmptyContentView *)fwEmptyContentView
{
    FWEmptyContentView *view = objc_getAssociatedObject(self, kEmptyContentView);
    if (!view) {
        view = [FWEmptyContentView new];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.hidden = YES;
        
        view.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fwEmptyDidTapContentView:)];
        view.tapGesture.delegate = self;
        [view addGestureRecognizer:view.tapGesture];
        
        [self setFwEmptyContentView:view];
    }
    return view;
}

- (BOOL)fwEmptyCanDisplay
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource conformsToProtocol:@protocol(FWEmptyViewDataSource)]) {
        if ([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]] || [self isKindOfClass:[UIScrollView class]]) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)fwEmptyItemsCount
{
    NSInteger items = 0;
    
    // UIScollView doesn't respond to 'dataSource' so let's exit
    if (![self respondsToSelector:@selector(dataSource)]) {
        return items;
    }
    
    // UITableView support
    if ([self isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self;
        id <UITableViewDataSource> dataSource = tableView.dataSource;
        
        NSInteger sections = 1;
        
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            sections = [dataSource numberOfSectionsInTableView:tableView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource tableView:tableView numberOfRowsInSection:section];
            }
        }
    // UICollectionView support
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        id <UICollectionViewDataSource> dataSource = collectionView.dataSource;
        
        NSInteger sections = 1;
        
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
            sections = [dataSource numberOfSectionsInCollectionView:collectionView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource collectionView:collectionView numberOfItemsInSection:section];
            }
        }
    }
    
    return items;
}


#pragma mark - Data Source Getters

- (NSAttributedString *)fwEmptyTitleLabelString
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwTitleForEmptyView:)]) {
        NSAttributedString *string = [self.fwEmptyViewDataSource fwTitleForEmptyView:self];
        if (string) NSAssert([string isKindOfClass:[NSAttributedString class]], @"You must return a valid NSAttributedString object for -fwTitleForEmptyView:");
        return string;
    }
    return nil;
}

- (NSAttributedString *)fwEmptyDetailLabelString
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwDescriptionForEmptyView:)]) {
        NSAttributedString *string = [self.fwEmptyViewDataSource fwDescriptionForEmptyView:self];
        if (string) NSAssert([string isKindOfClass:[NSAttributedString class]], @"You must return a valid NSAttributedString object for -fwDescriptionForEmptyView:");
        return string;
    }
    return nil;
}

- (UIImage *)fwEmptyImage
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwImageForEmptyView:)]) {
        UIImage *image = [self.fwEmptyViewDataSource fwImageForEmptyView:self];
        if (image) NSAssert([image isKindOfClass:[UIImage class]], @"You must return a valid UIImage object for -fwImageForEmptyView:");
        return image;
    }
    return nil;
}

- (CAAnimation *)fwEmptyImageAnimation
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwImageAnimationForEmptyView:)]) {
        CAAnimation *imageAnimation = [self.fwEmptyViewDataSource fwImageAnimationForEmptyView:self];
        if (imageAnimation) NSAssert([imageAnimation isKindOfClass:[CAAnimation class]], @"You must return a valid CAAnimation object for -fwImageAnimationForEmptyView:");
        return imageAnimation;
    }
    return nil;
}

- (UIColor *)fwEmptyImageTintColor
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwImageTintColorForEmptyView:)]) {
        UIColor *color = [self.fwEmptyViewDataSource fwImageTintColorForEmptyView:self];
        if (color) NSAssert([color isKindOfClass:[UIColor class]], @"You must return a valid UIColor object for -fwImageTintColorForEmptyView:");
        return color;
    }
    return nil;
}

- (NSAttributedString *)fwEmptyButtonTitleForState:(UIControlState)state
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwButtonTitleForEmptyView:forState:)]) {
        NSAttributedString *string = [self.fwEmptyViewDataSource fwButtonTitleForEmptyView:self forState:state];
        if (string) NSAssert([string isKindOfClass:[NSAttributedString class]], @"You must return a valid NSAttributedString object for -fwButtonTitleForEmptyView:forState:");
        return string;
    }
    return nil;
}

- (UIImage *)fwEmptyButtonImageForState:(UIControlState)state
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwButtonImageForEmptyView:forState:)]) {
        UIImage *image = [self.fwEmptyViewDataSource fwButtonImageForEmptyView:self forState:state];
        if (image) NSAssert([image isKindOfClass:[UIImage class]], @"You must return a valid UIImage object for -fwButtonImageForEmptyView:forState:");
        return image;
    }
    return nil;
}

- (UIImage *)fwEmptyButtonBackgroundImageForState:(UIControlState)state
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwButtonBackgroundImageForEmptyView:forState:)]) {
        UIImage *image = [self.fwEmptyViewDataSource fwButtonBackgroundImageForEmptyView:self forState:state];
        if (image) NSAssert([image isKindOfClass:[UIImage class]], @"You must return a valid UIImage object for -fwButtonBackgroundImageForEmptyView:forState:");
        return image;
    }
    return nil;
}

- (UIColor *)fwEmptyBackgroundColor
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwBackgroundColorForEmptyView:)]) {
        UIColor *color = [self.fwEmptyViewDataSource fwBackgroundColorForEmptyView:self];
        if (color) NSAssert([color isKindOfClass:[UIColor class]], @"You must return a valid UIColor object for -fwBackgroundColorForEmptyView:");
        return color;
    }
    return [UIColor clearColor];
}

- (UIView *)fwEmptyCustomView
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwCustomViewForEmptyView:)]) {
        UIView *view = [self.fwEmptyViewDataSource fwCustomViewForEmptyView:self];
        if (view) NSAssert([view isKindOfClass:[UIView class]], @"You must return a valid UIView object for -fwCustomViewForEmptyView:");
        return view;
    }
    return nil;
}

- (CGFloat)fwEmptyVerticalOffset
{
    CGFloat offset = 0.0;
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwVerticalOffsetForEmptyView:)]) {
        offset = [self.fwEmptyViewDataSource fwVerticalOffsetForEmptyView:self];
    }
    return offset;
}

- (CGFloat)fwEmptyVerticalSpace
{
    if (self.fwEmptyViewDataSource && [self.fwEmptyViewDataSource respondsToSelector:@selector(fwSpaceHeightForEmptyView:)]) {
        return [self.fwEmptyViewDataSource fwSpaceHeightForEmptyView:self];
    }
    return 0.0;
}

- (BOOL)fwEmptyShouldFadeIn {
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldFadeIn:)]) {
        return [self.fwEmptyViewDelegate fwEmptyViewShouldFadeIn:self];
    }
    return YES;
}

- (BOOL)fwEmptyShouldDisplay
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldDisplay:)]) {
        return [self.fwEmptyViewDelegate fwEmptyViewShouldDisplay:self];
    }
    return YES;
}

- (BOOL)fwEmptyShouldBeForcedToDisplay
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldBeForcedToDisplay:)]) {
        return [self.fwEmptyViewDelegate fwEmptyViewShouldBeForcedToDisplay:self];
    }
    return NO;
}

- (BOOL)fwEmptyIsTouchAllowed
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldAllowTouch:)]) {
        return [self.fwEmptyViewDelegate fwEmptyViewShouldAllowTouch:self];
    }
    return YES;
}

- (BOOL)fwEmptyIsScrollAllowed
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldAllowScroll:)]) {
        return [self.fwEmptyViewDelegate fwEmptyViewShouldAllowScroll:self];
    }
    return NO;
}

- (BOOL)fwEmptyIsImageViewAnimateAllowed
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldAnimateImageView:)]) {
        return [self.fwEmptyViewDelegate fwEmptyViewShouldAnimateImageView:self];
    }
    return NO;
}

- (void)fwEmptyWillAppear
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewWillAppear:)]) {
        [self.fwEmptyViewDelegate fwEmptyViewWillAppear:self];
    }
}

- (void)fwEmptyDidAppear
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewDidAppear:)]) {
        [self.fwEmptyViewDelegate fwEmptyViewDidAppear:self];
    }
}

- (void)fwEmptyWillDisappear
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewWillDisappear:)]) {
        [self.fwEmptyViewDelegate fwEmptyViewWillDisappear:self];
    }
}

- (void)fwEmptyDidDisappear
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewDidDisappear:)]) {
        [self.fwEmptyViewDelegate fwEmptyViewDidDisappear:self];
    }
}

- (void)fwEmptyDidTapContentView:(id)sender
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyView:didTapView:)]) {
        [self.fwEmptyViewDelegate fwEmptyView:self didTapView:sender];
    }
}

- (void)fwEmptyDidTapDataButton:(id)sender
{
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyView:didTapButton:)]) {
        [self.fwEmptyViewDelegate fwEmptyView:self didTapButton:sender];
    }
}

- (void)setFwEmptyViewDataSource:(id<FWEmptyViewDataSource>)dataSource
{
    if (!dataSource || ![self fwEmptyCanDisplay]) {
        [self fwEmptyInvalidate];
    }
    
    objc_setAssociatedObject(self, kEmptyViewDataSource, [[FWEmptyViewWeakTarget alloc] initWithWeakObject:dataSource], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // We add method sizzling for injecting -fw_reloadData implementation to the native -reloadData implementation
    [self fwEmptySwizzleIfPossible:@selector(reloadData)];
    
    // Exclusively for UITableView, we also inject -fw_reloadData to -endUpdates
    if ([self isKindOfClass:[UITableView class]]) {
        [self fwEmptySwizzleIfPossible:@selector(endUpdates)];
    }
}

- (void)setFwEmptyViewDelegate:(id<FWEmptyViewDelegate>)delegate
{
    if (!delegate) {
        [self fwEmptyInvalidate];
    }
    
    objc_setAssociatedObject(self, kEmptyViewDelegate, [[FWEmptyViewWeakTarget alloc] initWithWeakObject:delegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFwEmptyContentView:(FWEmptyContentView *)view
{
    objc_setAssociatedObject(self, kEmptyContentView, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwReloadEmptyView
{
    [self fwEmptyReloadEmptyView];
}

- (void)fwEmptyReloadEmptyView
{
    if (![self fwEmptyCanDisplay]) {
        return;
    }
    
    if (([self fwEmptyShouldDisplay] && [self fwEmptyItemsCount] == 0) || [self fwEmptyShouldBeForcedToDisplay]) {
        // Notifies that the empty dataset view will appear
        [self fwEmptyWillAppear];
        
        FWEmptyContentView *view = self.fwEmptyContentView;
        
        // Configure empty dataset fade in display
        view.fadeInOnDisplay = [self fwEmptyShouldFadeIn];
        
        if (!view.superview) {
            // Send the view all the way to the back, in case a header and/or footer is present, as well as for sectionHeaders or any other content
            if (([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]]) && self.subviews.count > 1) {
                [self insertSubview:view atIndex:0];
            }
            else {
                [self addSubview:view];
            }
        }
        
        // Removing view resetting the view and its constraints it very important to guarantee a good state
        [view prepareForReuse];
        
        UIView *customView = [self fwEmptyCustomView];
        
        // If a non-nil custom view is available, let's configure it instead
        if (customView) {
            view.customView = customView;
        } else {
            // Get the data from the data source
            NSAttributedString *titleLabelString = [self fwEmptyTitleLabelString];
            NSAttributedString *detailLabelString = [self fwEmptyDetailLabelString];
            
            UIImage *buttonImage = [self fwEmptyButtonImageForState:UIControlStateNormal];
            NSAttributedString *buttonTitle = [self fwEmptyButtonTitleForState:UIControlStateNormal];
            
            UIImage *image = [self fwEmptyImage];
            UIColor *imageTintColor = [self fwEmptyImageTintColor];
            UIImageRenderingMode renderingMode = imageTintColor ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAlwaysOriginal;
            
            view.verticalSpace = [self fwEmptyVerticalSpace];
            
            // Configure Image
            if (image) {
                view.imageView.fwImage = [image imageWithRenderingMode:renderingMode];
                view.imageView.tintColor = imageTintColor;
            }
            
            // Configure title label
            if (titleLabelString) {
                view.titleLabel.attributedText = titleLabelString;
            }
            
            // Configure detail label
            if (detailLabelString) {
                view.detailLabel.attributedText = detailLabelString;
            }
            
            // Configure button
            if (buttonImage) {
                [view.button setImage:buttonImage forState:UIControlStateNormal];
                [view.button setImage:[self fwEmptyButtonImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            } else if (buttonTitle) {
                [view.button setAttributedTitle:buttonTitle forState:UIControlStateNormal];
                [view.button setAttributedTitle:[self fwEmptyButtonTitleForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
                [view.button setBackgroundImage:[self fwEmptyButtonBackgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
                [view.button setBackgroundImage:[self fwEmptyButtonBackgroundImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            }
        }
        
        // Configure offset
        view.verticalOffset = [self fwEmptyVerticalOffset];
        
        // Configure the empty dataset view
        view.backgroundColor = [self fwEmptyBackgroundColor];
        view.hidden = NO;
        view.clipsToBounds = YES;
        
        // Configure empty dataset userInteraction permission
        view.userInteractionEnabled = [self fwEmptyIsTouchAllowed];
        
        [view setupConstraints];
        
        [UIView performWithoutAnimation:^{
            [view layoutIfNeeded];
        }];
        
        // Configure scroll permission
        self.scrollEnabled = [self fwEmptyIsScrollAllowed];
        
        // Configure image view animation
        if ([self fwEmptyIsImageViewAnimateAllowed]) {
            CAAnimation *animation = [self fwEmptyImageAnimation];
            
            if (animation) {
                [self.fwEmptyContentView.imageView.layer addAnimation:animation forKey:kEmptyViewImageAnimationKey];
            }
        } else if ([self.fwEmptyContentView.imageView.layer animationForKey:kEmptyViewImageAnimationKey]) {
            [self.fwEmptyContentView.imageView.layer removeAnimationForKey:kEmptyViewImageAnimationKey];
        }
        
        // Notifies that the empty dataset view did appear
        [self fwEmptyDidAppear];
    } else if (self.fwEmptyViewVisible) {
        [self fwEmptyInvalidate];
    }
}

- (void)fwEmptyInvalidate
{
    // Notifies that the empty dataset view will disappear
    [self fwEmptyWillDisappear];
    
    if (self.fwEmptyContentView) {
        [self.fwEmptyContentView prepareForReuse];
        [self.fwEmptyContentView removeFromSuperview];
        
        [self setFwEmptyContentView:nil];
    }
    
    self.scrollEnabled = YES;
    
    // Notifies that the empty dataset view did disappear
    [self fwEmptyDidDisappear];
}

static NSMutableDictionary *fwEmpty_impLookupTable;
static NSString *const FWEmptySwizzleInfoPointerKey = @"pointer";
static NSString *const FWEmptySwizzleInfoOwnerKey = @"owner";
static NSString *const FWEmptySwizzleInfoSelectorKey = @"selector";

// Based on Bryce Buchanan's swizzling technique http://blog.newrelic.com/2014/04/16/right-way-to-swizzle/
// And Juzzin's ideas https://github.com/juzzin/JUSEmptyViewController

void fwEmpty_original_implementation(id self, SEL _cmd)
{
    // Fetch original implementation from lookup table
    Class baseClass = fwEmpty_baseClassToSwizzleForTarget(self);
    NSString *key = fwEmpty_implementationKey(baseClass, _cmd);
    
    NSDictionary *swizzleInfo = [fwEmpty_impLookupTable objectForKey:key];
    NSValue *impValue = [swizzleInfo valueForKey:FWEmptySwizzleInfoPointerKey];
    
    IMP impPointer = [impValue pointerValue];
    
    // We then inject the additional implementation for reloading the empty dataset
    // Doing it before calling the original implementation does update the 'isEmptyDataSetVisible' flag on time.
    [self fwEmptyReloadEmptyView];
    
    // If found, call original implementation
    if (impPointer) {
        ((void(*)(id,SEL))impPointer)(self,_cmd);
    }
}

NSString *fwEmpty_implementationKey(Class class, SEL selector)
{
    if (!class || !selector) {
        return nil;
    }
    
    NSString *className = NSStringFromClass([class class]);
    
    NSString *selectorName = NSStringFromSelector(selector);
    return [NSString stringWithFormat:@"%@_%@",className,selectorName];
}

Class fwEmpty_baseClassToSwizzleForTarget(id target)
{
    if ([target isKindOfClass:[UITableView class]]) {
        return [UITableView class];
    }
    else if ([target isKindOfClass:[UICollectionView class]]) {
        return [UICollectionView class];
    }
    else if ([target isKindOfClass:[UIScrollView class]]) {
        return [UIScrollView class];
    }
    
    return nil;
}

- (void)fwEmptySwizzleIfPossible:(SEL)selector
{
    // Check if the target responds to selector
    if (![self respondsToSelector:selector]) {
        return;
    }
    
    // Create the lookup table
    if (!fwEmpty_impLookupTable) {
        fwEmpty_impLookupTable = [[NSMutableDictionary alloc] initWithCapacity:3]; // 3 represent the supported base classes
    }
    
    // We make sure that setImplementation is called once per class kind, UITableView or UICollectionView.
    for (NSDictionary *info in [fwEmpty_impLookupTable allValues]) {
        Class class = [info objectForKey:FWEmptySwizzleInfoOwnerKey];
        NSString *selectorName = [info objectForKey:FWEmptySwizzleInfoSelectorKey];
        
        if ([selectorName isEqualToString:NSStringFromSelector(selector)]) {
            if ([self isKindOfClass:class]) {
                return;
            }
        }
    }
    
    Class baseClass = fwEmpty_baseClassToSwizzleForTarget(self);
    NSString *key = fwEmpty_implementationKey(baseClass, selector);
    NSValue *impValue = [[fwEmpty_impLookupTable objectForKey:key] valueForKey:FWEmptySwizzleInfoPointerKey];
    
    // If the implementation for this class already exist, skip!!
    if (impValue || !key || !baseClass) {
        return;
    }
    
    // Swizzle by injecting additional implementation
    Method method = class_getInstanceMethod(baseClass, selector);
    IMP fwEmpty_newImplementation = method_setImplementation(method, (IMP)fwEmpty_original_implementation);
    
    // Store the new implementation in the lookup table
    NSDictionary *swizzledInfo = @{FWEmptySwizzleInfoOwnerKey: baseClass,
                                   FWEmptySwizzleInfoSelectorKey: NSStringFromSelector(selector),
                                   FWEmptySwizzleInfoPointerKey: [NSValue valueWithPointer:fwEmpty_newImplementation]};
    
    [fwEmpty_impLookupTable setObject:swizzledInfo forKey:key];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.view isEqual:self.fwEmptyContentView]) {
        return [self fwEmptyIsTouchAllowed];
    }
    
    return [super gestureRecognizerShouldBegin:gestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    UIGestureRecognizer *tapGesture = self.fwEmptyContentView.tapGesture;
    if ([gestureRecognizer isEqual:tapGesture] || [otherGestureRecognizer isEqual:tapGesture]) {
        return YES;
    }
    
    // defer to emptyDataSetDelegate's implementation if available
    if ( (self.fwEmptyViewDelegate != (id)self) && [self.fwEmptyViewDelegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [(id)self.fwEmptyViewDelegate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    
    return NO;
}

@end
