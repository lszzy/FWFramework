//
//  ImagePickerPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ImagePickerPluginImpl.h"
#import "ImageCropController.h"
#import "Bridge.h"

#pragma mark - __FWImagePickerPluginImpl

@implementation __FWImagePickerPluginImpl

+ (__FWImagePickerPluginImpl *)sharedInstance
{
    static __FWImagePickerPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWImagePickerPluginImpl alloc] init];
    });
    return instance;
}

- (void)viewController:(UIViewController *)viewController
         showImageCamera:(__FWImagePickerFilterType)filterType
           allowsEditing:(BOOL)allowsEditing
             customBlock:(void (^)(id _Nonnull))customBlock
              completion:(void (^)(id _Nullable, id _Nullable, BOOL))completion
{
    UIImagePickerController *pickerController = nil;
    if (self.cropControllerEnabled && filterType == __FWImagePickerFilterTypeImage && allowsEditing) {
        pickerController = [UIImagePickerController __fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera cropController:self.cropControllerBlock completion:^(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL cancel) {
            if (completion) completion(image, info, cancel);
        }];
    } else {
        pickerController = [UIImagePickerController __fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera filterType:filterType allowsEditing:allowsEditing shouldDismiss:YES completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, NSDictionary * _Nullable info, BOOL cancel) {
            if (completion) completion(object, info, cancel);
        }];
    }
    
    if (!pickerController) {
        if (completion) completion(nil, nil, YES);
        return;
    }
    
    if (self.customBlock) self.customBlock(pickerController);
    if (customBlock) customBlock(pickerController);
    [viewController presentViewController:pickerController animated:YES completion:nil];
}

- (void)viewController:(UIViewController *)viewController
         showImagePicker:(__FWImagePickerFilterType)filterType
          selectionLimit:(NSInteger)selectionLimit
           allowsEditing:(BOOL)allowsEditing
             customBlock:(void (^)(id _Nonnull))customBlock
              completion:(void (^)(NSArray * _Nonnull, NSArray * _Nonnull, BOOL))completion
{
    UIViewController *pickerController = nil;
    BOOL usePhotoPicker = NO;
    if (@available(iOS 14, *)) {
        usePhotoPicker = !self.photoPickerDisabled;
    }
    if (usePhotoPicker) {
        if (self.cropControllerEnabled && filterType == __FWImagePickerFilterTypeImage && selectionLimit == 1 && allowsEditing) {
            pickerController = [PHPhotoLibrary __fw_pickerControllerWithCropController:self.cropControllerBlock completion:^(UIImage * _Nullable image, id  _Nullable result, BOOL cancel) {
                if (completion) completion(image ? @[image] : @[], result ? @[result] : @[], cancel);
            }];
        } else {
            pickerController = [PHPhotoLibrary __fw_pickerControllerWithFilterType:filterType selectionLimit:selectionLimit allowsEditing:allowsEditing shouldDismiss:YES completion:^(__kindof UIViewController * _Nullable picker, NSArray * _Nonnull objects, NSArray * _Nonnull results, BOOL cancel) {
                if (completion) completion(objects, results, cancel);
            }];
        }
    } else {
        if (self.cropControllerEnabled && filterType == __FWImagePickerFilterTypeImage && allowsEditing) {
            pickerController = [UIImagePickerController __fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary cropController:self.cropControllerBlock completion:^(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL cancel) {
                if (completion) completion(image ? @[image] : @[], info ? @[info] : @[], cancel);
            }];
        } else {
            pickerController = [UIImagePickerController __fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary filterType:filterType allowsEditing:allowsEditing shouldDismiss:YES completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, NSDictionary * _Nullable info, BOOL cancel) {
                if (completion) completion(object ? @[object] : @[], info ? @[info] : @[], cancel);
            }];
        }
    }
    
    if (!pickerController) {
        if (completion) completion(@[], @[], YES);
        return;
    }
    
    if (self.customBlock) self.customBlock(pickerController);
    if (customBlock) customBlock(pickerController);
    [viewController presentViewController:pickerController animated:YES completion:nil];
}

@end
