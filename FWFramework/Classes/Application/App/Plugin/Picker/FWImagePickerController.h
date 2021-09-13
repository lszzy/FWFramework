/*!
 @header     FWImagePickerController.h
 @indexgroup FWFramework
 @brief      FWImagePickerController
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <UIKit/UIKit.h>
#import "FWAssetManager.h"
#import "FWImagePreviewController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImageAlbumController

@class FWImagePickerController;
@class FWImageAlbumController;

@protocol FWImageAlbumControllerDelegate <NSObject>

@required
/// 点击相簿里某一行时，需要给一个 FWImagePickerController 对象用于展示九宫格图片列表
- (FWImagePickerController *)imagePickerControllerForAlbumController:(FWImageAlbumController *)albumController;

@optional
/**
 *  取消查看相册列表后被调用
 */
- (void)albumControllerDidCancel:(FWImageAlbumController *)albumController;

/**
 *  即将需要显示 Loading 时调用
 *
 *  @see shouldShowDefaultLoadingView
 */
- (void)albumControllerWillStartLoading:(FWImageAlbumController *)albumController;

/**
 *  即将需要隐藏 Loading 时调用
 *
 *  @see shouldShowDefaultLoadingView
 */
- (void)albumControllerWillFinishLoading:(FWImageAlbumController *)albumController;

@end


@interface FWImageAlbumTableCell : UITableViewCell

@property(nonatomic, assign) CGFloat albumImageSize UI_APPEARANCE_SELECTOR; // 相册缩略图的大小
@property(nonatomic, assign) CGFloat albumImageMarginLeft UI_APPEARANCE_SELECTOR; // 相册缩略图的 left，-1 表示自动保持与上下 margin 相等
@property(nonatomic, assign) UIEdgeInsets albumNameInsets UI_APPEARANCE_SELECTOR; // 相册名称的上下左右间距
@property(nullable, nonatomic, strong) UIFont *albumNameFont UI_APPEARANCE_SELECTOR; // 相册名的字体
@property(nullable, nonatomic, strong) UIColor *albumNameColor UI_APPEARANCE_SELECTOR; // 相册名的颜色
@property(nullable, nonatomic, strong) UIFont *albumAssetsNumberFont UI_APPEARANCE_SELECTOR; // 相册资源数量的字体
@property(nullable, nonatomic, strong) UIColor *albumAssetsNumberColor UI_APPEARANCE_SELECTOR; // 相册资源数量的颜色

@end

/**
 *  当前设备照片里的相簿列表，使用方式：
 *  1. 使用 init 初始化。
 *  2. 指定一个 albumControllerDelegate，并实现 @required 方法。
 *
 *  @warning 注意，iOS 访问相册需要得到授权，建议先询问用户授权，通过了再进行 FWImageAlbumController 的初始化工作。关于授权的代码，可参考 FW Demo 项目里的 [QDImagePickerExampleViewController authorizationPresentAlbumViewControllerWithTitle] 方法。
 *  @see [FWAssetsManager requestAuthorization:]
 */
@interface FWImageAlbumController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;

@property(nullable, nonatomic, weak) id<FWImageAlbumControllerDelegate> albumControllerDelegate;

/// 相册列表 cell 的高度，同时也是相册预览图的宽高，默认57
@property(nonatomic, assign) CGFloat albumTableViewCellHeight UI_APPEARANCE_SELECTOR;

/// 相册展示内容的类型，可以控制只展示照片、视频或音频的其中一种，也可以同时展示所有类型的资源，默认展示所有类型的资源。
@property(nonatomic, assign) FWAlbumContentType contentType;

@property(nullable, nonatomic, copy) NSString *tipTextWhenNoPhotosAuthorization;
@property(nullable, nonatomic, copy) NSString *tipTextWhenPhotosEmpty;

/**
 *  加载相册列表时会出现 loading，若需要自定义 loading 的形式，可将该属性置为 NO，默认为 YES。
 *  @see albumControllerWillStartLoading: & albumControllerWillFinishLoading:
 */
@property(nonatomic, assign) BOOL shouldShowDefaultLoadingView;

/// 在 FWImageAlbumController 被放到 UINavigationController 里之后，可通过调用这个方法，来尝试直接进入上一次选中的相册列表
- (void)pickLastAlbumGroupDirectlyIfCan;

@end

#pragma mark - FWImagePickerCollectionCell

/**
 *  图片选择空间里的九宫格 cell，支持显示 checkbox、饼状进度条及重试按钮（iCloud 图片需要）
 */
@interface FWImagePickerCollectionCell : UICollectionViewCell

/// 收藏的资源的心形图片
@property(nonatomic, strong) UIImage *favoriteImage UI_APPEARANCE_SELECTOR;

/// 收藏的资源的心形图片的上下左右间距，相对于 cell 左下角零点而言，也即如果 left 越大则越往右，bottom 越大则越往上，另外 top 会影响底部遮罩的高度
@property(nonatomic, assign) UIEdgeInsets favoriteImageMargins UI_APPEARANCE_SELECTOR;

/// checkbox 未被选中时显示的图片
@property(nonatomic, strong) UIImage *checkboxImage UI_APPEARANCE_SELECTOR;

/// checkbox 被选中时显示的图片
@property(nonatomic, strong) UIImage *checkboxCheckedImage UI_APPEARANCE_SELECTOR;

/// checkbox 的 margin，定位从每个 cell（即每张图片）的最右边开始计算
@property(nonatomic, assign) UIEdgeInsets checkboxButtonMargins UI_APPEARANCE_SELECTOR;

/// videoDurationLabel 的字号
@property(nonatomic, strong) UIFont *videoDurationLabelFont UI_APPEARANCE_SELECTOR;

/// videoDurationLabel 的字体颜色
@property(nonatomic, strong) UIColor *videoDurationLabelTextColor UI_APPEARANCE_SELECTOR;

/// 视频时长文字的间距，相对于 cell 右下角而言，也即如果 right 越大则越往左，bottom 越大则越往上，另外 top 会影响底部遮罩的高度
@property(nonatomic, assign) UIEdgeInsets videoDurationLabelMargins UI_APPEARANCE_SELECTOR;

@property(nonatomic, strong, readonly) UIImageView *contentImageView;
@property(nonatomic, strong, readonly) UIImageView *favoriteImageView;
@property(nonatomic, strong, readonly) UIButton *checkboxButton;
@property(nonatomic, strong, readonly) UILabel *videoDurationLabel;
@property(nonatomic, strong, readonly) CAGradientLayer *bottomShadowLayer;// 当出现收藏或者视频时长文字时就会显示遮罩，遮罩高度为 favoriteImage 和 videoDurationLabel 中最高者的高度

@property(nonatomic, assign, getter=isSelectable) BOOL selectable;
@property(nonatomic, assign, getter=isChecked) BOOL checked;
@property(nonatomic, assign) FWAssetDownloadStatus downloadStatus; // Cell 中对应资源的下载状态，这个值的变动会相应地调整 UI 表现
@property(nonatomic, copy, nullable) NSString *assetIdentifier;// 当前这个 cell 正在展示的 FWAsset 的 identifier

- (void)renderWithAsset:(FWAsset *)asset referenceSize:(CGSize)referenceSize;

@end

#pragma mark - FWImagePickerHelper

/**
 *  配合 FWImagePickerController 使用的工具类
 */
@interface FWImagePickerHelper : NSObject

/**
 *  选中图片数量改变时，展示图片数量的 Label 的动画，动画过程如下：
 *  Label 背景色改为透明，同时产生一个与背景颜色和形状、大小都相同的图形置于 Label 底下，做先缩小再放大的 spring 动画
 *  动画结束后移除该图形，并恢复 Label 的背景色
 *
 *  @warning iOS6 下降级处理不调用动画效果
 *
 *  @param label 需要做动画的 UILabel
 */
+ (void)springAnimationOfImageSelectedCountChangeWithCountLabel:(UILabel *)label;

/**
 *  图片 checkBox 被选中时的动画
 *  @warning iOS6 下降级处理不调用动画效果
 *
 *  @param button 需要做动画的 checkbox 按钮
 */
+ (void)springAnimationOfImageCheckedWithCheckboxButton:(UIButton *)button;

/**
 * 搭配<i>springAnimationOfImageCheckedWithCheckboxButton:</i>一起使用，添加animation之前建议先remove
 */
+ (void)removeSpringAnimationOfImageCheckedWithCheckboxButton:(UIButton *)button;


/**
 *  获取最近一次调用 updateLastAlbumWithAssetsGroup 方法调用时储存的 FWAssetGroup 对象
 *
 *  @param userIdentify 用户标识，由于每个用户可能需要分开储存一个最近调用过的 FWAssetGroup，因此增加一个标识区分用户。
 *  一个常见的应用场景是选择图片时保存图片所在相册的对应的 FWAssetGroup，并使用用户的 user id 作为区分不同用户的标识，
 *  当用户再次选择图片时可以根据已经保存的 FWAssetGroup 直接进入上次使用过的相册。
 */
+ (FWAssetGroup *)assetsGroupOfLastPickerAlbumWithUserIdentify:(nullable NSString *)userIdentify;

/**
 *  储存一个 FWAssetGroup，从而储存一个对应的相册，与 assetsGroupOfLatestPickerAlbumWithUserIdentify 方法对应使用
 *
 *  @param assetsGroup   要被储存的 FWAssetGroup
 *  @param albumContentType 相册的内容类型
 *  @param userIdentify 用户标识，由于每个用户可能需要分开储存一个最近调用过的 FWAssetGroup，因此增加一个标识区分用户
 */
+ (void)updateLastestAlbumWithAssetsGroup:(FWAssetGroup *)assetsGroup ablumContentType:(FWAlbumContentType)albumContentType userIdentify:(nullable NSString *)userIdentify;

/**
 * 检测一组资源是否全部下载成功，如果有资源仍未从 iCloud 中下载成功，则返回 NO
 *
 * 可以用于选择图片后，业务需要自行处理 iCloud 下载的场景。
 */
+ (BOOL)imageAssetsDownloaded:(NSMutableArray<FWAsset *> *)imagesAssetArray;

/**
 * 检测资源是否已经在本地，如果资源仍未从 iCloud 中成功下载，则会发出请求从 iCloud 加载资源，并通过多次调用 block 返回请求结果
 *
 * 可以用于选择图片后，业务需要自行处理 iCloud 下载的场景。
 */
+ (void)requestImageAssetIfNeeded:(FWAsset *)asset completion: (void (^)(FWAssetDownloadStatus downloadStatus, NSError *error))completion;

@end

#pragma mark - FWImagePickerPreviewController

@class FWNavigationButton;
@class FWImagePickerController;
@class FWImagePreviewController;
@class FWImagePickerPreviewController;

@protocol FWImagePickerPreviewControllerDelegate <NSObject>

@optional

/// 取消选择图片后被调用
- (void)imagePickerPreviewControllerDidCancel:(FWImagePickerPreviewController *)imagePickerPreviewController;
/// 即将选中图片
- (void)imagePickerPreviewController:(FWImagePickerPreviewController *)imagePickerPreviewController willCheckImageAtIndex:(NSInteger)index;
/// 已经选中图片
- (void)imagePickerPreviewController:(FWImagePickerPreviewController *)imagePickerPreviewController didCheckImageAtIndex:(NSInteger)index;
/// 即将取消选中图片
- (void)imagePickerPreviewController:(FWImagePickerPreviewController *)imagePickerPreviewController willUncheckImageAtIndex:(NSInteger)index;
/// 已经取消选中图片
- (void)imagePickerPreviewController:(FWImagePickerPreviewController *)imagePickerPreviewController didUncheckImageAtIndex:(NSInteger)index;

@end


@interface FWImagePickerPreviewController : FWImagePreviewController <FWImagePreviewViewDelegate>

@property(nullable, nonatomic, weak) id<FWImagePickerPreviewControllerDelegate> delegate;

@property(nullable, nonatomic, strong) UIColor *toolBarBackgroundColor UI_APPEARANCE_SELECTOR;
@property(nullable, nonatomic, strong) UIColor *toolBarTintColor UI_APPEARANCE_SELECTOR;

@property(nullable, nonatomic, strong, readonly) UIView *topToolBarView;
@property(nullable, nonatomic, strong, readonly) FWNavigationButton *backButton;
@property(nullable, nonatomic, strong, readonly) UIButton *checkboxButton;

/// 由于组件需要通过本地图片的 FWAsset 对象读取图片的详细信息，因此这里的需要传入的是包含一个或多个 FWAsset 对象的数组
@property(nullable, nonatomic, strong) NSMutableArray<FWAsset *> *imagesAssetArray;
@property(nullable, nonatomic, strong) NSMutableArray<FWAsset *> *selectedImageAssetArray;

@property(nonatomic, assign) FWAssetDownloadStatus downloadStatus;

/// 最多可以选择的图片数，默认为无穷大
@property(nonatomic, assign) NSUInteger maximumSelectImageCount;
/// 最少需要选择的图片数，默认为 0
@property(nonatomic, assign) NSUInteger minimumSelectImageCount;
/// 选择图片超出最大图片限制时 alertView 的标题
@property(nullable, nonatomic, copy) NSString *alertTitleWhenExceedMaxSelectImageCount;
/// 选择图片超出最大图片限制时 alertView 的标题
@property(nullable, nonatomic, copy) NSString *alertButtonTitleWhenExceedMaxSelectImageCount;

/**
 *  更新数据并刷新 UI，手工调用
 *
 *  @param imageAssetArray         包含所有需要展示的图片的数组
 *  @param selectedImageAssetArray 包含所有需要展示的图片中已经被选中的图片的数组
 *  @param currentImageIndex       当前展示的图片在 imageAssetArray 的索引
 *  @param singleCheckMode         是否为单选模式，如果是单选模式，则不显示 checkbox
 */
- (void)updateImagePickerPreviewViewWithImagesAssetArray:(NSMutableArray<FWAsset *> * _Nullable)imageAssetArray
                                 selectedImageAssetArray:(NSMutableArray<FWAsset *> * _Nullable)selectedImageAssetArray
                                       currentImageIndex:(NSInteger)currentImageIndex
                                         singleCheckMode:(BOOL)singleCheckMode;

@end

#pragma mark - FWImagePickerController

@class FWImagePickerController;

@protocol FWImagePickerControllerDelegate <NSObject>

@optional

/**
 *  创建一个 ImagePickerPreviewViewController 用于预览图片
 */
- (FWImagePickerPreviewController *)imagePickerPreviewControllerForImagePickerController:(FWImagePickerController *)imagePickerController;

/**
 *  控制照片的排序，若不实现，默认为 FWAlbumSortTypePositive
 *  @note 注意返回值会决定第一次进来相片列表时列表默认的滚动位置，如果为 FWAlbumSortTypePositive，则列表默认滚动到底部，如果为 FWAlbumSortTypeReverse，则列表默认滚动到顶部。
 */
- (FWAlbumSortType)albumSortTypeForImagePickerController:(FWImagePickerController *)imagePickerController;

/**
 *  多选模式下选择图片完毕后被调用（点击 sendButton 后被调用），单选模式下没有底部发送按钮，所以也不会走到这个delegate
 *
 *  @param imagePickerController 对应的 FWImagePickerController
 *  @param imagesAssetArray          包含被选择的图片的 FWAsset 对象的数组。
 */
- (void)imagePickerController:(FWImagePickerController *)imagePickerController didFinishPickingImageWithImagesAssetArray:(NSMutableArray<FWAsset *> *)imagesAssetArray;

/**
 *  cell 被点击时调用（先调用这个接口，然后才去走预览大图的逻辑），注意这并非指选中 checkbox 事件
 *
 *  @param imagePickerController        对应的 FWImagePickerController
 *  @param imageAsset                       被选中的图片的 FWAsset 对象
 *  @param imagePickerPreviewController 选中图片后进行图片预览的 viewController
 */
- (void)imagePickerController:(FWImagePickerController *)imagePickerController didSelectImageWithImagesAsset:(FWAsset *)imageAsset afterImagePickerPreviewControllerUpdate:(FWImagePickerPreviewController *)imagePickerPreviewController;

/// 是否能够选中 checkbox
- (BOOL)imagePickerController:(FWImagePickerController *)imagePickerController shouldCheckImageAtIndex:(NSInteger)index;

/// 即将选中 checkbox 时调用
- (void)imagePickerController:(FWImagePickerController *)imagePickerController willCheckImageAtIndex:(NSInteger)index;

/// 选中了 checkbox 之后调用
- (void)imagePickerController:(FWImagePickerController *)imagePickerController didCheckImageAtIndex:(NSInteger)index;

/// 即将取消选中 checkbox 时调用
- (void)imagePickerController:(FWImagePickerController *)imagePickerController willUncheckImageAtIndex:(NSInteger)index;

/// 取消了 checkbox 选中之后调用
- (void)imagePickerController:(FWImagePickerController *)imagePickerController didUncheckImageAtIndex:(NSInteger)index;

/**
 *  取消选择图片后被调用
 */
- (void)imagePickerControllerDidCancel:(FWImagePickerController *)imagePickerController;

/**
 *  即将需要显示 Loading 时调用
 *
 *  @see shouldShowDefaultLoadingView
 */
- (void)imagePickerControllerWillStartLoading:(FWImagePickerController *)imagePickerController;

/**
 *  即将需要隐藏 Loading 时调用
 *
 *  @see shouldShowDefaultLoadingView
 */
- (void)imagePickerControllerDidFinishLoading:(FWImagePickerController *)imagePickerController;

@end


@interface FWImagePickerController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, FWImagePickerPreviewControllerDelegate>

@property(nullable, nonatomic, weak) id<FWImagePickerControllerDelegate> imagePickerControllerDelegate;

/*
 * 图片的最小尺寸，布局时如果有剩余空间，会将空间分配给图片大小，所以最终显示出来的大小不一定等于minimumImageWidth。默认是75。
 * @warning collectionViewLayout 和 collectionView 可能有设置 sectionInsets 和 contentInsets，所以设置几行不可以简单的通过 screenWdith / columnCount 来获得
 */
@property(nonatomic, assign) CGFloat minimumImageWidth UI_APPEARANCE_SELECTOR;

@property(nullable, nonatomic, strong, readonly) UICollectionViewFlowLayout *collectionViewLayout;
@property(nullable, nonatomic, strong, readonly) UICollectionView *collectionView;

@property(nullable, nonatomic, strong, readonly) UIView *operationToolBarView;
@property(nullable, nonatomic, strong, readonly) UIButton *previewButton;
@property(nullable, nonatomic, strong, readonly) UIButton *sendButton;
@property(nullable, nonatomic, strong, readonly) UILabel *imageCountLabel;

/// 也可以直接传入 FWAssetGroup，然后读取其中的 FWAsset 并储存到 imagesAssetArray 中，传入后会赋值到 FWAssetGroup，并自动刷新 UI 展示
- (void)refreshWithAssetsGroup:(FWAssetGroup * _Nullable)assetsGroup;

@property(nullable, nonatomic, strong, readonly) NSMutableArray<FWAsset *> *imagesAssetArray;
@property(nullable, nonatomic, strong, readonly) FWAssetGroup *assetsGroup;

/// 当前被选择的图片对应的 FWAsset 对象数组
@property(nullable, nonatomic, strong, readonly) NSMutableArray<FWAsset *> *selectedImageAssetArray;

/// 是否允许图片多选，默认为 YES。如果为 NO，则不显示 checkbox 和底部工具栏。
@property(nonatomic, assign) BOOL allowsMultipleSelection;

/// 最多可以选择的图片数，默认为无符号整形数的最大值，相当于没有限制
@property(nonatomic, assign) NSUInteger maximumSelectImageCount;

/// 最少需要选择的图片数，默认为 0
@property(nonatomic, assign) NSUInteger minimumSelectImageCount;

/// 选择图片超出最大图片限制时 alertView 的标题
@property(nullable, nonatomic, copy) NSString *alertTitleWhenExceedMaxSelectImageCount;

/// 选择图片超出最大图片限制时 alertView 底部按钮的标题
@property(nullable, nonatomic, copy) NSString *alertButtonTitleWhenExceedMaxSelectImageCount;

/**
 *  加载相册列表时会出现 loading，若需要自定义 loading 的形式，可将该属性置为 NO，默认为 YES。
 *  @see imagePickerControllerWillStartLoading: & imagePickerControllerDidFinishLoading:
 */
@property(nonatomic, assign) BOOL shouldShowDefaultLoadingView;

@end

NS_ASSUME_NONNULL_END
