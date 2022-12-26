//
//  ImagePreviewPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ImagePreviewPluginImpl.h"

#pragma mark - ____FWImagePreviewPluginImpl

@implementation ____FWImagePreviewPluginImpl

+ (____FWImagePreviewPluginImpl *)sharedInstance
{
    static ____FWImagePreviewPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[____FWImagePreviewPluginImpl alloc] init];
    });
    return instance;
}

- (void)viewController:(UIViewController *)viewController
        showImagePreview:(NSArray *)imageURLs
              imageInfos:(NSArray *)imageInfos
            currentIndex:(NSInteger)currentIndex
              sourceView:(id  _Nullable (^)(NSInteger))sourceView
        placeholderImage:(UIImage * _Nullable (^)(NSInteger))placeholderImage
             renderBlock:(void (^)(__kindof UIView * _Nonnull, NSInteger))renderBlock
             customBlock:(void (^)(id _Nonnull))customBlock
{
    __FWImagePreviewController *previewController;
    if (self.previewControllerBlock) {
        previewController = self.previewControllerBlock();
    } else {
        previewController = [[__FWImagePreviewController alloc] init];
        previewController.showsPageLabel = YES;
        previewController.dismissingWhenTappedImage = YES;
        previewController.dismissingWhenTappedVideo = YES;
        previewController.presentingStyle = __FWImagePreviewTransitioningStyleZoom;
    }
    
    previewController.imagePreviewView.placeholderImage = placeholderImage;
    previewController.imagePreviewView.renderZoomImageView = renderBlock;
    previewController.sourceImageView = sourceView;
    if (self.customBlock) self.customBlock(previewController);
    if (customBlock) customBlock(previewController);
    
    previewController.imagePreviewView.imageURLs = imageURLs;
    previewController.imagePreviewView.imageInfos = imageInfos;
    previewController.imagePreviewView.currentImageIndex = currentIndex;
    [viewController presentViewController:previewController animated:YES completion:nil];
}

@end
