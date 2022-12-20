//
//  FWViewPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWViewPluginImpl.h"
#import <objc/runtime.h>

#if FWMacroSPM



#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - UIActivityIndicatorView+FWViewPlugin

@implementation UIActivityIndicatorView (FWViewPlugin)

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
    
    UIActivityIndicatorView *indicatorView = [UIActivityIndicatorView fw_indicatorViewWithColor:nil];
    return indicatorView;
}

@end
