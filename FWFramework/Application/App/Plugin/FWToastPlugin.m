/*!
 @header     FWToastPlugin.m
 @indexgroup FWFramework
 @brief      FWToastPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWToastPlugin.h"
#import "FWAutoLayout.h"
#import "FWBlock.h"
#import "FWPlugin.h"
#import <objc/runtime.h>

#pragma mark - UIView+FWToastPlugin

@implementation UIView (FWToastPlugin)

- (void)fwShowLoadingWithText:(id)text
{
    NSAttributedString *attributedText = [text isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:text] : text;
    id<FWToastPlugin> plugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwShowLoadingWithAttributedText:inView:)]) {
        [plugin fwShowLoadingWithAttributedText:attributedText inView:self];
        return;
    }
    
    [self fwShowIndicatorLoadingWithStyle:-1 attributedTitle:attributedText];
}

- (void)fwHideLoading
{
    id<FWToastPlugin> plugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideLoading:)]) {
        [plugin fwHideLoading:self];
        return;
    }
    
    [self fwHideIndicatorLoading];
}

- (void)fwShowProgressWithText:(id)text progress:(CGFloat)progress
{
    NSAttributedString *attributedText = [text isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:text] : text;
    id<FWToastPlugin> plugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwShowProgressWithAttributedText:progress:inView:)]) {
        [plugin fwShowProgressWithAttributedText:attributedText progress:progress inView:self];
        return;
    }
    
    [self fwShowIndicatorLoadingWithStyle:-1 attributedTitle:attributedText];
}

- (void)fwHideProgress
{
    id<FWToastPlugin> plugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideProgress:)]) {
        [plugin fwHideProgress:self];
        return;
    }
    
    [self fwHideIndicatorLoading];
}

- (void)fwShowMessageWithText:(id)text
{
    [self fwShowMessageWithText:text style:FWToastStyleDefault];
}

- (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style
{
    [self fwShowMessageWithText:text style:style completion:nil];
}

- (void)fwShowMessageWithText:(id)text style:(FWToastStyle)style completion:(void (^)(void))completion
{
    NSAttributedString *attributedText = [text isKindOfClass:[NSString class]] ? [[NSAttributedString alloc] initWithString:text] : text;
    id<FWToastPlugin> plugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwShowMessageWithAttributedText:style:completion:inView:)]) {
        [plugin fwShowMessageWithAttributedText:attributedText style:style completion:completion inView:self];
        return;
    }
    
    UIView *indicatorView = [self fwShowIndicatorMessageWithAttributedText:attributedText];
    indicatorView.userInteractionEnabled = completion ? YES : NO;
    [self fwHideIndicatorMessageAfterDelay:2.0 completion:completion];
}

- (void)fwHideMessage
{
    id<FWToastPlugin> plugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWToastPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideMessage:)]) {
        [plugin fwHideMessage:self];
        return;
    }
    
    [self fwHideIndicatorMessage];
}

@end

#pragma mark - UIView+FWIndicator

@implementation UIView (FWIndicator)

+ (UIColor *)fwDefaultIndicatorColor
{
    UIColor *color = objc_getAssociatedObject([UIView class], @selector(fwDefaultIndicatorColor));
    if (color) return color;
    
    if (@available(iOS 13.0, *)) {
        return [UIColor systemBackgroundColor];
    } else {
        return [UIColor whiteColor];
    }
}

+ (void)setFwDefaultIndicatorColor:(UIColor *)color
{
    objc_setAssociatedObject([UIView class], @selector(fwDefaultIndicatorColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (UIColor *)fwDefaultIndicatorBackgroundColor
{
    UIColor *color = objc_getAssociatedObject([UIView class], @selector(fwDefaultIndicatorBackgroundColor));
    if (color) return color;
    
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    } else {
        return [[UIColor blackColor] colorWithAlphaComponent:0.8f];
    }
}

+ (void)setFwDefaultIndicatorBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject([UIView class], @selector(fwDefaultIndicatorBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)fwShowIndicatorLoadingWithStyle:(UIActivityIndicatorViewStyle)style
                            attributedTitle:(NSAttributedString *)attributedTitle
{
    return [self fwShowIndicatorLoadingWithStyle:style
                                 attributedTitle:attributedTitle
                                  indicatorColor:nil
                                 backgroundColor:nil
                              dimBackgroundColor:nil
                             horizontalAlignment:NO
                                   contentInsets:UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f)
                                    cornerRadius:5.f];
}

- (UIView *)fwShowIndicatorLoadingWithStyle:(UIActivityIndicatorViewStyle)style
                            attributedTitle:(NSAttributedString *)attributedTitle
                             indicatorColor:(UIColor *)indicatorColor
                            backgroundColor:(UIColor *)backgroundColor
                         dimBackgroundColor:(UIColor *)dimBackgroundColor
                        horizontalAlignment:(BOOL)horizontalAlignment
                              contentInsets:(UIEdgeInsets)contentInsets
                               cornerRadius:(CGFloat)cornerRadius
{
    // 设置默认指示器样式
    if (style < 0) {
        if (@available(iOS 13.0, *)) {
            style = UIActivityIndicatorViewStyleMedium;
        } else {
            style = UIActivityIndicatorViewStyleWhite;
        }
    }
    
    // 判断之前的指示器是否存在
    UIButton *indicatorView = [self viewWithTag:2011];
    if (indicatorView) {
        // 能否直接使用之前的指示器(避免进度重复调用出现闪烁)
        UIView *centerView = [indicatorView viewWithTag:(horizontalAlignment ? 2013 : 2012)];
        if (centerView) {
            indicatorView.backgroundColor = dimBackgroundColor ?: [UIColor clearColor];
            centerView.backgroundColor = backgroundColor ?: [UIView fwDefaultIndicatorBackgroundColor];
            centerView.layer.cornerRadius = cornerRadius;
            UIActivityIndicatorView *activityView = [indicatorView viewWithTag:2014];
            activityView.activityIndicatorViewStyle = style;
            activityView.color = indicatorColor ?: [UIView fwDefaultIndicatorColor];
            UILabel *titleLabel = [indicatorView viewWithTag:2015];
            titleLabel.attributedText = attributedTitle;
            titleLabel.textColor = indicatorColor ?: [UIView fwDefaultIndicatorColor];
            return indicatorView;
        }
        
        // 移除旧的视图
        [self fwHideIndicatorLoading];
    }
    
    // 背景容器，不可点击
    indicatorView = [UIButton fwAutoLayoutView];
    indicatorView.userInteractionEnabled = YES;
    indicatorView.backgroundColor = dimBackgroundColor ?: [UIColor clearColor];
    indicatorView.tag = 2011;
    [self addSubview:indicatorView];
    [indicatorView fwPinEdgesToSuperview];
    
    // 居中容器
    UIView *centerView = [UIView fwAutoLayoutView];
    centerView.userInteractionEnabled = NO;
    centerView.backgroundColor = backgroundColor ?: [UIView fwDefaultIndicatorBackgroundColor];
    centerView.layer.masksToBounds = YES;
    centerView.layer.cornerRadius = cornerRadius;
    centerView.tag = (horizontalAlignment ? 2013 : 2012);
    [indicatorView addSubview:centerView];
    [centerView fwAlignCenterToSuperview];
    
    // 小菊花
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    activityView.userInteractionEnabled = NO;
    activityView.backgroundColor = [UIColor clearColor];
    activityView.color = indicatorColor ?: [UIView fwDefaultIndicatorColor];
    activityView.tag = 2014;
    [centerView addSubview:activityView];
    [activityView startAnimating];
    
    // 文本框
    UILabel *titleLabel = [UILabel fwAutoLayoutView];
    titleLabel.userInteractionEnabled = NO;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.textColor = indicatorColor ?: [UIView fwDefaultIndicatorColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = attributedTitle;
    titleLabel.tag = 2015;
    titleLabel.fwAutoCollapse = YES;
    [centerView addSubview:titleLabel];
    
    // 左右布局
    if (horizontalAlignment) {
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:contentInsets.left];
        [activityView fwAlignAxisToSuperview:NSLayoutAttributeCenterY];
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:contentInsets.top relation:NSLayoutRelationGreaterThanOrEqual];
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:contentInsets.bottom relation:NSLayoutRelationGreaterThanOrEqual];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:contentInsets.right];
        [titleLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterY];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:contentInsets.top relation:NSLayoutRelationGreaterThanOrEqual];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:contentInsets.bottom relation:NSLayoutRelationGreaterThanOrEqual];
        NSLayoutConstraint *collapseConstraint = [titleLabel fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:activityView withOffset:5.f];
        [titleLabel fwAddCollapseConstraint:collapseConstraint];
    // 上下布局
    } else {
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:contentInsets.top];
        [activityView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:contentInsets.left relation:NSLayoutRelationGreaterThanOrEqual];
        [activityView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:contentInsets.right relation:NSLayoutRelationGreaterThanOrEqual];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:contentInsets.bottom];
        [titleLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:contentInsets.left relation:NSLayoutRelationGreaterThanOrEqual];
        [titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:contentInsets.right relation:NSLayoutRelationGreaterThanOrEqual];
        NSLayoutConstraint *collapseConstraint = [titleLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:activityView withOffset:5.f];
        [titleLabel fwAddCollapseConstraint:collapseConstraint];
    }
    return indicatorView;
}

- (BOOL)fwHideIndicatorLoading
{
    UIButton *indicatorView = [self viewWithTag:2011];
    if (indicatorView) {
        [indicatorView removeFromSuperview];
        return YES;
    }
    return NO;
}

- (UIView *)fwShowIndicatorMessageWithAttributedText:(NSAttributedString *)attributedText
{
    return [self fwShowIndicatorMessageWithAttributedText:attributedText
                                           indicatorColor:nil
                                          backgroundColor:nil
                                       dimBackgroundColor:nil
                                             paddingWidth:10.f
                                            contentInsets:UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f)
                                             cornerRadius:5.f];
}

- (UIView *)fwShowIndicatorMessageWithAttributedText:(NSAttributedString *)attributedText
                                      indicatorColor:(UIColor *)indicatorColor
                                     backgroundColor:(UIColor *)backgroundColor
                                  dimBackgroundColor:(UIColor *)dimBackgroundColor
                                        paddingWidth:(CGFloat)paddingWidth
                                       contentInsets:(UIEdgeInsets)contentInsets
                                        cornerRadius:(CGFloat)cornerRadius
{
    // 移除之前的视图
    [self fwHideIndicatorMessage];
    
    // 背景容器，默认不可点击
    UIButton *toastView = [UIButton fwAutoLayoutView];
    toastView.userInteractionEnabled = YES;
    toastView.backgroundColor = dimBackgroundColor ?: [UIColor clearColor];
    toastView.tag = 2031;
    [self addSubview:toastView];
    [toastView fwPinEdgesToSuperview];
    
    // 居中容器
    UIView *centerView = [UIView fwAutoLayoutView];
    centerView.userInteractionEnabled = NO;
    centerView.backgroundColor = backgroundColor ?: [UIView fwDefaultIndicatorBackgroundColor];
    centerView.layer.masksToBounds = YES;
    centerView.layer.cornerRadius = cornerRadius;
    [toastView addSubview:centerView];
    [centerView fwAlignCenterToSuperview];
    [centerView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:paddingWidth relation:NSLayoutRelationGreaterThanOrEqual];
    [centerView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:paddingWidth relation:NSLayoutRelationGreaterThanOrEqual];
    
    // 文本框
    UILabel *textLabel = [UILabel fwAutoLayoutView];
    textLabel.userInteractionEnabled = NO;
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.font = [UIFont systemFontOfSize:16];
    textLabel.textColor = indicatorColor ?: [UIView fwDefaultIndicatorColor];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.numberOfLines = 0;
    textLabel.attributedText = attributedText;
    [centerView addSubview:textLabel];
    [textLabel fwPinEdgesToSuperviewWithInsets:contentInsets];
    return toastView;
}

- (BOOL)fwHideIndicatorMessage
{
    UIButton *toastView = [self viewWithTag:2031];
    if (toastView) {
        [toastView removeFromSuperview];
        
        NSTimer *toastTimer = objc_getAssociatedObject(self, @selector(fwHideIndicatorMessageAfterDelay:completion:));
        if (toastTimer) {
            [toastTimer invalidate];
            objc_setAssociatedObject(self, @selector(fwHideIndicatorMessageAfterDelay:completion:), nil, OBJC_ASSOCIATION_ASSIGN);
        }
        
        return YES;
    }
    return NO;
}

- (BOOL)fwHideIndicatorMessageAfterDelay:(NSTimeInterval)delay
                              completion:(void (^)(void))completion
{
    UIButton *toastView = [self viewWithTag:2031];
    if (toastView) {
        // 创建Common模式Timer，避免ScrollView滚动时不触发
        NSTimer *toastTimer = [NSTimer fwCommonTimerWithTimeInterval:delay block:^(NSTimer *timer) {
            BOOL hideResult = [self fwHideIndicatorMessage];
            if (hideResult && completion) {
                completion();
            }
        } repeats:NO];
        objc_setAssociatedObject(self, @selector(fwHideIndicatorMessageAfterDelay:completion:), toastTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return YES;
    }
    return NO;
}

@end
