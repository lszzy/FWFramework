/*!
 @header     FWImagePickerPlugin.m
 @indexgroup FWFramework
 @brief      FWImagePickerPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWImagePickerPlugin.h"
#import "FWImagePickerPluginImpl.h"
#import "FWPlugin.h"
#import "FWToolkit.h"

#pragma mark - FWImagePickerPluginController

@implementation UIViewController (FWImagePickerPluginController)

- (void)fwShowImageCameraWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable, BOOL))completion
{
    [self fwShowImageCameraWithFilterType:FWImagePickerFilterTypeImage allowsEditing:allowsEditing customBlock:nil completion:^(id  _Nullable object, id  _Nullable result, BOOL cancel) {
        if (completion) completion(object, cancel);
    }];
}

- (void)fwShowImageCameraWithFilterType:(FWImagePickerFilterType)filterType
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(void (^)(id _Nonnull))customBlock
                             completion:(void (^)(id _Nullable, id _Nullable, BOOL))completion
{
    // 优先调用插件，不存在时使用默认
    id<FWImagePickerPlugin> imagePickerPlugin = [FWPluginManager loadPlugin:@protocol(FWImagePickerPlugin)];
    if (!imagePickerPlugin || ![imagePickerPlugin respondsToSelector:@selector(fwViewController:showImageCamera:allowsEditing:customBlock:completion:)]) {
        imagePickerPlugin = FWImagePickerPluginImpl.sharedInstance;
    }
    [imagePickerPlugin fwViewController:self showImageCamera:filterType allowsEditing:allowsEditing customBlock:customBlock completion:completion];
}

- (void)fwShowImagePickerWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable, BOOL))completion
{
    [self fwShowImagePickerWithSelectionLimit:1 allowsEditing:allowsEditing completion:^(NSArray<UIImage *> * _Nonnull images, NSArray * _Nonnull results, BOOL cancel) {
        if (completion) completion(images.firstObject, cancel);
    }];
}

- (void)fwShowImagePickerWithSelectionLimit:(NSInteger)selectionLimit
                              allowsEditing:(BOOL)allowsEditing
                                 completion:(void (^)(NSArray<UIImage *> * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    [self fwShowImagePickerWithFilterType:FWImagePickerFilterTypeImage selectionLimit:selectionLimit allowsEditing:allowsEditing customBlock:nil completion:^(NSArray * _Nonnull objects, NSArray * _Nonnull results, BOOL cancel) {
        if (completion) completion(objects, results, cancel);
    }];
}

- (void)fwShowImagePickerWithFilterType:(FWImagePickerFilterType)filterType
                         selectionLimit:(NSInteger)selectionLimit
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(void (^)(id _Nonnull))customBlock
                             completion:(void (^)(NSArray * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    // 优先调用插件，不存在时使用默认
    id<FWImagePickerPlugin> imagePickerPlugin = [FWPluginManager loadPlugin:@protocol(FWImagePickerPlugin)];
    if (!imagePickerPlugin || ![imagePickerPlugin respondsToSelector:@selector(fwViewController:showImagePicker:selectionLimit:allowsEditing:customBlock:completion:)]) {
        imagePickerPlugin = FWImagePickerPluginImpl.sharedInstance;
    }
    [imagePickerPlugin fwViewController:self showImagePicker:filterType selectionLimit:selectionLimit allowsEditing:allowsEditing customBlock:customBlock completion:completion];
}

@end

@implementation UIView (FWImagePickerPluginController)

- (void)fwShowImageCameraWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable, BOOL))completion
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowImageCameraWithAllowsEditing:allowsEditing
                                  completion:completion];
}

- (void)fwShowImageCameraWithFilterType:(FWImagePickerFilterType)filterType
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(void (^)(id _Nonnull))customBlock
                             completion:(void (^)(id _Nullable, id _Nullable, BOOL))completion
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowImageCameraWithFilterType:filterType
                            allowsEditing:allowsEditing
                              customBlock:customBlock
                               completion:completion];
}

- (void)fwShowImagePickerWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable, BOOL))completion
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowImagePickerWithAllowsEditing:allowsEditing
                                  completion:completion];
}

- (void)fwShowImagePickerWithSelectionLimit:(NSInteger)selectionLimit
                              allowsEditing:(BOOL)allowsEditing
                                 completion:(void (^)(NSArray<UIImage *> * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowImagePickerWithSelectionLimit:selectionLimit
                                allowsEditing:allowsEditing
                                   completion:completion];
}

- (void)fwShowImagePickerWithFilterType:(FWImagePickerFilterType)filterType
                         selectionLimit:(NSInteger)selectionLimit
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(void (^)(id _Nonnull))customBlock
                             completion:(void (^)(NSArray * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowImagePickerWithFilterType:filterType
                           selectionLimit:selectionLimit
                            allowsEditing:allowsEditing
                              customBlock:customBlock
                               completion:completion];
}

@end
