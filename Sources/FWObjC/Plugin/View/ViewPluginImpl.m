//
//  ViewPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "ViewPluginImpl.h"
#import <objc/runtime.h>

#if FWMacroSPM



#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - UIActivityIndicatorView+__FWViewPlugin

@implementation UIActivityIndicatorView (__FWViewPlugin)

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

#pragma mark - __FWViewPluginImpl

@implementation __FWViewPluginImpl

+ (__FWViewPluginImpl *)sharedInstance {
    static __FWViewPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWViewPluginImpl alloc] init];
    });
    return instance;
}

- (UIView<__FWProgressViewPlugin> *)progressViewWithStyle:(__FWProgressViewStyle)style {
    if (self.customProgressView) {
        return self.customProgressView(style);
    }
    
    __FWProgressView *progressView = [[__FWProgressView alloc] init];
    return progressView;
}

- (UIView<__FWIndicatorViewPlugin> *)indicatorViewWithStyle:(__FWIndicatorViewStyle)style {
    if (self.customIndicatorView) {
        return self.customIndicatorView(style);
    }
    
    UIActivityIndicatorView *indicatorView = [UIActivityIndicatorView fw_indicatorViewWithColor:nil];
    return indicatorView;
}

@end
