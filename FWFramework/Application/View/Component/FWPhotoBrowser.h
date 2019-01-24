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

@required

/**
 获取对应索引的高质量图片地址字符串
 
 @param pictureBrowser 图片浏览器
 @param index          索引
 
 @return 图片的 url 字符串
 */
- (NSString *)pictureView:(FWPhotoBrowser *)pictureBrowser highQualityUrlStringForIndex:(NSInteger)index;

@optional

/**
 获取对应索引的视图
 
 @param pictureBrowser 图片浏览器
 @param index          索引
 
 @return 视图
 */
- (UIView *)pictureView:(FWPhotoBrowser *)pictureBrowser viewForIndex:(NSInteger)index;

/**
 获取对应索引的图片大小
 
 @param pictureBrowser 图片浏览器
 @param index          索引
 
 @return 图片大小
 */
- (CGSize)pictureView:(FWPhotoBrowser *)pictureBrowser imageSizeForIndex:(NSInteger)index;

// 以下两个代理方法必须要实现一个

/**
 获取对应索引默认图片，可以是占位图片，可以是缩略图
 
 @param pictureBrowser 图片浏览器
 @param index          索引
 
 @return 图片
 */
- (UIImage *)pictureView:(FWPhotoBrowser *)pictureBrowser defaultImageForIndex:(NSInteger)index;

/**
 滚动到指定页时会调用该方法
 
 @param pictureBrowser 图片浏览器
 @param index          索引
 */
- (void)pictureView:(FWPhotoBrowser *)pictureBrowser scrollToIndex:(NSInteger)index;

@end

/*!
 @brief FWPhotoBrowser
 
 @see https://github.com/EnjoySR/ESPictureBrowser
 */
@interface FWPhotoBrowser : UIView

@property (nonatomic, weak) id<FWPhotoBrowserDelegate> delegate;

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
 
 @param fromView            用户点击的视图
 @param picturesCount       图片的张数
 @param currentPictureIndex 当前用户点击的图片索引
 */
- (void)showFromView:(UIView *)fromView picturesCount:(NSInteger)picturesCount currentPictureIndex:(NSInteger)currentPictureIndex;

/**
 让图片浏览器消失
 */
- (void)dismiss;

@end

@class FWPhotoBrowserView;

@protocol FWPhotoBrowserViewDelegate <NSObject>

- (void)pictureViewTouch:(FWPhotoBrowserView *)pictureView;

- (void)pictureView:(FWPhotoBrowserView *)pictureView scale:(CGFloat)scale;

@end

@interface FWPhotoBrowserView : UIScrollView

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
@property (nonatomic, weak) id<FWPhotoBrowserViewDelegate> pictureDelegate;

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
