/*!
 @header     FWImagePreviewPluginImpl.h
 @indexgroup FWFramework
 @brief      FWImagePreviewPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWImagePreviewPlugin.h"
#import "FWImagePreviewController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImagePreviewPluginImpl

/// 默认图片预览插件
@interface FWImagePreviewPluginImpl : NSObject <FWImagePreviewPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWImagePreviewPluginImpl *sharedInstance;

@end

NS_ASSUME_NONNULL_END
