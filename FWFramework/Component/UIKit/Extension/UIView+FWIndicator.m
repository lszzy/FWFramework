/*!
 @header     UIView+FWIndicator.m
 @indexgroup FWFramework
 @brief      UIView+FWIndicator
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "UIView+FWIndicator.h"
#import "FWLayoutManager.h"
#import "NSTimer+FWFramework.h"
#import <objc/runtime.h>

@implementation UIView (FWIndicator)

#pragma mark - Indicator

- (UIView *)fwShowIndicatorWithStyle:(UIActivityIndicatorViewStyle)style
                 attributedTitle:(NSAttributedString *)attributedTitle
{
    return [self fwShowIndicatorWithStyle:style
                          attributedTitle:attributedTitle
                          backgroundColor:nil
                       dimBackgroundColor:nil
                      horizontalAlignment:NO
                            contentInsets:UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f)
                             cornerRadius:5.f];
}

- (UIView *)fwShowIndicatorWithStyle:(UIActivityIndicatorViewStyle)style
                     attributedTitle:(NSAttributedString *)attributedTitle
                     backgroundColor:(UIColor *)backgroundColor
                  dimBackgroundColor:(UIColor *)dimBackgroundColor
                 horizontalAlignment:(BOOL)horizontalAlignment
                       contentInsets:(UIEdgeInsets)contentInsets
                        cornerRadius:(CGFloat)cornerRadius
{
    // 判断之前的指示器是否存在
    UIButton *indicatorView = [self viewWithTag:2011];
    if (indicatorView) {
        // 能否直接使用之前的指示器(避免进度重复调用出现闪烁)
        UIView *centerView = [indicatorView viewWithTag:(horizontalAlignment ? 2013 : 2012)];
        if (centerView) {
            indicatorView.backgroundColor = dimBackgroundColor ?: [UIColor clearColor];
            centerView.backgroundColor = backgroundColor ?: [[UIColor blackColor] colorWithAlphaComponent:0.8f];
            centerView.layer.cornerRadius = cornerRadius;
            UIActivityIndicatorView *activityView = [indicatorView viewWithTag:2014];
            activityView.activityIndicatorViewStyle = style;
            UILabel *titleLabel = [indicatorView viewWithTag:2015];
            titleLabel.attributedText = attributedTitle;
            return indicatorView;
        }
        
        // 移除旧的视图
        [self fwHideIndicator];
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
    centerView.backgroundColor = backgroundColor ?: [[UIColor blackColor] colorWithAlphaComponent:0.8f];
    centerView.layer.masksToBounds = YES;
    centerView.layer.cornerRadius = cornerRadius;
    centerView.tag = (horizontalAlignment ? 2013 : 2012);
    [indicatorView addSubview:centerView];
    [centerView fwAlignCenterToSuperview];
    
    // 小菊花
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    activityView.userInteractionEnabled = NO;
    activityView.backgroundColor = [UIColor clearColor];
    activityView.tag = 2014;
    [centerView addSubview:activityView];
    [activityView startAnimating];
    
    // 文本框
    UILabel *titleLabel = [UILabel fwAutoLayoutView];
    titleLabel.userInteractionEnabled = NO;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = attributedTitle;
    titleLabel.tag = 2015;
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
        [titleLabel fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:activityView withOffset:5.f];
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
        [titleLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:activityView withOffset:5.f];
    }
    return indicatorView;
}

- (BOOL)fwHideIndicator
{
    UIButton *indicatorView = [self viewWithTag:2011];
    if (indicatorView) {
        [indicatorView removeFromSuperview];
        return YES;
    }
    return NO;
}

#pragma mark - Toast

- (UIView *)fwShowToastWithAttributedText:(NSAttributedString *)attributedText
{
    return [self fwShowToastWithAttributedText:attributedText
                               backgroundColor:nil
                            dimBackgroundColor:nil
                                  paddingWidth:10.f
                                 contentInsets:UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f)
                                  cornerRadius:5.f];
}

- (UIView *)fwShowToastWithAttributedText:(NSAttributedString *)attributedText
                          backgroundColor:(UIColor *)backgroundColor
                       dimBackgroundColor:(UIColor *)dimBackgroundColor
                             paddingWidth:(CGFloat)paddingWidth
                            contentInsets:(UIEdgeInsets)contentInsets
                             cornerRadius:(CGFloat)cornerRadius
{
    // 移除之前的视图
    [self fwHideToast];
    
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
    centerView.backgroundColor = backgroundColor ?: [[UIColor blackColor] colorWithAlphaComponent:0.8f];
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
    textLabel.textColor = [UIColor whiteColor];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.numberOfLines = 0;
    textLabel.attributedText = attributedText;
    [centerView addSubview:textLabel];
    [textLabel fwPinEdgesToSuperviewWithInsets:contentInsets];
    return toastView;
}

- (BOOL)fwHideToast
{
    UIButton *toastView = [self viewWithTag:2031];
    if (toastView) {
        [toastView removeFromSuperview];
        
        NSTimer *toastTimer = objc_getAssociatedObject(self, @selector(fwHideToastAfterDelay:completion:));
        if (toastTimer) {
            [toastTimer invalidate];
            objc_setAssociatedObject(self, @selector(fwHideToastAfterDelay:completion:), nil, OBJC_ASSOCIATION_ASSIGN);
        }
        
        return YES;
    }
    return NO;
}

- (BOOL)fwHideToastAfterDelay:(NSTimeInterval)delay
                   completion:(void (^)(void))completion
{
    UIButton *toastView = [self viewWithTag:2031];
    if (toastView) {
        // 创建Common模式Timer，避免ScrollView滚动时不触发
        NSTimer *toastTimer = [NSTimer fwCommonTimerWithTimeInterval:delay block:^(NSTimer *timer) {
            BOOL hideToast = [self fwHideToast];
            if (hideToast && completion) {
                completion();
            }
        } repeats:NO];
        objc_setAssociatedObject(self, @selector(fwHideToastAfterDelay:completion:), toastTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return YES;
    }
    return NO;
}

@end
