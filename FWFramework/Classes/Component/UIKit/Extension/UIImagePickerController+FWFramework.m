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

@property (nonatomic, copy) void (^photosCompletionBlock)(PHPickerViewController * _Nullable picker, NSArray<PHPickerResult *> *results, BOOL cancel) API_AVAILABLE(ios(14));

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
    void (^completion)(PHPickerViewController *picker, NSArray<PHPickerResult *> *results, BOOL cancel) = self.photosCompletionBlock;
    if (self.shouldDismiss) {
        [picker dismissViewControllerAnimated:YES completion:^{
            if (completion) completion(nil, results, results.count < 1);
        }];
    } else {
        if (completion) completion(picker, results, results.count < 1);
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

+ (instancetype)fwPickerControllerWithConfiguration:(PHPickerConfiguration *)configuration
                                         completion:(void (^)(NSArray<PHPickerResult *> *, BOOL))completion
{
    return [self fwPickerControllerWithConfiguration:configuration shouldDismiss:YES completion:^(PHPickerViewController * _Nullable picker, NSArray<PHPickerResult *> * _Nonnull results, BOOL cancel) {
        if (completion) completion(results, cancel);
    }];
}

+ (instancetype)fwPickerControllerWithConfiguration:(PHPickerConfiguration *)configuration
                                      shouldDismiss:(BOOL)shouldDismiss
                                         completion:(void (^)(PHPickerViewController * _Nullable, NSArray<PHPickerResult *> * _Nonnull, BOOL))completion
{
    PHPickerViewController *pickerController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    
    FWImagePickerControllerDelegate *pickerDelegate = [[FWImagePickerControllerDelegate alloc] init];
    pickerDelegate.shouldDismiss = shouldDismiss;
    pickerDelegate.photosCompletionBlock = completion;
    
    objc_setAssociatedObject(pickerController, @selector(fwPickerControllerWithConfiguration:shouldDismiss:completion:), pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    pickerController.delegate = pickerDelegate;
    return pickerController;
}

@end
