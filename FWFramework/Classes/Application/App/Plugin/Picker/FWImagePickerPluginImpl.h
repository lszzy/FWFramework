/*!
 @header     FWImagePickerPluginImpl.h
 @indexgroup FWFramework
 @brief      FWImagePickerPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWImagePickerPlugin.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIImagePickerController+FWImagePickerPluginImpl

@class FWImageCropController;

/*!
 @brief UIImagePickerController+FWImagePickerPluginImpl
 */
@interface UIImagePickerController (FWImagePickerPluginImpl)

/*!
 @brief 快速创建单选照片选择器(仅图片)，自动设置delegate
 
 @param sourceType 选择器类型
 @param allowsEditing 是否允许编辑
 @param completion 完成回调。参数1为图片，2为信息字典，3为是否取消
 @return 照片选择器，不支持的返回nil
 */
+ (nullable instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                            allowsEditing:(BOOL)allowsEditing
                                               completion:(void (^)(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL cancel))completion;

/*!
 @brief 快速创建单选照片选择器，可自定义dismiss流程，自动设置delegate
 
 @param sourceType 选择器类型
 @param filterType 过滤类型，默认0同系统
 @param allowsEditing 是否允许编辑
 @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
 @param completion 完成回调。参数1为照片选择器，2为对象(UIImage|PHLivePhoto|NSURL)，3为信息字典，4为是否取消
 @return 照片选择器，不支持的返回nil
 */
+ (nullable instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                               filterType:(FWImagePickerFilterType)filterType
                                            allowsEditing:(BOOL)allowsEditing
                                            shouldDismiss:(BOOL)shouldDismiss
                                               completion:(void (^)(UIImagePickerController * _Nullable picker, id _Nullable object, NSDictionary * _Nullable info, BOOL cancel))completion;

/*!
 @brief 快速创建单选照片选择器，使用自定义裁剪控制器编辑
 
 @param sourceType 选择器类型
 @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
 @param completion 完成回调。参数1为图片，2为信息字典，3为是否取消
 @return 照片选择器，不支持的返回nil
 */
+ (nullable instancetype)fwPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                                           cropController:(nullable FWImageCropController * _Nullable (^)(UIImage *image))cropController
                                               completion:(void (^)(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL cancel))completion;

@end

#pragma mark - PHPickerViewController+FWImagePickerPluginImpl

API_AVAILABLE(ios(14.0))
@interface PHPickerViewController (FWImagePickerPluginImpl)

/*!
 @brief 图片选择器选择视频时临时文件存放目录，使用完成后需自行删除
 */
@property (class, nonatomic, copy, readonly) NSString *fwPickerControllerVideoCachePath;

/*!
 @brief 快速创建多选照片选择器(仅图片)，自动设置delegate
 
 @param selectionLimit 最大选择数量
 @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
 @return 照片选择器
 */
+ (instancetype)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                          completion:(void (^)(NSArray<UIImage *> *images, NSArray<PHPickerResult *> *results, BOOL cancel))completion;

/*!
 @brief 快速创建多选照片选择器，可自定义dismiss流程，自动设置delegate
 @discussion 当选择视频时，completion回调对象为NSURL临时文件路径，使用完毕后可手工删除或等待系统自动删除
 
 @param filterType 过滤类型，默认0同系统
 @param selectionLimit 最大选择数量
 @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
 @param completion 完成回调，主线程。参数1为照片选择器，2为对象数组(UIImage|PHLivePhoto|NSURL)，3为结果数组，4为是否取消
 @return 照片选择器
 */
+ (instancetype)fwPickerControllerWithFilterType:(FWImagePickerFilterType)filterType
                                  selectionLimit:(NSInteger)selectionLimit
                                   shouldDismiss:(BOOL)shouldDismiss
                                      completion:(void (^)(PHPickerViewController * _Nullable picker, NSArray *objects, NSArray<PHPickerResult *> *results, BOOL cancel))completion;

/*!
 @brief 快速创建单选照片选择器(仅图片)，使用自定义裁剪控制器编辑
 
 @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
 @param completion 完成回调，主线程。参数1为图片，2为结果信息，3为是否取消
 @return 照片选择器
 */
+ (instancetype)fwPickerControllerWithCropController:(nullable FWImageCropController * _Nullable (^)(UIImage *image))cropController
                                          completion:(void (^)(UIImage * _Nullable image, PHPickerResult * _Nullable result, BOOL cancel))completion;

@end

#pragma mark - PHPhotoLibrary+FWImagePickerPluginImpl

@interface PHPhotoLibrary (FWImagePickerPluginImpl)

/*!
 @brief 快速创建照片选择器(仅图片)
 
 @param selectionLimit 最大选择数量，iOS14以下只支持单选
 @param allowsEditing 是否允许编辑，仅iOS14以下支持编辑
 @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
 @return 照片选择器
 */
+ (nullable __kindof UIViewController *)fwPickerControllerWithSelectionLimit:(NSInteger)selectionLimit
                                                               allowsEditing:(BOOL)allowsEditing
                                                                  completion:(void (^)(NSArray<UIImage *> *images, NSArray *results, BOOL cancel))completion;

/*!
 @brief 快速创建照片选择器，可自定义dismiss流程
 
 @param filterType 过滤类型，默认0同系统
 @param selectionLimit 最大选择数量，iOS14以下只支持单选
 @param allowsEditing 是否允许编辑，仅iOS14以下支持编辑
 @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
 @param completion 完成回调，主线程。参数1为照片选择器，2为对象数组(UIImage|PHLivePhoto|NSURL)，3位结果数组，4为是否取消
 @return 照片选择器
 */
+ (nullable __kindof UIViewController *)fwPickerControllerWithFilterType:(FWImagePickerFilterType)filterType
                                                          selectionLimit:(NSInteger)selectionLimit
                                                           allowsEditing:(BOOL)allowsEditing
                                                           shouldDismiss:(BOOL)shouldDismiss
                                                              completion:(void (^)(__kindof UIViewController * _Nullable picker, NSArray *objects, NSArray *results, BOOL cancel))completion;

/*!
 @brief 快速创建单选照片选择器(仅图片)，使用自定义裁剪控制器编辑
 
 @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
 @param completion 完成回调，主线程。参数1为图片，2为结果信息，3为是否取消
 @return 照片选择器
 */
+ (nullable __kindof UIViewController *)fwPickerControllerWithCropController:(nullable FWImageCropController * _Nullable (^)(UIImage *image))cropController
                                                                  completion:(void (^)(UIImage * _Nullable image, id _Nullable result, BOOL cancel))completion;

@end

#pragma mark - FWImagePickerPluginImpl

/// 默认图片选取插件
@interface FWImagePickerPluginImpl : NSObject <FWImagePickerPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWImagePickerPluginImpl *sharedInstance;

/// 是否禁用iOS14+PHPickerViewController(支持多选)，默认NO；设为YES后始终使用UIImagePickerController(仅支持单选)
@property (nonatomic, assign) BOOL photoPickerDisabled;

/// 编辑单张图片时是否启用自定义裁剪控制器，默认NO，使用系统方式
@property (nonatomic, assign) BOOL cropControllerEnabled;

/// 图片选取自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(__kindof UIViewController *pickerController);

/// 自定义裁剪控制器句柄，启用自定义裁剪后生效
@property (nonatomic, copy, nullable) FWImageCropController * _Nullable (^cropControllerBlock)(UIImage *image);

@end

NS_ASSUME_NONNULL_END
