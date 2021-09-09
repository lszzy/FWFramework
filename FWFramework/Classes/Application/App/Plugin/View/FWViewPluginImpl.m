/*!
 @header     FWViewPluginImpl.m
 @indexgroup FWFramework
 @brief      FWViewPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWViewPluginImpl.h"
#import <objc/runtime.h>

#pragma mark - UIActivityIndicatorView+FWViewPlugin

@implementation UIActivityIndicatorView (FWViewPlugin)

+ (instancetype)fwIndicatorViewWithColor:(UIColor *)color {
    UIActivityIndicatorViewStyle indicatorStyle;
    if (@available(iOS 13.0, *)) {
        indicatorStyle = UIActivityIndicatorViewStyleMedium;
    } else {
        indicatorStyle = UIActivityIndicatorViewStyleWhite;
    }
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
    indicatorView.color = color ?: UIColor.whiteColor;
    indicatorView.hidesWhenStopped = YES;
    return indicatorView;
}

- (CGSize)size {
    return self.bounds.size;
}

- (void)setSize:(CGSize)size {
    CGFloat height = self.bounds.size.height;
    if (height <= 0) {
        height = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height;
        if (height <= 0) height = 20;
    }
    CGFloat scale = size.height / height;
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

- (CGFloat)progress {
    return [objc_getAssociatedObject(self, @selector(progress)) doubleValue];
}

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    objc_setAssociatedObject(self, @selector(progress), @(progress), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (0 < progress && progress < 1) {
        if (!self.isAnimating) [self startAnimating];
    } else {
        if (self.isAnimating) [self stopAnimating];
    }
}

@end

#pragma mark - FWViewPluginImpl

@implementation FWViewPluginImpl

+ (FWViewPluginImpl *)sharedInstance {
    static FWViewPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWViewPluginImpl alloc] init];
    });
    return instance;
}

- (UIView<FWProgressViewPlugin> *)progressViewWithStyle:(FWProgressViewStyle)style {
    if (self.customProgressView) {
        return self.customProgressView(style);
    }
    
    FWProgressView *progressView = [[FWProgressView alloc] init];
    return progressView;
}

- (UIView<FWIndicatorViewPlugin> *)indicatorViewWithStyle:(FWIndicatorViewStyle)style {
    if (self.customIndicatorView) {
        return self.customIndicatorView(style);
    }
    
    UIActivityIndicatorView *indicatorView = [UIActivityIndicatorView fwIndicatorViewWithColor:nil];
    return indicatorView;
}

@end
