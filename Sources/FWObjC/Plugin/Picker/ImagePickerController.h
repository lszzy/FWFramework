//
//  ImagePickerController.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>
#import "ImageCropController.h"

NS_ASSUME_NONNULL_BEGIN

@class __FWAsset;
@class __FWAssetGroup;

NS_SWIFT_NAME(ImagePickerController)
@interface __FWImagePickerController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, __FWImagePickerPreviewControllerDelegate>

@end

NS_ASSUME_NONNULL_END
