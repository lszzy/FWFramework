//
//  FWToolbarView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWToolbarView.h"
#import "FWViewPluginImpl.h"
#import "FWToolkit.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

+ (BOOL)fw_swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier block:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

@end

@interface UIView ()

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperview:(UIEdgeInsets)insets;
- (NSLayoutConstraint *)fw_setDimension:(NSLayoutAttribute)dimension size:(CGFloat)size relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)fw_pinEdgeToSuperview:(NSLayoutAttribute)edge inset:(CGFloat)inset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)fw_pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView offset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;

@end

@interface UIControl ()

- (NSString *)fw_addTouchWithBlock:(void (^)(id sender))block;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - FWToolbarView

@interface FWToolbarView ()

@property (nonatomic, assign) BOOL isLandscape;

@end

@implementation FWToolbarView

@synthesize topView = _topView;
@synthesize bottomView = _bottomView;

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self didInitializeWithType:FWToolbarViewTypeDefault];
    }
    return self;
}

- (instancetype)initWithType:(FWToolbarViewType)type {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self didInitializeWithType:type];
    }
    return self;
}

- (void)didInitializeWithType:(FWToolbarViewType)type {
    _type = type;
    _backgroundView = [[UIImageView alloc] init];
    _backgroundView.clipsToBounds = YES;
    _menuView = [[FWToolbarMenuView alloc] init];
    _menuView.equalWidth = (type == FWToolbarViewTypeTabBar);
    _menuView.titleView = (type == FWToolbarViewTypeNavBar) ? [FWToolbarTitleView new] : nil;
    [self updateHeight:YES];

    [self addSubview:self.backgroundView];
    [self addSubview:self.menuView];
    [self.backgroundView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
    [self.menuView fw_pinHorizontalToSuperview:0];
    [self.menuView fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:self.topHeight relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    [self.menuView fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:self.bottomHeight relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    [self.menuView fw_setDimension:NSLayoutAttributeHeight size:self.menuHeight relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (void)updateHeight:(BOOL)isFirst {
    switch (self.type) {
        case FWToolbarViewTypeNavBar: {
            _topHeight = UIScreen.fw_statusBarHeight;
            _menuHeight = UIScreen.fw_navigationBarHeight;
            break;
        }
        case FWToolbarViewTypeTabBar: {
            _menuHeight = UIScreen.fw_tabBarHeight - UIScreen.fw_safeAreaInsets.bottom;
            _bottomHeight = UIScreen.fw_safeAreaInsets.bottom;
            break;
        }
        case FWToolbarViewTypeCustom: {
            if (isFirst) _menuHeight = 44;
            break;
        }
        case FWToolbarViewTypeDefault:
        default: {
            _menuHeight = UIScreen.fw_toolBarHeight - UIScreen.fw_safeAreaInsets.bottom;
            _bottomHeight = UIScreen.fw_safeAreaInsets.bottom;
            break;
        }
    }
}

- (void)updateLayout:(BOOL)animated {
    [self setNeedsUpdateConstraints];
    [self invalidateIntrinsicContentSize];
    
    if (animated && self.superview) {
        [UIView animateWithDuration:0.25 animations:^{
            [self.superview layoutIfNeeded];
        }];
    }
}

- (void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation);
    if (isLandscape != self.isLandscape) {
        self.isLandscape = isLandscape;
        [self updateHeight:NO];
    }
    [self updateLayout:NO];
}

- (void)updateConstraints {
    [super updateConstraints];
    
    BOOL toolbarHidden = self.hidden || self.toolbarHidden;
    [self.menuView fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:toolbarHidden || self.topHidden ? 0 : self.topHeight relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    [self.menuView fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:toolbarHidden || self.bottomHidden ? 0 : self.bottomHeight relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    [self.menuView fw_setDimension:NSLayoutAttributeHeight size:toolbarHidden || self.menuHidden ? 0 : self.menuHeight relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat maxWidth = CGRectGetWidth(self.bounds) ?: UIScreen.mainScreen.bounds.size.width;
    return CGSizeMake(MIN(size.width, maxWidth), self.toolbarHeight);
}

- (CGSize)intrinsicContentSize {
    return [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
}

#pragma mark - Accessor

- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] init];
        _topView.clipsToBounds = YES;
        [self addSubview:_topView];
        [_topView fw_pinHorizontalToSuperview:0];
        [_topView fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        [_topView fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:self.menuView offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    }
    return _topView;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.clipsToBounds = YES;
        [self addSubview:_bottomView];
        [_bottomView fw_pinHorizontalToSuperview:0];
        [_bottomView fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        [_bottomView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.menuView offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    }
    return _bottomView;
}

- (void)setTopHeight:(CGFloat)topHeight {
    if (_topHeight == topHeight) return;
    _topHeight = topHeight;
    [self updateLayout:NO];
}

- (void)setMenuHeight:(CGFloat)menuHeight {
    if (_menuHeight == menuHeight) return;
    _menuHeight = menuHeight;
    [self updateLayout:NO];
}

- (void)setBottomHeight:(CGFloat)bottomHeight {
    if (_bottomHeight == bottomHeight) return;
    _bottomHeight = bottomHeight;
    [self updateLayout:NO];
}

- (CGFloat)toolbarHeight {
    CGFloat toolbarHeight = 0;
    if (self.hidden || self.toolbarHidden) return toolbarHeight;
    if (!self.topHidden) toolbarHeight += self.topHeight;
    if (!self.menuHidden) toolbarHeight += self.menuHeight;
    if (!self.bottomHidden) toolbarHeight += self.bottomHeight;
    return toolbarHeight;
}

- (void)setTopHidden:(BOOL)hidden {
    [self setTopHidden:hidden animated:NO];
}

- (void)setMenuHidden:(BOOL)hidden {
    [self setMenuHidden:hidden animated:NO];
}

- (void)setBottomHidden:(BOOL)hidden {
    [self setBottomHidden:hidden animated:NO];
}

- (void)setToolbarHidden:(BOOL)toolbarHidden {
    [self setToolbarHidden:toolbarHidden animated:NO];
}

- (void)setHidden:(BOOL)hidden {
    if (self.hidden == hidden) return;
    [super setHidden:hidden];
    [self updateLayout:NO];
}

- (void)setTopHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_topHidden == hidden) return;
    _topHidden = hidden;
    [self updateLayout:animated];
}

- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_menuHidden == hidden) return;
    _menuHidden = hidden;
    [self updateLayout:animated];
}

- (void)setBottomHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_bottomHidden == hidden) return;
    _bottomHidden = hidden;
    [self updateLayout:animated];
}

- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_toolbarHidden == hidden) return;
    _toolbarHidden = hidden;
    [self updateLayout:animated];
}

@end

#pragma mark - FWToolbarMenuView

@interface FWToolbarMenuView ()

@property (nonatomic, strong) NSMutableArray *subviewContraints;

@end

@implementation FWToolbarMenuView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setLeftButton:(__kindof UIView *)leftButton
{
    if (leftButton == _leftButton) return;
    if (_leftButton) [_leftButton removeFromSuperview];
    _leftButton = leftButton;
    if (leftButton) [self addSubview:leftButton];
    [self setNeedsUpdateConstraints];
}

- (void)setLeftMoreButton:(__kindof UIView *)leftMoreButton
{
    if (leftMoreButton == _leftMoreButton) return;
    if (_leftMoreButton) [_leftMoreButton removeFromSuperview];
    _leftMoreButton = leftMoreButton;
    if (leftMoreButton) [self addSubview:leftMoreButton];
    [self setNeedsUpdateConstraints];
}

- (void)setCenterButton:(__kindof UIView *)centerButton
{
    if (centerButton == _centerButton) return;
    if (_centerButton) [_centerButton removeFromSuperview];
    _centerButton = centerButton;
    if (centerButton) [self addSubview:centerButton];
    [self setNeedsUpdateConstraints];
}

- (void)setRightMoreButton:(__kindof UIView *)rightMoreButton
{
    if (rightMoreButton == _rightMoreButton) return;
    if (_rightMoreButton) [_rightMoreButton removeFromSuperview];
    _rightMoreButton = rightMoreButton;
    if (rightMoreButton) [self addSubview:rightMoreButton];
    [self setNeedsUpdateConstraints];
}

- (void)setRightButton:(__kindof UIView *)rightButton
{
    if (rightButton == _rightButton) return;
    if (_rightButton) [_rightButton removeFromSuperview];
    _rightButton = rightButton;
    if (rightButton) [self addSubview:rightButton];
    [self setNeedsUpdateConstraints];
}

- (void)setEqualWidth:(BOOL)equalWidth
{
    if (equalWidth == _equalWidth) return;
    _equalWidth = equalWidth;
    [self setNeedsUpdateConstraints];
}

- (FWToolbarTitleView *)titleView
{
    if ([self.centerButton isKindOfClass:[FWToolbarTitleView class]]) {
        return (FWToolbarTitleView *)self.centerButton;
    }
    return nil;
}

- (void)setTitleView:(FWToolbarTitleView *)titleView
{
    self.centerButton = titleView;
}

- (NSString *)title
{
    if ([self.centerButton conformsToProtocol:@protocol(FWTitleViewProtocol)]) {
        return ((id<FWTitleViewProtocol>)self.centerButton).title;
    }
    return nil;
}

- (void)setTitle:(NSString *)title
{
    if ([self.centerButton conformsToProtocol:@protocol(FWTitleViewProtocol)]) {
        ((id<FWTitleViewProtocol>)self.centerButton).title = title;
    }
}

- (void)safeAreaInsetsDidChange
{
    [super safeAreaInsetsDidChange];
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    if (self.subviewContraints) {
        [NSLayoutConstraint deactivateConstraints:self.subviewContraints];
        self.subviewContraints = nil;
    }
    
    if (self.equalWidth) {
        NSMutableArray *subviewButtons = [NSMutableArray array];
        if (self.leftButton) [subviewButtons addObject:self.leftButton];
        if (self.leftMoreButton) [subviewButtons addObject:self.leftMoreButton];
        if (self.centerButton) [subviewButtons addObject:self.centerButton];
        if (self.rightMoreButton) [subviewButtons addObject:self.rightMoreButton];
        if (self.rightButton) [subviewButtons addObject:self.rightButton];
        if (subviewButtons.count < 1) return;
        
        NSMutableArray *subviewContraints = [NSMutableArray array];
        UIView *previousButton = nil;
        for (UIView *subviewButton in subviewButtons) {
            [subviewContraints addObject:[subviewButton fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[subviewButton fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
            if (previousButton) {
                [subviewContraints addObject:[subviewButton fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:previousButton offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
                [subviewContraints addObject:[subviewButton fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:previousButton offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
            } else {
                [subviewContraints addObject:[subviewButton fw_pinEdgeToSuperview:NSLayoutAttributeLeft inset:UIScreen.fw_safeAreaInsets.left relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
            }
            previousButton = subviewButton;
        }
        [subviewContraints addObject:[previousButton fw_pinEdgeToSuperview:NSLayoutAttributeRight inset:UIScreen.fw_safeAreaInsets.right relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
        self.subviewContraints = subviewContraints;
    } else {
        NSMutableArray *subviewContraints = [NSMutableArray array];
        CGSize fitsSize = CGSizeMake(self.bounds.size.width ?: UIScreen.mainScreen.bounds.size.width, CGFLOAT_MAX);
        CGFloat leftWidth = 0;
        UIView *leftButton = self.leftButton ?: self.leftMoreButton;
        UIView *leftMoreButton = self.leftButton && self.leftMoreButton ? self.leftMoreButton : nil;
        if (leftButton) {
            [subviewContraints addObject:[leftButton fw_pinEdgeToSuperview:NSLayoutAttributeLeft inset:UIScreen.fw_safeAreaInsets.left + 8 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[leftButton fw_alignAxisToSuperview:NSLayoutAttributeCenterY offset:0]];
            [subviewContraints addObject:[leftButton fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[leftButton fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            CGFloat buttonWidth = leftButton.frame.size.width ?: [leftButton sizeThatFits:fitsSize].width;
            leftWidth += UIScreen.fw_safeAreaInsets.left + 8 + buttonWidth + 8;
        }
        if (leftMoreButton) {
            [subviewContraints addObject:[leftMoreButton fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:leftButton offset:8 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[leftMoreButton fw_alignAxisToSuperview:NSLayoutAttributeCenterY offset:0]];
            [subviewContraints addObject:[leftMoreButton fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[leftMoreButton fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            CGFloat buttonWidth = leftMoreButton.frame.size.width ?: [leftMoreButton sizeThatFits:fitsSize].width;
            leftWidth += buttonWidth + 8;
        }
        
        CGFloat rightWidth = 0;
        UIView *rightButton = self.rightButton ?: self.rightMoreButton;
        UIView *rightMoreButton = self.rightButton && self.rightMoreButton ? self.rightMoreButton : nil;
        if (rightButton) {
            [subviewContraints addObject:[rightButton fw_pinEdgeToSuperview:NSLayoutAttributeRight inset:8 + UIScreen.fw_safeAreaInsets.right relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[rightButton fw_alignAxisToSuperview:NSLayoutAttributeCenterY offset:0]];
            [subviewContraints addObject:[rightButton fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[rightButton fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            CGFloat buttonWidth = rightButton.frame.size.width ?: [rightButton sizeThatFits:fitsSize].width;
            rightWidth += 8 + buttonWidth + 8 + UIScreen.fw_safeAreaInsets.right;
        }
        if (rightMoreButton) {
            [subviewContraints addObject:[rightMoreButton fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:rightButton offset:-8 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[rightMoreButton fw_alignAxisToSuperview:NSLayoutAttributeCenterY offset:0]];
            [subviewContraints addObject:[rightMoreButton fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[rightMoreButton fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            CGFloat buttonWidth = rightMoreButton.frame.size.width ?: [rightMoreButton sizeThatFits:fitsSize].width;
            rightWidth += 8 + buttonWidth;
        }
        
        UIView *centerButton = self.centerButton;
        if (centerButton) {
            [subviewContraints addObject:[centerButton fw_alignAxisToSuperview:NSLayoutAttributeCenterX offset:0]];
            [subviewContraints addObject:[centerButton fw_alignAxisToSuperview:NSLayoutAttributeCenterY offset:0]];
            [subviewContraints addObject:[centerButton fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[centerButton fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:0 relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[centerButton fw_pinEdgeToSuperview:NSLayoutAttributeLeft inset:leftWidth relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
            [subviewContraints addObject:[centerButton fw_pinEdgeToSuperview:NSLayoutAttributeRight inset:rightWidth relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired]];
        }
        self.subviewContraints = subviewContraints;
    }
}

@end

#pragma mark - FWToolbarTitleView

@interface FWToolbarTitleView () <FWTitleViewProtocol>

@property(nonatomic, strong, readonly) UIView *contentView;
@property(nonatomic, assign) CGSize titleLabelSize;
@property(nonatomic, assign) CGSize subtitleLabelSize;
@property(nonatomic, strong) UIImageView *accessoryImageView;

@end

@implementation FWToolbarTitleView

#pragma mark - Static

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationBar, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            UIView *titleView = selfObject.topItem.titleView;
            if (![titleView conformsToProtocol:@protocol(FWTitleViewProtocol)]) {
                FWSwizzleOriginal();
                return;
            }
            
            CGFloat titleMaximumWidth = CGRectGetWidth(titleView.bounds);
            CGSize titleViewSize = [titleView sizeThatFits:CGSizeMake(titleMaximumWidth, CGFLOAT_MAX)];
            titleViewSize.height = ceil(titleViewSize.height);
            
            if (CGRectGetHeight(titleView.bounds) != titleViewSize.height) {
                CGFloat titleViewMinY = [UIScreen fw_flatValue:CGRectGetMinY(titleView.frame) - ((titleViewSize.height - CGRectGetHeight(titleView.bounds)) / 2.0) scale:0];
                titleView.frame = CGRectMake(CGRectGetMinX(titleView.frame), titleViewMinY, MIN(titleMaximumWidth, titleViewSize.width), titleViewSize.height);
            }
            
            if (CGRectGetWidth(titleView.bounds) != titleViewSize.width) {
                CGRect titleFrame = titleView.frame;
                titleFrame.size.width = titleViewSize.width;
                titleView.frame = titleFrame;
            }
            
            FWSwizzleOriginal();
        }));
        
        FWSwizzleClass(UIViewController, @selector(setTitle:), FWSwizzleReturn(void), FWSwizzleArgs(NSString *title), FWSwizzleCode({
            FWSwizzleOriginal(title);
            
            if ([selfObject.navigationItem.titleView conformsToProtocol:@protocol(FWTitleViewProtocol)]) {
                ((id<FWTitleViewProtocol>)selfObject.navigationItem.titleView).title = title;
            }
        }));
        
        FWSwizzleClass(UINavigationItem, @selector(setTitle:), FWSwizzleReturn(void), FWSwizzleArgs(NSString *title), FWSwizzleCode({
            FWSwizzleOriginal(title);
            
            if ([selfObject.titleView conformsToProtocol:@protocol(FWTitleViewProtocol)]) {
                ((id<FWTitleViewProtocol>)selfObject.titleView).title = title;
            }
        }));
        
        FWSwizzleClass(UINavigationItem, @selector(setTitleView:), FWSwizzleReturn(void), FWSwizzleArgs(UIView<FWTitleViewProtocol> *titleView), FWSwizzleCode({
            FWSwizzleOriginal(titleView);
            
            if ([titleView conformsToProtocol:@protocol(FWTitleViewProtocol)]) {
                if (titleView.title.length <= 0) {
                    titleView.title = selfObject.title;
                }
            }
        }));
    });
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    FWToolbarTitleView *appearance = [FWToolbarTitleView appearance];
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

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithStyle:FWToolbarTitleViewStyleHorizontal frame:frame];
}

- (instancetype)initWithStyle:(FWToolbarTitleViewStyle)style {
    return [self initWithStyle:style frame:CGRectZero];
}

- (instancetype)initWithStyle:(FWToolbarTitleViewStyle)style frame:(CGRect)frame {
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
        
        [self fw_applyAppearance];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, title = %@, subtitle = %@", [super description], self.title, self.subtitle];
}

#pragma mark - Accessor

- (void)setStyle:(FWToolbarTitleViewStyle)style {
    _style = style;
    if (style == FWToolbarTitleViewStyleVertical) {
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
    if (self.style == FWToolbarTitleViewStyleHorizontal) {
        self.titleLabel.font = horizontalTitleFont;
        [self refreshLayout];
    }
}

- (void)setHorizontalSubtitleFont:(UIFont *)horizontalSubtitleFont {
    _horizontalSubtitleFont = horizontalSubtitleFont;
    if (self.style == FWToolbarTitleViewStyleHorizontal) {
        self.subtitleLabel.font = horizontalSubtitleFont;
        [self refreshLayout];
    }
}

- (void)setVerticalTitleFont:(UIFont *)verticalTitleFont {
    _verticalTitleFont = verticalTitleFont;
    if (self.style == FWToolbarTitleViewStyleVertical) {
        self.titleLabel.font = verticalTitleFont;
        [self refreshLayout];
    }
}

- (void)setVerticalSubtitleFont:(UIFont *)verticalSubtitleFont {
    _verticalSubtitleFont = verticalSubtitleFont;
    if (self.style == FWToolbarTitleViewStyleVertical) {
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
    if (self.subAccessoryView && self.subtitleLabel.text.length && self.style == FWToolbarTitleViewStyleVertical) {
        self.subAccessoryView.hidden = NO;
    } else {
        self.subAccessoryView.hidden = YES;
    }
}

- (void)setLoadingView:(UIView<FWIndicatorViewPlugin> *)loadingView {
    if (_loadingView != loadingView) {
        [_loadingView stopAnimating];
        [_loadingView removeFromSuperview];
        _loadingView = nil;
    }
    if (loadingView) {
        _loadingView = loadingView;
        _loadingView.size = self.loadingViewSize;
        _loadingView.color = self.tintColor;
        [_loadingView stopAnimating];
        [self.contentView addSubview:_loadingView];
    }
    [self refreshLayout];
}

- (void)setShowsLoadingView:(BOOL)showsLoadingView {
    _showsLoadingView = showsLoadingView;
    if (showsLoadingView) {
        if (!self.loadingView) {
            self.loadingView = [UIActivityIndicatorView fw_indicatorViewWithColor:nil];
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
    if (self.style == FWToolbarTitleViewStyleVertical) {
        CGSize size = CGSizeZero;
        CGFloat firstLineWidth = [self firstLineWidthInVerticalStyle];
        CGFloat secondLineWidth = [self secondLineWidthInVerticalStyle];
        size.width = MAX(firstLineWidth, secondLineWidth);
        size.height = self.titleLabelSize.height + (self.titleEdgeInsetsIfShowingTitleLabel.top + self.titleEdgeInsetsIfShowingTitleLabel.bottom) + self.subtitleLabelSize.height + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.top + self.subtitleEdgeInsetsIfShowingSubtitleLabel.bottom);
        return CGSizeMake([UIScreen fw_flatValue:size.width scale:0], [UIScreen fw_flatValue:size.height scale:0]);
    } else {
        CGSize size = CGSizeZero;
        size.width = self.titleLabelSize.width + (self.titleEdgeInsetsIfShowingTitleLabel.left + self.titleEdgeInsetsIfShowingTitleLabel.right) + self.subtitleLabelSize.width + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.left + self.subtitleEdgeInsetsIfShowingSubtitleLabel.right);
        size.width += [self loadingViewSpacingSizeIfNeedsPlaceholder].width + [self accessorySpacingSizeIfNeedesPlaceholder].width;
        size.height = MAX(self.titleLabelSize.height + (self.titleEdgeInsetsIfShowingTitleLabel.top + self.titleEdgeInsetsIfShowingTitleLabel.bottom), self.subtitleLabelSize.height + (self.subtitleEdgeInsetsIfShowingSubtitleLabel.top + self.subtitleEdgeInsetsIfShowingSubtitleLabel.bottom));
        size.height = MAX(size.height, [self loadingViewSpacingSizeIfNeedsPlaceholder].height);
        size.height = MAX(size.height, [self accessorySpacingSizeIfNeedesPlaceholder].height);
        return CGSizeMake([UIScreen fw_flatValue:size.width scale:0], [UIScreen fw_flatValue:size.height scale:0]);
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize resultSize = [self contentSize];
    resultSize.width = MIN(resultSize.width, self.maximumWidth);
    return resultSize;
}

- (CGSize)intrinsicContentSize {
    return [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
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
    CGFloat contentOffsetRight = contentOffsetLeft;
    
    CGFloat loadingViewSpace = [self loadingViewSpacingSize].width;
    UIView *accessoryView = self.accessoryView ?: self.accessoryImageView;
    CGFloat accessoryViewSpace = [self accessorySpacingSize].width;
    BOOL isTitleLabelShowing = self.titleLabel.text.length > 0;
    BOOL isSubtitleLabelShowing = self.subtitleLabel.text.length > 0;
    BOOL isSubAccessoryViewShowing = isSubtitleLabelShowing && self.subAccessoryView && !self.subAccessoryView.hidden;
    UIEdgeInsets titleEdgeInsets = self.titleEdgeInsetsIfShowingTitleLabel;
    UIEdgeInsets subtitleEdgeInsets = self.subtitleEdgeInsetsIfShowingSubtitleLabel;
    
    if (self.style == FWToolbarTitleViewStyleVertical) {
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
    [self setActive:active animated:YES];
    [self refreshLayout];
}

@end

#pragma mark - FWToolbarButton

@interface FWToolbarButton()

@property (nonatomic, strong) UIImage *highlightedImage;
@property (nonatomic, strong) UIImage *disabledImage;
@property (nonatomic, assign) BOOL isLandscape;

@end

@implementation FWToolbarButton

+ (instancetype)buttonWithObject:(id)object target:(id)target action:(SEL)action {
    FWToolbarButton *button;
    if ([object isKindOfClass:[UIImage class]]) {
        button = [[FWToolbarButton alloc] initWithImage:(UIImage *)object];
    } else {
        button = [[FWToolbarButton alloc] initWithTitle:object];
    }
    if (target && action) {
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    return button;
}

+ (instancetype)buttonWithObject:(id)object block:(void (^)(id))block {
    FWToolbarButton *button;
    if ([object isKindOfClass:[UIImage class]]) {
        button = [[FWToolbarButton alloc] initWithImage:(UIImage *)object];
    } else {
        button = [[FWToolbarButton alloc] initWithTitle:object];
    }
    if (block) [button fw_addTouchWithBlock:block];
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
            self.highlightedImage = [[image fw_imageWithAlpha:0.2f] imageWithRenderingMode:image.renderingMode];
            [self setImage:self.highlightedImage forState:UIControlStateHighlighted];
            self.disabledImage = [[image fw_imageWithAlpha:0.2f] imageWithRenderingMode:image.renderingMode];
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
    } else if (CGRectGetMaxX(convertFrame) + 16 == CGRectGetWidth(navigationBar.bounds)) {
        UIEdgeInsets edgeInsets = self.contentEdgeInsets;
        edgeInsets.right = 0;
        self.contentEdgeInsets = edgeInsets;
    }
}

@end
