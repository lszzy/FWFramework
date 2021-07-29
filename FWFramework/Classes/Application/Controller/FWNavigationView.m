/*!
 @header     FWNavigationView.m
 @indexgroup FWFramework
 @brief      FWNavigationView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2021/07/28
 */

#import "FWNavigationView.h"
#import "FWAutoLayout.h"
#import "FWSwizzle.h"
#import "FWMessage.h"
#import "FWToolkit.h"
#import "FWAdaptive.h"
#import "FWBlock.h"
#import "FWImage.h"
#import "FWRouter.h"
#import "FWViewControllerStyle.h"
#import <objc/runtime.h>

#pragma mark - FWNavigationView

@interface FWNavigationView ()

@property (nonatomic, strong) NSLayoutConstraint *statusBarConstraint;
@property (nonatomic, strong) NSLayoutConstraint *navigationBarConstraint;
@property (nonatomic, strong) NSLayoutConstraint *additionalConstraint;

@property (nonatomic, strong) NSLayoutConstraint *noneEdgeConstraint;
@property (nonatomic, strong) NSLayoutConstraint *topEdgeConstraint;
@property (nonatomic, assign) BOOL backItemInitialized;

@end

@implementation FWNavigationView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

#pragma mark - Private

- (void)setupView
{
    _statusBarHeight = FWStatusBarHeight;
    _navigationBarHeight = 0;
    _addtionalHeight = 0;
    _navigationItem = [[UINavigationItem alloc] init];
    _navigationBar = [[UINavigationBar alloc] init];
    _navigationBar.items = @[_navigationItem];
    [self addSubview:_navigationBar];
    
    self.statusBarConstraint = [self.navigationBar fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.statusBarHeight];
    [self.navigationBar fwPinEdgesToSuperviewHorizontal];
    self.navigationBarConstraint = [self.navigationBar fwSetDimension:NSLayoutAttributeHeight toSize:self.navigationBarHeight];
    self.navigationBarConstraint.active = self.navigationBarHeight > 0;
    self.additionalConstraint = [self.navigationBar fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:self.addtionalHeight];
}

- (void)updateLayout
{
    self.statusBarConstraint.constant = self.isHidden ? 0 : self.statusBarHeight;
    self.navigationBarConstraint.constant = self.isHidden ? 0 : self.navigationBarHeight;
    self.navigationBarConstraint.active = self.isHidden || self.navigationBarHeight > 0;
    self.additionalConstraint.constant = self.isHidden ? 0 : -self.addtionalHeight;
}

#pragma mark - Accessor

- (void)setStatusBarHeight:(CGFloat)statusBarHeight
{
    _statusBarHeight = statusBarHeight;
    [self updateLayout];
}

- (void)setNavigationBarHeight:(CGFloat)navigationBarHeight
{
    _navigationBarHeight = navigationBarHeight;
    [self updateLayout];
}

- (void)setAddtionalHeight:(CGFloat)addtionalHeight
{
    _addtionalHeight = addtionalHeight;
    [self updateLayout];
}

- (void)setHidden:(BOOL)hidden
{
    if (hidden == self.isHidden) return;
    [super setHidden:hidden];
    [self updateLayout];
}

#pragma mark - Bar

- (void)setScrollView:(UIScrollView *)scrollView
{
    if (@available(iOS 11.0, *)) {} else { return; }
    if (!self.superview) return;
    if (scrollView == _scrollView) return;
    
    if (_scrollView) [_scrollView fwUnobserveProperty:@"contentOffset" target:self action:@selector(scrollView:change:)];
    _scrollView = scrollView;
    if (scrollView) [scrollView fwObserveProperty:@"contentOffset" target:self action:@selector(scrollView:change:)];
}

- (void)scrollView:(UIScrollView *)scrollView change:(NSDictionary *)change
{
    if (@available(iOS 11.0, *)) {
        if (!self.navigationBar.prefersLargeTitles) return;
        UIView *largeTitleView = self.navigationBar.fwLargeTitleView;
        if (!largeTitleView || largeTitleView.frame.origin.y <= 0) return;
        
        CGFloat minHeight = largeTitleView.frame.origin.y;
        CGFloat maxHeight = minHeight + UINavigationBar.fwLargeTitleHeight;
        CGFloat height = MIN(MAX(minHeight, maxHeight - scrollView.contentOffset.y), maxHeight);
        self.navigationBarHeight = height;
    }
}

#pragma mark - View

@end

#pragma mark - UIViewController+FWNavigationView

@interface UIViewController ()

- (void)fwSetNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated;

@end

@implementation UIViewController (FWNavigationView)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationBar, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            FWNavigationView *navigationView = (FWNavigationView *)selfObject.superview;
            if ([navigationView isKindOfClass:[FWNavigationView class]]) {
                UIView *backgroundView = selfObject.fwBackgroundView;
                backgroundView.frame = CGRectMake(backgroundView.frame.origin.x, -navigationView.statusBarHeight, backgroundView.frame.size.width, navigationView.bounds.size.height);
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwView), FWSwizzleReturn(UIView *), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            return [selfObject fwNavigationContentView];
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwNavigationBar), FWSwizzleReturn(UINavigationBar *), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            return selfObject.fwNavigationView.navigationBar;
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwNavigationItem), FWSwizzleReturn(UINavigationItem *), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            return selfObject.fwNavigationView.navigationItem;
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwNavigationBarHeight), FWSwizzleReturn(CGFloat), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            
            if (selfObject.fwNavigationView.isHidden) return 0.0;
            return selfObject.fwNavigationView.navigationBar.frame.size.height;
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwTopBarHeight), FWSwizzleReturn(CGFloat), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            
            if (selfObject.fwNavigationView.isHidden) return 0.0;
            return selfObject.fwNavigationView.frame.size.height;
        }));
        
        FWSwizzleClass(UIViewController, @selector(setFwBackBarItem:), FWSwizzleReturn(void), FWSwizzleArgs(id object), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) {
                FWSwizzleOriginal(object);
                return;
            }
            
            UIBarButtonItem *backItem;
            if ([object isKindOfClass:[UIBarButtonItem class]]) {
                backItem = (UIBarButtonItem *)object;
            } else {
                backItem = [UIBarButtonItem fwBarItemWithObject:(object ?: [UIImage new]) target:nil action:nil];
            }
            selfObject.fwNavigationItem.backBarButtonItem = backItem;
        }));
        
        FWSwizzleClass(UIViewController, @selector(loadView), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            if (!selfObject.fwNavigationViewEnabled) return;
            
            if (selfObject.navigationController) [selfObject fwNavigationViewLayout];
            BOOL hidden = selfObject.fwNavigationBarHidden || !selfObject.navigationController || selfObject.fwIsChild;
            selfObject.fwNavigationView.hidden = hidden;
            
            BOOL topEdges = (selfObject.edgesForExtendedLayout & UIRectEdgeTop) == UIRectEdgeTop;
            [selfObject.view addSubview:selfObject.fwNavigationView];
            [selfObject.view addSubview:selfObject.fwNavigationContentView];
            [selfObject.fwNavigationView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
            [selfObject.fwNavigationContentView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
            selfObject.fwNavigationView.noneEdgeConstraint = [selfObject.fwNavigationContentView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:selfObject.fwNavigationView];
            selfObject.fwNavigationView.noneEdgeConstraint.active = !topEdges;
            selfObject.fwNavigationView.topEdgeConstraint = [selfObject.fwNavigationContentView fwPinEdgeToSuperview:NSLayoutAttributeTop];
            selfObject.fwNavigationView.topEdgeConstraint.active = topEdges;
            [selfObject.view setNeedsLayout];
            [selfObject.view layoutIfNeeded];
        }));
        
        FWSwizzleClass(UIViewController, @selector(setEdgesForExtendedLayout:), FWSwizzleReturn(void), FWSwizzleArgs(UIRectEdge edges), FWSwizzleCode({
            FWSwizzleOriginal(edges);
            if (!selfObject.fwNavigationViewEnabled) return;
            
            BOOL topEdges = (edges & UIRectEdgeTop) == UIRectEdgeTop;
            selfObject.fwNavigationView.noneEdgeConstraint.active = !topEdges;
            selfObject.fwNavigationView.topEdgeConstraint.active = topEdges;
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwSetNavigationBarHidden:animated:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL hidden, BOOL animated), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) {
                return FWSwizzleOriginal(hidden, animated);
            }
            
            FWSwizzleOriginal(YES, animated);
            [selfObject.view bringSubviewToFront:selfObject.fwNavigationView];
            selfObject.fwNavigationView.hidden = hidden;
            
            // 只初始化backItem一次，iOS14+调用多级pop方法触发viewWillAppear:时，导航栏VC堆栈顺序不对
            if (selfObject.fwNavigationView.backItemInitialized) return;
            selfObject.fwNavigationView.backItemInitialized = YES;
            if (selfObject.navigationController.viewControllers.count < 2) return;
            UINavigationItem *navigationItem = selfObject.fwNavigationView.navigationItem;
            if (navigationItem.leftBarButtonItem || !navigationItem.backBarButtonItem) return;
            [navigationItem.backBarButtonItem fwSetBlock:^(id sender) {
                if (![selfObject fwPopBackBarItem]) return;
                [selfObject fwCloseViewControllerAnimated:YES];
            }];
            navigationItem.leftBarButtonItem = navigationItem.backBarButtonItem;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidLayoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            if (!selfObject.fwNavigationViewEnabled) return;
            
            [selfObject.view bringSubviewToFront:selfObject.fwNavigationView];
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillTransitionToSize:withTransitionCoordinator:), FWSwizzleReturn(void), FWSwizzleArgs(CGSize size, id<UIViewControllerTransitionCoordinator> coordinator), FWSwizzleCode({
            FWSwizzleOriginal(size, coordinator);
            if (!selfObject.fwNavigationViewEnabled) return;
            if (!selfObject.navigationController) return;
            
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                [selfObject fwNavigationViewLayout];
            } completion:nil];
        }));
    });
}

- (FWNavigationView *)fwNavigationView
{
    FWNavigationView *navigationView = objc_getAssociatedObject(self, _cmd);
    if (!navigationView) {
        navigationView = [[FWNavigationView alloc] init];
        objc_setAssociatedObject(self, _cmd, navigationView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return navigationView;
}

- (UIView *)fwNavigationContentView
{
    UIView *contentView = objc_getAssociatedObject(self, _cmd);
    if (!contentView) {
        contentView = [[UIView alloc] init];
        objc_setAssociatedObject(self, _cmd, contentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return contentView;
}

- (BOOL)fwNavigationViewEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwNavigationViewEnabled)) boolValue];
}

- (void)setFwNavigationViewEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fwNavigationViewEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwNavigationViewLayout
{
    CGFloat statusBarHeight = FWStatusBarHeight;
    if (@available(iOS 13.0, *)) {
        BOOL isPageSheet = self.navigationController.modalPresentationStyle == UIModalPresentationAutomatic || self.navigationController.modalPresentationStyle == UIModalPresentationPageSheet;
        isPageSheet = isPageSheet && self.navigationController.presentingViewController != nil;
        if (isPageSheet) statusBarHeight = 0;
    }
    self.fwNavigationView.statusBarHeight = statusBarHeight;
}

@end

#pragma mark - FWNavigationTitleView

@interface FWNavigationTitleView ()

@property(nonatomic, strong, readonly) UIView *contentView;
@property(nonatomic, assign) CGSize titleLabelSize;
@property(nonatomic, assign) CGSize subtitleLabelSize;
@property(nonatomic, strong) UIImageView *accessoryImageView;

@end

@implementation FWNavigationTitleView

#pragma mark - Static

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationBar, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            UIView *titleView = selfObject.topItem.titleView;
            if (![titleView conformsToProtocol:@protocol(FWNavigationTitleViewProtocol)]) {
                FWSwizzleOriginal();
                return;
            }
            
            CGFloat titleViewMaximumWidth = CGRectGetWidth(titleView.bounds);
            CGSize titleViewSize = [titleView sizeThatFits:CGSizeMake(titleViewMaximumWidth, CGFLOAT_MAX)];
            titleViewSize.height = ceil(titleViewSize.height);
            
            if (CGRectGetHeight(titleView.bounds) != titleViewSize.height) {
                CGFloat titleViewMinY = FWFlatValue(CGRectGetMinY(titleView.frame) - ((titleViewSize.height - CGRectGetHeight(titleView.bounds)) / 2.0));
                titleView.frame = CGRectMake(CGRectGetMinX(titleView.frame), titleViewMinY, MIN(titleViewMaximumWidth, titleViewSize.width), titleViewSize.height);
            }
            
            if (@available(iOS 11, *)) {
                if (CGRectGetWidth(titleView.bounds) != titleViewSize.width) {
                    CGRect titleFrame = titleView.frame;
                    titleFrame.size.width = titleViewSize.width;
                    titleView.frame = titleFrame;
                }
            }
            
            FWSwizzleOriginal();
        }));
        
        FWSwizzleClass(UIViewController, @selector(setTitle:), FWSwizzleReturn(void), FWSwizzleArgs(NSString *title), FWSwizzleCode({
            FWSwizzleOriginal(title);
            
            if ([selfObject.fwNavigationItem.titleView conformsToProtocol:@protocol(FWNavigationTitleViewProtocol)]) {
                ((id<FWNavigationTitleViewProtocol>)selfObject.fwNavigationItem.titleView).title = title;
            }
        }));
        
        FWSwizzleClass(UINavigationItem, @selector(setTitle:), FWSwizzleReturn(void), FWSwizzleArgs(NSString *title), FWSwizzleCode({
            FWSwizzleOriginal(title);
            
            if ([selfObject.titleView conformsToProtocol:@protocol(FWNavigationTitleViewProtocol)]) {
                ((id<FWNavigationTitleViewProtocol>)selfObject.titleView).title = title;
            }
        }));
        
        FWSwizzleClass(UINavigationItem, @selector(setTitleView:), FWSwizzleReturn(void), FWSwizzleArgs(id<FWNavigationTitleViewProtocol> titleView), FWSwizzleCode({
            FWSwizzleOriginal(titleView);
            
            if ([titleView conformsToProtocol:@protocol(FWNavigationTitleViewProtocol)]) {
                if (titleView.title.length <= 0) {
                    titleView.title = selfObject.title;
                }
            }
        }));
    });
}

+ (void)setDefaultAppearance {
    FWNavigationTitleView *appearance = [FWNavigationTitleView appearance];
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
}

+ (void)applyAppearance:(FWNavigationTitleView *)titleView {
    FWNavigationTitleView *appearance = FWNavigationTitleView.appearance;
    titleView.adjustsTintColor = appearance.adjustsTintColor;
    titleView.maximumWidth = appearance.maximumWidth;
    titleView.loadingViewSize = appearance.loadingViewSize;
    titleView.loadingViewSpacing = appearance.loadingViewSpacing;
    titleView.horizontalTitleFont = appearance.horizontalTitleFont;
    titleView.horizontalSubtitleFont = appearance.horizontalSubtitleFont;
    titleView.verticalTitleFont = appearance.verticalTitleFont;
    titleView.verticalSubtitleFont = appearance.verticalSubtitleFont;
    titleView.accessoryViewOffset = appearance.accessoryViewOffset;
    titleView.subAccessoryViewOffset = appearance.subAccessoryViewOffset;
    titleView.titleEdgeInsets = appearance.titleEdgeInsets;
    titleView.subtitleEdgeInsets = appearance.subtitleEdgeInsets;
}

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithStyle:FWNavigationTitleViewStyleHorizontal frame:frame];
}

- (instancetype)initWithStyle:(FWNavigationTitleViewStyle)style {
    return [self initWithStyle:style frame:CGRectZero];
}

- (instancetype)initWithStyle:(FWNavigationTitleViewStyle)style frame:(CGRect)frame {
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
        
        [FWNavigationTitleView applyAppearance:self];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, title = %@, subtitle = %@", [super description], self.title, self.subtitle];
}

#pragma mark - Accessor

- (void)setStyle:(FWNavigationTitleViewStyle)style {
    _style = style;
    if (style == FWNavigationTitleViewStyleVertical) {
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
    if (self.style == FWNavigationTitleViewStyleHorizontal) {
        self.titleLabel.font = horizontalTitleFont;
        [self refreshLayout];
    }
}

- (void)setHorizontalSubtitleFont:(UIFont *)horizontalSubtitleFont {
    _horizontalSubtitleFont = horizontalSubtitleFont;
    if (self.style == FWNavigationTitleViewStyleHorizontal) {
        self.subtitleLabel.font = horizontalSubtitleFont;
        [self refreshLayout];
    }
}

- (void)setVerticalTitleFont:(UIFont *)verticalTitleFont {
    _verticalTitleFont = verticalTitleFont;
    if (self.style == FWNavigationTitleViewStyleVertical) {
        self.titleLabel.font = verticalTitleFont;
        [self refreshLayout];
    }
}

- (void)setVerticalSubtitleFont:(UIFont *)verticalSubtitleFont {
    _verticalSubtitleFont = verticalSubtitleFont;
    if (self.style == FWNavigationTitleViewStyleVertical) {
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
    if (self.subAccessoryView && self.subtitleLabel.text.length && self.style == FWNavigationTitleViewStyleVertical) {
        self.subAccessoryView.hidden = NO;
    } else {
        self.subAccessoryView.hidden = YES;
    }
}

- (void)setShowsLoadingView:(BOOL)showsLoadingView {
    _showsLoadingView = showsLoadingView;
    if (showsLoadingView) {
        if (!self.loadingView) {
            _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            CGSize initialSize = _loadingView.bounds.size;
            CGFloat scale = self.loadingViewSize.width / initialSize.width;
            self.loadingView.transform = CGAffineTransformMakeScale(scale, scale);
            self.loadingView.color = self.tintColor;
            [self.loadingView stopAnimating];
            [self.contentView addSubview:self.loadingView];
        }
    } else {
        if (self.loadingView) {
            [self.loadingView stopAnimating];
            [self.loadingView removeFromSuperview];
            _loadingView = nil;
        }
    }
    [self refreshLayout];
}

- (void)setLoadingViewHidden:(BOOL)loadingViewHidden {
    _loadingViewHidden = loadingViewHidden;
    if (self.showsLoadingView) {
        loadingViewHidden ? [self.loadingView stopAnimating] : [self.loadingView startAnimating];
    }
    [self refreshLayout];
}

- (void)setActive:(BOOL)active {
    _active = active;
    if ([self.delegate respondsToSelector:@selector(didChangedActive:forTitleView:)]) {
        [self.delegate didChangedActive:active forTitleView:self];
    }
    if (self.accessoryImage != nil) {
        if (active) {
            [UIView animateWithDuration:.25f delay:0 options:(8<<16) animations:^(void){
                self.accessoryImageView.transform = CGAffineTransformMakeRotation((M_PI * (-180) / 180.0));
            } completion:^(BOOL finished) {}];
        } else {
            [UIView animateWithDuration:.25f delay:0 options:(8<<16) animations:^(void){
                self.accessoryImageView.transform = CGAffineTransformMakeRotation((M_PI * (0.1) / 180.0));
            } completion:^(BOOL finished) {}];
        }
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
    if (self.style == FWNavigationTitleViewStyleVertical) {
        CGSize size = CGSizeZero;
        CGFloat firstLineWidth = [self firstLineWidthInVerticalStyle];
        CGFloat secondLineWidth = [self secondLineWidthInVerticalStyle];
        size.width = MAX(firstLineWidth, secondLineWidth);
        size.height = self.titleLabelSize.height + (self.titleEdgeInsetsIfShowingTitleLabel.top + self.titleEdgeInsetsIfShowingTitleLabel.bottom) + self.subtitleLabelSize.height + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.top + self.subtitleEdgeInsetsIfShowingSubtitleLabel.bottom);
        return CGSizeMake(FWFlatValue(size.width), FWFlatValue(size.height));
    } else {
        CGSize size = CGSizeZero;
        size.width = self.titleLabelSize.width + (self.titleEdgeInsetsIfShowingTitleLabel.left + self.titleEdgeInsetsIfShowingTitleLabel.right) + self.subtitleLabelSize.width + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.left + self.subtitleEdgeInsetsIfShowingSubtitleLabel.right);
        size.width += [self loadingViewSpacingSizeIfNeedsPlaceholder].width + [self accessorySpacingSizeIfNeedesPlaceholder].width;
        size.height = MAX(self.titleLabelSize.height + (self.titleEdgeInsetsIfShowingTitleLabel.top + self.titleEdgeInsetsIfShowingTitleLabel.bottom), self.subtitleLabelSize.height + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.top + self.subtitleEdgeInsetsIfShowingSubtitleLabel.bottom));
        size.height = MAX(size.height, [self loadingViewSpacingSizeIfNeedsPlaceholder].height);
        size.height = MAX(size.height, [self accessorySpacingSizeIfNeedesPlaceholder].height);
        return CGSizeMake(FWFlatValue(size.width), FWFlatValue(size.height));
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize resultSize = [self contentSize];
    resultSize.width = MIN(resultSize.width, self.maximumWidth);
    return resultSize;
}

- (void)layoutSubviews {
    if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0) return;
    [super layoutSubviews];
    self.contentView.frame = self.bounds;
    
    BOOL alignLeft = self.contentHorizontalAlignment == UIControlContentHorizontalAlignmentLeft;
    BOOL alignRight = self.contentHorizontalAlignment == UIControlContentHorizontalAlignmentRight;
    CGSize maxSize = self.bounds.size;
    CGSize contentSize = [self contentSize];
    contentSize.width = MIN(maxSize.width, contentSize.width);
    contentSize.height = MIN(maxSize.height, contentSize.height);
    CGFloat contentOffsetLeft = (maxSize.width - contentSize.width) / 2.0;
    CGFloat contentOffsetRight = contentOffsetLeft;
    
    CGFloat loadingViewSpace = [self loadingViewSpacingSize].width;
    UIView *accessoryView = self.accessoryView ?: self.accessoryImageView;
    CGFloat accessoryViewSpace = [self accessorySpacingSize].width;
    BOOL isTitleLabelShowing = self.titleLabel.text.length > 0;
    BOOL isSubtitleLabelShowing = self.subtitleLabel.text.length > 0;
    BOOL isSubAccessoryViewShowing = isSubtitleLabelShowing && self.subAccessoryView && !self.subAccessoryView.hidden;
    UIEdgeInsets titleEdgeInsets = self.titleEdgeInsetsIfShowingTitleLabel;
    UIEdgeInsets subtitleEdgeInsets = self.subtitleEdgeInsetsIfShowingSubtitleLabel;
    
    if (self.style == FWNavigationTitleViewStyleVertical) {
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
        if (self.loadingView) {
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
        
        if (self.loadingView) {
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
        self.loadingView.color = color;
    }
}

- (void)titleViewTouched {
    BOOL active = !self.active;
    if ([self.delegate respondsToSelector:@selector(didTouchTitleView:isActive:)]) {
        [self.delegate didTouchTitleView:self isActive:active];
    }
    self.active = active;
    [self refreshLayout];
}

@end

#pragma mark - FWNavigationButton

@interface FWNavigationButton()

@property (nonatomic, assign) BOOL isImageType;
@property (nonatomic, strong) UIImage *highlightedImage;
@property (nonatomic, strong) UIImage *disabledImage;

@end

@implementation FWNavigationButton

- (instancetype)init
{
    return [self initWithTitle:nil];
}

- (instancetype)initWithTitle:(NSString *)title
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.isImageType = NO;
        [self setTitle:title forState:UIControlStateNormal];
        [self renderButtonStyle];
        [self sizeToFit];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.isImageType = YES;
        [self setTitle:nil forState:UIControlStateNormal];
        [self renderButtonStyle];
        [self setImage:image forState:UIControlStateNormal];
        [self sizeToFit];
    }
    return self;
}

- (void)renderButtonStyle
{
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

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    if (image && self.adjustsTintColor) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    if (image && [self imageForState:state] != image) {
        if (state == UIControlStateNormal) {
            self.highlightedImage = [[image fwImageWithAlpha:0.2f] imageWithRenderingMode:image.renderingMode];
            [self setImage:self.highlightedImage forState:UIControlStateHighlighted];
            self.disabledImage = [[image fwImageWithAlpha:0.2f] imageWithRenderingMode:image.renderingMode];
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

- (void)setAdjustsTintColor:(BOOL)adjustsTintColor
{
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

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    [self setTitleColor:self.tintColor forState:UIControlStateNormal];
    [self setTitleColor:[self.tintColor colorWithAlphaComponent:0.2f] forState:UIControlStateHighlighted];
    [self setTitleColor:[self.tintColor colorWithAlphaComponent:0.2f] forState:UIControlStateDisabled];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIView *navigationBar = nil;
    UIView *superView = self.superview;
    while (superView != nil) {
        if ([superView isKindOfClass:[UINavigationBar class]]) {
            navigationBar = superView;
            break;
        }
        superView = superView.superview;
    }
    if (!navigationBar) return;
    
    CGRect convertFrame = [self.superview convertRect:self.frame toView:navigationBar];
    if (CGRectGetMinX(convertFrame) == 16) {
        UIEdgeInsets edgeInsets = self.contentEdgeInsets;
        edgeInsets.left = 0;
        self.contentEdgeInsets = edgeInsets;
        [self sizeToFit];
    } else if (CGRectGetMaxX(convertFrame) + 16 == CGRectGetWidth(navigationBar.bounds)) {
        UIEdgeInsets edgeInsets = self.contentEdgeInsets;
        edgeInsets.right = 0;
        self.contentEdgeInsets = edgeInsets;
        [self sizeToFit];
    }
}

@end
