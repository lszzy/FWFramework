/*!
 @header     UIImagePickerController+FWFramework.m
 @indexgroup FWFramework
 @brief      UIImagePickerController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/12
 */

#import "UIImagePickerController+FWFramework.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>

#pragma mark - UIImagePickerController+FWFramework

@interface FWImagePickerControllerDelegate : NSObject <UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, assign) FWImagePickerControllerFilterType filterType;
@property (nonatomic, assign) BOOL shouldDismiss;
@property (nonatomic, copy) void (^completionBlock)(UIImagePickerController * _Nullable picker, id _Nullable object, BOOL cancel);

@property (nonatomic, copy) void (^photosCompletionBlock)(PHPickerViewController * _Nullable picker, NSArray *objects, BOOL cancel) API_AVAILABLE(ios(14));

@end

@implementation FWImagePickerControllerDelegate

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    void (^completion)(UIImagePickerController *picker, NSDictionary *info, BOOL cancel) = self.completionBlock;
    if (self.shouldDismiss) {
        [picker dismissViewControllerAnimated:YES completion:^{
            if (completion) completion(nil, info, NO);
        }];
    } else {
        if (completion) completion(picker, info, NO);
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    void (^completion)(UIImagePickerController *picker, NSDictionary *info, BOOL cancel) = self.completionBlock;
    if (self.shouldDismiss) {
        [picker dismissViewControllerAnimated:YES completion:^{
            if (completion) completion(nil, nil, YES);
        }];
    } else {
        if (completion) completion(picker, nil, YES);
    }
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14))
{
    void (^completion)(PHPickerViewController *picker, NSArray *objects, BOOL cancel) = self.photosCompletionBlock;
    if (self.shouldDismiss) {
        [picker dismissViewControllerAnimated:YES completion:^{
            if (!completion) {
                return;
            }
            if (results.count < 1) {
                completion(nil, @[], YES);
                return;
            }
            
            NSMutableArray *objects = [NSMutableArray array];
            NSInteger totalCount = results.count;
            __block NSInteger finishCount = 0;
            [results enumerateObjectsUsingBlock:^(PHPickerResult *result, NSUInteger idx, BOOL *stop) {
                [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([object isKindOfClass:[UIImage class]]) {
                            [objects addObject:object];
                        }
                        
                        finishCount += 1;
                        if (finishCount == totalCount) {
                            completion(nil, [objects copy], NO);
                        }
                    });
                }];
            }];
        }];
    } else {
        if (!completion) {
            return;
        }
        if (results.count < 1) {
            completion(picker, @[], YES);
            return;
        }
        
        NSMutableArray *objects = [NSMutableArray array];
        NSInteger totalCount = results.count;
        __block NSInteger finishCount = 0;
        [results enumerateObjectsUsingBlock:^(PHPickerResult *result, NSUInteger idx, BOOL *stop) {
            [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([object isKindOfClass:[UIImage class]]) {
                        [objects addObject:object];
                    }
                    
                    finishCount += 1;
                    if (finishCount == totalCount) {
                        completion(picker, [objects copy], NO);
                    }
                });
            }];
        }];
    }
}

@end

@implementation UIImagePickerController (FWFramework)

+ (instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                      completion:(void (^)(UIImage * _Nullable, BOOL))completion
{
    return [self fwPickerControllerWithSourceType:sourceType filterType:FWImagePickerControllerFilterTypeImage shouldDismiss:YES completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, BOOL cancel) {
        if (completion) completion(object, cancel);
    }];
}

+ (instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                      filterType:(FWImagePickerControllerFilterType)filterType
                                   shouldDismiss:(BOOL)shouldDismiss
                                      completion:(void (^)(UIImagePickerController * _Nullable, id _Nullable, BOOL))completion
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
    pickerDelegate.filterType = filterType;
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
                                          completion:(void (^)(NSArray<UIImage *> * _Nonnull, BOOL))completion
{
    return [self fwPickerControllerWithFilterType:FWImagePickerControllerFilterTypeImage selectionLimit:selectionLimit shouldDismiss:YES completion:^(PHPickerViewController * _Nullable picker, NSArray * _Nonnull objects, BOOL cancel) {
        if (completion) completion(objects, cancel);
    }];
}

+ (instancetype)fwPickerControllerWithFilterType:(FWImagePickerControllerFilterType)filterType
                                  selectionLimit:(NSInteger)selectionLimit
                                   shouldDismiss:(BOOL)shouldDismiss
                                      completion:(void (^)(PHPickerViewController * _Nullable, NSArray * _Nonnull, BOOL))completion
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
    pickerDelegate.filterType = filterType;
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
                                                         completion:(void (^)(NSArray<UIImage *> * _Nonnull, BOOL))completion
{
    return [self fwPickerControllerWithFilterType:FWImagePickerControllerFilterTypeImage selectionLimit:selectionLimit shouldDismiss:YES completion:^(__kindof UIViewController * _Nullable picker, NSArray * _Nonnull objects, BOOL cancel) {
        if (completion) completion(objects, cancel);
    }];
}

+ (__kindof UIViewController *)fwPickerControllerWithFilterType:(FWImagePickerControllerFilterType)filterType
                                                 selectionLimit:(NSInteger)selectionLimit
                                                  shouldDismiss:(BOOL)shouldDismiss
                                                     completion:(void (^)(__kindof UIViewController * _Nullable, NSArray * _Nonnull, BOOL))completion
{
    if (@available(iOS 14, *)) {
        return [PHPickerViewController fwPickerControllerWithFilterType:filterType selectionLimit:selectionLimit shouldDismiss:shouldDismiss completion:^(PHPickerViewController * _Nullable picker, NSArray * _Nonnull objects, BOOL cancel) {
            if (completion) completion(picker, objects, cancel);
        }];
    } else {
        return [UIImagePickerController fwPickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary filterType:filterType shouldDismiss:shouldDismiss completion:^(UIImagePickerController * _Nullable picker, id  _Nullable object, BOOL cancel) {
            if (completion) completion(picker, object ? @[object] : @[], cancel);
        }];
    }
}

@end
