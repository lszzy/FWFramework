//
//  FWImagePreviewPlugin.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWImagePreviewPlugin.h"
#import "FWImagePreviewPluginImpl.h"
#import "FWPlugin.h"
#import "FWUIKit.h"
#import "FWNavigator.h"
#import <objc/runtime.h>

#if FWMacroSPM



#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - UIViewController+FWImagePreviewPlugin

@implementation UIViewController (FWImagePreviewPlugin)

- (id<FWImagePreviewPlugin>)fw_imagePreviewPlugin
{
    id<FWImagePreviewPlugin> previewPlugin = objc_getAssociatedObject(self, @selector(fw_imagePreviewPlugin));
    if (!previewPlugin) previewPlugin = [FWPluginManager loadPlugin:@protocol(FWImagePreviewPlugin)];
    if (!previewPlugin) previewPlugin = FWImagePreviewPluginImpl.sharedInstance;
    return previewPlugin;
}

- (void)setFw_imagePreviewPlugin:(id<FWImagePreviewPlugin>)imagePreviewPlugin
{
    objc_setAssociatedObject(self, @selector(fw_imagePreviewPlugin), imagePreviewPlugin, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_showImagePreviewWithImageURLs:(NSArray *)imageURLs
                             imageInfos:(NSArray *)imageInfos
                           currentIndex:(NSInteger)currentIndex
                             sourceView:(id  _Nullable (^)(NSInteger))sourceView
{
    [self fw_showImagePreviewWithImageURLs:imageURLs
                               imageInfos:imageInfos
                             currentIndex:currentIndex
                               sourceView:sourceView
                         placeholderImage:nil
                              renderBlock:nil
                              customBlock:nil];
}

- (void)fw_showImagePreviewWithImageURLs:(NSArray *)imageURLs
                             imageInfos:(NSArray *)imageInfos
                           currentIndex:(NSInteger)currentIndex
                             sourceView:(id  _Nullable (^)(NSInteger))sourceView
                       placeholderImage:(UIImage * _Nullable (^)(NSInteger))placeholderImage
                            renderBlock:(void (^)(__kindof UIView * _Nonnull, NSInteger))renderBlock
                            customBlock:(void (^)(id _Nonnull))customBlock
{
    // 优先调用插件，不存在时使用默认
    id<FWImagePreviewPlugin> imagePreviewPlugin = self.fw_imagePreviewPlugin;
    if (!imagePreviewPlugin || ![imagePreviewPlugin respondsToSelector:@selector(viewController:showImagePreview:imageInfos:currentIndex:sourceView:placeholderImage:renderBlock:customBlock:)]) {
        imagePreviewPlugin = FWImagePreviewPluginImpl.sharedInstance;
    }
    [imagePreviewPlugin viewController:self showImagePreview:imageURLs imageInfos:imageInfos currentIndex:currentIndex sourceView:sourceView placeholderImage:placeholderImage renderBlock:renderBlock customBlock:customBlock];
}

@end

@implementation UIView (FWImagePreviewPlugin)

- (void)fw_showImagePreviewWithImageURLs:(NSArray *)imageURLs
                             imageInfos:(NSArray *)imageInfos
                           currentIndex:(NSInteger)currentIndex
                             sourceView:(id  _Nullable (^)(NSInteger))sourceView
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showImagePreviewWithImageURLs:imageURLs
                               imageInfos:imageInfos
                             currentIndex:currentIndex
                               sourceView:sourceView];
}

- (void)fw_showImagePreviewWithImageURLs:(NSArray *)imageURLs
                             imageInfos:(NSArray *)imageInfos
                           currentIndex:(NSInteger)currentIndex
                             sourceView:(id  _Nullable (^)(NSInteger))sourceView
                       placeholderImage:(UIImage * _Nullable (^)(NSInteger))placeholderImage
                            renderBlock:(void (^)(__kindof UIView * _Nonnull, NSInteger))renderBlock
                            customBlock:(void (^)(id _Nonnull))customBlock
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = UIWindow.fw_mainWindow.fw_topPresentedController;
    }
    [ctrl fw_showImagePreviewWithImageURLs:imageURLs
                               imageInfos:imageInfos
                             currentIndex:currentIndex
                               sourceView:sourceView
                         placeholderImage:placeholderImage
                              renderBlock:renderBlock
                              customBlock:customBlock];
}

@end
