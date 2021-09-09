/*!
 @header     FWEmptyPluginImpl.m
 @indexgroup FWFramework
 @brief      FWEmptyPluginImpl
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import "FWEmptyPluginImpl.h"
#import "FWAutoLayout.h"
#import "FWBlock.h"

#pragma mark - FWEmptyPluginImpl

@implementation FWEmptyPluginImpl

+ (FWEmptyPluginImpl *)sharedInstance
{
    static FWEmptyPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWEmptyPluginImpl alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fadeAnimated = YES;
    }
    return self;
}

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image loading:(BOOL)loading action:(NSString *)action block:(void (^)(id))block inView:(UIView *)view
{
    NSString *emptyText = text;
    if (!loading && !emptyText && self.defaultText) {
        emptyText = self.defaultText();
    }
    NSString *emptyDetail = detail;
    if (!loading && !emptyDetail && self.defaultDetail) {
        emptyDetail = self.defaultDetail();
    }
    UIImage *emptyImage = image;
    if (!loading && !emptyImage && self.defaultImage) {
        emptyImage = self.defaultImage();
    }
    NSString *emptyAction = action;
    if (!loading && !emptyAction && block && self.defaultAction) {
        emptyAction = self.defaultAction();
    }
    
    FWEmptyView *emptyView = [view viewWithTag:2021];
    BOOL fadeAnimated = self.fadeAnimated && !emptyView;
    if (emptyView) { [emptyView removeFromSuperview]; }
    
    emptyView = [[FWEmptyView alloc] initWithFrame:view.bounds];
    emptyView.tag = 2021;
    [view addSubview:emptyView];
    [emptyView fwPinEdgesToSuperviewWithInsets:view.fwEmptyInsets];
    [emptyView setLoadingViewHidden:!loading];
    [emptyView setImage:emptyImage];
    [emptyView setTextLabelText:emptyText];
    [emptyView setDetailTextLabelText:emptyDetail];
    [emptyView setActionButtonTitle:emptyAction];
    if (block) [emptyView.actionButton fwAddTouchBlock:block];

    if (self.customBlock) {
        self.customBlock(emptyView);
    }
    
    if (fadeAnimated) {
        emptyView.alpha = 0;
        [UIView animateWithDuration:0.25 animations:^{
            emptyView.alpha = 1.0;
        } completion:NULL];
    }
}

- (void)fwHideEmptyView:(UIView *)view
{
    UIView *emptyView = [view viewWithTag:2021];
    if (!emptyView) return;
    
    if ([emptyView.superview isKindOfClass:[FWScrollOverlayView class]]) {
        UIView *overlayView = emptyView.superview;
        [emptyView removeFromSuperview];
        [overlayView removeFromSuperview];
    } else {
        [emptyView removeFromSuperview];
    }
}

- (BOOL)fwHasEmptyView:(UIView *)view
{
    UIView *emptyView = [view viewWithTag:2021];
    return emptyView != nil ? YES : NO;
}

@end
