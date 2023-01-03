//
//  CollectionViewFlowLayout.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWCollectionViewSectionConfig

/**
 通用布局section配置类
 */
NS_SWIFT_NAME(CollectionViewSectionConfig)
@interface __FWCollectionViewSectionConfig : NSObject

/// 自定义section背景色，默认nil
@property (nonatomic, strong, nullable) UIColor *backgroundColor;
/// 自定义section句柄，可用于处理边框、圆角、阴影等其他效果
@property (nonatomic, copy, nullable) void (^customBlock)(UICollectionReusableView *reusableView);

@end

/**
 通用布局section配置协议
 */
NS_SWIFT_NAME(CollectionViewDelegateFlowLayout)
@protocol __FWCollectionViewDelegateFlowLayout <UICollectionViewDelegateFlowLayout>
@optional

/// 自定义section配置可选代理方法
/// @param collectionView UICollectionView对象
/// @param layout 布局对象
/// @param section section
- (nullable __FWCollectionViewSectionConfig *)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout configForSectionAtIndex:(NSInteger)section;

@end

#pragma mark - __FWCollectionViewFlowLayout

/**
 * 系统FlowLayout水平滚动时默认横向渲染，可通过本类开启纵向渲染
 * 示例效果如下：
 * [0  3  6  9 ]    [0  1  2   3 ]
 * [1  4  7  10] => [4  5  6   7 ]
 * [2  5  8  11]    [8  9  10  11]
 */
NS_SWIFT_NAME(CollectionViewFlowLayout)
@interface __FWCollectionViewFlowLayout : UICollectionViewFlowLayout

/// 是否启用元素纵向渲染，默认关闭，开启时需设置渲染总数itemRenderCount
@property (nonatomic, assign) BOOL itemRenderVertical;

/// 纵向渲染列数，开启itemRenderVertical且大于0时生效
@property (nonatomic, assign) NSUInteger columnCount;

/// 纵向渲染行数，开启itemRenderVertical且大于0时生效
@property (nonatomic, assign) NSUInteger rowCount;

/// 计算实际渲染总数，超出部分需渲染空数据，一般numberOfItems中调用
- (NSInteger)itemRenderCount:(NSInteger)itemCount;

/// 转换指定indexPath为纵向索引indexPath，一般无需调用
- (NSIndexPath *)verticalIndexPath:(NSIndexPath *)indexPath;

@end

#pragma mark - __FWCollectionViewDelegateWaterfallLayout

/**
 *  Enumerated structure to define direction in which items can be rendered.
 */
typedef NS_ENUM (NSUInteger, __FWCollectionViewWaterfallLayoutItemRenderDirection) {
  __FWCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst,
  __FWCollectionViewWaterfallLayoutItemRenderDirectionLeftToRight,
  __FWCollectionViewWaterfallLayoutItemRenderDirectionRightToLeft
} NS_SWIFT_NAME(CollectionViewWaterfallLayoutItemRenderDirection);

@class __FWCollectionViewWaterfallLayout;

/**
 *  The __FWCollectionViewDelegateWaterfallLayout protocol defines methods that let you coordinate with a
 *  __FWCollectionViewWaterfallLayout object to implement a waterfall-based layout.
 *  The methods of this protocol define the size of items.
 *
 *  The waterfall layout object expects the collection view’s delegate object to adopt this protocol.
 *  Therefore, implement this protocol on object assigned to your collection view’s delegate property.
 */
NS_SWIFT_NAME(CollectionViewDelegateWaterfallLayout)
@protocol __FWCollectionViewDelegateWaterfallLayout <UICollectionViewDelegate>
@required
/**
 *  Asks the delegate for the size of the specified item’s cell.
 *
 *  @param collectionView
 *    The collection view object displaying the waterfall layout.
 *  @param collectionViewLayout
 *    The layout object requesting the information.
 *  @param indexPath
 *    The index path of the item.
 *
 *  @return
 *    The original size of the specified item. Both width and height must be greater than 0.
 */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional
/**
 *  Asks the delegate for the column count in a section
 *
 *  @param collectionView
 *    The collection view object displaying the waterfall layout.
 *  @param collectionViewLayout
 *    The layout object requesting the information.
 *  @param section
 *    The section.
 *
 *  @return
 *    The original column count for that section. Must be greater than 0.
 */
- (NSInteger)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout columnCountForSection:(NSInteger)section;

/**
 *  Asks the delegate for the height of the header view in the specified section.
 *
 *  @param collectionView
 *    The collection view object displaying the waterfall layout.
 *  @param collectionViewLayout
 *    The layout object requesting the information.
 *  @param section
 *    The index of the section whose header size is being requested.
 *
 *  @return
 *    The height of the header. If you return 0, no header is added.
 *
 *  @note
 *    If you do not implement this method, the waterfall layout uses the value in its headerHeight property to set the size of the header.
 *
 *  @see
 *    headerHeight
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout heightForHeaderInSection:(NSInteger)section;

/**
 *  Asks the delegate for the height of the footer view in the specified section.
 *
 *  @param collectionView
 *    The collection view object displaying the waterfall layout.
 *  @param collectionViewLayout
 *    The layout object requesting the information.
 *  @param section
 *    The index of the section whose header size is being requested.
 *
 *  @return
 *    The height of the footer. If you return 0, no footer is added.
 *
 *  @note
 *    If you do not implement this method, the waterfall layout uses the value in its footerHeight property to set the size of the footer.
 *
 *  @see
 *    footerHeight
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout heightForFooterInSection:(NSInteger)section;

/**
 * Asks the delegate for the insets in the specified section.
 *
 * @param collectionView
 *   The collection view object displaying the waterfall layout.
 * @param collectionViewLayout
 *   The layout object requesting the information.
 * @param section
 *   The index of the section whose insets are being requested.
 *
 * @note
 *   If you do not implement this method, the waterfall layout uses the value in its sectionInset property.
 *
 * @return
 *   The insets for the section.
 */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;

/**
 * Asks the delegate for the header insets in the specified section.
 *
 * @param collectionView
 *   The collection view object displaying the waterfall layout.
 * @param collectionViewLayout
 *   The layout object requesting the information.
 * @param section
 *   The index of the section whose header insets are being requested.
 *
 * @note
 *   If you do not implement this method, the waterfall layout uses the value in its headerInset property.
 *
 * @return
 *   The headerInsets for the section.
 */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForHeaderInSection:(NSInteger)section;

/**
 * Asks the delegate for the footer insets in the specified section.
 *
 * @param collectionView
 *   The collection view object displaying the waterfall layout.
 * @param collectionViewLayout
 *   The layout object requesting the information.
 * @param section
 *   The index of the section whose footer insets are being requested.
 *
 * @note
 *   If you do not implement this method, the waterfall layout uses the value in its footerInset property.
 *
 * @return
 *   The footerInsets for the section.
 */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForFooterInSection:(NSInteger)section;

/**
 * Asks the delegate for the minimum spacing between two items in the same column
 * in the specified section. If this method is not implemented, the
 * minimumInteritemSpacing property is used for all sections.
 *
 * @param collectionView
 *   The collection view object displaying the waterfall layout.
 * @param collectionViewLayout
 *   The layout object requesting the information.
 * @param section
 *   The index of the section whose minimum interitem spacing is being requested.
 *
 * @note
 *   If you do not implement this method, the waterfall layout uses the value in its minimumInteritemSpacing property to determine the amount of space between items in the same column.
 *
 * @return
 *   The minimum interitem spacing.
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;

/**
 * Asks the delegate for the minimum spacing between colums in a secified section. If this method is not implemented, the
 * minimumColumnSpacing property is used for all sections.
 *
 * @param collectionView
 *   The collection view object displaying the waterfall layout.
 * @param collectionViewLayout
 *   The layout object requesting the information.
 * @param section
 *   The index of the section whose minimum interitem spacing is being requested.
 *
 * @note
 *   If you do not implement this method, the waterfall layout uses the value in its minimumColumnSpacing property to determine the amount of space between columns in each section.
 *
 * @return
 *   The minimum spacing between each column.
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumColumnSpacingForSectionAtIndex:(NSInteger)section;

/**
 *  Asks the delegate for the pin offset of the header view in the specified section.
 *
 *  @param collectionView
 *    The collection view object displaying the waterfall layout.
 *  @param collectionViewLayout
 *    The layout object requesting the information.
 *  @param section
 *    The index of the section whose pin offset is being requested.
 *
 *  @return
 *    The pin offset of the header. If you return less than 0, header pin is disabled in the specified section.
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout pinOffsetForHeaderInSection:(NSInteger)section;

@end

#pragma mark - __FWCollectionViewWaterfallLayout

/**
 *  The __FWCollectionViewWaterfallLayout class is a concrete layout object that organizes items into waterfall-based grids
 *  with optional header and footer views for each section.
 *
 *  A waterfall layout works with the collection view’s delegate object to determine the size of items, headers, and footers
 *  in each section. That delegate object must conform to the `__FWCollectionViewDelegateWaterfallLayout` protocol.
 *
 *  Each section in a waterfall layout can have its own custom header and footer. To configure the header or footer for a view,
 *  you must configure the height of the header or footer to be non zero. You can do this by implementing the appropriate delegate
 *  methods or by assigning appropriate values to the `headerHeight` and `footerHeight` properties.
 *  If the header or footer height is 0, the corresponding view is not added to the collection view.
 *
 *  @note __FWCollectionViewWaterfallLayout doesn't support decoration view, and it supports vertical scrolling direction only.
 *  @see https://github.com/chiahsien/CHTCollectionViewWaterfallLayout
 */
NS_SWIFT_NAME(CollectionViewWaterfallLayout)
@interface __FWCollectionViewWaterfallLayout : UICollectionViewLayout

/**
 *  How many columns for this layout.
 *  @note Default: 2
 */
@property (nonatomic, assign) NSInteger columnCount;

/**
 *  The minimum spacing to use between successive columns.
 *  @note Default: 10.0
 */
@property (nonatomic, assign) CGFloat minimumColumnSpacing;

/**
 *  The minimum spacing to use between items in the same column.
 *  @note Default: 10.0
 *  @note This spacing is not applied to the space between header and columns or between columns and footer.
 */
@property (nonatomic, assign) CGFloat minimumInteritemSpacing;

/**
 *  Height for section header
 *  @note
 *    If your collectionView's delegate doesn't implement `collectionView:layout:heightForHeaderInSection:`,
 *    then this value will be used.
 *
 *    Default: 0
 */
@property (nonatomic, assign) CGFloat headerHeight;

/**
 *  Height for section footer
 *  @note
 *    If your collectionView's delegate doesn't implement `collectionView:layout:heightForFooterInSection:`,
 *    then this value will be used.
 *
 *    Default: 0
 */
@property (nonatomic, assign) CGFloat footerHeight;

/**
 *  The margins that are used to lay out the header for each section.
 *  @note
 *    These insets are applied to the headers in each section.
 *    They represent the distance between the top of the collection view and the top of the content items
 *    They also indicate the spacing on either side of the header. They do not affect the size of the headers or footers themselves.
 *
 *    Default: UIEdgeInsetsZero
 */
@property (nonatomic, assign) UIEdgeInsets headerInset;

/**
 *  The margins that are used to lay out the footer for each section.
 *  @note
 *    These insets are applied to the footers in each section.
 *    They represent the distance between the top of the collection view and the top of the content items
 *    They also indicate the spacing on either side of the footer. They do not affect the size of the headers or footers themselves.
 *
 *    Default: UIEdgeInsetsZero
 */
@property (nonatomic, assign) UIEdgeInsets footerInset;

/**
 *  The margins that are used to lay out content in each section.
 *  @note
 *    Section insets are margins applied only to the items in the section.
 *    They represent the distance between the header view and the columns and between the columns and the footer view.
 *    They also indicate the spacing on either side of columns. They do not affect the size of the headers or footers themselves.
 *
 *    Default: UIEdgeInsetsZero
 */
@property (nonatomic, assign) UIEdgeInsets sectionInset;

/**
 *  The direction in which items will be rendered in subsequent rows.
 *  @note
 *    The direction in which each item is rendered. This could be left to right (__FWCollectionViewWaterfallLayoutItemRenderDirectionLeftToRight), right to left (__FWCollectionViewWaterfallLayoutItemRenderDirectionRightToLeft), or shortest column fills first (__FWCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst).
 *
 *    Default: __FWCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst
 */
@property (nonatomic, assign) __FWCollectionViewWaterfallLayoutItemRenderDirection itemRenderDirection;

/**
 *  The minimum height of the collection view's content.
 *  @note
 *    The minimum height of the collection view's content. This could be used to allow hidden headers with no content.
 *
 *    Default: 0.f
 */
@property (nonatomic, assign) CGFloat minimumContentHeight;

/**
 *  Set these properties to YES to get headers that pin to the top of the screen while scrolling.
 *
 *    Default: NO
 */
@property (nonatomic, assign) BOOL sectionHeadersPinToVisibleBounds;

/**
 *  The calculated width of an item in the specified section.
 *  @note
 *    The width of an item is calculated based on number of columns, the collection view width, and the horizontal insets for that section.
 */
- (CGFloat)itemWidthInSectionAtIndex:(NSInteger)section;

@end

#pragma mark - __FWCollectionViewAlignLayout

typedef NS_ENUM(NSInteger, __FWCollectionViewItemsHorizontalAlignment) {
    __FWCollectionViewItemsHorizontalAlignmentFlow,       /**< 水平流式（水平方向效果与 UICollectionViewDelegateFlowLayout 一致） */
    __FWCollectionViewItemsHorizontalAlignmentFlowFilled, /**< 水平流式并充满（行内各 item 均分行内剩余空间，使行内充满显示） */
    __FWCollectionViewItemsHorizontalAlignmentLeft,       /**< 水平居左 */
    __FWCollectionViewItemsHorizontalAlignmentCenter,     /**< 水平居中 */
    __FWCollectionViewItemsHorizontalAlignmentRight       /**< 水平居右 */
} NS_SWIFT_NAME(CollectionViewItemsHorizontalAlignment);

typedef NS_ENUM(NSInteger, __FWCollectionViewItemsVerticalAlignment) {
    __FWCollectionViewItemsVerticalAlignmentCenter, /**< 竖直方向居中 */
    __FWCollectionViewItemsVerticalAlignmentTop,    /**< 竖直方向顶部对齐 */
    __FWCollectionViewItemsVerticalAlignmentBottom  /**< 竖直方向底部对齐 */
} NS_SWIFT_NAME(CollectionViewItemsVerticalAlignment);

typedef NS_ENUM(NSInteger, __FWCollectionViewItemsDirection) {
    __FWCollectionViewItemsDirectionLTR, /**< 排布方向从左到右 */
    __FWCollectionViewItemsDirectionRTL  /**< 排布方向从右到左 */
} NS_SWIFT_NAME(CollectionViewItemsDirection);

@class __FWCollectionViewAlignLayout;

/// 扩展 UICollectionViewDelegateFlowLayout/NSCollectionViewDelegateFlowLayout 协议，
/// 添加设置水平、竖直方向的对齐方式以及 items 排布方向协议方法
NS_SWIFT_NAME(CollectionViewDelegateAlignLayout)
@protocol __FWCollectionViewDelegateAlignLayout <__FWCollectionViewDelegateFlowLayout>

@optional

/// 设置不同 section items 水平方向的对齐方式
/// @param collectionView UICollectionView/NSCollectionView 对象
/// @param layout 布局对象
/// @param section section
- (__FWCollectionViewItemsHorizontalAlignment)collectionView:(UICollectionView *)collectionView layout:(__FWCollectionViewAlignLayout *)layout itemsHorizontalAlignmentInSection:(NSInteger)section;

/// 设置不同 section items 竖直方向的对齐方式
/// @param collectionView UICollectionView/NSCollectionView 对象
/// @param layout 布局对象
/// @param section section
- (__FWCollectionViewItemsVerticalAlignment)collectionView:(UICollectionView *)collectionView layout:(__FWCollectionViewAlignLayout *)layout itemsVerticalAlignmentInSection:(NSInteger)section;

/// 设置不同 section items 的排布方向
/// @param collectionView UICollectionView/NSCollectionView 对象
/// @param layout 布局对象
/// @param section section
- (__FWCollectionViewItemsDirection)collectionView:(UICollectionView *)collectionView layout:(__FWCollectionViewAlignLayout *)layout itemsDirectionInSection:(NSInteger)section;

@end

/// 在 UICollectionViewFlowLayout/NSCollectionViewFlowLayout 基础上，
/// 自定义 UICollectionView/NSCollectionView 对齐布局
///
/// 实现以下功能：
/// 1. 设置水平方向对齐方式：流式（默认）、流式填充、居左、居中、居右、平铺；
/// 2. 设置竖直方向对齐方式：居中（默认）、置顶、置底；
/// 3. 设置显示条目排布方向：从左到右（默认）、从右到左。
///
/// @see https://github.com/Coder-ZJQ/JQCollectionViewAlignLayout
NS_SWIFT_NAME(CollectionViewAlignLayout)
@interface __FWCollectionViewAlignLayout : UICollectionViewFlowLayout

/// 水平方向对齐方式，默认为流式(__FWCollectionViewItemsHorizontalAlignmentFlow)
@property (nonatomic) __FWCollectionViewItemsHorizontalAlignment itemsHorizontalAlignment;
/// 竖直方向对齐方式，默认为居中(__FWCollectionViewItemsVerticalAlignmentCenter)
@property (nonatomic) __FWCollectionViewItemsVerticalAlignment itemsVerticalAlignment;
/// items 排布方向，默认为从左到右(__FWCollectionViewItemsDirectionLTR)
@property (nonatomic) __FWCollectionViewItemsDirection itemsDirection;

// 禁用 setScrollDirection: 方法，不可设置滚动方向，默认为竖直滚动
- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
