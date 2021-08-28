/*!
 @header     UIImagePickerController+FWFramework.m
 @indexgroup FWFramework
 @brief      UIImagePickerController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/12
 */

#import "UIImagePickerController+FWFramework.h"
#import "FWEncode.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>

#pragma mark - UIImagePickerController+FWFramework

@interface FWImagePickerControllerDelegate : NSObject <UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate>

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
    if ([mediaType isEqualToString:(NSString *)kUTTypeLivePhoto]) {
        object = info[UIImagePickerControllerLivePhoto];
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
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
    void (^completion)(PHPickerViewController *picker, NSArray *objects, NSArray<PHPickerResult *> *results, BOOL cancel) = self.photosCompletionBlock;
    if (self.shouldDismiss) {
        [picker dismissViewControllerAnimated:YES completion:^{
            [FWImagePickerControllerDelegate picker:nil didFinishPicking:results completion:completion];
        }];
    } else {
        [FWImagePickerControllerDelegate picker:picker didFinishPicking:results completion:completion];
    }
}

+ (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results completion:(void (^)(PHPickerViewController *picker, NSArray *objects, NSArray<PHPickerResult *> *results, BOOL cancel))completion API_AVAILABLE(ios(14))
{
    if (!completion) return;
    if (results.count < 1) {
        completion(picker, @[], results, YES);
        return;
    }
    
    NSMutableArray *objects = [NSMutableArray array];
    NSInteger totalCount = results.count;
    __block NSInteger finishCount = 0;
    [results enumerateObjectsUsingBlock:^(PHPickerResult *result, NSUInteger idx, BOOL *stop) {
        Class objectClass = NULL;
        if ([result.itemProvider canLoadObjectOfClass:[PHLivePhoto class]]) {
            objectClass = [PHLivePhoto class];
        } else if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
            objectClass = [UIImage class];
        }
        
        if (objectClass) {
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
        
        [result.itemProvider loadFileRepresentationForTypeIdentifier:(NSString *)kUTTypeMovie completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
            NSURL *fileURL = nil;
            if (url) {
                NSString *filePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:[url.absoluteString fwMd5Encode]] stringByAppendingPathExtension:url.pathExtension];
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

@implementation UIImagePickerController (FWFramework)

+ (instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                      completion:(nonnull void (^)(UIImage * _Nullable, NSDictionary * _Nullable, BOOL))completion
{
    return [self fwPickerControllerWithSourceType:sourceType filterType:FWImagePickerControllerFilterTypeImage shouldDismiss:YES completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, NSDictionary * _Nullable info, BOOL cancel) {
        if (completion) completion(object, info, cancel);
    }];
}

+ (instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                      filterType:(FWImagePickerControllerFilterType)filterType
                                   shouldDismiss:(BOOL)shouldDismiss
                                      completion:(void (^)(UIImagePickerController * _Nullable, id _Nullable, NSDictionary * _Nullable, BOOL))completion
{
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return nil;
    }
    
    NSMutableArray<NSString *> *mediaTypes = [NSMutableArray array];
    if (filterType & FWImagePickerControllerFilterTypeImage) {
        [mediaTypes addObject:(NSString *)kUTTypeImage];
    }
    if (filterType & FWImagePickerControllerFilterTypeLivePhoto) {
        if (![mediaTypes containsObject:(NSString *)kUTTypeImage]) {
            [mediaTypes addObject:(NSString *)kUTTypeImage];
        }
        [mediaTypes addObject:(NSString *)kUTTypeLivePhoto];
    }
    if (filterType & FWImagePickerControllerFilterTypeVideo) {
        [mediaTypes addObject:(NSString *)kUTTypeMovie];
    }
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.sourceType = sourceType;
    if (mediaTypes.count > 0) {
        pickerController.mediaTypes = [mediaTypes copy];
    }
    
    FWImagePickerControllerDelegate *pickerDelegate = [[FWImagePickerControllerDelegate alloc] init];
    pickerDelegate.shouldDismiss = shouldDismiss;
    pickerDelegate.completionBlock = completion;
    
    objc_setAssociatedObject(pickerController, @selector(fwPickerControllerWithSourceType:filterType:shouldDismiss:completion:), pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    pickerController.delegate = pickerDelegate;
    return pickerController;
}

@end

#pragma mark - PHPickerViewController+FWFramework

@implementation PHPickerViewController (FWFramework)

+ (instancetype)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                          completion:(nonnull void (^)(NSArray<UIImage *> * _Nonnull, NSArray<PHPickerResult *> * _Nonnull, BOOL))completion
{
    return [self fwPickerControllerWithFilterType:FWImagePickerControllerFilterTypeImage selectionLimit:selectionLimit shouldDismiss:YES completion:^(PHPickerViewController * _Nullable picker, NSArray * _Nonnull objects, NSArray<PHPickerResult *> *results, BOOL cancel) {
        if (completion) completion(objects, results, cancel);
    }];
}

+ (instancetype)fwPickerControllerWithFilterType:(FWImagePickerControllerFilterType)filterType
                                  selectionLimit:(NSInteger)selectionLimit
                                   shouldDismiss:(BOOL)shouldDismiss
                                      completion:(void (^)(PHPickerViewController * _Nullable, NSArray *, NSArray<PHPickerResult *> *, BOOL))completion
{
    NSMutableArray *subFilters = [NSMutableArray array];
    if (filterType & FWImagePickerControllerFilterTypeImage) {
        [subFilters addObject:PHPickerFilter.imagesFilter];
    }
    if (filterType & FWImagePickerControllerFilterTypeLivePhoto) {
        [subFilters addObject:PHPickerFilter.livePhotosFilter];
    }
    if (filterType & FWImagePickerControllerFilterTypeVideo) {
        [subFilters addObject:PHPickerFilter.videosFilter];
    }
    
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.selectionLimit = selectionLimit;
    if (subFilters.count > 0) {
        configuration.filter = [PHPickerFilter anyFilterMatchingSubfilters:subFilters];
    }
    PHPickerViewController *pickerController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    
    FWImagePickerControllerDelegate *pickerDelegate = [[FWImagePickerControllerDelegate alloc] init];
    pickerDelegate.shouldDismiss = shouldDismiss;
    pickerDelegate.photosCompletionBlock = completion;
    
    objc_setAssociatedObject(pickerController, @selector(fwPickerControllerWithFilterType:selectionLimit:shouldDismiss:completion:), pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    pickerController.delegate = pickerDelegate;
    return pickerController;
}

@end

#pragma mark - PHPhotoLibrary+FWFramework

@implementation PHPhotoLibrary (FWFramework)

+ (__kindof UIViewController *)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                                         completion:(void (^)(NSArray<UIImage *> *, NSArray *, BOOL))completion
{
    return [self fwPickerControllerWithFilterType:FWImagePickerControllerFilterTypeImage selectionLimit:selectionLimit shouldDismiss:YES completion:^(__kindof UIViewController * _Nullable picker, NSArray *objects, NSArray *results, BOOL cancel) {
        if (completion) completion(objects, results, cancel);
    }];
}

+ (__kindof UIViewController *)fwPickerControllerWithFilterType:(FWImagePickerControllerFilterType)filterType
                                                 selectionLimit:(NSInteger)selectionLimit
                                                  shouldDismiss:(BOOL)shouldDismiss
                                                     completion:(void (^)(__kindof UIViewController * _Nullable, NSArray *, NSArray *, BOOL))completion
{
    if (@available(iOS 14, *)) {
        return [PHPickerViewController fwPickerControllerWithFilterType:filterType selectionLimit:selectionLimit shouldDismiss:shouldDismiss completion:^(PHPickerViewController * _Nullable picker, NSArray *objects, NSArray<PHPickerResult *> *results, BOOL cancel) {
            if (completion) completion(picker, objects, results, cancel);
        }];
    } else {
        return [UIImagePickerController fwPickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary filterType:filterType shouldDismiss:shouldDismiss completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, NSDictionary * _Nullable info, BOOL cancel) {
            if (completion) completion(picker, object ? @[object] : @[], info ? @[info] : @[], cancel);
        }];
    }
}

@end
