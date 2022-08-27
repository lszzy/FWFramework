//
//  FWImagePickerPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImagePickerPlugin

/// 图片选择插件过滤类型
typedef NS_OPTIONS(NSUInteger, FWImagePickerFilterType) {
    FWImagePickerFilterTypeImage      = 1 << 0,
    FWImagePickerFilterTypeLivePhoto  = 1 << 1,
    FWImagePickerFilterTypeVideo      = 1 << 2,
} NS_SWIFT_NAME(ImagePickerFilterType);

/// 图片选取插件协议，应用可自定义图片选取插件实现
NS_SWIFT_NAME(ImagePickerPlugin)
@protocol FWImagePickerPlugin <NSObject>
@optional

/// 从Camera选取单张图片插件方法
/// @param viewController 当前视图控制器
/// @param filterType 过滤类型，默认0同系统
/// @param allowsEditing 是否允许编辑
/// @param customBlock 自定义配置句柄，默认nil
/// @param completion 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
- (void)viewController:(UIViewController *)viewController
         showImageCamera:(FWImagePickerFilterType)filterType
           allowsEditing:(BOOL)allowsEditing
             customBlock:(nullable void (^)(id imagePicker))customBlock
              completion:(void (^)(id _Nullable object, id _Nullable result, BOOL cancel))completion;

/// 从图片库选取多张图片插件方法
/// @param viewController 当前视图控制器
/// @param filterType 过滤类型，默认0同系统
/// @param selectionLimit 最大选择数量
/// @param allowsEditing 是否允许编辑
/// @param customBlock 自定义配置句柄，默认nil
/// @param completion 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
- (void)viewController:(UIViewController *)viewController
         showImagePicker:(FWImagePickerFilterType)filterType
          selectionLimit:(NSInteger)selectionLimit
           allowsEditing:(BOOL)allowsEditing
             customBlock:(nullable void (^)(id imagePicker))customBlock
              completion:(void (^)(NSArray *objects, NSArray *results, BOOL cancel))completion;

@end

#pragma mark - UIViewController

/// UIViewController使用图片选取插件，全局可使用UIWindow.fw.topPresentedController
@interface UIViewController (FWImagePickerPlugin)

/// 自定义图片选取插件，未设置时自动从插件池加载
@property (nonatomic, strong, nullable) id<FWImagePickerPlugin> fw_imagePickerPlugin NS_REFINED_FOR_SWIFT;

/// 从Camera选取单张图片(简单版)
/// @param allowsEditing 是否允许编辑
/// @param completion 完成回调，主线程。参数1为图片，2为是否取消
- (void)fw_showImageCameraWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable image, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

/// 从Camera选取单张图片(详细版)
/// @param filterType 过滤类型，默认0同系统
/// @param allowsEditing 是否允许编辑
/// @param customBlock 自定义配置句柄，默认nil
/// @param completion 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
- (void)fw_showImageCameraWithFilterType:(FWImagePickerFilterType)filterType
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(nullable void (^)(id imagePicker))customBlock
                             completion:(void (^)(id _Nullable object, id _Nullable result, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

/// 从图片库选取单张图片(简单版)
/// @param allowsEditing 是否允许编辑
/// @param completion 完成回调，主线程。参数1为图片，2为是否取消
- (void)fw_showImagePickerWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable image, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

/// 从图片库选取多张图片(简单版)
/// @param selectionLimit 最大选择数量
/// @param allowsEditing 是否允许编辑
/// @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
- (void)fw_showImagePickerWithSelectionLimit:(NSInteger)selectionLimit
                              allowsEditing:(BOOL)allowsEditing
                                 completion:(void (^)(NSArray<UIImage *> *images, NSArray *results, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

/// 从图片库选取多张图片(详细版)
/// @param filterType 过滤类型，默认0同系统
/// @param selectionLimit 最大选择数量
/// @param allowsEditing 是否允许编辑
/// @param customBlock 自定义配置句柄，默认nil
/// @param completion 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
- (void)fw_showImagePickerWithFilterType:(FWImagePickerFilterType)filterType
                         selectionLimit:(NSInteger)selectionLimit
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(nullable void (^)(id imagePicker))customBlock
                             completion:(void (^)(NSArray *objects, NSArray *results, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

@end

/// UIView使用图片选取插件，内部使用UIView.fw.viewController
@interface UIView (FWImagePickerPlugin)

/// 从Camera选取单张图片(简单版)
/// @param allowsEditing 是否允许编辑
/// @param completion 完成回调，主线程。参数1为图片，2为是否取消
- (void)fw_showImageCameraWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable image, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

/// 从Camera选取单张图片(详细版)
/// @param filterType 过滤类型，默认0同系统
/// @param allowsEditing 是否允许编辑
/// @param customBlock 自定义配置句柄，默认nil
/// @param completion 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
- (void)fw_showImageCameraWithFilterType:(FWImagePickerFilterType)filterType
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(nullable void (^)(id imagePicker))customBlock
                             completion:(void (^)(id _Nullable object, id _Nullable result, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

/// 从图片库选取单张图片(简单版)
/// @param allowsEditing 是否允许编辑
/// @param completion 完成回调，主线程。参数1为图片，2为是否取消
- (void)fw_showImagePickerWithAllowsEditing:(BOOL)allowsEditing
                                completion:(void (^)(UIImage * _Nullable image, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

/// 从图片库选取多张图片(简单版)
/// @param selectionLimit 最大选择数量
/// @param allowsEditing 是否允许编辑
/// @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
- (void)fw_showImagePickerWithSelectionLimit:(NSInteger)selectionLimit
                              allowsEditing:(BOOL)allowsEditing
                                 completion:(void (^)(NSArray<UIImage *> *images, NSArray *results, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

/// 从图片库选取多张图片(详细版)
/// @param filterType 过滤类型，默认0同系统
/// @param selectionLimit 最大选择数量
/// @param allowsEditing 是否允许编辑
/// @param customBlock 自定义配置句柄，默认nil
/// @param completion 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
- (void)fw_showImagePickerWithFilterType:(FWImagePickerFilterType)filterType
                         selectionLimit:(NSInteger)selectionLimit
                          allowsEditing:(BOOL)allowsEditing
                            customBlock:(nullable void (^)(id imagePicker))customBlock
                             completion:(void (^)(NSArray *objects, NSArray *results, BOOL cancel))completion NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
