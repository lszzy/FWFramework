//
//  SDWebImageImpl.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// SDWebImage图片插件，启用SDWebImage子模块后生效
NS_SWIFT_NAME(SDWebImageImpl)
@interface FWSDWebImageImpl : NSObject

/// 单例模式
@property (class, nonatomic, readonly) FWSDWebImageImpl *sharedInstance;

/// 图片加载完成是否显示渐变动画，默认NO
@property (nonatomic, assign) BOOL fadeAnimated;

/// 图片自定义句柄，setImageURL开始时调用
@property (nonatomic, copy, nullable) void (^customBlock)(UIImageView *imageView);

@end

NS_ASSUME_NONNULL_END
