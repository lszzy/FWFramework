/*!
 @header     FWEmptyPluginImpl.m
 @indexgroup FWFramework
 @brief      FWEmptyPlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import "FWEmptyPluginImpl.h"
#import <objc/runtime.h>

#pragma mark - FWEmptyView

@interface FWEmptyViewButton : UIButton

@property (nonatomic, assign) UIEdgeInsets fwTouchInsets;

@end

@implementation FWEmptyViewButton

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!UIEdgeInsetsEqualToEdgeInsets(self.fwTouchInsets, UIEdgeInsetsZero)) {
        UIEdgeInsets touchInsets = self.fwTouchInsets;
        CGRect bounds = self.bounds;
        bounds = CGRectMake(bounds.origin.x - touchInsets.left,
                            bounds.origin.y - touchInsets.top,
                            bounds.size.width + touchInsets.left + touchInsets.right,
                            bounds.size.height + touchInsets.top + touchInsets.bottom);
        return CGRectContainsPoint(bounds, point);
    }
    
    return [super pointInside:point withEvent:event];
}

@end

@interface FWEmptyView ()

@property(nonatomic, strong) UIScrollView *scrollView;

@end

@implementation FWEmptyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self didInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize {
    self.scrollView = [[UIScrollView alloc] init];
    if (@available(iOS 11, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    [self addSubview:self.scrollView];
    
    _contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    
    _loadingView = (UIView<FWEmptyLoadingViewProtocol> *)[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    ((UIActivityIndicatorView *)self.loadingView).hidesWhenStopped = NO;
    [self.contentView addSubview:self.loadingView];
    
    _imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeCenter;
    [self.contentView addSubview:self.imageView];
    
    _textLabel = [[UILabel alloc] init];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.numberOfLines = 0;
    [self.contentView addSubview:self.textLabel];
    
    _detailTextLabel = [[UILabel alloc] init];
    self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
    self.detailTextLabel.numberOfLines = 0;
    [self.contentView addSubview:self.detailTextLabel];
    
    FWEmptyViewButton *actionButton = [[FWEmptyViewButton alloc] init];
    actionButton.fwTouchInsets = UIEdgeInsetsMake(20, 20, 20, 20);
    _actionButton = actionButton;
    [self.contentView addSubview:self.actionButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.scrollView.frame = self.bounds;
    
    CGSize contentViewSize = [self sizeThatContentViewFits];
    // contentView 默认垂直居中于 scrollView
    self.contentView.frame = CGRectMake(0, CGRectGetMidY(self.scrollView.bounds) - contentViewSize.height / 2 + self.verticalOffset, contentViewSize.width, contentViewSize.height);
    
    // 如果 contentView 要比 scrollView 高，则置顶展示
    if (CGRectGetHeight(self.contentView.bounds) > CGRectGetHeight(self.scrollView.bounds)) {
        CGRect frame = self.contentView.frame;
        frame.origin.y = 0;
        self.contentView.frame = frame;
    }
    
    self.scrollView.contentSize = CGSizeMake(fmax(CGRectGetWidth(self.scrollView.bounds) - (self.scrollView.contentInset.left + self.scrollView.contentInset.right), contentViewSize.width), fmax(CGRectGetHeight(self.scrollView.bounds) - (self.scrollView.contentInset.top + self.scrollView.contentInset.bottom), CGRectGetMaxY(self.contentView.frame)));
    
    CGFloat originY = 0;
    
    if (!self.imageView.hidden) {
        [self.imageView sizeToFit];
        CGRect frame = self.imageView.frame;
        frame.origin = CGPointMake(((CGRectGetWidth(self.contentView.bounds) - CGRectGetWidth(self.imageView.frame)) / 2.0) + self.imageViewInsets.left - self.imageViewInsets.right, originY + self.imageViewInsets.top);
        self.imageView.frame = frame;
        originY = CGRectGetMaxY(self.imageView.frame) + self.imageViewInsets.bottom;
    }
    
    if (!self.loadingView.hidden) {
        CGRect frame = self.loadingView.frame;
        frame.origin = CGPointMake(((CGRectGetWidth(self.contentView.bounds) - CGRectGetWidth(self.loadingView.frame)) / 2.0) + self.loadingViewInsets.left - self.loadingViewInsets.right, originY + self.loadingViewInsets.top);
        self.loadingView.frame = frame;
        originY = CGRectGetMaxY(self.loadingView.frame) + self.loadingViewInsets.bottom;
    }
    
    if (!self.textLabel.hidden) {
        CGFloat textWidth = CGRectGetWidth(self.contentView.bounds) - (self.textLabelInsets.left + self.textLabelInsets.right);
        CGSize textSize = [self.textLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
        self.textLabel.frame = CGRectMake(self.textLabelInsets.left, originY + self.textLabelInsets.top, textWidth, textSize.height);
        originY = CGRectGetMaxY(self.textLabel.frame) + self.textLabelInsets.bottom;
    }
    
    if (!self.detailTextLabel.hidden) {
        CGFloat detailWidth = CGRectGetWidth(self.contentView.bounds) - (self.detailTextLabelInsets.left + self.detailTextLabelInsets.right);
        CGSize detailSize = [self.detailTextLabel sizeThatFits:CGSizeMake(detailWidth, CGFLOAT_MAX)];
        self.detailTextLabel.frame = CGRectMake(self.detailTextLabelInsets.left, originY + self.detailTextLabelInsets.top, detailWidth, detailSize.height);
        originY = CGRectGetMaxY(self.detailTextLabel.frame) + self.detailTextLabelInsets.bottom;
    }
    
    if (!self.actionButton.hidden) {
        [self.actionButton sizeToFit];
        CGRect frame = self.actionButton.frame;
        frame.origin = CGPointMake(((CGRectGetWidth(self.contentView.bounds) - CGRectGetWidth(self.actionButton.frame)) / 2.0) + self.actionButtonInsets.left - self.actionButtonInsets.right, originY + self.actionButtonInsets.top);
        self.actionButton.frame = frame;
        originY = CGRectGetMaxY(self.actionButton.frame) + self.actionButtonInsets.bottom;
    }
}

- (CGSize)sizeThatContentViewFits {
    CGFloat resultWidth = CGRectGetWidth(self.scrollView.bounds) - (self.scrollView.contentInset.left + self.scrollView.contentInset.right);
    
    CGFloat imageViewHeight = [self.imageView sizeThatFits:CGSizeMake(resultWidth, CGFLOAT_MAX)].height + (self.imageViewInsets.top + self.imageViewInsets.bottom);
    CGFloat loadingViewHeight = CGRectGetHeight(self.loadingView.bounds) + (self.loadingViewInsets.top + self.loadingViewInsets.bottom);
    CGFloat textLabelHeight = [self.textLabel sizeThatFits:CGSizeMake(resultWidth, CGFLOAT_MAX)].height + (self.textLabelInsets.top + self.textLabelInsets.bottom);
    CGFloat detailTextLabelHeight = [self.detailTextLabel sizeThatFits:CGSizeMake(resultWidth, CGFLOAT_MAX)].height + (self.detailTextLabelInsets.top + self.detailTextLabelInsets.bottom);
    CGFloat actionButtonHeight = [self.actionButton sizeThatFits:CGSizeMake(resultWidth, CGFLOAT_MAX)].height + (self.actionButtonInsets.top + self.actionButtonInsets.bottom);
    
    CGFloat resultHeight = 0;
    if (!self.imageView.hidden) {
        resultHeight += imageViewHeight;
    }
    if (!self.loadingView.hidden) {
        resultHeight += loadingViewHeight;
    }
    if (!self.textLabel.hidden) {
        resultHeight += textLabelHeight;
    }
    if (!self.detailTextLabel.hidden) {
        resultHeight += detailTextLabelHeight;
    }
    if (!self.actionButton.hidden) {
        resultHeight += actionButtonHeight;
    }
    
    return CGSizeMake(resultWidth, resultHeight);
}

- (void)updateDetailTextLabelWithText:(NSString *)text {
    if (self.detailTextLabelFont && self.detailTextLabelTextColor && text) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.minimumLineHeight = self.detailTextLabelFont.lineHeight;
        paragraphStyle.maximumLineHeight = self.detailTextLabelFont.lineHeight;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:text attributes:@{
                                                                                                  NSFontAttributeName: self.detailTextLabelFont,
                                                                                                  NSForegroundColorAttributeName: self.detailTextLabelTextColor,
                                                                                                  NSParagraphStyleAttributeName: paragraphStyle
                                                                                                  }];
        self.detailTextLabel.attributedText = string;
    }
    self.detailTextLabel.hidden = !text;
    [self setNeedsLayout];
}

- (void)setLoadingView:(UIView<FWEmptyLoadingViewProtocol> *)loadingView {
    if (self.loadingView != loadingView) {
        [self.loadingView removeFromSuperview];
        _loadingView = loadingView;
        [self.contentView addSubview:loadingView];
    }
    [self setNeedsLayout];
}

- (void)setLoadingViewHidden:(BOOL)hidden {
    self.loadingView.hidden = hidden;
    if (!hidden && [self.loadingView respondsToSelector:@selector(startAnimating)]) {
        [self.loadingView startAnimating];
    }
    [self setNeedsLayout];
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    self.imageView.hidden = !image;
    [self setNeedsLayout];
}

- (void)setTextLabelText:(NSString *)text {
    self.textLabel.text = text;
    self.textLabel.hidden = !text;
    [self setNeedsLayout];
}

- (void)setDetailTextLabelText:(NSString *)text {
    [self updateDetailTextLabelWithText:text];
}

- (void)setActionButtonTitle:(NSString *)title {
    [self.actionButton setTitle:title forState:UIControlStateNormal];
    self.actionButton.hidden = !title;
    [self setNeedsLayout];
}

- (void)setImageViewInsets:(UIEdgeInsets)imageViewInsets {
    _imageViewInsets = imageViewInsets;
    [self setNeedsLayout];
}

- (void)setTextLabelInsets:(UIEdgeInsets)textLabelInsets {
    _textLabelInsets = textLabelInsets;
    [self setNeedsLayout];
}

- (void)setDetailTextLabelInsets:(UIEdgeInsets)detailTextLabelInsets {
    _detailTextLabelInsets = detailTextLabelInsets;
    [self setNeedsLayout];
}

- (void)setActionButtonInsets:(UIEdgeInsets)actionButtonInsets {
    _actionButtonInsets = actionButtonInsets;
    [self setNeedsLayout];
}

- (void)setVerticalOffset:(CGFloat)verticalOffset {
    _verticalOffset = verticalOffset;
    [self setNeedsLayout];
}

- (void)setTextLabelFont:(UIFont *)textLabelFont {
    _textLabelFont = textLabelFont;
    self.textLabel.font = textLabelFont;
    [self setNeedsLayout];
}

- (void)setDetailTextLabelFont:(UIFont *)detailTextLabelFont {
    _detailTextLabelFont = detailTextLabelFont;
    [self updateDetailTextLabelWithText:self.detailTextLabel.text];
}

- (void)setActionButtonFont:(UIFont *)actionButtonFont {
    _actionButtonFont = actionButtonFont;
    self.actionButton.titleLabel.font = actionButtonFont;
    [self setNeedsLayout];
}

- (void)setTextLabelTextColor:(UIColor *)textLabelTextColor {
    _textLabelTextColor = textLabelTextColor;
    self.textLabel.textColor = textLabelTextColor;
}

- (void)setDetailTextLabelTextColor:(UIColor *)detailTextLabelTextColor {
    _detailTextLabelTextColor = detailTextLabelTextColor;
    [self updateDetailTextLabelWithText:self.detailTextLabel.text];
}

- (void)setActionButtonTitleColor:(UIColor *)actionButtonTitleColor {
    _actionButtonTitleColor = actionButtonTitleColor;
    [self.actionButton setTitleColor:actionButtonTitleColor forState:UIControlStateNormal];
    [self.actionButton setTitleColor:[actionButtonTitleColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
    [self.actionButton setTitleColor:[actionButtonTitleColor colorWithAlphaComponent:0.5f] forState:UIControlStateDisabled];
}

@end

@interface FWEmptyView (UIAppearance)

@end

@implementation FWEmptyView (UIAppearance)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    FWEmptyView *appearance = [FWEmptyView appearance];
    appearance.imageViewInsets = UIEdgeInsetsMake(0, 0, 36, 0);
    appearance.loadingViewInsets = UIEdgeInsetsMake(0, 0, 36, 0);
    appearance.textLabelInsets = UIEdgeInsetsMake(0, 0, 10, 0);
    appearance.detailTextLabelInsets = UIEdgeInsetsMake(0, 0, 14, 0);
    appearance.actionButtonInsets = UIEdgeInsetsZero;
    appearance.verticalOffset = -30;
    
    appearance.textLabelFont = [UIFont systemFontOfSize:15];
    appearance.detailTextLabelFont = [UIFont systemFontOfSize:14];
    appearance.actionButtonFont = [UIFont systemFontOfSize:15];
    
    appearance.textLabelTextColor = [UIColor colorWithRed:93/255.0 green:100/255.0 blue:110/255.0 alpha:1];
    appearance.detailTextLabelTextColor = [UIColor colorWithRed:133/255.0 green:140/255.0 blue:150/255.0 alpha:1];
    appearance.actionButtonTitleColor = [UIColor colorWithRed:49/255.0 green:189/255.0 blue:243/255.0 alpha:1];
}

@end

#pragma mark - UIScrollView+FWEmptyPluginImpl

@interface FWScrollOverlayView : UIView

@property (nonatomic, assign) BOOL fadeAnimated;

@end

@implementation FWScrollOverlayView

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.fadeAnimated) {
        self.fadeAnimated = NO;
        self.alpha = 0;
        self.frame = self.superview.bounds;
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 1.0;
        } completion:NULL];
    } else {
        self.frame = self.superview.bounds;
    }
}

@end

@implementation UIScrollView (FWEmptyPluginImpl)

- (UIView *)fwOverlayView
{
    UIView *overlayView = objc_getAssociatedObject(self, @selector(fwOverlayView));
    if (!overlayView) {
        overlayView = [[FWScrollOverlayView alloc] init];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlayView.userInteractionEnabled = YES;
        overlayView.backgroundColor = UIColor.clearColor;
        overlayView.clipsToBounds = YES;
        
        objc_setAssociatedObject(self, @selector(fwOverlayView), overlayView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return overlayView;
}

- (BOOL)fwHasOverlayView
{
    UIView *overlayView = objc_getAssociatedObject(self, @selector(fwOverlayView));
    return overlayView && overlayView.superview;
}

- (void)fwShowOverlayView
{
    [self fwShowOverlayViewAnimated:NO];
}

- (void)fwShowOverlayViewAnimated:(BOOL)animated
{
    FWScrollOverlayView *overlayView = (FWScrollOverlayView *)self.fwOverlayView;
    if (!overlayView.superview) {
        overlayView.fadeAnimated = animated;
        if (([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]]) && self.subviews.count > 1) {
            [self insertSubview:overlayView atIndex:0];
        } else {
            [self addSubview:overlayView];
        }
    }
}

- (void)fwHideOverlayView
{
    UIView *overlayView = objc_getAssociatedObject(self, @selector(fwOverlayView));
    if (overlayView && overlayView.superview) {
        [overlayView removeFromSuperview];
    }
}

@end
