//
//  BannerView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, __FWBannerViewPageControlAlignment) {
    __FWBannerViewPageControlAlignmentRight,
    __FWBannerViewPageControlAlignmentCenter,
} NS_SWIFT_NAME(BannerViewPageControlAlignment);

typedef NS_ENUM(NSInteger, __FWBannerViewPageControlStyle) {
    // 系统样式
    __FWBannerViewPageControlStyleSystem,
    // 自定义样式，可设置图片等
    __FWBannerViewPageControlStyleCustom,
    // 不显示
    __FWBannerViewPageControlStyleNone,
} NS_SWIFT_NAME(BannerViewPageControlStyle);

@class __FWBannerView;

NS_SWIFT_NAME(BannerViewDelegate)
@protocol __FWBannerViewDelegate <NSObject>

@optional

- (void)bannerView:(__FWBannerView *)bannerView didSelectItemAtIndex:(NSInteger)index;

/** 监听bannerView滚动，快速滚动时也会回调 */
- (void)bannerView:(__FWBannerView *)bannerView didScrollToIndex:(NSInteger)index;

/** 如果你需要自定义UICollectionViewCell样式，请实现此代理方法，默认的__FWBannerViewCell也会调用。 */
- (void)bannerView:(__FWBannerView *)bannerView customCell:(UICollectionViewCell *)cell forIndex:(NSInteger)index;

/** 如果你需要自定义UICollectionViewCell样式，请实现此代理方法返回你的自定义UICollectionViewCell的class。 */
- (nullable Class)customCellClassForBannerView:(__FWBannerView *)view;

/** 如果你需要自定义UICollectionViewCell样式，请实现此代理方法返回你的自定义UICollectionViewCell的Nib。 */
- (nullable UINib *)customCellNibForBannerView:(__FWBannerView *)view;

@end

/**
 __FWBannerView
 
 @see https://github.com/gsdios/SDCycleScrollView
 */
NS_SWIFT_NAME(BannerView)
@interface __FWBannerView : UIView

/** 初始轮播图（推荐使用） */
+ (instancetype)bannerViewWithFrame:(CGRect)frame delegate:(nullable id<__FWBannerViewDelegate>)delegate placeholderImage:(nullable UIImage *)placeholderImage;

/** 本地图片轮播初始化方式 */
+ (instancetype)bannerViewWithFrame:(CGRect)frame imagesGroup:(nullable NSArray *)imagesGroup;

/** 本地图片轮播初始化方式2,infiniteLoop:是否无限循环 */
+ (instancetype)bannerViewWithFrame:(CGRect)frame shouldInfiniteLoop:(BOOL)infiniteLoop imagesGroup:(nullable NSArray *)imagesGroup;

/** 图片数组，支持URL|String|UIImage */
@property (nonatomic, strong, nullable) NSArray *imagesGroup;

/** 每张图片对应要显示的文字数组 */
@property (nonatomic, strong, nullable) NSArray *titlesGroup;

/** 自动滚动间隔时间,默认2s */
@property (nonatomic, assign) CGFloat autoScrollTimeInterval;

/** 是否无限循环,默认Yes */
@property (nonatomic,assign) BOOL infiniteLoop;

/** 是否自动滚动,默认Yes */
@property (nonatomic,assign) BOOL autoScroll;

/** 图片滚动方向，默认为水平滚动 */
@property (nonatomic, assign) UICollectionViewScrollDirection scrollDirection;

/** 是否启用根据item分页滚动，默认NO，根据frame大小滚动 */
@property (nonatomic, assign) BOOL itemPagingEnabled;

/** 整体布局尺寸，默认占满视图，itemPagingEnabled启用后生效 */
@property (nonatomic, assign) CGSize itemSize;

/** 整体布局间隔，默认0，itemPagingEnabled启用后生效 */
@property (nonatomic, assign) CGFloat itemSpacing;

/** 是否设置item分页停留位置居中，默认NO，停留左侧，itemPagingEnabled启用后生效 */
@property (nonatomic, assign) BOOL itemPagingCenter;

/** 设置事件代理 */
@property (nonatomic, weak, nullable) id<__FWBannerViewDelegate> delegate;

/** block方式监听点击 */
@property (nonatomic, copy, nullable) void (^didSelectItemBlock)(NSInteger currentIndex);

/** block方式监听滚动，快速滚动时也会回调 */
@property (nonatomic, copy, nullable) void (^didScrollToItemBlock)(NSInteger currentIndex);

/** 自定义cell句柄 */
@property (nonatomic, copy, nullable) void (^customCellBlock)(UICollectionViewCell *cell, NSInteger index);

/** 手工滚动到指定index，不使用动画 */
- (void)scrollToIndex:(NSInteger)index;

/** 手工滚动到指定index，可指定动画 */
- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;

/** 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法 */
- (void)adjustWhenViewWillAppear;

/** 轮播图片的ContentMode，默认为 UIViewContentModeScaleAspectFill */
@property (nonatomic, assign) UIViewContentMode imageViewContentMode;

/** 占位图，用于网络未加载到图片时 */
@property (nonatomic, strong, nullable) UIImage *placeholderImage;

/** 是否显示分页控件 */
@property (nonatomic, assign) BOOL showPageControl;

/** 自定义pageControl控件，初始化后调用 */
@property (nonatomic, copy, nullable) void (^customPageControl)(UIControl *pageControl);

/** 是否在只有一张图时隐藏pagecontrol，默认为YES */
@property(nonatomic) BOOL hidesForSinglePage;

/** 只展示文字轮播 */
@property (nonatomic, assign) BOOL onlyDisplayText;

/** pageControl 样式，默认为系统样式 */
@property (nonatomic, assign) __FWBannerViewPageControlStyle pageControlStyle;

/** 分页控件位置 */
@property (nonatomic, assign) __FWBannerViewPageControlAlignment pageControlAlignment;

/** 分页控件距离轮播图的底部间距（在默认间距基础上）的偏移量 */
@property (nonatomic, assign) CGFloat pageControlBottomOffset;

/** 分页控件距离轮播图的右边间距（在默认间距基础上）的偏移量 */
@property (nonatomic, assign) CGFloat pageControlRightOffset;

/** 分页控件小圆标大小 */
@property (nonatomic, assign) CGSize pageControlDotSize;

/** 分页空间小圆标间隔 */
@property (nonatomic, assign) CGFloat pageControlDotSpacing;

/** 当前分页控件小圆标颜色 */
@property (nonatomic, strong, nullable) UIColor *currentPageDotColor;

/** 其他分页控件小圆标颜色 */
@property (nonatomic, strong, nullable) UIColor *pageDotColor;

/** 当前分页控件小圆标图片 */
@property (nonatomic, strong, nullable) UIImage *currentPageDotImage;

/** 其他分页控件小圆标图片 */
@property (nonatomic, strong, nullable) UIImage *pageDotImage;

/** 其他分页控件自定义视图类，默认__FWDotView */
@property (nonatomic, nullable) Class pageDotViewClass;

/** 轮播文字label字体颜色 */
@property (nonatomic, strong, nullable) UIColor *titleLabelTextColor;

/** 轮播文字label字体大小 */
@property (nonatomic, strong, nullable) UIFont  *titleLabelTextFont;

/** 轮播文字label背景颜色 */
@property (nonatomic, strong, nullable) UIColor *titleLabelBackgroundColor;

/** 轮播文字label高度 */
@property (nonatomic, assign) CGFloat titleLabelHeight;

/** 轮播文字label对齐方式 */
@property (nonatomic, assign) NSTextAlignment titleLabelTextAlignment;

/** 内容视图间距设置，默认全部0 */
@property (nonatomic, assign) UIEdgeInsets contentViewInset;

/** 内容视图圆角设置，默认0 */
@property (nonatomic, assign) CGFloat contentViewCornerRadius;

/** 滚动手势禁用（文字轮播较实用） */
- (void)disableScrollGesture;

@end

NS_SWIFT_NAME(BannerViewCell)
@interface __FWBannerViewCell : UICollectionViewCell

@property (nonatomic, weak, nullable) UIImageView *imageView;
@property (nonatomic, copy, nullable) NSString *title;

@property (nonatomic, strong, nullable) UIColor *titleLabelTextColor;
@property (nonatomic, strong, nullable) UIFont *titleLabelTextFont;
@property (nonatomic, strong, nullable) UIColor *titleLabelBackgroundColor;
@property (nonatomic, assign) CGFloat titleLabelHeight;
@property (nonatomic, assign) NSTextAlignment titleLabelTextAlignment;
@property (nonatomic, assign) UIEdgeInsets contentViewInset;
@property (nonatomic, assign) CGFloat contentViewCornerRadius;

@property (nonatomic, assign) BOOL hasConfigured;

/** 只展示文字轮播 */
@property (nonatomic, assign) BOOL onlyDisplayText;

@end

NS_ASSUME_NONNULL_END
