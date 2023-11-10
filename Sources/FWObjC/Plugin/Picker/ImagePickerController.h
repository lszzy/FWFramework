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

@property(nullable, nonatomic, weak) id<__FWImagePickerControllerDelegate> imagePickerControllerDelegate;
/// 自定义预览控制器句柄，优先级低于delegate
@property(nullable, nonatomic, copy) __FWImagePickerPreviewController * (^previewControllerBlock)(void);
/// 自定义相册控制器句柄，优先级低于delegate
@property(nullable, nonatomic, copy) __FWImageAlbumController * (^albumControllerBlock)(void);
/// 自定义cell展示句柄，cellForItem自动调用，优先级低于delegate
@property(nullable, nonatomic, copy) void (^customCellBlock)(__FWImagePickerCollectionCell *cell, NSIndexPath *indexPath);

/// 图片选取完成回调句柄，优先级低于delegate
@property(nullable, nonatomic, copy) void (^didFinishPicking)(NSArray<__FWAsset *> *imagesAssetArray);
/// 图片选取取消回调句柄，优先级低于delegate
@property(nullable, nonatomic, copy) void (^didCancelPicking)(void);

@property(nullable, nonatomic, strong) UIColor *toolBarBackgroundColor;
@property(nullable, nonatomic, strong) UIColor *toolBarTintColor;

/// 当前titleView，默认不可点击，contentType方式会自动切换点击状态
@property(nonatomic, strong, readonly) __FWToolbarTitleView *titleView;
/// 标题视图accessoryImage，默认nil，contentType方式会自动设置
@property(nullable, nonatomic, strong) UIImage *titleAccessoryImage;

/*
 * 图片的最小尺寸，布局时如果有剩余空间，会将空间分配给图片大小，所以最终显示出来的大小不一定等于minimumImageWidth。默认是75。
 * @warning collectionViewLayout 和 collectionView 可能有设置 sectionInsets 和 contentInsets，所以设置几行不可以简单的通过 screenWdith / columnCount 来获得
 */
@property(nonatomic, assign) CGFloat minimumImageWidth;
/// 图片显示列数，默认0使用minimumImageWidth自动计算，指定后固定列数
@property(nonatomic, assign) NSInteger imageColumnCount;

@property(nonatomic, strong, readonly) UICollectionViewFlowLayout *collectionViewLayout;
@property(nonatomic, strong, readonly) UICollectionView *collectionView;

@property(nonatomic, strong, readonly) UIView *operationToolBarView;
/// 自定义工具栏高度，默认同系统
@property(nonatomic, assign) CGFloat operationToolBarHeight;
@property(nonatomic, assign) CGFloat toolBarPaddingHorizontal;
@property(nonatomic, strong, readonly) UIButton *previewButton;
@property(nonatomic, strong, readonly) UIButton *sendButton;

/// 也可以直接传入 __FWAssetGroup，然后读取其中的 __FWAsset 并储存到 imagesAssetArray 中，传入后会赋值到 __FWAssetGroup，并自动刷新 UI 展示
- (void)refreshWithAssetsGroup:(__FWAssetGroup * _Nullable)assetsGroup;

/// 根据filterType刷新，自动选取第一个符合条件的相册，自动初始化并使用albumController
- (void)refreshWithFilterType:(__FWImagePickerFilterType)filterType;

@property(nullable, nonatomic, strong, readonly) NSMutableArray<__FWAsset *> *imagesAssetArray;
@property(nullable, nonatomic, strong, readonly) __FWAssetGroup *assetsGroup;
/// 图片过滤类型，默认0不过滤，影响requestImage结果和previewController预览效果
@property(nonatomic, assign) __FWImagePickerFilterType filterType;

/// 当前被选择的图片对应的 __FWAsset 对象数组
@property(nullable, nonatomic, strong, readonly) NSMutableArray<__FWAsset *> *selectedImageAssetArray;

/// 是否允许图片多选，默认为 YES。如果为 NO，则不显示 checkbox 和底部工具栏
@property(nonatomic, assign) BOOL allowsMultipleSelection;

/// 是否禁用预览时左右滚动，默认NO。如果为YES，单选时不能左右滚动切换图片
@property(nonatomic, assign) BOOL previewScrollDisabled;

/// 最多可以选择的图片数，默认为9
@property(nonatomic, assign) NSUInteger maximumSelectImageCount;

/// 最少需要选择的图片数，默认为 0
@property(nonatomic, assign) NSUInteger minimumSelectImageCount;

/// 是否显示默认loading，优先级低于delegate，默认YES
@property(nonatomic, assign) BOOL showsDefaultLoading;

/// 是否需要请求图片资源，默认NO，开启后会先requestImagesAssetArray再回调didFinishPicking
@property(nonatomic, assign) BOOL shouldRequestImage;

/// 图片过滤类型转换为相册内容类型
+ (__FWAlbumContentType)albumContentTypeWithFilterType:(__FWImagePickerFilterType)filterType;

/**
 * 检查并下载一组资源，如果资源仍未从 iCloud 中成功下载，则会发出请求从 iCloud 加载资源，下载完成后，主线程回调。
 * 图片资源对象和结果信息保存在__FWAsset.requestObject，自动根据过滤类型返回UIImage|PHLivePhoto|NSURL
 */
+ (void)requestImagesAssetArray:(NSArray<__FWAsset *> *)imagesAssetArray
                     filterType:(__FWImagePickerFilterType)filterType
                      useOrigin:(BOOL)useOrigin
                     completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
