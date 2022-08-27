//
//  FWEmptyPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWEmptyPluginImpl.h"
#import "FWAutoLayout.h"
#import "FWUIKit.h"
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

- (void)showEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image loading:(BOOL)loading actions:(NSArray<NSString *> *)actions block:(void (^)(NSInteger, id))block inView:(UIView *)view
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
    NSString *emptyAction = actions.count > 0 ? actions.firstObject : nil;
    if (!loading && !emptyAction && block && self.defaultAction) {
        emptyAction = self.defaultAction();
    }
    NSString *emptyMoreAction = actions.count > 1 ? [actions objectAtIndex:1] : nil;
    
    FWEmptyView *emptyView = [view fw_subviewWithTag:2021];
    BOOL fadeAnimated = self.fadeAnimated && !emptyView;
    if (emptyView) { [emptyView removeFromSuperview]; }
    
    emptyView = [[FWEmptyView alloc] initWithFrame:view.bounds];
    emptyView.tag = 2021;
    [view addSubview:emptyView];
    [emptyView fw_pinEdgesToSuperviewWithInsets:view.fw_emptyInsets];
    [emptyView setLoadingViewHidden:!loading];
    [emptyView setImage:emptyImage];
    [emptyView setTextLabelText:emptyText];
    [emptyView setDetailTextLabelText:emptyDetail];
    [emptyView setActionButtonTitle:emptyAction];
    [emptyView setMoreActionButtonTitle:emptyMoreAction];
    if (block) [emptyView.actionButton fw_addTouchBlock:^(id sender) { if (block) block(0, sender); }];
    if (block && emptyMoreAction) [emptyView.moreActionButton fw_addTouchBlock:^(id sender) { if (block) block(1, sender); }];

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

- (void)hideEmptyView:(UIView *)view
{
    UIView *emptyView = [view fw_subviewWithTag:2021];
    if (!emptyView) return;
    
    if ([emptyView.superview isKindOfClass:[FWScrollOverlayView class]]) {
        UIView *overlayView = emptyView.superview;
        [emptyView removeFromSuperview];
        [overlayView removeFromSuperview];
    } else {
        [emptyView removeFromSuperview];
    }
}

- (BOOL)hasEmptyView:(UIView *)view
{
    UIView *emptyView = [view fw_subviewWithTag:2021];
    return emptyView != nil ? YES : NO;
}

@end
