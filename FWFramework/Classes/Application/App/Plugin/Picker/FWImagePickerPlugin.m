/*!
 @header     FWImagePickerPlugin.m
 @indexgroup FWFramework
 @brief      FWImagePickerPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWImagePickerPlugin.h"
#import "FWImagePreviewPluginImpl.h"
#import "FWPlugin.h"
#import "FWToolkit.h"

#pragma mark - FWImagePickerPluginController

@implementation UIViewController (FWImagePickerPluginController)

- (void)fwShowImagePreviewWithImageURLs:(NSArray *)imageURLs
                           currentIndex:(NSInteger)currentIndex
                             sourceView:(id  _Nullable (^)(NSInteger))sourceView
{
    [self fwShowImagePreviewWithImageURLs:imageURLs
                             currentIndex:currentIndex
                               sourceView:sourceView
                         placeholderImage:nil
                              renderBlock:nil
                              customBlock:nil];
}

- (void)fwShowImagePreviewWithImageURLs:(NSArray *)imageURLs
                           currentIndex:(NSInteger)currentIndex
                             sourceView:(id  _Nullable (^)(NSInteger))sourceView
                       placeholderImage:(UIImage * _Nullable (^)(NSInteger))placeholderImage
                            renderBlock:(void (^)(__kindof UIView * _Nonnull, NSInteger))renderBlock
                            customBlock:(void (^)(id _Nonnull))customBlock
{
    // 优先调用插件，不存在时使用默认
    id<FWImagePreviewPlugin> imagePreviewPlugin = [FWPluginManager loadPlugin:@protocol(FWImagePreviewPlugin)];
    if (!imagePreviewPlugin || ![imagePreviewPlugin respondsToSelector:@selector(fwViewController:showImagePreview:currentIndex:sourceView:placeholderImage:renderBlock:customBlock:)]) {
        imagePreviewPlugin = FWImagePreviewPluginImpl.sharedInstance;
    }
    [imagePreviewPlugin fwViewController:self showImagePreview:imageURLs currentIndex:currentIndex sourceView:sourceView placeholderImage:placeholderImage renderBlock:renderBlock customBlock:customBlock];
}

@end

@implementation UIView (FWImagePickerPluginController)

- (void)fwShowImagePreviewWithImageURLs:(NSArray *)imageURLs
                           currentIndex:(NSInteger)currentIndex
                             sourceView:(id  _Nullable (^)(NSInteger))sourceView
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowImagePreviewWithImageURLs:imageURLs
                             currentIndex:currentIndex
                               sourceView:sourceView];
}

- (void)fwShowImagePreviewWithImageURLs:(NSArray *)imageURLs
                           currentIndex:(NSInteger)currentIndex
                             sourceView:(id  _Nullable (^)(NSInteger))sourceView
                       placeholderImage:(UIImage * _Nullable (^)(NSInteger))placeholderImage
                            renderBlock:(void (^)(__kindof UIView * _Nonnull, NSInteger))renderBlock
                            customBlock:(void (^)(id _Nonnull))customBlock
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowImagePreviewWithImageURLs:imageURLs
                             currentIndex:currentIndex
                               sourceView:sourceView
                         placeholderImage:placeholderImage
                              renderBlock:renderBlock
                              customBlock:customBlock];
}

@end
