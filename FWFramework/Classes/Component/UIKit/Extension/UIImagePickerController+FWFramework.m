/*!
 @header     UIImagePickerController+FWFramework.m
 @indexgroup FWFramework
 @brief      UIImagePickerController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/12
 */

#import "UIImagePickerController+FWFramework.h"
#import <objc/runtime.h>

#pragma mark - UIImagePickerController+FWFramework

@interface FWImagePickerControllerDelegate : NSObject <UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, assign) BOOL shouldDismiss;
@property (nonatomic, copy) void (^completionBlock)(UIImagePickerController * _Nullable picker, NSDictionary * _Nullable info, BOOL cancel);

@property (nonatomic, copy) void (^photosCompletionBlock)(PHPickerViewController * _Nullable picker, NSArray<UIImage *> *images, BOOL cancel) API_AVAILABLE(ios(14));

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
    void (^completion)(PHPickerViewController *picker, NSArray<UIImage *> *images, BOOL cancel) = self.photosCompletionBlock;
    if (self.shouldDismiss) {
        [picker dismissViewControllerAnimated:YES completion:^{
            if (!completion) {
                return;
            }
            if (results.count < 1) {
                completion(nil, @[], YES);
                return;
            }
            
            NSMutableArray *images = [NSMutableArray array];
            NSInteger totalCount = results.count;
            __block NSInteger finishCount = 0;
            [results enumerateObjectsUsingBlock:^(PHPickerResult *result, NSUInteger idx, BOOL *stop) {
                [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([object isKindOfClass:[UIImage class]]) {
                            [images addObject:(UIImage *)object];
                        }
                        
                        finishCount += 1;
                        if (finishCount == totalCount) {
                            completion(nil, [images copy], NO);
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
        
        NSMutableArray *images = [NSMutableArray array];
        NSInteger totalCount = results.count;
        __block NSInteger finishCount = 0;
        [results enumerateObjectsUsingBlock:^(PHPickerResult *result, NSUInteger idx, BOOL *stop) {
            [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([object isKindOfClass:[UIImage class]]) {
                        [images addObject:(UIImage *)object];
                    }
                    
                    finishCount += 1;
                    if (finishCount == totalCount) {
                        completion(picker, [images copy], NO);
                    }
                });
            }];
        }];
    }
}

@end

@implementation UIImagePickerController (FWFramework)

+ (instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType completion:(void (^)(NSDictionary * _Nullable, BOOL))completion
{
    return [self fwPickerControllerWithSourceType:sourceType shouldDismiss:YES completion:^(UIImagePickerController * _Nullable picker, NSDictionary * _Nullable info, BOOL cancel) {
        if (completion) completion(info, cancel);
    }];
}

+ (instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                   shouldDismiss:(BOOL)shouldDismiss
                                      completion:(void (^)(UIImagePickerController * _Nullable, NSDictionary * _Nullable, BOOL))completion
{
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return nil;
    }
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.sourceType = sourceType;
    
    FWImagePickerControllerDelegate *pickerDelegate = [[FWImagePickerControllerDelegate alloc] init];
    pickerDelegate.shouldDismiss = shouldDismiss;
    pickerDelegate.completionBlock = completion;
    
    objc_setAssociatedObject(pickerController, @selector(fwPickerControllerWithSourceType:shouldDismiss:completion:), pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    pickerController.delegate = pickerDelegate;
    return pickerController;
}

@end

#pragma mark - PHPickerViewController+FWFramework

@implementation PHPickerViewController (FWFramework)

+ (instancetype)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                          completion:(void (^)(NSArray<UIImage *> * _Nonnull, BOOL))completion
{
    return [self fwPickerControllerWithSelectionLimit:selectionLimit shouldDismiss:YES completion:^(PHPickerViewController * _Nullable picker, NSArray<UIImage *> * _Nonnull images, BOOL cancel) {
        if (completion) completion(images, cancel);
    }];
}

+ (instancetype)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                       shouldDismiss:(BOOL)shouldDismiss
                                          completion:(void (^)(PHPickerViewController * _Nullable, NSArray<UIImage *> * _Nonnull, BOOL))completion
{
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.selectionLimit = selectionLimit;
    configuration.filter = [PHPickerFilter anyFilterMatchingSubfilters:@[PHPickerFilter.imagesFilter, PHPickerFilter.livePhotosFilter]];
    PHPickerViewController *pickerController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    
    FWImagePickerControllerDelegate *pickerDelegate = [[FWImagePickerControllerDelegate alloc] init];
    pickerDelegate.shouldDismiss = shouldDismiss;
    pickerDelegate.photosCompletionBlock = completion;
    
    objc_setAssociatedObject(pickerController, @selector(fwPickerControllerWithSelectionLimit:shouldDismiss:completion:), pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    pickerController.delegate = pickerDelegate;
    return pickerController;
}

@end

#pragma mark - PHPhotoLibrary+FWFramework

@implementation PHPhotoLibrary (FWFramework)

+ (__kindof UIViewController *)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                                         completion:(void (^)(NSArray<UIImage *> * _Nonnull, BOOL))completion
{
    return [self fwPickerControllerWithSelectionLimit:selectionLimit shouldDismiss:YES completion:^(__kindof UIViewController * _Nullable picker, NSArray<UIImage *> * _Nonnull images, BOOL cancel) {
        if (completion) completion(images, cancel);
    }];
}

+ (__kindof UIViewController *)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                                      shouldDismiss:(BOOL)shouldDismiss
                                                         completion:(void (^)(__kindof UIViewController * _Nullable, NSArray<UIImage *> * _Nonnull, BOOL))completion
{
    if (@available(iOS 14, *)) {
        return [PHPickerViewController fwPickerControllerWithSelectionLimit:selectionLimit shouldDismiss:shouldDismiss completion:^(PHPickerViewController * _Nullable picker, NSArray<UIImage *> * _Nonnull images, BOOL cancel) {
            if (completion) completion(picker, images, cancel);
        }];
    } else {
        return [UIImagePickerController fwPickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary shouldDismiss:shouldDismiss completion:^(UIImagePickerController * _Nullable picker, NSDictionary * _Nullable info, BOOL cancel) {
            UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
            if (completion) completion(picker, image ? @[image] : @[], cancel);
        }];
    }
}

@end
