//
//  FWImagePreviewPluginImpl.h
//  
//
//  Created by wuyong on 2022/8/23.
//

#import "FWImagePreviewPlugin.h"
#import "FWImagePreviewController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImagePreviewPluginImpl

/// 默认图片预览插件
NS_SWIFT_NAME(ImagePreviewPluginImpl)
@interface FWImagePreviewPluginImpl : NSObject <FWImagePreviewPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWImagePreviewPluginImpl *sharedInstance NS_SWIFT_NAME(shared);

/// 自定义图片预览控制器句柄，默认nil时使用自带控制器，显示分页，点击图片|视频时关闭，present样式为zoom
@property (nonatomic, copy, nullable) FWImagePreviewController * (^previewControllerBlock)(void);

/// 图片预览全局自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(__kindof FWImagePreviewController *previewController);

@end

NS_ASSUME_NONNULL_END
