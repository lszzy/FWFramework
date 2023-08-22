//
//  FWAppBundle.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWMediator.h"

NS_ASSUME_NONNULL_BEGIN

/**
 框架内置应用Bundle类，应用可替换
 @note 如果主应用存在FWFramework.bundle或主Bundle内包含对应图片|多语言，则优先使用；否则使用框架默认实现。
 FWFramework所需本地化翻译如下：完成|关闭|确定|取消|原有，配置同App本地化一致即可，如zh-Hans|en等
 */
NS_SWIFT_NAME(AppBundle)
@interface FWAppBundle : FWModuleBundle

#pragma mark - Image

/// 图片，导航栏返回，fw.navBack
@property (class, nonatomic, strong, readonly, nullable) UIImage *navBackImage;
/// 图片，导航栏关闭，fw.navClose
@property (class, nonatomic, strong, readonly, nullable) UIImage *navCloseImage;
/// 图片，视频播放大图，fw.videoPlay
@property (class, nonatomic, strong, readonly, nullable) UIImage *videoPlayImage;
/// 图片，视频暂停，fw.videoPause
@property (class, nonatomic, strong, readonly, nullable) UIImage *videoPauseImage;
/// 图片，视频开始，fw.videoStart
@property (class, nonatomic, strong, readonly, nullable) UIImage *videoStartImage;
/// 图片，相册多选，fw.pickerCheck
@property (class, nonatomic, strong, readonly, nullable) UIImage *pickerCheckImage;
/// 图片，相册选中，fw.pickerChecked
@property (class, nonatomic, strong, readonly, nullable) UIImage *pickerCheckedImage;

#pragma mark - String

/// 多语言，取消，fw.cancel
@property (class, nonatomic, copy, readonly) NSString *cancelButton;
/// 多语言，确定，fw.confirm
@property (class, nonatomic, copy, readonly) NSString *confirmButton;
/// 多语言，好的，fw.close
@property (class, nonatomic, copy, readonly) NSString *closeButton;
/// 多语言，完成，fw.done
@property (class, nonatomic, copy, readonly) NSString *doneButton;
/// 多语言，更多，fw.more
@property (class, nonatomic, copy, readonly) NSString *moreButton;
/// 多语言，编辑，fw.edit
@property (class, nonatomic, copy, readonly) NSString *editButton;
/// 多语言，预览，fw.preview
@property (class, nonatomic, copy, readonly) NSString *previewButton;
/// 多语言，原图，fw.original
@property (class, nonatomic, copy, readonly) NSString *originalButton;

/// 多语言，相册，fw.pickerAlbum
@property (class, nonatomic, copy, readonly) NSString *pickerAlbumTitle;
/// 多语言，无照片，fw.pickerEmpty
@property (class, nonatomic, copy, readonly) NSString *pickerEmptyTitle;
/// 多语言，无权限，fw.pickerDenied
@property (class, nonatomic, copy, readonly) NSString *pickerDeniedTitle;
/// 多语言，超出数量，fw.pickerExceed
@property (class, nonatomic, copy, readonly) NSString *pickerExceedTitle;

/// 多语言，下拉可以刷新，fw.refreshIdle
@property (class, nonatomic, copy, readonly) NSString *refreshIdleTitle;
/// 多语言，松开立即刷新，fw.refreshTriggered
@property (class, nonatomic, copy, readonly) NSString *refreshTriggeredTitle;
/// 多语言，正在刷新数据，fw.refreshLoading
@property (class, nonatomic, copy, readonly) NSString *refreshLoadingTitle;
/// 多语言，已经全部加载完毕，fw.refreshFinished
@property (class, nonatomic, copy, readonly) NSString *refreshFinishedTitle;

@end

NS_ASSUME_NONNULL_END
