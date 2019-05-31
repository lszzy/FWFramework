/*!
 @header     FWBannerView.h
 @indexgroup FWFramework
 @brief      FWBannerView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/13
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FWBannerViewPageControlAlignment) {
    FWBannerViewPageControlAlignmentRight,
    FWBannerViewPageControlAlignmentCenter,
};

typedef NS_ENUM(NSInteger, FWBannerViewPageControlStyle) {
    // 系统样式
    FWBannerViewPageControlStyleSystem,
    // 自定义样式，可设置图片等
    FWBannerViewPageControlStyleCustom,
    // 不显示
    FWBannerViewPageControlStyleNone,
};

@class FWBannerView;

@protocol FWBannerViewDelegate <NSObject>

@optional

- (void)bannerView:(FWBannerView *)bannerView didSelectItemAtIndex:(NSInteger)index;

- (void)bannerView:(FWBannerView *)bannerView didScrollToIndex:(NSInteger)index;

/** 如果你需要自定义UICollectionViewCell样式，请实现此代理方法，默认的FWBannerViewCell也会调用。 */
- (void)bannerView:(FWBannerView *)bannerView customCell:(UICollectionViewCell *)cell forIndex:(NSInteger)index;

/** 如果你需要自定义UICollectionViewCell样式，请实现此代理方法返回你的自定义UICollectionViewCell的class。 */
- (Class)customCellClassForBannerView:(FWBannerView *)view;

/** 如果你需要自定义UICollectionViewCell样式，请实现此代理方法返回你的自定义UICollectionViewCell的Nib。 */
- (UINib *)customCellNibForBannerView:(FWBannerView *)view;

@end

/*!
 @brief FWBannerView
 
 @see https://github.com/gsdios/SDCycleScrollView
 */
@interface FWBannerView : UIView

/** 初始轮播图（推荐使用） */
+ (instancetype)bannerViewWithFrame:(CGRect)frame delegate:(id<FWBannerViewDelegate>)delegate placeholderImage:(UIImage *)placeholderImage;

+ (instancetype)bannerViewWithFrame:(CGRect)frame imageURLStringsGroup:(NSArray *)imageURLStringsGroup;

/** 本地图片轮播初始化方式 */
+ (instancetype)bannerViewWithFrame:(CGRect)frame imageNamesGroup:(NSArray *)imageNamesGroup;

/** 本地图片轮播初始化方式2,infiniteLoop:是否无限循环 */
+ (instancetype)bannerViewWithFrame:(CGRect)frame shouldInfiniteLoop:(BOOL)infiniteLoop imageNamesGroup:(NSArray *)imageNamesGroup;

/** 网络图片 url string 数组 */
@property (nonatomic, strong) NSArray *imageURLStringsGroup;

/** 每张图片对应要显示的文字数组 */
@property (nonatomic, strong) NSArray *titlesGroup;

/** 本地图片数组 */
@property (nonatomic, strong) NSArray *localizationImageNamesGroup;

/** 自动滚动间隔时间,默认2s */
@property (nonatomic, assign) CGFloat autoScrollTimeInterval;

/** 是否无限循环,默认Yes */
@property (nonatomic,assign) BOOL infiniteLoop;

/** 是否自动滚动,默认Yes */
@property (nonatomic,assign) BOOL autoScroll;

/** 图片滚动方向，默认为水平滚动 */
@property (nonatomic, assign) UICollectionViewScrollDirection scrollDirection;

/** 整体布局边距，默认全部0 */
@property (nonatomic, assign) UIEdgeInsets sectionInset;

/** 整体布局尺寸，默认占满视图 */
@property (nonatomic, assign) CGSize itemSize;

/** 整体布局间隔，默认0 */
@property (nonatomic, assign) CGFloat itemSpacing;

/** 是否启用根据item大小分页滚动，默认NO，根据frame大小滚动 */
@property (nonatomic, assign) BOOL itemPagingEnabled;

/** 设置事件代理 */
@property (nonatomic, weak) id<FWBannerViewDelegate> delegate;

/** block方式监听点击 */
@property (nonatomic, copy) void (^clickItemOperationBlock)(NSInteger currentIndex);

/** block方式监听滚动 */
@property (nonatomic, copy) void (^itemDidScrollOperationBlock)(NSInteger currentIndex);

/** 可以调用此方法手动控制滚动到哪一个index */
- (void)makeScrollViewScrollToIndex:(NSInteger)index;

/** 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法 */
- (void)adjustWhenControllerViewWillAppear;

/** 轮播图片的ContentMode，默认为 UIViewContentModeScaleAspectFill */
@property (nonatomic, assign) UIViewContentMode bannerImageViewContentMode;

/** 占位图，用于网络未加载到图片时 */
@property (nonatomic, strong) UIImage *placeholderImage;

/** 是否显示分页控件 */
@property (nonatomic, assign) BOOL showPageControl;

/** 是否在只有一张图时隐藏pagecontrol，默认为YES */
@property(nonatomic) BOOL hidesForSinglePage;

/** 只展示文字轮播 */
@property (nonatomic, assign) BOOL onlyDisplayText;

/** pageControl 样式，默认为系统样式 */
@property (nonatomic, assign) FWBannerViewPageControlStyle pageControlStyle;

/** 分页控件位置 */
@property (nonatomic, assign) FWBannerViewPageControlAlignment pageControlAlignment;

/** 分页控件距离轮播图的底部间距（在默认间距基础上）的偏移量 */
@property (nonatomic, assign) CGFloat pageControlBottomOffset;

/** 分页控件距离轮播图的右边间距（在默认间距基础上）的偏移量 */
@property (nonatomic, assign) CGFloat pageControlRightOffset;

/** 分页控件小圆标大小 */
@property (nonatomic, assign) CGSize pageControlDotSize;

/** 分页空间小圆标间隔 */
@property (nonatomic, assign) CGFloat pageControlDotSpacing;

/** 当前分页控件小圆标颜色 */
@property (nonatomic, strong) UIColor *currentPageDotColor;

/** 其他分页控件小圆标颜色 */
@property (nonatomic, strong) UIColor *pageDotColor;

/** 当前分页控件小圆标图片 */
@property (nonatomic, strong) UIImage *currentPageDotImage;

/** 其他分页控件小圆标图片 */
@property (nonatomic, strong) UIImage *pageDotImage;

/** 其他分页控件自定义视图类，默认FWDotView */
@property (nonatomic) Class pageDotViewClass;

/** 轮播文字label字体颜色 */
@property (nonatomic, strong) UIColor *titleLabelTextColor;

/** 轮播文字label字体大小 */
@property (nonatomic, strong) UIFont  *titleLabelTextFont;

/** 轮播文字label背景颜色 */
@property (nonatomic, strong) UIColor *titleLabelBackgroundColor;

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

@interface FWBannerViewCell : UICollectionViewCell

@property (weak, nonatomic) UIImageView *imageView;
@property (copy, nonatomic) NSString *title;

@property (nonatomic, strong) UIColor *titleLabelTextColor;
@property (nonatomic, strong) UIFont *titleLabelTextFont;
@property (nonatomic, strong) UIColor *titleLabelBackgroundColor;
@property (nonatomic, assign) CGFloat titleLabelHeight;
@property (nonatomic, assign) NSTextAlignment titleLabelTextAlignment;
@property (nonatomic, assign) UIEdgeInsets contentViewInset;
@property (nonatomic, assign) CGFloat contentViewCornerRadius;

@property (nonatomic, assign) BOOL hasConfigured;

/** 只展示文字轮播 */
@property (nonatomic, assign) BOOL onlyDisplayText;

@end
