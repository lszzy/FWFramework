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
#import <objc/runtime.h>

#pragma mark - UIView+FWToastPluginImpl

@implementation UIView (FWToastPluginImpl)

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
    [self fwHideIndicatorLoadingInvalidateTimer];
    
    // 判断之前的指示器是否存在
    UIButton *indicatorView = [self viewWithTag:2011];
    if (indicatorView) {
        // 能否直接使用之前的指示器(避免进度重复调用出现闪烁)
        UIView *centerView = [indicatorView viewWithTag:(horizontalAlignment ? 2013 : 2012)];
        if (centerView) {
            // 重用指示器视图并移至顶层
            [self bringSubviewToFront:indicatorView];
            indicatorView.backgroundColor = dimBackgroundColor ?: [UIColor clearColor];
            centerView.backgroundColor = backgroundColor ?: [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1.0];
            centerView.layer.cornerRadius = cornerRadius;
            UIActivityIndicatorView *activityView = [indicatorView viewWithTag:2014];
            activityView.activityIndicatorViewStyle = style;
            activityView.color = indicatorColor ?: [UIColor whiteColor];
            UILabel *titleLabel = [indicatorView viewWithTag:2015];
            titleLabel.attributedText = attributedTitle;
            titleLabel.textColor = indicatorColor ?: [UIColor whiteColor];
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
    centerView.backgroundColor = backgroundColor ?: [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1.0];
    centerView.layer.masksToBounds = YES;
    centerView.layer.cornerRadius = cornerRadius;
    centerView.tag = (horizontalAlignment ? 2013 : 2012);
    [indicatorView addSubview:centerView];
    [centerView fwAlignCenterToSuperview];
    
    // 小菊花
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    activityView.userInteractionEnabled = NO;
    activityView.backgroundColor = [UIColor clearColor];
    activityView.color = indicatorColor ?: [UIColor whiteColor];
    activityView.tag = 2014;
    [centerView addSubview:activityView];
    [activityView startAnimating];
    
    // 文本框
    UILabel *titleLabel = [UILabel fwAutoLayoutView];
    titleLabel.userInteractionEnabled = NO;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.textColor = indicatorColor ?: [UIColor whiteColor];
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
        [self fwHideIndicatorLoadingInvalidateTimer];
        
        return YES;
    }
    return NO;
}

- (BOOL)fwHideIndicatorLoadingAfterDelay:(NSTimeInterval)delay
{
    UIButton *indicatorView = [self viewWithTag:2011];
    if (indicatorView) {
        // 创建Common模式Timer，避免ScrollView滚动时不触发
        [self fwHideIndicatorLoadingInvalidateTimer];
        NSTimer *indicatorTimer = [NSTimer fwCommonTimerWithTimeInterval:delay block:^(NSTimer *timer) {
            [self fwHideIndicatorLoading];
        } repeats:NO];
        objc_setAssociatedObject(self, @selector(fwHideIndicatorLoadingAfterDelay:), indicatorTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return YES;
    }
    return NO;
}

- (void)fwHideIndicatorLoadingInvalidateTimer
{
    NSTimer *indicatorTimer = objc_getAssociatedObject(self, @selector(fwHideIndicatorLoadingAfterDelay:));
    if (indicatorTimer) {
        [indicatorTimer invalidate];
        objc_setAssociatedObject(self, @selector(fwHideIndicatorLoadingAfterDelay:), nil, OBJC_ASSOCIATION_ASSIGN);
    }
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
    centerView.backgroundColor = backgroundColor ?: [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1.0];
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
    textLabel.textColor = indicatorColor ?: [UIColor whiteColor];
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
        [self fwHideIndicatorMessageInvalidateTimer];
        
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
        [self fwHideIndicatorMessageInvalidateTimer];
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

- (void)fwHideIndicatorMessageInvalidateTimer
{
    NSTimer *toastTimer = objc_getAssociatedObject(self, @selector(fwHideIndicatorMessageAfterDelay:completion:));
    if (toastTimer) {
        [toastTimer invalidate];
        objc_setAssociatedObject(self, @selector(fwHideIndicatorMessageAfterDelay:completion:), nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

@end