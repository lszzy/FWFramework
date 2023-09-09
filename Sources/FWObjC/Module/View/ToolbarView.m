//
//  ToolbarView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "ToolbarView.h"
#import <objc/runtime.h>
#import <FWFramework/FWFramework-Swift.h>

#pragma mark - __FWToolbarTitleView

@interface __FWToolbarTitleView () <__FWTitleViewProtocol>

@property(nonatomic, strong, readonly) UIView *contentView;
@property(nonatomic, assign) CGSize titleLabelSize;
@property(nonatomic, assign) CGSize subtitleLabelSize;
@property(nonatomic, strong) UIImageView *accessoryImageView;

@end

@implementation __FWToolbarTitleView

#pragma mark - Static

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSObject __fw_swizzleMethod:[UINavigationBar class] selector:@selector(layoutSubviews) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained UINavigationBar *selfObject) {
                void (*originalMSG)(id, SEL) = (void (*)(id, SEL))originalIMP();
                UIView *titleView = selfObject.topItem.titleView;
                if (![titleView conformsToProtocol:@protocol(__FWTitleViewProtocol)]) {
                    originalMSG(selfObject, originalCMD);
                    return;
                }
                
                CGFloat titleMaximumWidth = CGRectGetWidth(titleView.bounds);
                CGSize titleViewSize = [titleView sizeThatFits:CGSizeMake(titleMaximumWidth, CGFLOAT_MAX)];
                titleViewSize.height = ceil(titleViewSize.height);
                
                if (CGRectGetHeight(titleView.bounds) != titleViewSize.height) {
                    CGFloat titleViewMinY = [UIScreen __fw_flatValue:CGRectGetMinY(titleView.frame) - ((titleViewSize.height - CGRectGetHeight(titleView.bounds)) / 2.0) scale:0];
                    titleView.frame = CGRectMake(CGRectGetMinX(titleView.frame), titleViewMinY, MIN(titleMaximumWidth, titleViewSize.width), titleViewSize.height);
                }
                
                if (CGRectGetWidth(titleView.bounds) != titleViewSize.width) {
                    CGRect titleFrame = titleView.frame;
                    titleFrame.size.width = titleViewSize.width;
                    titleView.frame = titleFrame;
                }
                
                originalMSG(selfObject, originalCMD);
            };
        }];
        
        [NSObject __fw_swizzleMethod:[UIViewController class] selector:@selector(setTitle:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained UIViewController *selfObject, NSString *title) {
                void (*originalMSG)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))originalIMP();
                originalMSG(selfObject, originalCMD, title);
                
                if ([selfObject.navigationItem.titleView conformsToProtocol:@protocol(__FWTitleViewProtocol)]) {
                    ((id<__FWTitleViewProtocol>)selfObject.navigationItem.titleView).title = title;
                }
            };
        }];
        
        [NSObject __fw_swizzleMethod:[UINavigationItem class] selector:@selector(setTitle:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained UINavigationItem *selfObject, NSString *title) {
                void (*originalMSG)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))originalIMP();
                originalMSG(selfObject, originalCMD, title);
                
                if ([selfObject.titleView conformsToProtocol:@protocol(__FWTitleViewProtocol)]) {
                    ((id<__FWTitleViewProtocol>)selfObject.titleView).title = title;
                }
            };
        }];
        
        [NSObject __fw_swizzleMethod:[UINavigationItem class] selector:@selector(setTitleView:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained UINavigationItem *selfObject, UIView<__FWTitleViewProtocol> *titleView) {
                void (*originalMSG)(id, SEL, UIView *) = (void (*)(id, SEL, UIView *))originalIMP();
                originalMSG(selfObject, originalCMD, titleView);
                
                if ([titleView conformsToProtocol:@protocol(__FWTitleViewProtocol)]) {
                    if (titleView.title.length <= 0) {
                        titleView.title = selfObject.title;
                    }
                }
            };
        }];
    });
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    __FWToolbarTitleView *appearance = [__FWToolbarTitleView appearance];
    appearance.adjustsTintColor = YES;
    appearance.maximumWidth = CGFLOAT_MAX;
    appearance.loadingViewSize = CGSizeMake(18, 18);
    appearance.loadingViewSpacing = 3;
    appearance.horizontalTitleFont = [UIFont boldSystemFontOfSize:17];
    appearance.horizontalSubtitleFont = [UIFont boldSystemFontOfSize:17];
    appearance.verticalTitleFont = [UIFont systemFontOfSize:15];
    appearance.verticalSubtitleFont = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
    appearance.accessoryViewOffset = CGPointMake(3, 0);
    appearance.subAccessoryViewOffset = CGPointMake(3, 0);
    appearance.titleEdgeInsets = UIEdgeInsetsZero;
    appearance.subtitleEdgeInsets = UIEdgeInsetsZero;
    appearance.minimumLeftMargin = 16;
}

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithStyle:__FWToolbarTitleViewStyleHorizontal frame:frame];
}

- (instancetype)initWithStyle:(__FWToolbarTitleViewStyle)style {
    return [self initWithStyle:style frame:CGRectZero];
}

- (instancetype)initWithStyle:(__FWToolbarTitleViewStyle)style frame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addTarget:self action:@selector(titleViewTouched) forControlEvents:UIControlEventTouchUpInside];
        
        _contentView = [[UIView alloc] init];
        _contentView.userInteractionEnabled = NO;
        [self addSubview:self.contentView];
        
        _titleLabel = [[UILabel alloc] init];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.titleLabel.accessibilityTraits |= UIAccessibilityTraitHeader;
        [self.contentView addSubview:self.titleLabel];
        
        _subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        self.subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.subtitleLabel.accessibilityTraits |= UIAccessibilityTraitHeader;
        [self.contentView addSubview:self.subtitleLabel];
        
        self.userInteractionEnabled = NO;
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        self.style = style;
        self.showsLoadingView = NO;
        self.loadingViewHidden = YES;
        self.showsAccessoryPlaceholder = NO;
        self.showsSubAccessoryPlaceholder = NO;
        self.showsLoadingPlaceholder = YES;
        
        [self __fw_applyAppearance];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, title = %@, subtitle = %@", [super description], self.title, self.subtitle];
}

#pragma mark - Accessor

- (void)setStyle:(__FWToolbarTitleViewStyle)style {
    _style = style;
    if (style == __FWToolbarTitleViewStyleVertical) {
        self.titleLabel.font = self.verticalTitleFont;
        self.subtitleLabel.font = self.verticalSubtitleFont;
    } else {
        self.titleLabel.font = self.horizontalTitleFont;
        self.subtitleLabel.font = self.horizontalSubtitleFont;
    }
    [self refreshLayout];
}

- (void)setMaximumWidth:(CGFloat)maximumWidth {
    _maximumWidth = maximumWidth;
    [self refreshLayout];
}

- (void)setContentHorizontalAlignment:(UIControlContentHorizontalAlignment)contentHorizontalAlignment {
    [super setContentHorizontalAlignment:contentHorizontalAlignment];
    [self refreshLayout];
}

- (void)setShowsLoadingPlaceholder:(BOOL)showsLoadingPlaceholder {
    _showsLoadingPlaceholder = showsLoadingPlaceholder;
    [self refreshLayout];
}

- (void)setShowsAccessoryPlaceholder:(BOOL)showsAccessoryPlaceholder {
    _showsAccessoryPlaceholder = showsAccessoryPlaceholder;
    [self refreshLayout];
}

- (void)setAccessoryViewOffset:(CGPoint)accessoryViewOffset {
    _accessoryViewOffset = accessoryViewOffset;
    [self refreshLayout];
}

- (void)setShowsSubAccessoryPlaceholder:(BOOL)showsSubAccessoryPlaceholder {
    _showsSubAccessoryPlaceholder = showsSubAccessoryPlaceholder;
    [self refreshLayout];
}

- (void)setSubAccessoryViewOffset:(CGPoint)subAccessoryViewOffset {
    _subAccessoryViewOffset = subAccessoryViewOffset;
    [self refreshLayout];
}

- (void)setLoadingViewSpacing:(CGFloat)loadingViewSpacing {
    _loadingViewSpacing = loadingViewSpacing;
    [self refreshLayout];
}

- (void)setHorizontalTitleFont:(UIFont *)horizontalTitleFont {
    _horizontalTitleFont = horizontalTitleFont;
    if (self.style == __FWToolbarTitleViewStyleHorizontal) {
        self.titleLabel.font = horizontalTitleFont;
        [self refreshLayout];
    }
}

- (void)setHorizontalSubtitleFont:(UIFont *)horizontalSubtitleFont {
    _horizontalSubtitleFont = horizontalSubtitleFont;
    if (self.style == __FWToolbarTitleViewStyleHorizontal) {
        self.subtitleLabel.font = horizontalSubtitleFont;
        [self refreshLayout];
    }
}

- (void)setVerticalTitleFont:(UIFont *)verticalTitleFont {
    _verticalTitleFont = verticalTitleFont;
    if (self.style == __FWToolbarTitleViewStyleVertical) {
        self.titleLabel.font = verticalTitleFont;
        [self refreshLayout];
    }
}

- (void)setVerticalSubtitleFont:(UIFont *)verticalSubtitleFont {
    _verticalSubtitleFont = verticalSubtitleFont;
    if (self.style == __FWToolbarTitleViewStyleVertical) {
        self.subtitleLabel.font = verticalSubtitleFont;
        [self refreshLayout];
    }
}

- (void)setTitleEdgeInsets:(UIEdgeInsets)titleEdgeInsets {
    _titleEdgeInsets = titleEdgeInsets;
    [self refreshLayout];
}

- (void)setSubtitleEdgeInsets:(UIEdgeInsets)subtitleEdgeInsets {
    _subtitleEdgeInsets = subtitleEdgeInsets;
    [self refreshLayout];
}

- (void)setAlignmentLeft:(BOOL)alignmentLeft {
    _alignmentLeft = alignmentLeft;
    self.titleLabel.textAlignment = alignmentLeft ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    self.subtitleLabel.textAlignment = alignmentLeft ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    [self refreshLayout];
}

- (void)setIsExpandedSize:(BOOL)isExpandedSize {
    _isExpandedSize = isExpandedSize;
    [self refreshLayout];
}

- (void)setMinimumLeftMargin:(CGFloat)minimumLeftMargin {
    _minimumLeftMargin = minimumLeftMargin;
    [self refreshLayout];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
    [self refreshLayout];
}

- (void)setSubtitle:(NSString *)subtitle {
    _subtitle = subtitle;
    self.subtitleLabel.text = subtitle;
    [self refreshLayout];
}

- (void)setAccessoryImage:(UIImage *)accessoryImage {
    if (self.accessoryView) accessoryImage = nil;
    _accessoryImage = accessoryImage;
    
    if (!accessoryImage) {
        [self.accessoryImageView removeFromSuperview];
        self.accessoryImageView = nil;
        [self refreshLayout];
        return;
    }
    
    if (!self.accessoryImageView) {
        self.accessoryImageView = [[UIImageView alloc] init];
        self.accessoryImageView.contentMode = UIViewContentModeCenter;
    }
    self.accessoryImageView.image = accessoryImage;
    [self.accessoryImageView sizeToFit];
    if (self.accessoryImageView.superview != self) {
        [self.contentView addSubview:self.accessoryImageView];
    }
    [self refreshLayout];
}

- (void)setAccessoryView:(UIView *)accessoryView {
    if (_accessoryView != accessoryView) {
        [_accessoryView removeFromSuperview];
        _accessoryView = nil;
    }
    if (accessoryView) {
        _accessoryView = accessoryView;
        self.accessoryImage = nil;
        [self.accessoryView sizeToFit];
        [self.contentView addSubview:self.accessoryView];
    }
    [self refreshLayout];
}

- (void)setSubAccessoryView:(UIView *)subAccessoryView {
    if (_subAccessoryView != subAccessoryView) {
        [_subAccessoryView removeFromSuperview];
        _subAccessoryView = nil;
    }
    if (subAccessoryView) {
        _subAccessoryView = subAccessoryView;
        [self.subAccessoryView sizeToFit];
        [self.contentView addSubview:self.subAccessoryView];
    }
    [self refreshLayout];
}

- (void)updateSubAccessoryViewHidden {
    if (self.subAccessoryView && self.subtitleLabel.text.length && self.style == __FWToolbarTitleViewStyleVertical) {
        self.subAccessoryView.hidden = NO;
    } else {
        self.subAccessoryView.hidden = YES;
    }
}

- (void)setLoadingView:(UIView<__FWIndicatorViewPlugin> *)loadingView {
    if (_loadingView != loadingView) {
        [_loadingView stopAnimating];
        [_loadingView removeFromSuperview];
        _loadingView = nil;
    }
    if (loadingView) {
        _loadingView = loadingView;
        _loadingView.indicatorSize = self.loadingViewSize;
        _loadingView.indicatorColor = self.tintColor;
        [_loadingView stopAnimating];
        [self.contentView addSubview:_loadingView];
    }
    [self refreshLayout];
}

- (void)setShowsLoadingView:(BOOL)showsLoadingView {
    _showsLoadingView = showsLoadingView;
    if (showsLoadingView) {
        if (!self.loadingView) {
            self.loadingView = [UIActivityIndicatorView __fw_indicatorView];
        } else {
            [self refreshLayout];
        }
    } else {
        if (self.loadingView) {
            self.loadingView = nil;
        } else {
            [self refreshLayout];
        }
    }
}

- (void)setLoadingViewHidden:(BOOL)loadingViewHidden {
    _loadingViewHidden = loadingViewHidden;
    if (self.showsLoadingView) {
        loadingViewHidden ? [self.loadingView stopAnimating] : [self.loadingView startAnimating];
    }
    [self refreshLayout];
}

- (void)setActive:(BOOL)active {
    [self setActive:active animated:NO];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
    if (_active == active) return;
    _active = active;
    if ([self.delegate respondsToSelector:@selector(didChangedActive:forTitleView:)]) {
        [self.delegate didChangedActive:active forTitleView:self];
    }
    if (self.accessoryImage != nil) {
        CGFloat rotationDegree = active ? -180 : -360;
        [UIView animateWithDuration:animated ? .25f : 0 delay:0 options:(8<<16) animations:^(void){
            self.accessoryImageView.transform = CGAffineTransformMakeRotation((M_PI * rotationDegree / 180.0));
        } completion:^(BOOL finished) {}];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? 0.5f : 1;
}

#pragma mark - Private

- (void)setNeedsLayout {
    [self updateTitleLabelSize];
    [self updateSubtitleLabelSize];
    [self updateSubAccessoryViewHidden];
    [super setNeedsLayout];
}

- (void)refreshLayout {
    UINavigationBar *navigationBar = [self searchNavigationBar:self];
    if (navigationBar) [navigationBar setNeedsLayout];
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (UINavigationBar *)searchNavigationBar:(UIView *)subview {
    if (!subview.superview) return nil;
    if ([subview.superview isKindOfClass:[UINavigationBar class]]) {
        return (UINavigationBar *)subview.superview;
    }
    return [self searchNavigationBar:subview.superview];
}

- (void)updateTitleLabelSize {
    if (self.titleLabel.text.length > 0) {
        CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        self.titleLabelSize = CGSizeMake(ceil(size.width), ceil(size.height));
    } else {
        self.titleLabelSize = CGSizeZero;
    }
}

- (void)updateSubtitleLabelSize {
    if (self.subtitleLabel.text.length > 0) {
        CGSize size = [self.subtitleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        self.subtitleLabelSize = CGSizeMake(ceil(size.width), ceil(size.height));
    } else {
        self.subtitleLabelSize = CGSizeZero;
    }
}

- (CGSize)loadingViewSpacingSize {
    if (self.showsLoadingView) {
        return CGSizeMake(self.loadingViewSize.width + self.loadingViewSpacing, self.loadingViewSize.height);
    }
    return CGSizeZero;
}

- (CGSize)loadingViewSpacingSizeIfNeedsPlaceholder {
    return CGSizeMake([self loadingViewSpacingSize].width * (self.showsLoadingPlaceholder ? 2 : 1), [self loadingViewSpacingSize].height);
}

- (CGSize)accessorySpacingSize {
    if (self.accessoryView || self.accessoryImageView) {
        UIView *view = self.accessoryView ?: self.accessoryImageView;
        return CGSizeMake(CGRectGetWidth(view.bounds) + self.accessoryViewOffset.x, CGRectGetHeight(view.bounds));
    }
    return CGSizeZero;
}

- (CGSize)subAccessorySpacingSize {
    if (self.subAccessoryView) {
        UIView *view = self.subAccessoryView;
        return CGSizeMake(CGRectGetWidth(view.bounds) + self.subAccessoryViewOffset.x, CGRectGetHeight(view.bounds));
    }
    return CGSizeZero;
}

- (CGSize)accessorySpacingSizeIfNeedesPlaceholder {
    return CGSizeMake([self accessorySpacingSize].width * (self.showsAccessoryPlaceholder ? 2 : 1), [self accessorySpacingSize].height);
}

- (CGSize)subAccessorySpacingSizeIfNeedesPlaceholder {
    return CGSizeMake([self subAccessorySpacingSize].width * (self.showsSubAccessoryPlaceholder ? 2 : 1), [self subAccessorySpacingSize].height);
}

- (UIEdgeInsets)titleEdgeInsetsIfShowingTitleLabel {
    return (self.titleLabelSize.width <= 0 || self.titleLabelSize.height <= 0) ? UIEdgeInsetsZero : self.titleEdgeInsets;
}

- (UIEdgeInsets)subtitleEdgeInsetsIfShowingSubtitleLabel {
    return (self.subtitleLabelSize.width <= 0 || self.subtitleLabelSize.height <= 0) ? UIEdgeInsetsZero : self.subtitleEdgeInsets;
}

- (CGFloat)firstLineWidthInVerticalStyle {
    CGFloat firstLineWidth = self.titleLabelSize.width + (self.titleEdgeInsetsIfShowingTitleLabel.left + self.titleEdgeInsetsIfShowingTitleLabel.right);
    firstLineWidth += [self loadingViewSpacingSizeIfNeedsPlaceholder].width;
    firstLineWidth += [self accessorySpacingSizeIfNeedesPlaceholder].width;
    return firstLineWidth;
}

- (CGFloat)secondLineWidthInVerticalStyle {
    CGFloat secondLineWidth = self.subtitleLabelSize.width + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.left + self.subtitleEdgeInsetsIfShowingSubtitleLabel.right);
    if (self.subtitleLabelSize.width > 0 && self.subAccessoryView && !self.subAccessoryView.hidden) {
        secondLineWidth += [self subAccessorySpacingSizeIfNeedesPlaceholder].width;
    }
    return secondLineWidth;
}

- (CGSize)contentSize {
    if (self.style == __FWToolbarTitleViewStyleVertical) {
        CGSize size = CGSizeZero;
        CGFloat firstLineWidth = [self firstLineWidthInVerticalStyle];
        CGFloat secondLineWidth = [self secondLineWidthInVerticalStyle];
        size.width = MAX(firstLineWidth, secondLineWidth);
        size.height = self.titleLabelSize.height + (self.titleEdgeInsetsIfShowingTitleLabel.top + self.titleEdgeInsetsIfShowingTitleLabel.bottom) + self.subtitleLabelSize.height + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.top + self.subtitleEdgeInsetsIfShowingSubtitleLabel.bottom);
        return CGSizeMake([UIScreen __fw_flatValue:size.width scale:0], [UIScreen __fw_flatValue:size.height scale:0]);
    } else {
        CGSize size = CGSizeZero;
        size.width = self.titleLabelSize.width + (self.titleEdgeInsetsIfShowingTitleLabel.left + self.titleEdgeInsetsIfShowingTitleLabel.right) + self.subtitleLabelSize.width + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.left + self.subtitleEdgeInsetsIfShowingSubtitleLabel.right);
        size.width += [self loadingViewSpacingSizeIfNeedsPlaceholder].width + [self accessorySpacingSizeIfNeedesPlaceholder].width;
        size.height = MAX(self.titleLabelSize.height + (self.titleEdgeInsetsIfShowingTitleLabel.top + self.titleEdgeInsetsIfShowingTitleLabel.bottom), self.subtitleLabelSize.height + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.top + self.subtitleEdgeInsetsIfShowingSubtitleLabel.bottom));
        size.height = MAX(size.height, [self loadingViewSpacingSizeIfNeedsPlaceholder].height);
        size.height = MAX(size.height, [self accessorySpacingSizeIfNeedesPlaceholder].height);
        return CGSizeMake([UIScreen __fw_flatValue:size.width scale:0], [UIScreen __fw_flatValue:size.height scale:0]);
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize resultSize = [self contentSize];
    if (self.isExpandedSize) {
        resultSize.width = MIN(UIScreen.mainScreen.bounds.size.width, self.maximumWidth);
    } else {
        resultSize.width = MIN(resultSize.width, self.maximumWidth);
    }
    return resultSize;
}

- (CGSize)intrinsicContentSize {
    if (self.isExpandedSize) {
        return UILayoutFittingExpandedSize;
    } else {
        return [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0) return;
    self.contentView.frame = self.bounds;
    
    BOOL alignLeft = self.contentHorizontalAlignment == UIControlContentHorizontalAlignmentLeft;
    BOOL alignRight = self.contentHorizontalAlignment == UIControlContentHorizontalAlignmentRight;
    CGSize maxSize = self.bounds.size;
    CGSize contentSize = [self contentSize];
    contentSize.width = MIN(maxSize.width, contentSize.width);
    contentSize.height = MIN(maxSize.height, contentSize.height);
    
    CGFloat contentOffsetLeft = (maxSize.width - contentSize.width) / 2.0;
    if (self.alignmentLeft) {
        contentOffsetLeft = 0;
        // 处理navigationBar左侧按钮和标题视图位置，和系统一致
        UINavigationBar *navigationBar = [self searchNavigationBar:self];
        if (navigationBar) {
            CGRect convertFrame = [self.superview convertRect:self.frame toView:navigationBar];
            if (CGRectGetMinX(convertFrame) < self.minimumLeftMargin) {
                contentOffsetLeft = self.minimumLeftMargin - CGRectGetMinX(convertFrame);
            }
        }
    }
    CGFloat contentOffsetRight = contentOffsetLeft;
    
    CGFloat loadingViewSpace = [self loadingViewSpacingSize].width;
    UIView *accessoryView = self.accessoryView ?: self.accessoryImageView;
    CGFloat accessoryViewSpace = [self accessorySpacingSize].width;
    BOOL isTitleLabelShowing = self.titleLabel.text.length > 0;
    BOOL isSubtitleLabelShowing = self.subtitleLabel.text.length > 0;
    BOOL isSubAccessoryViewShowing = isSubtitleLabelShowing && self.subAccessoryView && !self.subAccessoryView.hidden;
    UIEdgeInsets titleEdgeInsets = self.titleEdgeInsetsIfShowingTitleLabel;
    UIEdgeInsets subtitleEdgeInsets = self.subtitleEdgeInsetsIfShowingSubtitleLabel;
    
    if (self.style == __FWToolbarTitleViewStyleVertical) {
        CGFloat firstLineWidth = [self firstLineWidthInVerticalStyle];
        CGFloat firstLineMinX = 0;
        CGFloat firstLineMaxX = 0;
        if (alignLeft) {
            firstLineMinX = contentOffsetLeft;
        } else if (alignRight) {
            firstLineMinX = MAX(contentOffsetLeft, contentOffsetLeft + contentSize.width - firstLineWidth);
        } else {
            firstLineMinX = contentOffsetLeft + MAX(0, (contentSize.width - firstLineWidth) / 2.0);
        }
        firstLineMaxX = firstLineMinX + MIN(firstLineWidth, contentSize.width) - (self.showsLoadingPlaceholder ? [self loadingViewSpacingSize].width : 0);
        firstLineMinX += self.showsAccessoryPlaceholder ? accessoryViewSpace : 0;
        if (self.loadingView && (self.showsLoadingPlaceholder || !self.loadingViewHidden)) {
            CGRect loadingFrame = self.loadingView.frame;
            loadingFrame.origin.x = firstLineMinX;
            loadingFrame.origin.y = (self.titleLabelSize.height - self.loadingViewSize.height) / 2.0 + titleEdgeInsets.top;
            self.loadingView.frame = loadingFrame;
            firstLineMinX = CGRectGetMaxX(self.loadingView.frame) + self.loadingViewSpacing;
        }
        if (accessoryView) {
            CGRect accessoryFrame = accessoryView.frame;
            accessoryFrame.origin.x = firstLineMaxX - CGRectGetWidth(accessoryView.frame);
            accessoryFrame.origin.y = (self.titleLabelSize.height - CGRectGetHeight(accessoryView.frame)) / 2.0 + titleEdgeInsets.top + self.accessoryViewOffset.y;
            accessoryView.frame = accessoryFrame;
            firstLineMaxX = CGRectGetMinX(accessoryView.frame) - self.accessoryViewOffset.x;
        }
        if (isTitleLabelShowing) {
            firstLineMinX += titleEdgeInsets.left;
            firstLineMaxX -= titleEdgeInsets.right;
            self.titleLabel.frame = CGRectMake(firstLineMinX, titleEdgeInsets.top, firstLineMaxX - firstLineMinX, self.titleLabelSize.height);
        } else {
            self.titleLabel.frame = CGRectZero;
        }
        
        if (isSubtitleLabelShowing) {
            CGFloat secondLineWidth = [self secondLineWidthInVerticalStyle];
            CGFloat secondLineMinX = 0;
            CGFloat secondLineMaxX = 0;
            CGFloat secondLineMinY = subtitleEdgeInsets.top + (isTitleLabelShowing ? CGRectGetMaxY(self.titleLabel.frame) + titleEdgeInsets.bottom : 0);
            if (alignLeft) {
                secondLineMinX = contentOffsetLeft;
            } else if (alignRight) {
                secondLineMinX = MAX(contentOffsetLeft, contentOffsetLeft + contentSize.width - secondLineWidth);
            } else {
                secondLineMinX = contentOffsetLeft + MAX(0, (contentSize.width - secondLineWidth) / 2.0);
            }
            secondLineMaxX = secondLineMinX + MIN(secondLineWidth, contentSize.width);
            secondLineMinX += self.showsSubAccessoryPlaceholder ? [self subAccessorySpacingSize].width : 0;
            if (isSubAccessoryViewShowing) {
                CGRect subFrame = self.subAccessoryView.frame;
                subFrame.origin.x = secondLineMaxX - CGRectGetWidth(self.subAccessoryView.frame);
                subFrame.origin.y = secondLineMinY + (self.subtitleLabelSize.height - CGRectGetHeight(self.subAccessoryView.frame)) / 2.0 + self.subAccessoryViewOffset.y;
                self.subAccessoryView.frame = subFrame;
                secondLineMaxX = CGRectGetMinX(self.subAccessoryView.frame) - self.subAccessoryViewOffset.x;
            }
            self.subtitleLabel.frame = CGRectMake(secondLineMinX, secondLineMinY, secondLineMaxX - secondLineMinX, self.subtitleLabelSize.height);
        } else {
            self.subtitleLabel.frame = CGRectZero;
        }
        
    } else {
        CGFloat minX = contentOffsetLeft + (self.showsAccessoryPlaceholder ? accessoryViewSpace : 0);
        CGFloat maxX = maxSize.width - contentOffsetRight - (self.showsLoadingPlaceholder ? loadingViewSpace : 0);
        
        if (self.loadingView && (self.showsLoadingPlaceholder || !self.loadingViewHidden)) {
            CGRect loadingFrame = self.loadingView.frame;
            loadingFrame.origin.x = minX;
            loadingFrame.origin.y = (maxSize.height - self.loadingViewSize.height) / 2.0;
            self.loadingView.frame = loadingFrame;
            minX = CGRectGetMaxX(self.loadingView.frame) + self.loadingViewSpacing;
        }
        if (accessoryView) {
            CGRect accessoryFrame = accessoryView.frame;
            accessoryFrame.origin.x = maxX - CGRectGetWidth(accessoryView.bounds);
            accessoryFrame.origin.y = (maxSize.height - CGRectGetHeight(accessoryView.bounds)) / 2.0 + self.accessoryViewOffset.y;
            accessoryView.frame = accessoryFrame;
            maxX = CGRectGetMinX(accessoryView.frame) - self.accessoryViewOffset.x;
        }
        if (isSubtitleLabelShowing) {
            maxX -= subtitleEdgeInsets.right;
            BOOL shouldSubtitleLabelCenterVertically = self.subtitleLabelSize.height + (subtitleEdgeInsets.top + subtitleEdgeInsets.bottom) < contentSize.height;
            CGFloat subtitleMinY = shouldSubtitleLabelCenterVertically ? (maxSize.height - self.subtitleLabelSize.height) / 2.0 + subtitleEdgeInsets.top - subtitleEdgeInsets.bottom : subtitleEdgeInsets.top;
            self.subtitleLabel.frame = CGRectMake(MAX(minX + subtitleEdgeInsets.left, maxX - self.subtitleLabelSize.width), subtitleMinY, MIN(self.subtitleLabelSize.width, maxX - minX - subtitleEdgeInsets.left), self.subtitleLabelSize.height);
            maxX = CGRectGetMinX(self.subtitleLabel.frame) - subtitleEdgeInsets.left;
        } else {
            self.subtitleLabel.frame = CGRectZero;
        }
        if (isTitleLabelShowing) {
            minX += titleEdgeInsets.left;
            maxX -= titleEdgeInsets.right;
            BOOL shouldTitleLabelCenterVertically = self.titleLabelSize.height + (titleEdgeInsets.top + titleEdgeInsets.bottom) < contentSize.height;
            CGFloat titleLabelMinY = shouldTitleLabelCenterVertically ? (maxSize.height - self.titleLabelSize.height) / 2.0 + titleEdgeInsets.top - titleEdgeInsets.bottom : titleEdgeInsets.top;
            self.titleLabel.frame = CGRectMake(minX, titleLabelMinY, maxX - minX, self.titleLabelSize.height);
        } else {
            self.titleLabel.frame = CGRectZero;
        }
    }
    
    CGFloat offsetY = (maxSize.height - contentSize.height) / 2.0;
    if (self.contentVerticalAlignment == UIControlContentVerticalAlignmentTop) {
        offsetY = 0;
    } else if (self.contentVerticalAlignment == UIControlContentVerticalAlignmentBottom) {
        offsetY = maxSize.height - contentSize.height;
    }
    [self.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        if (!CGRectIsEmpty(obj.frame)) {
            CGRect objFrame = obj.frame;
            objFrame.origin.y = CGRectGetMinY(obj.frame) + offsetY;
            obj.frame = objFrame;
        }
    }];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    
    if (self.adjustsTintColor) {
        UIColor *color = self.tintColor;
        self.titleLabel.textColor = color;
        self.subtitleLabel.textColor = color;
        self.loadingView.indicatorColor = color;
    }
}

- (void)titleViewTouched {
    BOOL active = !self.active;
    if ([self.delegate respondsToSelector:@selector(didTouchTitleView:isActive:)]) {
        [self.delegate didTouchTitleView:self isActive:active];
    }
    [self setActive:active animated:YES];
    [self refreshLayout];
}

@end

#pragma mark - __FWToolbarButton

@interface __FWToolbarButton()

@property (nonatomic, strong) UIImage *highlightedImage;
@property (nonatomic, strong) UIImage *disabledImage;
@property (nonatomic, assign) BOOL isLandscape;

@end

@implementation __FWToolbarButton

+ (instancetype)buttonWithObject:(id)object target:(id)target action:(SEL)action {
    __FWToolbarButton *button;
    if ([object isKindOfClass:[UIImage class]]) {
        button = [[__FWToolbarButton alloc] initWithImage:(UIImage *)object];
    } else {
        button = [[__FWToolbarButton alloc] initWithTitle:object];
    }
    if (target && action) {
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    return button;
}

+ (instancetype)buttonWithObject:(id)object block:(void (^)(id))block {
    __FWToolbarButton *button;
    if ([object isKindOfClass:[UIImage class]]) {
        button = [[__FWToolbarButton alloc] initWithImage:(UIImage *)object];
    } else {
        button = [[__FWToolbarButton alloc] initWithTitle:object];
    }
    if (block) [button __fw_addTouchWithBlock:block];
    return button;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self didInitialize];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self didInitialize];
        [self setTitle:title forState:UIControlStateNormal];
        [self sizeToFit];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self didInitialize];
        [self setTitle:nil forState:UIControlStateNormal];
        [self setImage:image forState:UIControlStateNormal];
        [self sizeToFit];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self didInitialize];
        [self setTitle:title forState:UIControlStateNormal];
        [self setImage:image forState:UIControlStateNormal];
        [self sizeToFit];
    }
    return self;
}

- (void)didInitialize {
    self.titleLabel.font = [UIFont systemFontOfSize:17];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.contentMode = UIViewContentModeCenter;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.adjustsTintColor = YES;
    self.adjustsImageWhenHighlighted = NO;
    self.adjustsImageWhenDisabled = NO;
    self.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    if (image && self.adjustsTintColor) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    if (image && [self imageForState:state] != image) {
        if (state == UIControlStateNormal) {
            self.highlightedImage = [[image __fw_imageWithAlpha:0.2f] imageWithRenderingMode:image.renderingMode];
            [self setImage:self.highlightedImage forState:UIControlStateHighlighted];
            self.disabledImage = [[image __fw_imageWithAlpha:0.2f] imageWithRenderingMode:image.renderingMode];
            [self setImage:self.disabledImage forState:UIControlStateDisabled];
        } else {
            if (image != self.highlightedImage && image != self.disabledImage) {
                if ([self imageForState:UIControlStateHighlighted] == self.highlightedImage && state != UIControlStateHighlighted) {
                    [self setImage:nil forState:UIControlStateHighlighted];
                }
                if ([self imageForState:UIControlStateDisabled] == self.disabledImage && state != UIControlStateDisabled) {
                    [self setImage:nil forState:UIControlStateDisabled];
                }
            }
        }
    }
    
    [super setImage:image forState:state];
}

- (void)setAdjustsTintColor:(BOOL)adjustsTintColor {
    if (_adjustsTintColor == adjustsTintColor) return;
    _adjustsTintColor = adjustsTintColor;
    if (!self.currentImage) return;
    
    NSArray<NSNumber *> *states = @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected), @(UIControlStateSelected | UIControlStateHighlighted), @(UIControlStateDisabled)];
    for (NSNumber *number in states) {
        UIImage *image = [self imageForState:number.unsignedIntegerValue];
        if (!image) return;

        if (self.adjustsTintColor) {
            [self setImage:image forState:[number unsignedIntegerValue]];
        } else {
            [self setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:[number unsignedIntegerValue]];
        }
    }
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self setTitleColor:self.tintColor forState:UIControlStateNormal];
    [self setTitleColor:[self.tintColor colorWithAlphaComponent:0.2f] forState:UIControlStateHighlighted];
    [self setTitleColor:[self.tintColor colorWithAlphaComponent:0.2f] forState:UIControlStateDisabled];
}

- (UINavigationBar *)searchNavigationBar:(UIView *)subview {
    if (!subview.superview) return nil;
    if ([subview.superview isKindOfClass:[UINavigationBar class]]) {
        return (UINavigationBar *)subview.superview;
    }
    return [self searchNavigationBar:subview.superview];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 横竖屏方向改变时才修改默认contentEdgeInsets，方便项目使用
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation);
    if (isLandscape != self.isLandscape) {
        self.isLandscape = isLandscape;
        UIEdgeInsets edgeInsets = self.contentEdgeInsets;
        edgeInsets.top = isLandscape ? 0 : 8;
        edgeInsets.bottom = isLandscape ? 0 : 8;
        self.contentEdgeInsets = edgeInsets;
    }
    
    // 处理navigationBar左侧第一个按钮和右侧第一个按钮位置，和系统一致
    UINavigationBar *navigationBar = [self searchNavigationBar:self];
    if (!navigationBar) return;
    
    CGRect convertFrame = [self.superview convertRect:self.frame toView:navigationBar];
    if (CGRectGetMinX(convertFrame) == 16) {
        UIEdgeInsets edgeInsets = self.contentEdgeInsets;
        edgeInsets.left = 0;
        self.contentEdgeInsets = edgeInsets;
    } else if (CGRectGetMaxX(convertFrame) + 16 == CGRectGetWidth(navigationBar.bounds)) {
        UIEdgeInsets edgeInsets = self.contentEdgeInsets;
        edgeInsets.right = 0;
        self.contentEdgeInsets = edgeInsets;
    }
}

@end
