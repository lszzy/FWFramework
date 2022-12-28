//
//  ImagePickerPluginImpl.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ImagePickerPlugin.h"
#import "ImageCropController.h"
#import "ImagePickerControllerImpl.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImagePickerPluginImpl

/// 默认图片选取插件
NS_SWIFT_NAME(ImagePickerPluginImpl)
@interface FWImagePickerPluginImpl : NSObject <FWImagePickerPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWImagePickerPluginImpl *sharedInstance NS_SWIFT_NAME(shared);

/// 是否禁用iOS14+PHPickerViewController(支持多选)，默认NO；设为YES后始终使用UIImagePickerController(仅支持单选)
@property (nonatomic, assign) BOOL photoPickerDisabled;

/// 编辑单张图片时是否启用自定义裁剪控制器，默认NO，使用系统方式
@property (nonatomic, assign) BOOL cropControllerEnabled;

/// 自定义图片裁剪控制器句柄，启用自定义裁剪后生效
@property (nonatomic, copy, nullable) FWImageCropController * (^cropControllerBlock)(UIImage *image);

/// 图片选取全局自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(__kindof UIViewController *pickerController);

@end

NS_ASSUME_NONNULL_END
