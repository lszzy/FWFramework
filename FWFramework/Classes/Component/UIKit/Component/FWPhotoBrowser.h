/*!
 @header     FWPhotoBrowser.h
 @indexgroup FWFramework
 @brief      FWPhotoBrowser
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/24
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FWPhotoBrowser;
@class FWPhotoView;

@protocol FWPhotoBrowserDelegate <NSObject>

@optional

/**
 获取对应索引的高质量图片地址字符串或UIImage
 
 @param photoBrowser 图片浏览器
 @param index          索引
 
 @return 图片的 url 字符串或UIImage
 */
- (nullable id)photoBrowser:(FWPhotoBrowser *)photoBrowser photoUrlForIndex:(NSInteger)index;

/**
 异步获取对应索引的高质量图片地址字符串或UIImage
 
 @param photoBrowser 图片浏览器
 @param index          索引
 @param photoView 图片视图，异步完成后设置urlString即可
 */
- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser asyncUrlForIndex:(NSInteger)index photoView:(FWPhotoView *)photoView;

/**
 获取对应索引的视图或相对于window的位置NSValue
 
 @param photoBrowser 图片浏览器
 @param index          索引
 
 @return 视图或位置NSValue
 */
- (nullable id)photoBrowser:(FWPhotoBrowser *)photoBrowser viewForIndex:(NSInteger)index;

/**
 获取对应索引的图片大小
 
 @param photoBrowser 图片浏览器
 @param index          索引
 
 @return 图片大小
 */
- (CGSize)photoBrowser:(FWPhotoBrowser *)photoBrowser imageSizeForIndex:(NSInteger)index;

/**
 获取对应索引默认图片，可以是占位图片，可以是缩略图
 
 @param photoBrowser 图片浏览器
 @param index          索引
 
 @return 图片
 */
- (nullable UIImage *)photoBrowser:(FWPhotoBrowser *)photoBrowser placeholderImageForIndex:(NSInteger)index;

/**
 滚动到指定页时会调用该方法
 
 @param photoBrowser 图片浏览器
 @param index          索引
 */
- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser scrollToIndex:(NSInteger)index;

/**
 图片视图开始加载回调，可自定义子视图等。注意photoView可重用
 
 @param photoBrowser 图片浏览器
 @param photoView 图片视图，索引为index属性
 */
- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser startLoadPhotoView:(FWPhotoView *)photoView;

/**
 图片视图加载完成回调，图片加载失败时也会回调。视图加载成功时，可通过imageView获取图片。注意photoView可重用
 
 @param photoBrowser 图片浏览器
 @param photoView 图片视图，索引为index属性
 */
- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser finishLoadPhotoView:(FWPhotoView *)photoView;

/**
 图片视图将要显示回调，可用来处理自定义视图动画效果。注意photoView可重用
 
 @param photoBrowser 图片浏览器
 @param photoView 图片视图，索引为index属性
 */
- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser willShowPhotoView:(FWPhotoView *)photoView;

/**
 图片视图将要隐藏回调，可用来处理自定义视图动画效果。注意photoView可重用
 
 @param photoBrowser 图片浏览器
 @param photoView 图片视图，索引为index属性
 */
- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser willDismissPhotoView:(FWPhotoView *)photoView;

@end

/*!
 @brief FWPhotoBrowser
 
 @see https://github.com/EnjoySR/ESPictureBrowser
 */
@interface FWPhotoBrowser : UIView

/**
 必须参数，与pictureUrls二选一，图片张数。使用此参数必须实现代理photoUrlForIndex
 */
@property (nonatomic, assign) NSInteger picturesCount;

/**
 必须参数，与picturesCount二选一，图片地址列表，自动设置图片张数
 */
@property (nonatomic, copy, nullable) NSArray *pictureUrls;

/**
 当前选中索引，默认0
 */
@property (nonatomic, assign) NSInteger currentIndex;

/**
 事件代理，可选
 */
@property (nonatomic, weak, nullable) id<FWPhotoBrowserDelegate> delegate;

/**
 是否隐藏状态栏，默认YES
 */
@property (nonatomic, assign) BOOL statusBarHidden;

/**
 图片之间的间距，默认： 20
 */
@property (nonatomic, assign) CGFloat imagesSpacing;

/**
 页数文字标签，只读，方便外部布局
 */
@property (nonatomic, strong, readonly) UILabel *pageTextLabel;

/**
 页数文字中心点，默认：居中，中心 y 距离底部 20+安全区域高度
 */
@property (nonatomic, assign) CGPoint pageTextCenter;

/**
 页数文字字体，默认：系统字体，16号
 */
@property (nonatomic, strong) UIFont *pageTextFont;

/**
 页数文字颜色，默认：白色
 */
@property (nonatomic, strong) UIColor *pageTextColor;

/**
 长按图片要执行的事件，将长按图片索引回调
 */
@property (nonatomic, copy, nullable) void(^longPressBlock)(NSInteger index);

/**
 显示图片浏览器
 
 @param fromView 用户点击的视图
 */
- (void)showFromView:(nullable UIView *)fromView;

/**
 显示图片浏览器，居中显示
 */
- (void)show;

/**
 让图片浏览器消失
 */
- (void)dismiss;

@end

@class FWPhotoView;

@protocol FWPhotoViewDelegate <NSObject>

- (void)photoViewClicked:(FWPhotoView *)photoView;

- (void)photoView:(FWPhotoView *)photoView scale:(CGFloat)scale;

- (void)photoViewLoaded:(FWPhotoView *)photoView;

@end

@interface FWPhotoView : UIScrollView

// 当前视图所在的索引
@property (nonatomic, assign) NSInteger index;
// 图片的大小
@property (nonatomic, assign) CGSize pictureSize;
// 显示的默认图片
@property (nonatomic, strong, nullable) UIImage *placeholderImage;
// 图片的地址，支持NSString和UIImage
@property (nonatomic, strong, nullable) id urlString;
// 当前显示图片的控件
@property (nonatomic, strong, readonly) UIImageView *imageView;
// 图片是否加载成功，加载成功可获取imageView.image
@property (nonatomic, assign) BOOL imageLoaded;
// 当前图片加载进度
@property (nonatomic, assign) CGFloat progress;
// 图片事件代理
@property (nonatomic, weak, nullable) id<FWPhotoViewDelegate> pictureDelegate;

/**
 动画显示
 
 @param rect            从哪个位置开始做动画
 @param animationBlock  附带的动画信息
 @param completionBlock 结束的回调
 */
- (void)animationShowWithFromRect:(CGRect)rect animationBlock:(nullable void(^)(void))animationBlock completionBlock:(nullable void(^)(void))completionBlock;

/**
 动画消失
 
 @param rect            回到哪个位置
 @param animationBlock  附带的动画信息
 @param completionBlock 结束的回调
 */
- (void)animationDismissWithToRect:(CGRect)rect animationBlock:(nullable void(^)(void))animationBlock completionBlock:(nullable void(^)(void))completionBlock;

@end

NS_ASSUME_NONNULL_END
