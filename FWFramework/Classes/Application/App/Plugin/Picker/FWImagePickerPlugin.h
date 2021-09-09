/*!
 @header     FWImagePickerPlugin.h
 @indexgroup FWFramework
 @brief      FWImagePickerPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImagePickerPlugin

/// 图片选取插件协议，应用可自定义图片选取插件实现
@protocol FWImagePickerPlugin <NSObject>

@optional

@end

/// UIViewController使用图片选取插件
@interface UIViewController (FWImagePickerPlugin)

@end

NS_ASSUME_NONNULL_END
