/*!
 @header     UICollectionView+FWFramework.h
 @indexgroup FWFramework
 @brief      UICollectionView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/31
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// UICollectionView分类
@interface UICollectionView (FWFramework)

/// reloadData完成回调
- (void)fwReloadDataWithCompletion:(nullable void (^)(void))completion;

/// reloadData禁用动画
- (void)fwReloadDataWithoutAnimation;

/// reloadData清空尺寸缓存
- (void)fwReloadDataWithoutCache;

/// reloadItems禁用动画
- (void)fwReloadItemsWithoutAnimation:(NSArray<NSIndexPath *> *)indexPaths;

@end

@interface UICollectionViewCell (FWFramework)

/// 获取当前所属collectionView
- (nullable UICollectionView *)fwCollectionView;

/// 获取当前显示indexPath
- (nullable NSIndexPath *)fwIndexPath;

@end

// iOS9+可通过UICollectionViewFlowLayout调用sectionHeadersPinToVisibleBounds实现Header悬停效果
@interface UICollectionViewFlowLayout (FWFramework)

/// 设置Header和Footer是否悬停，支持iOS9+
- (void)fwHoverWithHeader:(BOOL)header footer:(BOOL)footer;

/*!
 @brief 默认FlowLayout水平滚动时从左往右布局，可通过此方法转换为上下布局矩阵，仅支持单section
 @discussion 示例图如下：
    [0  3  6  9 ]    [(0,0)  (1,0)  (2,0)  (3,0)]
    [1  4  7  10] => [(0,1)  (1,1)  (2,1)  (3,1)]
    [2  5  8  11]    [(0,2)  (1,2)  (2,2)  (3,2)]
 
 @param indexPath 原始indexPath
 @param columnCount 每页列数
 @param rowCount 每页行数
 @return 上下布局矩阵，section为行坐标y，item为列坐标x
 */
- (NSIndexPath *)fwHorizontalMatrixWithIndexPath:(NSIndexPath *)indexPath columnCount:(NSInteger)columnCount rowCount:(NSInteger)rowCount;

/*!
 @brief 默认FlowLayout水平滚动时从左往右布局，可通过此方法转换为上下布局索引，仅支持单section
 @discussion 示例图如下：
    [0  3  6  9 ]    [0  1  2   3]
    [1  4  7  10] => [4  5  6   7]
    [2  5  8  11]    [8  9  10  11]
 
 @param indexPath 原始indexPath
 @param columnCount 每页列数
 @param rowCount 每页行数
 @return 上下布局索引，section为0，item为索引位置
 */
- (NSIndexPath *)fwHorizontalIndexWithIndexPath:(NSIndexPath *)indexPath columnCount:(NSInteger)columnCount rowCount:(NSInteger)rowCount;

@end

NS_ASSUME_NONNULL_END
