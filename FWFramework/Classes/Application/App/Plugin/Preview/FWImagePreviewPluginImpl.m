/*!
 @header     FWImagePreviewPluginImpl.m
 @indexgroup FWFramework
 @brief      FWImagePreviewPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWImagePreviewPluginImpl.h"

#pragma mark - FWImagePreviewPluginImpl

@implementation FWImagePreviewPluginImpl

+ (FWImagePreviewPluginImpl *)sharedInstance
{
    static FWImagePreviewPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWImagePreviewPluginImpl alloc] init];
    });
    return instance;
}

- (void)fwViewController:(UIViewController *)viewController
        showImagePreview:(NSArray *)imageURLs
            currentIndex:(NSInteger)currentIndex
              sourceView:(id  _Nullable (^)(NSInteger))sourceView
        placeholderImage:(UIImage * _Nullable (^)(NSInteger))placeholderImage
             renderBlock:(void (^)(__kindof UIView * _Nonnull, NSInteger))renderBlock
             customBlock:(void (^)(id _Nonnull))customBlock
{
    FWImagePreviewController *previewController = [[FWImagePreviewController alloc] init];
    previewController.showsPageLabel = YES;
    previewController.dismissingWhenTapped = YES;
    previewController.presentingStyle = FWImagePreviewTransitioningStyleZoom;
    previewController.sourceImageView = sourceView;
    previewController.imagePreviewView.placeholderImage = placeholderImage;
    previewController.imagePreviewView.imageURLs = imageURLs;
    previewController.imagePreviewView.currentImageIndex = currentIndex;
    previewController.imagePreviewView.renderZoomImageView = renderBlock;
    
    if (customBlock) customBlock(previewController);
    [viewController presentViewController:previewController animated:YES completion:nil];
}

@end
