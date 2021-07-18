/*!
 @header     FWNavigationView.m
 @indexgroup FWFramework
 @brief      FWNavigationView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import "FWNavigationView.h"
#import "FWAutoLayout.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import "FWAdaptive.h"
#import "FWBlock.h"
#import "FWImage.h"
#import "FWRouter.h"
#import "FWViewControllerStyle.h"
#import <objc/runtime.h>

#pragma mark - FWNavigationView

@implementation FWNavigationView

- (instancetype)init
{
    return [self initWithFrame:CGRectMake(0, 0, FWScreenWidth, FWTopBarHeight)];
}

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

- (void)setupView
{
    _topBarHeight = self.frame.size.height;
    _navigationBarHeight = FWNavigationBarHeight;
    _navigationItem = [[UINavigationItem alloc] init];
    _navigationBar = [[UINavigationBar alloc] init];
    _navigationBar.items = @[_navigationItem];
    [self addSubview:_navigationBar];
    [self updateLayout:NO];
}

- (void)updateLayout:(BOOL)refresh
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.hidden ? 0 : self.topBarHeight);
    self.navigationBar.frame = CGRectMake(0, self.topBarHeight - self.navigationBarHeight, self.frame.size.width, self.navigationBarHeight);
    if (refresh) [self invalidateIntrinsicContentSize];
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self updateLayout:YES];
}

- (void)setTopBarHeight:(CGFloat)topBarHeight
{
    _topBarHeight = topBarHeight;
    [self updateLayout:YES];
}

- (void)setNavigationBarHeight:(CGFloat)navigationBarHeight
{
    _navigationBarHeight = navigationBarHeight;
    [self updateLayout:YES];
}

- (CGSize)intrinsicContentSize
{
    return self.bounds.size;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateLayout:NO];
}

@end

#pragma mark - UIViewController+FWNavigationView

@implementation UIViewController (FWNavigationView)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationBar, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if ([selfObject.superview isKindOfClass:[FWNavigationView class]]) {
                UIView *backgroundView = selfObject.fwBackgroundView;
                backgroundView.frame = CGRectMake(backgroundView.frame.origin.x, -(selfObject.superview.bounds.size.height - backgroundView.frame.size.height), backgroundView.frame.size.width, selfObject.superview.bounds.size.height);
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwView), FWSwizzleReturn(UIView *), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            return selfObject.fwContainerView;
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwNavigationBar), FWSwizzleReturn(UINavigationBar *), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            return selfObject.fwNavigationView.navigationBar;
        }));
        
        FWSwizzleClass(UIViewController, @selector(navigationItem), FWSwizzleReturn(UINavigationItem *), FWSwizzleArgs(), FWSwizzleCode({
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
            selfObject.navigationItem.backBarButtonItem = backItem;
        }));
        
        FWSwizzleClass(UIViewController, @selector(loadView), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            if (!selfObject.fwNavigationViewEnabled) return;
            
            [selfObject fwNavigationViewUpdateLayout];
            BOOL hidden = selfObject.fwNavigationBarHidden || !selfObject.navigationController;
            selfObject.fwNavigationView.hidden = hidden;
            
            [selfObject.view addSubview:selfObject.fwNavigationView];
            [selfObject.view addSubview:selfObject.fwContainerView];
            [selfObject.fwNavigationView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
            [selfObject.fwContainerView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
            [selfObject.fwContainerView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:selfObject.fwNavigationView];
            [selfObject.view setNeedsLayout];
            [selfObject.view layoutIfNeeded];
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillTransitionToSize:withTransitionCoordinator:), FWSwizzleReturn(void), FWSwizzleArgs(CGSize size, id<UIViewControllerTransitionCoordinator> coordinator), FWSwizzleCode({
            FWSwizzleOriginal(size, coordinator);
            if (!selfObject.fwNavigationViewEnabled) return;
            
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                [selfObject fwNavigationViewUpdateLayout];
            } completion:nil];
        }));
        
        FWSwizzleClass(UIViewController, NSSelectorFromString(@"fwSetNavigationBarHidden:animated:"), FWSwizzleReturn(void), FWSwizzleArgs(BOOL hidden, BOOL animated), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal(hidden, animated);
            
            FWSwizzleOriginal(YES, animated);
            selfObject.fwNavigationView.hidden = hidden;
            
            if (selfObject.navigationItem.leftBarButtonItem && selfObject.navigationItem.leftBarButtonItem != selfObject.navigationItem.backBarButtonItem) return;
            if (selfObject.navigationController.viewControllers.firstObject == selfObject) {
                selfObject.navigationItem.leftBarButtonItem = nil;
            } else if (selfObject.navigationItem.leftBarButtonItem != selfObject.navigationItem.backBarButtonItem) {
                [selfObject.navigationItem.backBarButtonItem fwSetBlock:^(id sender) {
                    if (![selfObject fwPopBackBarItem]) return;
                    [selfObject fwCloseViewControllerAnimated:YES];
                }];
                selfObject.navigationItem.leftBarButtonItem = selfObject.navigationItem.backBarButtonItem;
            }
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

- (UIView *)fwContainerView
{
    UIView *containerView = objc_getAssociatedObject(self, _cmd);
    if (!containerView) {
        containerView = [[UIView alloc] init];
        objc_setAssociatedObject(self, _cmd, containerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return containerView;
}

- (BOOL)fwNavigationViewEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwNavigationViewEnabled)) boolValue];
}

- (void)setFwNavigationViewEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fwNavigationViewEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwNavigationViewUpdateLayout
{
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (!navigationBar || navigationBar.frame.size.height < 1) return;
    
    CGFloat topBarHeight = FWTopBarHeight;
    CGFloat navigationBarHeight = FWNavigationBarHeight;
    if (@available(iOS 13.0, *)) {
        BOOL isPageSheet = self.navigationController.modalPresentationStyle == UIModalPresentationAutomatic || self.navigationController.modalPresentationStyle == UIModalPresentationPageSheet;
        isPageSheet = isPageSheet && self.navigationController.presentingViewController != nil;
        if (isPageSheet) {
            topBarHeight = navigationBar.frame.size.height;
            navigationBarHeight = navigationBar.frame.size.height;
        }
    }
    self.fwNavigationView.topBarHeight = topBarHeight;
    self.fwNavigationView.navigationBarHeight = navigationBarHeight;
}

@end

#pragma mark - FWNavigationButton

@interface FWNavigationButton()

@property (nonatomic, assign) BOOL isImageType;
@property (nonatomic, strong) UIImage *highlightedImage;
@property (nonatomic, strong) UIImage *disabledImage;
@property (nonatomic, assign) UIControlContentHorizontalAlignment buttonPosition;

@end

@implementation FWNavigationButton

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 自动查找FWNavigationButton并设置位置偏移
        FWSwizzleMethod(objc_getClass("_UIButtonBarStackView"), @selector(layoutSubviews), nil, FWSwizzleType(UIView *), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            [FWNavigationButton layoutButtons:selfObject];
        }));
    });
}

+ (void)layoutButtons:(UIView *)stackView
{
    if (stackView.frame.origin.x < 1) return;
    
    BOOL reverse = stackView.frame.origin.x > FWScreenWidth / 3.f;
    [self layoutView:stackView reverse:reverse block:^BOOL(UIView *view) {
        if (![view isKindOfClass:[FWNavigationButton class]]) return NO;
        
        FWNavigationButton *navigationButton = (FWNavigationButton *)view;
        [navigationButton updateContentInsets:reverse];
        return YES;
    }];
}

+ (BOOL)layoutView:(UIView *)layoutView reverse:(BOOL)reverse block:(BOOL (^)(UIView *view))block
{
    if (block(layoutView)) return YES;
    
    __block BOOL isSuccess = NO;
    NSArray<UIView *> *layoutSubviews = layoutView.subviews;
    [layoutSubviews enumerateObjectsWithOptions:reverse ? NSEnumerationReverse : 0 usingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        isSuccess = [self layoutView:obj reverse:reverse block:block];
        if (isSuccess) *stop = YES;
    }];
    return isSuccess;
}

#pragma mark - Lifecycle

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
    self.adjustsContentInsets = YES;
    self.adjustsImageWhenHighlighted = NO;
    self.adjustsImageWhenDisabled = NO;
    self.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
}

- (void)updateContentInsets:(BOOL)reverse
{
    if (!self.adjustsContentInsets) return;
    UIEdgeInsets contentInsets = self.contentEdgeInsets;
    if (reverse) {
        contentInsets.right = 0;
    } else {
        contentInsets.left = 0;
    }
    self.contentEdgeInsets = contentInsets;
    [self sizeToFit];
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

@end
