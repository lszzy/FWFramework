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

/// reloadData清空尺寸缓存
- (void)fwReloadDataWithoutCache;

/// reloadData禁用动画
- (void)fwReloadDataWithoutAnimation;

/// reloadSections禁用动画
- (void)fwReloadSectionsWithoutAnimation:(NSIndexSet *)sections;

/// reloadItems禁用动画
- (void)fwReloadItemsWithoutAnimation:(NSArray<NSIndexPath *> *)indexPaths;

@end

@interface UICollectionViewCell (FWFramework)

/// 获取当前所属collectionView
@property (nonatomic, weak, readonly, nullable) UICollectionView *fwCollectionView;

/// 获取当前显示indexPath
@property (nonatomic, readonly, nullable) NSIndexPath *fwIndexPath;

@end

// iOS9+可通过UICollectionViewFlowLayout调用sectionHeadersPinToVisibleBounds实现Header悬停效果
@interface UICollectionViewFlowLayout (FWFramework)

/// 设置Header和Footer是否悬停，支持iOS9+
- (void)fwHoverWithHeader:(BOOL)header footer:(BOOL)footer;

@end

NS_ASSUME_NONNULL_END
