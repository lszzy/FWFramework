/*!
 @header     UIImagePickerController+FWFramework.h
 @indexgroup FWFramework
 @brief      UIImagePickerController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/12
 */

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIImagePickerController+FWFramework

/// 照片选择器过滤类型
typedef NS_OPTIONS(NSUInteger, FWImagePickerControllerFilterType) {
    FWImagePickerControllerFilterTypeImage      = 1 << 0,
    FWImagePickerControllerFilterTypeLivePhoto  = 1 << 1,
    FWImagePickerControllerFilterTypeVideo      = 1 << 2,
};

/*!
 @brief UIImagePickerController+FWFramework
 */
@interface UIImagePickerController (FWFramework)

/*!
 @brief 快速创建照片选择器(仅图片)，自动设置delegate
 
 @param sourceType 选择器类型
 @param completion 完成回调。参数1为回调图片，参数2为是否取消
 @return 照片选择器，不支持的返回nil
 */
+ (nullable instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                               completion:(void (^)(UIImage * _Nullable image, BOOL cancel))completion;

/*!
 @brief 快速创建照片选择器，可自定义dismiss流程，自动设置delegate
 
 @param sourceType 选择器类型
 @param filterType 过滤类型，默认0同系统
 @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
 @param completion 完成回调。参数1为照片选择器，2为回调对象，参数3为是否取消
 @return 照片选择器，不支持的返回nil
 */
+ (nullable instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                               filterType:(FWImagePickerControllerFilterType)filterType
                                            shouldDismiss:(BOOL)shouldDismiss
                                               completion:(void (^)(UIImagePickerController * _Nullable picker, id _Nullable object, BOOL cancel))completion;

@end

#pragma mark - PHPickerViewController+FWFramework

API_AVAILABLE(ios(14.0))
@interface PHPickerViewController (FWFramework)

/*!
 @brief 快速创建照片选择器(仅图片)，自动设置delegate
 
 @param selectionLimit 最大选择数量
 @param completion 完成回调，主线程。参数1为图片数组，参数2为是否取消
 @return 照片选择器
 */
+ (instancetype)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                          completion:(void (^)(NSArray<UIImage *> *images, BOOL cancel))completion;

/*!
 @brief 快速创建照片选择器，可自定义dismiss流程，自动设置delegate
 
 @param filterType 过滤类型，默认0同系统
 @param selectionLimit 最大选择数量
 @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
 @param completion 完成回调，主线程。参数1为照片选择器，2为对象数组，参数3为是否取消
 @return 照片选择器
 */
+ (instancetype)fwPickerControllerWithFilterType:(FWImagePickerControllerFilterType)filterType
                                  selectionLimit:(NSInteger)selectionLimit
                                   shouldDismiss:(BOOL)shouldDismiss
                                      completion:(void (^)(PHPickerViewController * _Nullable picker, NSArray *objects, BOOL cancel))completion;

@end

#pragma mark - PHPhotoLibrary+FWFramework

@interface PHPhotoLibrary (FWFramework)

/*!
 @brief 快速创建照片选择器(仅图片)
 
 @param selectionLimit 最大选择数量，iOS14以下只支持单选
 @param completion 完成回调，主线程。参数1为图片数组，参数2为是否取消
 @return 照片选择器
 */
+ (nullable __kindof UIViewController *)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                                                  completion:(void (^)(NSArray<UIImage *> *images, BOOL cancel))completion;

/*!
 @brief 快速创建照片选择器，可自定义dismiss流程
 
 @param filterType 过滤类型，默认0同系统
 @param selectionLimit 最大选择数量，iOS14以下只支持单选
 @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
 @param completion 完成回调，主线程。参数1为照片选择器，2为对象数组，参数3为是否取消
 @return 照片选择器
 */
+ (nullable __kindof UIViewController *)fwPickerControllerWithFilterType:(FWImagePickerControllerFilterType)filterType
                                                          selectionLimit:(NSInteger)selectionLimit
                                                           shouldDismiss:(BOOL)shouldDismiss
                                                              completion:(void (^)(__kindof UIViewController * _Nullable picker, NSArray *objects, BOOL cancel))completion;

@end

NS_ASSUME_NONNULL_END
