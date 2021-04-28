/*!
 @header     FWToastPluginImpl.m
 @indexgroup FWFramework
 @brief      FWToastPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWToastPluginImpl.h"
#import "FWAutoLayout.h"
#import "FWBlock.h"
#import "FWPlugin.h"
#import <objc/runtime.h>

#pragma mark - FWAppToastPlugin

@implementation FWAppToastPlugin

+ (FWAppToastPlugin *)sharedInstance
{
    static FWAppToastPlugin *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWAppToastPlugin alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _textFont = [UIFont systemFontOfSize:16];
        _textColor = [UIColor whiteColor];
        if (@available(iOS 13.0, *)) {
            _indicatorStyle = UIActivityIndicatorViewStyleMedium;
        } else {
            _indicatorStyle = UIActivityIndicatorViewStyleWhite;
        }
        _indicatorColor = [UIColor whiteColor];
        _backgroundColor = [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1.0];
        _dimBackgroundColor = [UIColor clearColor];
        _horizontalAlignment = NO;
        _contentInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
        _contentSpacing = 5.f;
        _paddingWidth = 10.f;
        _cornerRadius = 5.f;
        _delayTime = 2.0;
    }
    return self;
}

#pragma mark - Public

- (UIView *)showIndicator:(NSAttributedString *)attributedTitle inView:(UIView *)view
{
    [self invalidateIndicatorTimer:view];
    
    // 判断之前的指示器是否存在
    UIButton *indicatorView = [view viewWithTag:2011];
    if (indicatorView) {
        // 能否直接使用之前的指示器(避免进度重复调用出现闪烁)
        UIView *centerView = [indicatorView viewWithTag:(self.horizontalAlignment ? 2013 : 2012)];
        if (centerView) {
            // 重用指示器视图并移至顶层
            [view bringSubviewToFront:indicatorView];
            UILabel *titleLabel = [indicatorView viewWithTag:2015];
            titleLabel.attributedText = attributedTitle;
            return indicatorView;
        }
        
        // 移除旧的视图
        [self hideIndicator:view];
    }
    
    // 背景容器，不可点击
    indicatorView = [UIButton fwAutoLayoutView];
    indicatorView.userInteractionEnabled = YES;
    indicatorView.backgroundColor = self.dimBackgroundColor;
    indicatorView.tag = 2011;
    [view addSubview:indicatorView];
    [indicatorView fwPinEdgesToSuperview];
    
    // 居中容器
    UIView *centerView = [UIView fwAutoLayoutView];
    centerView.userInteractionEnabled = NO;
    centerView.backgroundColor = self.backgroundColor;
    centerView.layer.masksToBounds = YES;
    centerView.layer.cornerRadius = self.cornerRadius;
    centerView.tag = (self.horizontalAlignment ? 2013 : 2012);
    [indicatorView addSubview:centerView];
    [centerView fwAlignCenterToSuperview];
    [centerView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.paddingWidth relation:NSLayoutRelationGreaterThanOrEqual];
    [centerView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.paddingWidth relation:NSLayoutRelationGreaterThanOrEqual];
    
    // 小菊花
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.indicatorStyle];
    activityView.userInteractionEnabled = NO;
    activityView.backgroundColor = [UIColor clearColor];
    activityView.color = self.indicatorColor;
    activityView.tag = 2014;
    [centerView addSubview:activityView];
    [activityView startAnimating];
    
    // 文本框
    UILabel *titleLabel = [UILabel fwAutoLayoutView];
    titleLabel.userInteractionEnabled = NO;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = self.textFont;
    titleLabel.textColor = self.textColor;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = attributedTitle;
    titleLabel.tag = 2015;
    titleLabel.fwAutoCollapse = YES;
    [centerView addSubview:titleLabel];
    
    // 左右布局
    if (self.horizontalAlignment) {
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.contentInsets.left];
        [activityView fwAlignAxisToSuperview:NSLayoutAttributeCenterY];
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.contentInsets.top relation:NSLayoutRelationGreaterThanOrEqual];
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:self.contentInsets.bottom relation:NSLayoutRelationGreaterThanOrEqual];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.contentInsets.right];
        [titleLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterY];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.contentInsets.top relation:NSLayoutRelationGreaterThanOrEqual];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:self.contentInsets.bottom relation:NSLayoutRelationGreaterThanOrEqual];
        NSLayoutConstraint *collapseConstraint = [titleLabel fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:activityView withOffset:self.contentSpacing];
        [titleLabel fwAddCollapseConstraint:collapseConstraint];
    // 上下布局
    } else {
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.contentInsets.top];
        [activityView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.contentInsets.left relation:NSLayoutRelationGreaterThanOrEqual];
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.contentInsets.right relation:NSLayoutRelationGreaterThanOrEqual];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:self.contentInsets.bottom];
        [titleLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.contentInsets.left relation:NSLayoutRelationGreaterThanOrEqual];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.contentInsets.right relation:NSLayoutRelationGreaterThanOrEqual];
        NSLayoutConstraint *collapseConstraint = [titleLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:activityView withOffset:self.contentSpacing];
        [titleLabel fwAddCollapseConstraint:collapseConstraint];
    }
    
    if (self.customBlock) {
        self.customBlock(view);
    }
    return indicatorView;
}

- (BOOL)hideIndicator:(UIView *)view
{
    UIButton *indicatorView = [view viewWithTag:2011];
    if (indicatorView) {
        [indicatorView removeFromSuperview];
        [self invalidateIndicatorTimer:view];
        
        return YES;
    }
    return NO;
}

- (BOOL)hideIndicatorAfterDelay:(NSTimeInterval)delay inView:(UIView *)view
{
    UIButton *indicatorView = [view viewWithTag:2011];
    if (indicatorView) {
        // 创建Common模式Timer，避免ScrollView滚动时不触发
        [self invalidateIndicatorTimer:view];
        NSTimer *indicatorTimer = [NSTimer fwCommonTimerWithTimeInterval:delay block:^(NSTimer *timer) {
            [self hideIndicator:view];
        } repeats:NO];
        objc_setAssociatedObject(view, @selector(hideIndicatorAfterDelay:inView:), indicatorTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return YES;
    }
    return NO;
}

- (void)invalidateIndicatorTimer:(UIView *)view
{
    NSTimer *indicatorTimer = objc_getAssociatedObject(view, @selector(hideIndicatorAfterDelay:inView:));
    if (indicatorTimer) {
        [indicatorTimer invalidate];
        objc_setAssociatedObject(view, @selector(hideIndicatorAfterDelay:inView:), nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

- (UIView *)showToast:(NSAttributedString *)attributedText inView:(UIView *)view
{
    // 移除之前的视图
    [self hideToast:view];
    
    // 背景容器，默认不可点击
    UIButton *toastView = [UIButton fwAutoLayoutView];
    toastView.userInteractionEnabled = YES;
    toastView.backgroundColor = self.dimBackgroundColor;
    toastView.tag = 2031;
    [view addSubview:toastView];
    [toastView fwPinEdgesToSuperview];
    
    // 居中容器
    UIView *centerView = [UIView fwAutoLayoutView];
    centerView.userInteractionEnabled = NO;
    centerView.backgroundColor = self.backgroundColor;
    centerView.layer.masksToBounds = YES;
    centerView.layer.cornerRadius = self.cornerRadius;
    [toastView addSubview:centerView];
    [centerView fwAlignCenterToSuperview];
    [centerView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.paddingWidth relation:NSLayoutRelationGreaterThanOrEqual];
    [centerView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.paddingWidth relation:NSLayoutRelationGreaterThanOrEqual];
    
    // 文本框
    UILabel *textLabel = [UILabel fwAutoLayoutView];
    textLabel.userInteractionEnabled = NO;
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.font = self.textFont;
    textLabel.textColor = self.textColor;
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.numberOfLines = 0;
    textLabel.attributedText = attributedText;
    [centerView addSubview:textLabel];
    [textLabel fwPinEdgesToSuperviewWithInsets:self.contentInsets];
    
    if (self.customBlock) {
        self.customBlock(view);
    }
    return toastView;
}

- (BOOL)hideToast:(UIView *)view
{
    UIButton *toastView = [view viewWithTag:2031];
    if (toastView) {
        [toastView removeFromSuperview];
        [self invalidateToastTimer:view];
        
        return YES;
    }
    return NO;
}

- (BOOL)hideToastAfterDelay:(NSTimeInterval)delay completion:(void (^)(void))completion inView:(UIView *)view
{
    UIButton *toastView = [view viewWithTag:2031];
    if (toastView) {
        // 创建Common模式Timer，避免ScrollView滚动时不触发
        [self invalidateToastTimer:view];
        NSTimer *toastTimer = [NSTimer fwCommonTimerWithTimeInterval:delay block:^(NSTimer *timer) {
            BOOL hideResult = [self hideToast:view];
            if (hideResult && completion) {
                completion();
            }
        } repeats:NO];
        objc_setAssociatedObject(view, @selector(hideToastAfterDelay:completion:inView:), toastTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return YES;
    }
    return NO;
}

- (void)invalidateToastTimer:(UIView *)view
{
    NSTimer *toastTimer = objc_getAssociatedObject(view, @selector(hideToastAfterDelay:completion:inView:));
    if (toastTimer) {
        [toastTimer invalidate];
        objc_setAssociatedObject(view, @selector(hideToastAfterDelay:completion:inView:), nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

#pragma mark - FWToastPlugin

- (void)fwShowLoadingWithAttributedText:(NSAttributedString *)attributedText inView:(UIView *)view
{
    [self showIndicator:attributedText inView:view];
}

- (void)fwHideLoading:(UIView *)view
{
    [self hideIndicator:view];
}

- (void)fwShowProgressWithAttributedText:(NSAttributedString *)attributedText progress:(CGFloat)progress inView:(UIView *)view
{
    [self showIndicator:attributedText inView:view];
}

- (void)fwHideProgress:(UIView *)view
{
    [self hideIndicator:view];
}

- (void)fwShowMessageWithAttributedText:(NSAttributedString *)attributedText style:(FWToastStyle)style completion:(void (^)(void))completion inView:(UIView *)view
{
    UIView *toastView = [self showToast:attributedText inView:view];
    toastView.userInteractionEnabled = completion ? YES : NO;
    [self hideToastAfterDelay:self.delayTime completion:completion inView:view];
}

- (void)fwHideMessage:(UIView *)view
{
    [self hideToast:view];
}

@end
