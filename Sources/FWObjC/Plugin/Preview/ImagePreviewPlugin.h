//
//  ImagePreviewPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ____FWImagePreviewPlugin

/// 图片预览插件协议，应用可自定义图片预览插件实现
NS_SWIFT_NAME(ImagePreviewPlugin)
@protocol ____FWImagePreviewPlugin <NSObject>
@required

/// 显示图片预览方法
/// @param viewController 当前视图控制器
/// @param imageURLs 预览图片列表，支持NSString|UIImage|PHLivePhoto|AVPlayerItem类型
/// @param imageInfos 自定义图片信息数组
/// @param currentIndex 当前索引，默认0
/// @param sourceView 来源视图句柄，支持UIView|NSValue.CGRect，默认nil
/// @param placeholderImage 占位图或缩略图句柄，默认nil
/// @param renderBlock 自定义渲染句柄，默认nil
/// @param customBlock 自定义配置句柄，默认nil
- (void)viewController:(UIViewController *)viewController
        showImagePreview:(NSArray *)imageURLs
              imageInfos:(nullable NSArray *)imageInfos
            currentIndex:(NSInteger)currentIndex
              sourceView:(nullable id _Nullable (^)(NSInteger index))sourceView
        placeholderImage:(nullable UIImage * _Nullable (^)(NSInteger index))placeholderImage
             renderBlock:(nullable void (^)(__kindof UIView *view, NSInteger index))renderBlock
             customBlock:(nullable void (^)(id imagePreview))customBlock;

@end

NS_ASSUME_NONNULL_END
