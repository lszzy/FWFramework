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

@implementation UIImagePickerController (FWFramework)

+ (instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType completion:(void (^)(NSDictionary *, BOOL))completion
{
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return nil;
    }
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = pickerController;
    pickerController.sourceType = sourceType;
    if (completion) {
        objc_setAssociatedObject(pickerController, @selector(imagePickerController:didFinishPickingMediaWithInfo:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return pickerController;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    void (^completion)(NSDictionary *info, BOOL cancel) = objc_getAssociatedObject(picker, @selector(imagePickerController:didFinishPickingMediaWithInfo:));
    [picker dismissViewControllerAnimated:YES completion:^{
        if (completion) {
            completion(info, NO);
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    void (^completion)(NSDictionary *info, BOOL cancel) = objc_getAssociatedObject(picker, @selector(imagePickerController:didFinishPickingMediaWithInfo:));
    [picker dismissViewControllerAnimated:YES completion:^{
        if (completion) {
            completion(nil, YES);
        }
    }];
}

@end
