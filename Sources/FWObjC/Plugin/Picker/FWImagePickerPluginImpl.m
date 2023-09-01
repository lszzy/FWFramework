//
//  FWImagePickerPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWImagePickerPluginImpl.h"
#import "FWImageCropController.h"
#import "FWEncode.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>

#pragma mark - FWImagePickerControllerDelegate

@interface FWImagePickerControllerDelegate : NSObject <UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, assign) FWImagePickerFilterType filterType;
@property (nonatomic, assign) BOOL shouldDismiss;
@property (nonatomic, copy) void (^completionBlock)(UIImagePickerController * _Nullable picker, id _Nullable object, NSDictionary * _Nullable info, BOOL cancel);

@property (nonatomic, copy) void (^photosCompletionBlock)(PHPickerViewController * _Nullable picker, NSArray *objects, NSArray<PHPickerResult *> *results, BOOL cancel) API_AVAILABLE(ios(14));

@end

@implementation FWImagePickerControllerDelegate

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    id object = nil;
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    BOOL checkLivePhoto = (self.filterType & FWImagePickerFilterTypeLivePhoto) || self.filterType < 1;
    BOOL checkVideo = (self.filterType & FWImagePickerFilterTypeVideo) || self.filterType < 1;
    if (checkLivePhoto && [mediaType isEqualToString:(NSString *)kUTTypeLivePhoto]) {
        object = info[UIImagePickerControllerLivePhoto];
    } else if (checkVideo && [mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        object = info[UIImagePickerControllerMediaURL];
    } else {
        object = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    }
    
    void (^completion)(UIImagePickerController *picker, id object, NSDictionary *info, BOOL cancel) = self.completionBlock;
    if (self.shouldDismiss) {
        [picker dismissViewControllerAnimated:YES completion:^{
            if (completion) completion(nil, object, info, NO);
        }];
    } else {
        if (completion) completion(picker, object, info, NO);
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    void (^completion)(UIImagePickerController *picker, id object, NSDictionary *info, BOOL cancel) = self.completionBlock;
    if (self.shouldDismiss) {
        [picker dismissViewControllerAnimated:YES completion:^{
            if (completion) completion(nil, nil, nil, YES);
        }];
    } else {
        if (completion) completion(picker, nil, nil, YES);
    }
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14))
{
    FWImagePickerFilterType filterType = self.filterType;
    void (^completion)(PHPickerViewController *picker, NSArray *objects, NSArray<PHPickerResult *> *results, BOOL cancel) = self.photosCompletionBlock;
    if (self.shouldDismiss) {
        [picker dismissViewControllerAnimated:YES completion:^{
            [FWImagePickerControllerDelegate picker:nil didFinishPicking:results filterType:filterType completion:completion];
        }];
    } else {
        [FWImagePickerControllerDelegate picker:picker didFinishPicking:results filterType:filterType completion:completion];
    }
}

+ (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results filterType:(FWImagePickerFilterType)filterType completion:(void (^)(PHPickerViewController *picker, NSArray *objects, NSArray<PHPickerResult *> *results, BOOL cancel))completion API_AVAILABLE(ios(14))
{
    if (!completion) return;
    if (results.count < 1) {
        completion(picker, @[], results, YES);
        return;
    }
    
    NSMutableArray *objects = [NSMutableArray array];
    NSInteger totalCount = results.count;
    __block NSInteger finishCount = 0;
    BOOL checkLivePhoto = (filterType & FWImagePickerFilterTypeLivePhoto) || filterType < 1;
    BOOL checkVideo = (filterType & FWImagePickerFilterTypeVideo) || filterType < 1;
    [results enumerateObjectsUsingBlock:^(PHPickerResult *result, NSUInteger idx, BOOL *stop) {
        BOOL isVideo = checkVideo && [result.itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie];
        if (!isVideo) {
            Class objectClass = [UIImage class];
            if (checkLivePhoto) {
                @try {
                    if ([result.itemProvider canLoadObjectOfClass:[PHLivePhoto class]]) {
                        objectClass = [PHLivePhoto class];
                    }
                } @catch (NSException *exception) {}
            }
            
            [result.itemProvider loadObjectOfClass:objectClass completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([object isKindOfClass:[UIImage class]] ||
                        [object isKindOfClass:[PHLivePhoto class]]) {
                        [objects addObject:object];
                    }
                    
                    finishCount += 1;
                    if (finishCount == totalCount) {
                        completion(picker, [objects copy], results, NO);
                    }
                });
            }];
            return;
        }
        
        // completionHandler完成后，临时文件url会被系统删除，所以在此期间移动临时文件到FWImagePicker目录
        [result.itemProvider loadFileRepresentationForTypeIdentifier:(NSString *)kUTTypeMovie completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
            NSURL *fileURL = nil;
            if (url) {
                NSString *filePath = [PHPhotoLibrary fw_pickerControllerVideoCachePath];
                [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
                filePath = [[filePath stringByAppendingPathComponent:[url.absoluteString fw_md5Encode]] stringByAppendingPathExtension:url.pathExtension];
                fileURL = [NSURL fileURLWithPath:filePath];
                if (![[NSFileManager defaultManager] moveItemAtURL:url toURL:fileURL error:NULL]) {
                    fileURL = nil;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (fileURL) [objects addObject:fileURL];
                
                finishCount += 1;
                if (finishCount == totalCount) {
                    completion(picker, [objects copy], results, NO);
                }
            });
        }];
    }];
}

@end

#pragma mark - UIImagePickerController+FWImagePickerPluginImpl

@implementation UIImagePickerController (FWImagePickerPluginImpl)

+ (UIImagePickerController *)fw_pickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                   allowsEditing:(BOOL)allowsEditing
                                      completion:(nonnull void (^)(UIImage * _Nullable, NSDictionary * _Nullable, BOOL))completion
{
    return [self fw_pickerControllerWithSourceType:sourceType filterType:FWImagePickerFilterTypeImage allowsEditing:allowsEditing shouldDismiss:YES completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, NSDictionary * _Nullable info, BOOL cancel) {
        if (completion) completion(object, info, cancel);
    }];
}

+ (UIImagePickerController *)fw_pickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                      filterType:(FWImagePickerFilterType)filterType
                                   allowsEditing:(BOOL)allowsEditing
                                   shouldDismiss:(BOOL)shouldDismiss
                                      completion:(void (^)(UIImagePickerController * _Nullable, id _Nullable, NSDictionary * _Nullable, BOOL))completion
{
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return nil;
    }
    
    NSMutableArray<NSString *> *mediaTypes = [NSMutableArray array];
    if (filterType & FWImagePickerFilterTypeImage) {
        [mediaTypes addObject:(NSString *)kUTTypeImage];
    }
    if (filterType & FWImagePickerFilterTypeLivePhoto) {
        if (![mediaTypes containsObject:(NSString *)kUTTypeImage]) {
            [mediaTypes addObject:(NSString *)kUTTypeImage];
        }
        [mediaTypes addObject:(NSString *)kUTTypeLivePhoto];
    }
    if (filterType & FWImagePickerFilterTypeVideo) {
        [mediaTypes addObject:(NSString *)kUTTypeMovie];
    }
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.sourceType = sourceType;
    pickerController.allowsEditing = allowsEditing;
    if (mediaTypes.count > 0) {
        pickerController.mediaTypes = [mediaTypes copy];
    }
    
    FWImagePickerControllerDelegate *pickerDelegate = [[FWImagePickerControllerDelegate alloc] init];
    pickerDelegate.filterType = filterType;
    pickerDelegate.shouldDismiss = shouldDismiss;
    pickerDelegate.completionBlock = completion;
    
    objc_setAssociatedObject(pickerController, @selector(fw_pickerControllerWithSourceType:filterType:allowsEditing:shouldDismiss:completion:), pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    pickerController.delegate = pickerDelegate;
    return pickerController;
}

+ (UIImagePickerController *)fw_pickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                  cropController:(nullable FWImageCropController * (^)(UIImage * _Nonnull))cropControllerBlock
                                      completion:(void (^)(UIImage * _Nullable, NSDictionary * _Nullable, BOOL))completion
{
    UIImagePickerController *pickerController = [UIImagePickerController fw_pickerControllerWithSourceType:sourceType filterType:FWImagePickerFilterTypeImage allowsEditing:NO shouldDismiss:NO completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, NSDictionary * _Nullable info, BOOL cancel) {
        UIImage *originalImage = cancel ? nil : object;
        if (originalImage) {
            FWImageCropController *cropController;
            if (cropControllerBlock) {
                cropController = cropControllerBlock(originalImage);
            } else {
                cropController = [[FWImageCropController alloc] initWithImage:originalImage];
                cropController.aspectRatioPreset = FWImageCropAspectRatioPresetSquare;
                cropController.aspectRatioLockEnabled = YES;
                cropController.resetAspectRatioEnabled = NO;
                cropController.aspectRatioPickerButtonHidden = YES;
            }
            cropController.onDidCropToRect = ^(UIImage * _Nonnull image, CGRect cropRect, NSInteger angle) {
                [picker dismissViewControllerAnimated:YES completion:^{
                    if (completion) completion(image, info, NO);
                }];
            };
            cropController.onDidFinishCancelled = ^(BOOL isFinished) {
                if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
                    [picker dismissViewControllerAnimated:YES completion:^{
                        if (completion) completion(nil, nil, YES);
                    }];
                } else {
                    [picker popViewControllerAnimated:YES];
                }
            };
            [picker pushViewController:cropController animated:YES];
        } else {
            [picker dismissViewControllerAnimated:YES completion:^{
                if (completion) completion(nil, nil, YES);
            }];
        }
    }];
    return pickerController;
}

@end

#pragma mark - PHPickerViewController+FWImagePickerPluginImpl

@implementation PHPickerViewController (FWImagePickerPluginImpl)

+ (PHPickerViewController *)fw_pickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                          completion:(nonnull void (^)(NSArray<UIImage *> * _Nonnull, NSArray<PHPickerResult *> * _Nonnull, BOOL))completion
{
    return [self fw_pickerControllerWithFilterType:FWImagePickerFilterTypeImage selectionLimit:selectionLimit shouldDismiss:YES completion:^(PHPickerViewController * _Nullable picker, NSArray * _Nonnull objects, NSArray<PHPickerResult *> *results, BOOL cancel) {
        if (completion) completion(objects, results, cancel);
    }];
}

+ (PHPickerViewController *)fw_pickerControllerWithFilterType:(FWImagePickerFilterType)filterType
                                  selectionLimit:(NSInteger)selectionLimit
                                   shouldDismiss:(BOOL)shouldDismiss
                                      completion:(void (^)(PHPickerViewController * _Nullable, NSArray *, NSArray<PHPickerResult *> *, BOOL))completion
{
    NSMutableArray *subFilters = [NSMutableArray array];
    if (filterType & FWImagePickerFilterTypeImage) {
        [subFilters addObject:PHPickerFilter.imagesFilter];
    }
    if (filterType & FWImagePickerFilterTypeLivePhoto) {
        [subFilters addObject:PHPickerFilter.livePhotosFilter];
    }
    if (filterType & FWImagePickerFilterTypeVideo) {
        [subFilters addObject:PHPickerFilter.videosFilter];
    }
    
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.selectionLimit = selectionLimit;
    if (subFilters.count > 0) {
        configuration.filter = [PHPickerFilter anyFilterMatchingSubfilters:subFilters];
    }
    PHPickerViewController *pickerController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    
    FWImagePickerControllerDelegate *pickerDelegate = [[FWImagePickerControllerDelegate alloc] init];
    pickerDelegate.filterType = filterType;
    pickerDelegate.shouldDismiss = shouldDismiss;
    pickerDelegate.photosCompletionBlock = completion;
    
    objc_setAssociatedObject(pickerController, @selector(fw_pickerControllerWithFilterType:selectionLimit:shouldDismiss:completion:), pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    pickerController.delegate = pickerDelegate;
    return pickerController;
}

+ (PHPickerViewController *)fw_pickerControllerWithCropController:(FWImageCropController * (^)(UIImage * _Nonnull))cropControllerBlock completion:(void (^)(UIImage * _Nullable, PHPickerResult * _Nullable, BOOL))completion
{
    PHPickerViewController *pickerController = [PHPickerViewController fw_pickerControllerWithFilterType:FWImagePickerFilterTypeImage selectionLimit:1 shouldDismiss:NO completion:^(PHPickerViewController * _Nullable picker, NSArray *objects, NSArray<PHPickerResult *> *results, BOOL cancel) {
        UIImage *originalImage = objects.firstObject;
        if (originalImage) {
            FWImageCropController *cropController;
            if (cropControllerBlock) {
                cropController = cropControllerBlock(originalImage);
            } else {
                cropController = [[FWImageCropController alloc] initWithImage:originalImage];
                cropController.aspectRatioPreset = FWImageCropAspectRatioPresetSquare;
                cropController.aspectRatioLockEnabled = YES;
                cropController.resetAspectRatioEnabled = NO;
                cropController.aspectRatioPickerButtonHidden = YES;
            }
            cropController.onDidCropToRect = ^(UIImage * _Nonnull image, CGRect cropRect, NSInteger angle) {
                [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    if (completion) completion(image, results.firstObject, NO);
                }];
            };
            cropController.onDidFinishCancelled = ^(BOOL isFinished) {
                if (picker.navigationController) {
                    [picker.navigationController popViewControllerAnimated:YES];
                } else {
                    [picker dismissViewControllerAnimated:YES completion:nil];
                }
            };
            if (picker.navigationController) {
                [picker.navigationController pushViewController:cropController animated:YES];
            } else {
                [picker presentViewController:cropController animated:YES completion:nil];
            }
        } else {
            [picker dismissViewControllerAnimated:YES completion:^{
                if (completion) completion(nil, nil, YES);
            }];
        }
    }];
    return pickerController;
}

@end

#pragma mark - PHPhotoLibrary+FWImagePickerPluginImpl

@implementation PHPhotoLibrary (FWImagePickerPluginImpl)

+ (NSString *)fw_pickerControllerVideoCachePath
{
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"FWImagePicker"];
    return videoPath;
}

+ (__kindof UIViewController *)fw_pickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                                      allowsEditing:(BOOL)allowsEditing
                                                         completion:(void (^)(NSArray<UIImage *> *, NSArray *, BOOL))completion
{
    return [self fw_pickerControllerWithFilterType:FWImagePickerFilterTypeImage selectionLimit:selectionLimit allowsEditing:allowsEditing shouldDismiss:YES completion:^(__kindof UIViewController * _Nullable picker, NSArray *objects, NSArray *results, BOOL cancel) {
        if (completion) completion(objects, results, cancel);
    }];
}

+ (__kindof UIViewController *)fw_pickerControllerWithFilterType:(FWImagePickerFilterType)filterType
                                                 selectionLimit:(NSInteger)selectionLimit
                                                  allowsEditing:(BOOL)allowsEditing
                                                  shouldDismiss:(BOOL)shouldDismiss
                                                     completion:(void (^)(__kindof UIViewController * _Nullable, NSArray *, NSArray *, BOOL))completion
{
    if (@available(iOS 14, *)) {
        return [PHPickerViewController fw_pickerControllerWithFilterType:filterType selectionLimit:selectionLimit shouldDismiss:shouldDismiss completion:^(PHPickerViewController * _Nullable picker, NSArray *objects, NSArray<PHPickerResult *> *results, BOOL cancel) {
            if (completion) completion(picker, objects, results, cancel);
        }];
    } else {
        return [UIImagePickerController fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary filterType:filterType allowsEditing:allowsEditing shouldDismiss:shouldDismiss completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, NSDictionary * _Nullable info, BOOL cancel) {
            if (completion) completion(picker, object ? @[object] : @[], info ? @[info] : @[], cancel);
        }];
    }
}

+ (__kindof UIViewController *)fw_pickerControllerWithCropController:(FWImageCropController * (^)(UIImage * _Nonnull))cropController completion:(void (^)(UIImage * _Nullable, id _Nullable, BOOL))completion
{
    if (@available(iOS 14, *)) {
        return [PHPickerViewController fw_pickerControllerWithCropController:cropController completion:completion];
    } else {
        return [UIImagePickerController fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary cropController:cropController completion:completion];
    }
}

@end

#pragma mark - FWImagePickerPluginImpl

@implementation FWImagePickerPluginImpl

+ (FWImagePickerPluginImpl *)sharedInstance
{
    static FWImagePickerPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWImagePickerPluginImpl alloc] init];
    });
    return instance;
}

- (void)viewController:(UIViewController *)viewController
         showImageCamera:(FWImagePickerFilterType)filterType
           allowsEditing:(BOOL)allowsEditing
             customBlock:(void (^)(id _Nonnull))customBlock
              completion:(void (^)(id _Nullable, id _Nullable, BOOL))completion
{
    UIImagePickerController *pickerController = nil;
    if (self.cropControllerEnabled && filterType == FWImagePickerFilterTypeImage && allowsEditing) {
        pickerController = [UIImagePickerController fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera cropController:self.cropControllerBlock completion:^(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL cancel) {
            if (completion) completion(image, info, cancel);
        }];
    } else {
        pickerController = [UIImagePickerController fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera filterType:filterType allowsEditing:allowsEditing shouldDismiss:YES completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, NSDictionary * _Nullable info, BOOL cancel) {
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
         showImagePicker:(FWImagePickerFilterType)filterType
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
        if (self.cropControllerEnabled && filterType == FWImagePickerFilterTypeImage && selectionLimit == 1 && allowsEditing) {
            pickerController = [PHPhotoLibrary fw_pickerControllerWithCropController:self.cropControllerBlock completion:^(UIImage * _Nullable image, id  _Nullable result, BOOL cancel) {
                if (completion) completion(image ? @[image] : @[], result ? @[result] : @[], cancel);
            }];
        } else {
            pickerController = [PHPhotoLibrary fw_pickerControllerWithFilterType:filterType selectionLimit:selectionLimit allowsEditing:allowsEditing shouldDismiss:YES completion:^(__kindof UIViewController * _Nullable picker, NSArray * _Nonnull objects, NSArray * _Nonnull results, BOOL cancel) {
                if (completion) completion(objects, results, cancel);
            }];
        }
    } else {
        if (self.cropControllerEnabled && filterType == FWImagePickerFilterTypeImage && allowsEditing) {
            pickerController = [UIImagePickerController fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary cropController:self.cropControllerBlock completion:^(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL cancel) {
                if (completion) completion(image ? @[image] : @[], info ? @[info] : @[], cancel);
            }];
        } else {
            pickerController = [UIImagePickerController fw_pickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary filterType:filterType allowsEditing:allowsEditing shouldDismiss:YES completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, NSDictionary * _Nullable info, BOOL cancel) {
                if (completion) completion(object ? @[object] : @[], info ? @[info] : @[], cancel);
            }];
        }
    }
    
    if (!pickerController) {
        if (completion) completion(@[], @[], YES);
        return;
    }
    
    if (self.photoNavigationEnabled && ![pickerController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:pickerController];
        navigationController.navigationBarHidden = YES;
        pickerController = navigationController;
    }
    
    if (self.customBlock) self.customBlock(pickerController);
    if (customBlock) customBlock(pickerController);
    [viewController presentViewController:pickerController animated:YES completion:nil];
}

@end
