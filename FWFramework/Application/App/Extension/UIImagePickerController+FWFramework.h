/*!
 @header     UIImagePickerController+FWFramework.h
 @indexgroup FWFramework
 @brief      UIImagePickerController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/12
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIImagePickerController+FWFramework
 */
@interface UIImagePickerController (FWFramework)

/*!
 @brief 快速创建照片选择器，自动设置delegate
 
 @param sourceType 选择器类型
 @param completion 完成回调。参数1为回调数据，参数2为是否取消
 @return 照片选择器，不支持的返回nil
 */
+ (nullable instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                               completion:(void (^)(NSDictionary * _Nullable info, BOOL cancel))completion;

/*!
 @brief 快速创建照片选择器，可自定义dismiss流程，自动设置delegate
 
 @param sourceType 选择器类型
 @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
 @param completion 完成回调。参数1为照片选择器，2为回调数据，参数3为是否取消
 @return 照片选择器，不支持的返回nil
 */
+ (nullable instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                            shouldDismiss:(BOOL)shouldDismiss
                                               completion:(void (^)(UIImagePickerController * _Nullable picker, NSDictionary * _Nullable info, BOOL cancel))completion;

@end

NS_ASSUME_NONNULL_END
