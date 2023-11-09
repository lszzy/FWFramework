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

typedef NS_ENUM(NSUInteger, __FWAssetDownloadStatus) {
    __FWAssetDownloadStatusSucceed,
    __FWAssetDownloadStatusDownloading,
    __FWAssetDownloadStatusCanceled,
    __FWAssetDownloadStatusFailed
};

typedef NS_ENUM(NSUInteger, __FWAlbumContentType) {
    __FWAlbumContentTypeAll,
    __FWAlbumContentTypeOnlyPhoto,
    __FWAlbumContentTypeOnlyVideo,
    __FWAlbumContentTypeOnlyAudio,
    __FWAlbumContentTypeOnlyLivePhoto
};

typedef NS_ENUM(NSUInteger, __FWAlbumSortType) {
    __FWAlbumSortTypePositive,
    __FWAlbumSortTypeReverse
};

typedef NS_OPTIONS(NSUInteger, __FWImagePickerFilterType) {
    __FWImagePickerFilterTypeImage      = 1 << 0,
    __FWImagePickerFilterTypeLivePhoto  = 1 << 1,
    __FWImagePickerFilterTypeVideo      = 1 << 2,
};

#pragma mark - __FWImageAlbumController

@class __FWImageAlbumTableCell;
@class __FWImagePickerController;
@class __FWImageAlbumController;

/// 相册列表事件代理
NS_SWIFT_NAME(ImageAlbumControllerDelegate)
@protocol __FWImageAlbumControllerDelegate <NSObject>

@optional
/// 需提供__FWImagePickerController 用于展示九宫格图片列表
- (__FWImagePickerController *)imagePickerControllerForAlbumController:(__FWImageAlbumController *)albumController;

/// 点击相簿里某一行时被调用，未实现时默认打开imagePickerController
- (void)albumController:(__FWImageAlbumController *)albumController didSelectAssetsGroup:(__FWAssetGroup *)assetsGroup;

/// 自定义相册列表cell展示，cellForRow自动调用
- (void)albumController:(__FWImageAlbumController *)albumController customCell:(__FWImageAlbumTableCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/// 取消查看相册列表后被调用，未实现时自动转发给当前imagePickerController
- (void)albumControllerDidCancel:(__FWImageAlbumController *)albumController;

/// 即将需要显示 Loading 时调用，可自定义Loading效果
- (void)albumControllerWillStartLoading:(__FWImageAlbumController *)albumController;

/// 需要隐藏 Loading 时调用，可自定义Loading效果
- (void)albumControllerDidFinishLoading:(__FWImageAlbumController *)albumController;

/// 相册列表未授权时调用，可自定义空界面等
- (void)albumControllerWillShowDenied:(__FWImageAlbumController *)albumController;

/// 相册列表为空时调用，可自定义空界面等
- (void)albumControllerWillShowEmpty:(__FWImageAlbumController *)albumController;

@end

/**
 *  当前设备照片里的相簿列表，使用方式：
 *  1. 使用 init 初始化。
 *  2. 指定一个 albumControllerDelegate，并实现 @required 方法。
 *
 *  注意，iOS 访问相册需要得到授权，建议先询问用户授权([__FWAssetsManager requestAuthorization:])，通过了再进行 __FWImageAlbumController 的初始化工作。
 */
NS_SWIFT_NAME(ImageAlbumController)
@interface __FWImageAlbumController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property(nullable, nonatomic, strong) UIColor *toolBarBackgroundColor;
@property(nullable, nonatomic, strong) UIColor *toolBarTintColor;

/// 背景视图，可设置背景色，添加点击手势等
@property(nonatomic, strong, readonly) UIView *backgroundView;
/// 相册只读列表视图
@property(nonatomic, strong, readonly) UITableView *tableView;

/// 相册列表 cell 的高度，同时也是相册预览图的宽高，默认76
@property(nonatomic, assign) CGFloat albumTableViewCellHeight;
/// 相册列表视图最大高度，默认0不限制
@property(nonatomic, assign) CGFloat maximumTableViewHeight;
/// 相册列表附加显示高度，当内容高度小于最大高度时生效，默认0
@property(nonatomic, assign) CGFloat additionalTableViewHeight;
/// 当前相册列表实际显示高度，只读
@property(nonatomic, assign, readonly) CGFloat tableViewHeight;

/// 当前相册列表，异步加载
@property(nonatomic, strong, readonly) NSMutableArray<__FWAssetGroup *> *albumsArray;

/// 相册列表事件代理
@property(nullable, nonatomic, weak) id<__FWImageAlbumControllerDelegate> albumControllerDelegate;

/// 自定义pickerController句柄，优先级低于delegate
@property(nullable, nonatomic, copy) __FWImagePickerController * (^pickerControllerBlock)(void);

/// 自定义cell展示句柄，cellForRow自动调用，优先级低于delegate
@property(nullable, nonatomic, copy) void (^customCellBlock)(__FWImageAlbumTableCell *cell, NSIndexPath *indexPath);

/// 相册列表默认封面图，默认nil
@property(nullable, nonatomic, strong) UIImage *defaultPosterImage;

/// 相册展示内容的类型，可以控制只展示照片、视频或音频的其中一种，也可以同时展示所有类型的资源，默认展示所有类型的资源。
@property(nonatomic, assign) __FWAlbumContentType contentType;

/// 当前选中相册，默认nil
@property(nullable, nonatomic, strong, readonly) __FWAssetGroup *assetsGroup;

/// 是否显示默认loading，优先级低于delegate，默认YES
@property(nonatomic, assign) BOOL showsDefaultLoading;

/// 是否直接进入第一个相册列表，默认NO
@property(nonatomic, assign) BOOL pickDefaultAlbumGroup;

@end

#pragma mark - __FWImagePickerPreviewController

@class __FWImageCropController;
@class __FWImagePickerController;
@class __FWImagePreviewController;
@class __FWImagePickerPreviewController;
@class __FWImagePickerPreviewCollectionCell;

NS_SWIFT_NAME(ImagePickerPreviewControllerDelegate)
@protocol __FWImagePickerPreviewControllerDelegate <NSObject>

@optional

/// 完成选中图片回调，未实现时自动转发给当前imagePickerController
- (void)imagePickerPreviewController:(__FWImagePickerPreviewController *)imagePickerPreviewController didFinishPickingImageWithImagesAssetArray:(NSArray<__FWAsset *> *)imagesAssetArray;
/// 即将选中图片
- (void)imagePickerPreviewController:(__FWImagePickerPreviewController *)imagePickerPreviewController willCheckImageAtIndex:(NSInteger)index;
/// 已经选中图片
- (void)imagePickerPreviewController:(__FWImagePickerPreviewController *)imagePickerPreviewController didCheckImageAtIndex:(NSInteger)index;
/// 即将取消选中图片
- (void)imagePickerPreviewController:(__FWImagePickerPreviewController *)imagePickerPreviewController willUncheckImageAtIndex:(NSInteger)index;
/// 已经取消选中图片
- (void)imagePickerPreviewController:(__FWImagePickerPreviewController *)imagePickerPreviewController didUncheckImageAtIndex:(NSInteger)index;
/// 选中数量变化时调用，仅多选有效
- (void)imagePickerPreviewController:(__FWImagePickerPreviewController *)imagePickerPreviewController willChangeCheckedCount:(NSInteger)checkedCount;
/// 即将需要显示 Loading 时调用
- (void)imagePickerPreviewControllerWillStartLoading:(__FWImagePickerPreviewController *)imagePickerPreviewController;
/// 即将需要隐藏 Loading 时调用
- (void)imagePickerPreviewControllerDidFinishLoading:(__FWImagePickerPreviewController *)imagePickerPreviewController;
/// 已经选中数量超过最大选择数量时被调用，默认弹窗提示
- (void)imagePickerPreviewControllerWillShowExceed:(__FWImagePickerPreviewController *)imagePickerPreviewController;
/// 图片预览界面关闭返回时被调用
- (void)imagePickerPreviewControllerDidCancel:(__FWImagePickerPreviewController *)imagePickerPreviewController;
/// 自定义编辑按钮点击事件，启用编辑时生效，未实现时使用图片裁剪控制器
- (void)imagePickerPreviewController:(__FWImagePickerPreviewController *)imagePickerPreviewController willEditImageAtIndex:(NSInteger)index;
/// 自定义图片裁剪控制器，启用编辑时生效，未实现时使用默认配置
- (__FWImageCropController *)imageCropControllerForPreviewController:(__FWImagePickerPreviewController *)previewController image:(UIImage *)image;
/// 自定义编辑cell展示，cellForRow自动调用
- (void)imagePickerPreviewController:(__FWImagePickerPreviewController *)imagePickerPreviewController customCell:(__FWImagePickerPreviewCollectionCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

NS_SWIFT_NAME(ImagePickerPreviewController)
@interface __FWImagePickerPreviewController : __FWImagePreviewController <UICollectionViewDataSource, UICollectionViewDelegate, __FWImagePreviewViewDelegate>

@property(nullable, nonatomic, weak) id<__FWImagePickerPreviewControllerDelegate> delegate;
/// 自定义裁剪控制器句柄，优先级低于delegate
@property(nullable, nonatomic, copy) __FWImageCropController * (^cropControllerBlock)(UIImage *image);
/// 自定义cell展示句柄，cellForItem自动调用，优先级低于delegate
@property(nullable, nonatomic, copy) void (^customCellBlock)(__FWImagePickerPreviewCollectionCell *cell, NSIndexPath *indexPath);

@property(nullable, nonatomic, strong) UIColor *toolBarBackgroundColor;
@property(nullable, nonatomic, strong) UIColor *toolBarTintColor;

@property(nonatomic, strong, readonly) UIView *topToolBarView;
@property(nonatomic, assign) CGFloat toolBarPaddingHorizontal;
@property(nonatomic, strong, readonly) UIButton *backButton;
@property(nonatomic, strong, readonly) UIButton *checkboxButton;
@property(nonatomic, strong) UIImage *checkboxImage;
@property(nonatomic, strong) UIImage *checkboxCheckedImage;

@property(nonatomic, strong, readonly) UIView *bottomToolBarView;
/// 自定义底部工具栏高度，默认同系统
@property(nonatomic, assign) CGFloat bottomToolBarHeight;
@property(nonatomic, strong, readonly) UIButton *sendButton;
@property(nonatomic, strong, readonly) UIButton *editButton;
@property(nonatomic, strong, readonly) UIButton *originImageCheckboxButton;
@property(nonatomic, strong) UIImage *originImageCheckboxImage;
@property(nonatomic, strong) UIImage *originImageCheckboxCheckedImage;
/// 是否使用原图，不显示原图按钮时默认YES，显示原图按钮时默认NO
@property(nonatomic, assign) BOOL shouldUseOriginImage;
/// 是否显示原图按钮，默认NO，设置后会修改shouldUseOriginImage
@property(nonatomic, assign) BOOL showsOriginImageCheckboxButton;
/// 是否显示编辑按钮，默认YES
@property(nonatomic, assign) BOOL showsEditButton;

/// 是否显示编辑collectionView，默认YES，仅多选生效
@property(nonatomic, assign) BOOL showsEditCollectionView;
@property(nonatomic, strong, readonly) UICollectionViewFlowLayout *editCollectionViewLayout;
@property(nonatomic, strong, readonly) UICollectionView *editCollectionView;
/// 编辑collectionView总高度，默认80
@property(nonatomic, assign) CGFloat editCollectionViewHeight;
/// 编辑collectionCell大小，默认(60, 60)
@property(nonatomic, assign) CGSize editCollectionCellSize;

/// 是否显示默认loading，优先级低于delegate，默认YES
@property(nonatomic, assign) BOOL showsDefaultLoading;

/// 由于组件需要通过本地图片的 __FWAsset 对象读取图片的详细信息，因此这里的需要传入的是包含一个或多个 __FWAsset 对象的数组
@property(nullable, nonatomic, strong) NSMutableArray<__FWAsset *> *imagesAssetArray;
@property(nullable, nonatomic, strong) NSMutableArray<__FWAsset *> *selectedImageAssetArray;

@property(nonatomic, assign) __FWAssetDownloadStatus downloadStatus;

/// 最多可以选择的图片数，默认为9
@property(nonatomic, assign) NSUInteger maximumSelectImageCount;
/// 最少需要选择的图片数，默认为 0
@property(nonatomic, assign) NSUInteger minimumSelectImageCount;

/**
 *  更新数据并刷新 UI，手工调用
 *
 *  @param imageAssetArray         包含所有需要展示的图片的数组
 *  @param selectedImageAssetArray 包含所有需要展示的图片中已经被选中的图片的数组
 *  @param currentImageIndex       当前展示的图片在 imageAssetArray 的索引
 *  @param singleCheckMode         是否为单选模式，如果是单选模式，则不显示 checkbox
 *  @param previewMode         是否是预览模式，如果是预览模式，图片取消选中时editCollectionView会置灰而不是隐藏
 */
- (void)updateImagePickerPreviewViewWithImagesAssetArray:(NSMutableArray<__FWAsset *> * _Nullable)imageAssetArray
                                 selectedImageAssetArray:(NSMutableArray<__FWAsset *> * _Nullable)selectedImageAssetArray
                                       currentImageIndex:(NSInteger)currentImageIndex
                                         singleCheckMode:(BOOL)singleCheckMode
                                             previewMode:(BOOL)previewMode;

@end

#pragma mark - __FWImagePickerController

@class __FWImagePickerCollectionCell;
@class __FWImagePickerController;
@class __FWToolbarTitleView;

NS_SWIFT_NAME(ImagePickerControllerDelegate)
@protocol __FWImagePickerControllerDelegate <NSObject>

@optional

/**
 *  创建一个 ImagePickerPreviewViewController 用于预览图片
 */
- (__FWImagePickerPreviewController *)imagePickerPreviewControllerForImagePickerController:(__FWImagePickerController *)imagePickerController;

/**
 *  控制照片的排序，若不实现，默认为 __FWAlbumSortTypePositive
 *  @note 注意返回值会决定第一次进来相片列表时列表默认的滚动位置，如果为 __FWAlbumSortTypePositive，则列表默认滚动到底部，如果为 __FWAlbumSortTypeReverse，则列表默认滚动到顶部。
 */
- (__FWAlbumSortType)albumSortTypeForImagePickerController:(__FWImagePickerController *)imagePickerController;

/**
 *  选择图片完毕后被调用（点击 sendButton 后被调用），如果previewController没有实现完成回调方法，也会走到这个方法
 *
 *  @param imagePickerController 对应的 __FWImagePickerController
 *  @param imagesAssetArray          包含被选择的图片的 __FWAsset 对象的数组。
 */
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController didFinishPickingImageWithImagesAssetArray:(NSArray<__FWAsset *> *)imagesAssetArray;

/**
 *  取消选择图片后被调用，如果albumController没有实现取消回调方法，也会走到这个方法
 */
- (void)imagePickerControllerDidCancel:(__FWImagePickerController *)imagePickerController;

/**
 *  cell 被点击时调用（先调用这个接口，然后才去走预览大图的逻辑），注意这并非指选中 checkbox 事件
 *
 *  @param imagePickerController        对应的 __FWImagePickerController
 *  @param imageAsset                       被选中的图片的 __FWAsset 对象
 *  @param imagePickerPreviewController 选中图片后进行图片预览的 viewController
 */
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController didSelectImageWithImagesAsset:(__FWAsset *)imageAsset afterImagePickerPreviewControllerUpdate:(__FWImagePickerPreviewController *)imagePickerPreviewController;

/// 是否能够选中 checkbox
- (BOOL)imagePickerController:(__FWImagePickerController *)imagePickerController shouldCheckImageAtIndex:(NSInteger)index;

/// 即将选中 checkbox 时调用
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController willCheckImageAtIndex:(NSInteger)index;

/// 选中了 checkbox 之后调用
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController didCheckImageAtIndex:(NSInteger)index;

/// 即将取消选中 checkbox 时调用
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController willUncheckImageAtIndex:(NSInteger)index;

/// 取消了 checkbox 选中之后调用
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController didUncheckImageAtIndex:(NSInteger)index;

/// 选中数量变化时调用，仅多选有效
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController willChangeCheckedCount:(NSInteger)checkedCount;

/// 自定义图片九宫格cell展示，cellForRow自动调用
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController customCell:(__FWImagePickerCollectionCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/// 标题视图被点击时调用，返回弹出的相册列表控制器
- (__FWImageAlbumController *)albumControllerForImagePickerController:(__FWImagePickerController *)imagePickerController;

/// 即将显示弹出相册列表控制器时调用
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController willShowAlbumController:(__FWImageAlbumController *)albumController;

/// 即将隐藏弹出相册列表控制器时调用
- (void)imagePickerController:(__FWImagePickerController *)imagePickerController willHideAlbumController:(__FWImageAlbumController *)albumController;

/**
 *  即将需要显示 Loading 时调用
 */
- (void)imagePickerControllerWillStartLoading:(__FWImagePickerController *)imagePickerController;

/**
 *  即将需要隐藏 Loading 时调用
 */
- (void)imagePickerControllerDidFinishLoading:(__FWImagePickerController *)imagePickerController;

/// 图片未授权时调用，可自定义空界面等
- (void)imagePickerControllerWillShowDenied:(__FWImagePickerController *)imagePickerController;

/// 图片为空时调用，可自定义空界面等
- (void)imagePickerControllerWillShowEmpty:(__FWImagePickerController *)imagePickerController;

/// 已经选中数量超过最大选择数量时被调用，默认弹窗提示
- (void)imagePickerControllerWillShowExceed:(__FWImagePickerController *)imagePickerController;

@end

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
