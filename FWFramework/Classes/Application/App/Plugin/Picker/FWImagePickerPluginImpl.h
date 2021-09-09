/*!
 @header     FWImagePickerPluginImpl.h
 @indexgroup FWFramework
 @brief      FWImagePickerPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWImagePickerPlugin.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImagePickerPluginImpl

/// 默认图片选取插件
@interface FWImagePickerPluginImpl : NSObject <FWImagePickerPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWImagePickerPluginImpl *sharedInstance;

@end

NS_ASSUME_NONNULL_END
