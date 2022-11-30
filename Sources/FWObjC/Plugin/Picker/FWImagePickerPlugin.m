//
//  FWImagePickerPlugin.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWImagePickerPlugin.h"
#import "FWImagePickerPluginImpl.h"
#import "FWPlugin.h"
#import "FWUIKit.h"
#import "FWNavigator.h"
#import <objc/runtime.h>

#if FWMacroSPM



#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - UIViewController+FWImagePickerPlugin

@implementation UIViewController (FWImagePickerPlugin)

- (id<FWImagePickerPlugin>)fw_imagePickerPlugin
{
    id<FWImagePickerPlugin> pickerPlugin = objc_getAssociatedObject(self, @selector(fw_imagePickerPlugin));
    if (!pickerPlugin) pickerPlugin = [FWPluginManager loadPlugin:@protocol(FWImagePickerPlugin)];
    if (!pickerPlugin) pickerPlugin = FWImagePickerPluginImpl.sharedInstance;
    return pickerPlugin;
}

- (void)setFw_imagePickerPlugin:(id<FWImagePickerPlugin>)imagePickerPlugin
{
    objc_setAssociatedObject(self, @selector(fw_imagePickerPlugin), imagePickerPlugin, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_showImageCameraWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable, BOOL))completion
{
    [self fw_showImageCameraWithFilterType:FWImagePickerFilterTypeImage allowsEditing:allowsEditing customBlock:nil completion:^(id  _Nullable object, id  _Nullable result, BOOL cancel) {
        if (completion) completion(object, cancel);
    }];
}

- (void)fw_showImageCameraWithFilterType:(FWImagePickerFilterType)filterType
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(void (^)(id _Nonnull))customBlock
                             completion:(void (^)(id _Nullable, id _Nullable, BOOL))completion
{
    // 优先调用插件，不存在时使用默认
    id<FWImagePickerPlugin> imagePickerPlugin = self.fw_imagePickerPlugin;
    if (!imagePickerPlugin || ![imagePickerPlugin respondsToSelector:@selector(viewController:showImageCamera:allowsEditing:customBlock:completion:)]) {
        imagePickerPlugin = FWImagePickerPluginImpl.sharedInstance;
    }
    [imagePickerPlugin viewController:self showImageCamera:filterType allowsEditing:allowsEditing customBlock:customBlock completion:completion];
}

- (void)fw_showImagePickerWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable, BOOL))completion
{
    [self fw_showImagePickerWithSelectionLimit:1 allowsEditing:allowsEditing completion:^(NSArray<UIImage *> * _Nonnull images, NSArray * _Nonnull results, BOOL cancel) {
        if (completion) completion(images.firstObject, cancel);
    }];
}

- (void)fw_showImagePickerWithSelectionLimit:(NSInteger)selectionLimit
                              allowsEditing:(BOOL)allowsEditing
                                 completion:(void (^)(NSArray<UIImage *> * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    [self fw_showImagePickerWithFilterType:FWImagePickerFilterTypeImage selectionLimit:selectionLimit allowsEditing:allowsEditing customBlock:nil completion:^(NSArray * _Nonnull objects, NSArray * _Nonnull results, BOOL cancel) {
        if (completion) completion(objects, results, cancel);
    }];
}

- (void)fw_showImagePickerWithFilterType:(FWImagePickerFilterType)filterType
                         selectionLimit:(NSInteger)selectionLimit
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(void (^)(id _Nonnull))customBlock
                             completion:(void (^)(NSArray * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    // 优先调用插件，不存在时使用默认
    id<FWImagePickerPlugin> imagePickerPlugin = self.fw_imagePickerPlugin;
    if (!imagePickerPlugin || ![imagePickerPlugin respondsToSelector:@selector(viewController:showImagePicker:selectionLimit:allowsEditing:customBlock:completion:)]) {
        imagePickerPlugin = FWImagePickerPluginImpl.sharedInstance;
    }
    [imagePickerPlugin viewController:self showImagePicker:filterType selectionLimit:selectionLimit allowsEditing:allowsEditing customBlock:customBlock completion:completion];
}

@end

#pragma mark - UIView+FWImagePickerPlugin

@implementation UIView (FWImagePickerPlugin)

- (void)fw_showImageCameraWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable, BOOL))completion
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = FWNavigator.topPresentedController;
    }
    [ctrl fw_showImageCameraWithAllowsEditing:allowsEditing
                                  completion:completion];
}

- (void)fw_showImageCameraWithFilterType:(FWImagePickerFilterType)filterType
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(void (^)(id _Nonnull))customBlock
                             completion:(void (^)(id _Nullable, id _Nullable, BOOL))completion
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = FWNavigator.topPresentedController;
    }
    [ctrl fw_showImageCameraWithFilterType:filterType
                            allowsEditing:allowsEditing
                              customBlock:customBlock
                               completion:completion];
}

- (void)fw_showImagePickerWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable, BOOL))completion
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = FWNavigator.topPresentedController;
    }
    [ctrl fw_showImagePickerWithAllowsEditing:allowsEditing
                                  completion:completion];
}

- (void)fw_showImagePickerWithSelectionLimit:(NSInteger)selectionLimit
                              allowsEditing:(BOOL)allowsEditing
                                 completion:(void (^)(NSArray<UIImage *> * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = FWNavigator.topPresentedController;
    }
    [ctrl fw_showImagePickerWithSelectionLimit:selectionLimit
                                allowsEditing:allowsEditing
                                   completion:completion];
}

- (void)fw_showImagePickerWithFilterType:(FWImagePickerFilterType)filterType
                         selectionLimit:(NSInteger)selectionLimit
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(void (^)(id _Nonnull))customBlock
                             completion:(void (^)(NSArray * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    UIViewController *ctrl = self.fw_viewController;
    if (!ctrl || ctrl.presentedViewController) {
        ctrl = FWNavigator.topPresentedController;
    }
    [ctrl fw_showImagePickerWithFilterType:filterType
                           selectionLimit:selectionLimit
                            allowsEditing:allowsEditing
                              customBlock:customBlock
                               completion:completion];
}

@end
