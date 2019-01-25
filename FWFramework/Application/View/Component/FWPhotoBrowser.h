/*!
 @header     FWPhotoBrowser.h
 @indexgroup FWFramework
 @brief      FWPhotoBrowser
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/24
 */

#import <UIKit/UIKit.h>

@class FWPhotoBrowser;

@protocol FWPhotoBrowserDelegate <NSObject>

@optional

/**
 获取对应索引的高质量图片地址字符串
 
 @param photoBrowser 图片浏览器
 @param index          索引
 
 @return 图片的 url 字符串
 */
- (NSString *)photoBrowser:(FWPhotoBrowser *)photoBrowser highQualityUrlStringForIndex:(NSInteger)index;

/**
 获取对应索引的视图
 
 @param photoBrowser 图片浏览器
 @param index          索引
 
 @return 视图
 */
- (UIView *)photoBrowser:(FWPhotoBrowser *)photoBrowser viewForIndex:(NSInteger)index;

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
- (UIImage *)photoBrowser:(FWPhotoBrowser *)photoBrowser defaultImageForIndex:(NSInteger)index;

/**
 滚动到指定页时会调用该方法
 
 @param photoBrowser 图片浏览器
 @param index          索引
 */
- (void)photoBrowser:(FWPhotoBrowser *)photoBrowser scrollToIndex:(NSInteger)index;

@end

/*!
 @brief FWPhotoBrowser
 
 @see https://github.com/EnjoySR/ESPictureBrowser
 */
@interface FWPhotoBrowser : UIView

/**
 必须参数，与pictureUrls二选一，图片张数。使用此参数必须实现代理highQualityUrlStringForIndex
 */
@property (nonatomic, assign) NSInteger picturesCount;

/**
 必须参数，与picturesCount二选一，图片地址列表，自动设置图片张数
 */
@property (nonatomic, copy) NSArray<NSString *> *pictureUrls;

/**
 当前选中索引，默认0
 */
@property (nonatomic, assign) NSInteger currentIndex;

/**
 事件代理，可选
 */
@property (nonatomic, weak) id<FWPhotoBrowserDelegate> delegate;

/**
 是否隐藏状态栏，默认YES
 */
@property (nonatomic, assign) BOOL statusBarHidden;

/**
 图片之间的间距，默认： 20
 */
@property (nonatomic, assign) CGFloat betweenImagesSpacing;

/**
 页数文字中心点，默认：居中，中心 y 距离底部 20
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
@property (nonatomic, copy) void(^longPressBlock)(NSInteger index);

/**
 显示图片浏览器
 
 @param fromView 用户点击的视图
 */
- (void)showFromView:(UIView *)fromView;

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

- (void)photoViewTouch:(FWPhotoView *)photoView;

- (void)photoView:(FWPhotoView *)photoView scale:(CGFloat)scale;

@end

@interface FWPhotoView : UIScrollView

// 当前视图所在的索引
@property (nonatomic, assign) NSInteger index;
// 图片的大小
@property (nonatomic, assign) CGSize pictureSize;
// 显示的默认图片
@property (nonatomic, strong) UIImage *placeholderImage;
// 图片的地址 URL
@property (nonatomic, strong) NSString *urlString;
// 当前显示图片的控件
@property (nonatomic, strong, readonly) UIImageView *imageView;
// 代理
@property (nonatomic, weak) id<FWPhotoViewDelegate> pictureDelegate;

/**
 动画显示
 
 @param rect            从哪个位置开始做动画
 @param animationBlock  附带的动画信息
 @param completionBlock 结束的回调
 */
- (void)animationShowWithFromRect:(CGRect)rect animationBlock:(void(^)(void))animationBlock completionBlock:(void(^)(void))completionBlock;


/**
 动画消失
 
 @param rect            回到哪个位置
 @param animationBlock  附带的动画信息
 @param completionBlock 结束的回调
 */
- (void)animationDismissWithToRect:(CGRect)rect animationBlock:(void(^)(void))animationBlock completionBlock:(void(^)(void))completionBlock;

@end
