/*!
 @header     FWImagePreviewPlugin.h
 @indexgroup FWFramework
 @brief      FWImagePreviewPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImagePreviewPlugin

/// 图片预览插件协议，应用可自定义图片预览插件实现
@protocol FWImagePreviewPlugin <NSObject>

@optional

@end

/// UIViewController使用图片预览插件
@interface UIViewController (FWImagePreviewPlugin)

@end

NS_ASSUME_NONNULL_END
