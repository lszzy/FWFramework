/*!
 @header     UIImagePickerController+FWFramework.h
 @indexgroup FWFramework
 @brief      UIImagePickerController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/12
 */

#import <UIKit/UIKit.h>

/*!
 @brief UIImagePickerController+FWFramework
 */
@interface UIImagePickerController (FWFramework) <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

/*!
 @brief 快速创建照片选择器，自动设置delegate
 
 @param sourceType 选择器类型
 @param completion 完成回调，取消时返回nil
 @return 照片选择器，不支持的返回nil
 */
+ (instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType completion:(void(^)(NSDictionary *info))completion;

@end
